# Plano de Implementação MVP - Feature Matchpoint

## Documento Técnico Completo

**Versão:** 1.1 (Revisada)
**Data:** 06/02/2026
**Projeto:** MubeApp (Flutter + Firebase)

---

## 1. RESUMO EXECUTIVO

Este documento detalha o plano de implementação para o MVP da feature Matchpoint, incluindo:
- Remoção do match fake de teste
- Implementação do limite diário de 50 likes
- Criação das Cloud Functions críticas
- Atualização das Firestore Rules
- Implementação do ranking de hashtags
- Alterações necessárias no app Flutter

---

## 2. ANÁLISE DO ESTADO ATUAL

### 2.1 Match Fake de Teste Identificado

**Localização:** [`lib/src/core/data/app_seeder.dart`](lib/src/core/data/app_seeder.dart:1)

O arquivo `app_seeder.dart` contém a classe `AppSeeder` que gera perfis fake para teste. Estes perfis são identificados pelo email `@seeded.mube.app` e são usados para popular o app durante desenvolvimento.

**Como Remover:**
1. Remover a opção "Limpar Perfis Fake" da tela de Settings
2. Garantir que o seeder não seja executado em produção
3. Adicionar flag de ambiente para controlar execução

**Código a modificar em [`lib/src/features/settings/presentation/settings_screen.dart`](lib/src/features/settings/presentation/settings_screen.dart:347):**

```dart
// REMOVER este método e sua chamada no UI
void _deleteSeededUsers(BuildContext context, WidgetRef ref) async { ... }
```

### 2.2 Limite Diário Atual (Errado)

Atualmente não existe limite implementado no backend. A spec do Backend Spec MVP v1 menciona 20 likes, mas o requisito atual é **50 likes por dia**.

**Schema necessário no documento `users/{uid}`:**
```typescript
private_stats: {
  today_date: string,      // "2026-02-06" formato ISO
  likes_count: number,     // contador do dia
  last_reset: timestamp    // para controle
}
```

### 2.3 Cloud Functions Existentes

Atualmente existem apenas:
- [`onMessageCreated`](functions/src/index.ts:18) - Trigger de mensagens
- [`migrategeohashes`](functions/src/geohash_migration.ts:13) - Migração de geohash
- [`updateusergeohash`](functions/src/geohash_migration.ts:109) - Atualização de geohash

**Faltam implementar (conforme Backend Spec):**
- `submitMatchpointAction`
- `manageBandInvite`
- `initiateContact`
- `onReportCreated`
- `liftSuspensions` (scheduled)
- `pruneOldInteractions` (scheduled)

### 2.5 Migração de `interactions` de Subcoleção para Coleção Global

**Estado atual:** Interações são armazenadas em `users/{uid}/interactions/{targetId}` (subcoleção).

**Estado desejado (spec):** Interações em coleção global `interactions` (Auto-ID) com campos `autor_id`, `alvo_id`, `acao`, `pair_key`.

**Impacto:** Esta é uma mudança estrutural significativa. Dados existentes em subcoleções precisarão de migração.

**Plano de migração:**
1. Criar Cloud Function de migração one-time (similar a `migrategeohashes`)
2. Ler todos os docs de `users/{uid}/interactions/{targetId}`
3. Recriar na coleção global `interactions` com o schema novo
4. Após validação, remover subcoleções antigas

### 2.6 Firestore Rules Atuais vs Spec Blindada

As rules atuais permitem:
- Escrita direta em `interactions` pelo cliente (subcoleção `users/{uid}/interactions`)
- Criação de matches pelo cliente (`matchpoint_remote_data_source.dart` linha 112)
- Updates em campos protegidos (`status`, `private_stats`)
- Qualquer autenticado pode criar invites

A spec blindada exige:
- **Bloqueio total** de escrita em `interactions`, `invites`, `matches`
- Todas as operações via Cloud Functions
- Validação rigorosa de campos editáveis em `users`

---

## 3. PLANO DE IMPLEMENTAÇÃO PASSO A PASSO

### FASE 1: Cloud Functions Backend (CRÍTICO)

#### 3.1.1 submitMatchpointAction

**Arquivo:** [`functions/src/matchpoint.ts`](functions/src/matchpoint.ts:1) (novo)

```typescript
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {getFirestore, Timestamp} from "firebase-admin/firestore";

const DAILY_LIKE_LIMIT = 50;
const db = getFirestore();

interface SubmitMatchpointActionRequest {
  target_id: string;
  target_type: 'profissional' | 'banda' | 'estudio';
  action: 'like' | 'dislike';
}

export const submitMatchpointAction = onCall(
  async (request) => {
    // 1. Auth Check
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const myUid = request.auth.uid;
    const {target_id, target_type, action} = request.data as SubmitMatchpointActionRequest;

    // 2. Validar input
    if (!target_id || !target_type || !action) {
      throw new HttpsError("invalid-argument", "Missing required fields");
    }

    // 3. Verificar limite diário (Lazy Reset)
    const userRef = db.collection("users").doc(myUid);
    const userDoc = await userRef.get();
    
    if (!userDoc.exists) {
      throw new HttpsError("not-found", "User not found");
    }

    const userData = userDoc.data()!;
    const privateStats = userData.private_stats || {};
    const today = new Date().toISOString().split('T')[0]; // "2026-02-06"
    
    let likesCount = privateStats.likes_count || 0;
    let todayDate = privateStats.today_date;

    // Reset lazy se mudou o dia
    if (todayDate !== today) {
      likesCount = 0;
      todayDate = today;
    }

    // Verificar quota apenas para likes
    if (action === 'like' && likesCount >= DAILY_LIKE_LIMIT) {
      throw new HttpsError("resource-exhausted", "QUOTA_EXCEEDED");
    }

    // 4. Criar interação
    const pairKey = [myUid, target_id].sort().join('_');
    const interactionRef = db.collection("interactions").doc();

    const batch = db.batch();

    batch.set(interactionRef, {
      autor_id: myUid,
      alvo_id: target_id,
      alvo_tipo: target_type,
      acao: action,
      timestamp: Timestamp.now(),
      pair_key: pairKey,
    });

    // 5. Atualizar contador apenas se for like
    if (action === 'like') {
      batch.update(userRef, {
        'private_stats.likes_count': likesCount + 1,
        'private_stats.today_date': today,
        'private_stats.last_reset': Timestamp.now(),
      });
    }

    await batch.commit();

    // 6. Verificar match (se for like)
    let isMatch = false;
    if (action === 'like') {
      const reverseInteraction = await db
        .collection("interactions")
        .where("autor_id", "==", target_id)
        .where("alvo_id", "==", myUid)
        .where("acao", "==", "like")
        .limit(1)
        .get();

      if (!reverseInteraction.empty) {
        isMatch = true;
        await processMatch(myUid, target_id, target_type);
      }
    }

    return {
      success: true,
      isMatch,
      remainingLikes: action === 'like' ? DAILY_LIKE_LIMIT - likesCount - 1 : DAILY_LIKE_LIMIT - likesCount,
    };
  }
);

async function processMatch(uid1: string, uid2: string, targetType: string) {
  const pairKey = [uid1, uid2].sort().join('_');
  
  // Verificar se match já existe (idempotência)
  const existingMatch = await db
    .collection("matches")
    .where("pair_key", "==", pairKey)
    .limit(1)
    .get();

  if (!existingMatch.empty) {
    return; // Match já existe
  }

  const matchRef = db.collection("matches").doc();
  const batch = db.batch();

  // Criar match
  batch.set(matchRef, {
    pair_key: pairKey,
    user_id_1: uid1,
    user_id_2: uid2,
    status: 'matched',
    created_at: Timestamp.now(),
    matched_at: Timestamp.now(),
  });

  await batch.commit();

  // Criar chat via initiateContact
  await createChatForMatch(uid1, uid2);

  // Enviar notificação push
  await sendMatchNotification(uid1, uid2);
}

async function createChatForMatch(uid1: string, uid2: string) {
  // IMPORTANTE: Usa "conversations" (coleção existente no app) em vez de "chats"
  // O conversationId é determinístico: uidMenor_uidMaior
  const conversationId = [uid1, uid2].sort().join('_');
  const conversationRef = db.collection("conversations").doc(conversationId);
  
  // Verificar se já existe (idempotência)
  const existing = await conversationRef.get();
  if (existing.exists) return;
  
  // Buscar dados dos usuários
  const [user1Doc, user2Doc] = await Promise.all([
    db.collection("users").doc(uid1).get(),
    db.collection("users").doc(uid2).get(),
  ]);

  const user1Data = user1Doc.data();
  const user2Data = user2Doc.data();

  const batch = db.batch();

  // 1. Criar documento da conversa
  batch.set(conversationRef, {
    participants: [uid1, uid2],
    participantsMap: {[uid1]: true, [uid2]: true},
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
    readUntil: {[uid1]: Timestamp.fromMillis(0), [uid2]: Timestamp.fromMillis(0)},
    lastMessageText: null,
    lastMessageAt: null,
    lastSenderId: null,
    type: 'matchpoint',
  });

  // 2. Criar preview para uid1
  const preview1Ref = db
    .collection("users").doc(uid1)
    .collection("conversationPreviews").doc(conversationId);

  batch.set(preview1Ref, {
    otherUserId: uid2,
    otherUserName: user2Data?.nome || 'Usuário',
    otherUserPhoto: user2Data?.foto || null,
    lastMessageText: null,
    lastMessageAt: null,
    lastSenderId: null,
    unreadCount: 0,
    updatedAt: Timestamp.now(),
    type: 'matchpoint',
  });

  // 3. Criar preview para uid2
  const preview2Ref = db
    .collection("users").doc(uid2)
    .collection("conversationPreviews").doc(conversationId);

  batch.set(preview2Ref, {
    otherUserId: uid1,
    otherUserName: user1Data?.nome || 'Usuário',
    otherUserPhoto: user1Data?.foto || null,
    lastMessageText: null,
    lastMessageAt: null,
    lastSenderId: null,
    unreadCount: 0,
    updatedAt: Timestamp.now(),
    type: 'matchpoint',
  });

  await batch.commit();
}

async function sendMatchNotification(fromUid: string, toUid: string) {
  const toUserDoc = await db.collection("users").doc(toUid).get();
  const toUserData = toUserDoc.data();
  const fcmToken = toUserData?.fcm_token;

  if (!fcmToken) return;

  const fromUserDoc = await db.collection("users").doc(fromUid).get();
  const fromUserData = fromUserDoc.data();

  await admin.messaging().send({
    token: fcmToken,
    notification: {
      title: "Novo Match! 🎵",
      body: `Você deu match com ${fromUserData?.nome || 'alguém'}!`,
    },
    data: {
      type: "new_match",
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
  });
}
```

#### 3.1.2 manageBandInvite

**Arquivo:** [`functions/src/bands.ts`](functions/src/bands.ts:1) (novo)

```typescript
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore, Timestamp, FieldValue} from "firebase-admin/firestore";

const db = getFirestore();

interface BandInviteRequest {
  action: 'send' | 'accept' | 'decline';
  band_id?: string;
  target_uid?: string;
  invite_id?: string;
}

export const manageBandInvite = onCall(
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const myUid = request.auth.uid;
    const {action, band_id, target_uid, invite_id} = request.data as BandInviteRequest;

    switch (action) {
      case 'send':
        return await sendInvite(myUid, band_id!, target_uid!);
      case 'accept':
        return await acceptInvite(myUid, invite_id!);
      case 'decline':
        return await declineInvite(myUid, invite_id!);
      default:
        throw new HttpsError("invalid-argument", "Invalid action");
    }
  }
);

async function sendInvite(adminUid: string, bandId: string, targetUid: string) {
  // Verificar se adminUid é admin da banda
  const bandDoc = await db.collection("bands").doc(bandId).get();
  if (!bandDoc.exists) {
    throw new HttpsError("not-found", "Band not found");
  }

  const bandData = bandDoc.data()!;
  if (bandData.admin_id !== adminUid) {
    throw new HttpsError("permission-denied", "Only admin can send invites");
  }

  // Verificar se target já é membro
  const membros = bandData.membros_ids || [];
  if (membros.includes(targetUid)) {
    throw new HttpsError("already-exists", "User is already a member");
  }

  // Verificar se já existe invite pendente
  const existingInvite = await db
    .collection("invites")
    .where("band_id", "==", bandId)
    .where("target_uid", "==", targetUid)
    .where("status", "==", "pendente")
    .limit(1)
    .get();

  if (!existingInvite.empty) {
    throw new HttpsError("already-exists", "Pending invite already exists");
  }

  // Criar invite
  const inviteRef = db.collection("invites").doc();
  await inviteRef.set({
    band_id: bandId,
    target_uid: targetUid,
    from_user_id: adminUid,
    status: "pendente",
    created_at: Timestamp.now(),
    updated_at: Timestamp.now(),
  });

  return {success: true, invite_id: inviteRef.id};
}

async function acceptInvite(targetUid: string, inviteId: string) {
  const inviteRef = db.collection("invites").doc(inviteId);
  const inviteDoc = await inviteRef.get();

  if (!inviteDoc.exists) {
    throw new HttpsError("not-found", "Invite not found");
  }

  const inviteData = inviteDoc.data()!;
  if (inviteData.target_uid !== targetUid) {
    throw new HttpsError("permission-denied", "Not your invite");
  }

  if (inviteData.status !== "pendente") {
    throw new HttpsError("failed-precondition", "Invite is not pending");
  }

  const bandRef = db.collection("bands").doc(inviteData.band_id);
  const targetUserRef = db.collection("users").doc(targetUid);

  // Transação atômica
  await db.runTransaction(async (transaction) => {
    const [bandDoc, userDoc] = await Promise.all([
      transaction.get(bandRef),
      transaction.get(targetUserRef),
    ]);

    const bandData = bandDoc.data()!;
    const userData = userDoc.data()!;

    const membrosIds = bandData.membros_ids || [];
    const membrosPreview = bandData.membros_preview || [];

    // Adicionar membro
    membrosIds.push(targetUid);
    membrosPreview.push({
      uid: targetUid,
      nome: userData.nome || 'Usuário',
      foto: userData.foto || null,
      instrumento: userData.profissional?.instrumentos?.[0] || null,
    });

    // Atualizar banda
    transaction.update(bandRef, {
      membros_ids: membrosIds,
      membros_preview: membrosPreview,
      status: membrosIds.length >= 3 ? "ativa" : bandData.status,
      updated_at: Timestamp.now(),
    });

    // Atualizar invite
    transaction.update(inviteRef, {
      status: "aceito",
      updated_at: Timestamp.now(),
    });
  });

  return {success: true};
}

async function declineInvite(targetUid: string, inviteId: string) {
  const inviteRef = db.collection("invites").doc(inviteId);
  const inviteDoc = await inviteRef.get();

  if (!inviteDoc.exists) {
    throw new HttpsError("not-found", "Invite not found");
  }

  const inviteData = inviteDoc.data()!;
  if (inviteData.target_uid !== targetUid) {
    throw new HttpsError("permission-denied", "Not your invite");
  }

  await inviteRef.update({
    status: "recusado",
    updated_at: Timestamp.now(),
  });

  return {success: true};
}
```

#### 3.1.3 initiateContact

**Arquivo:** [`functions/src/chat.ts`](functions/src/chat.ts:1) (novo)

```typescript
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore, Timestamp} from "firebase-admin/firestore";

const db = getFirestore();

interface InitiateContactRequest {
  target_id: string;
  target_type: string;
}

export const initiateContact = onCall(
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const myUid = request.auth.uid;
    const {target_id, target_type} = request.data as InitiateContactRequest;

    if (!target_id) {
      throw new HttpsError("invalid-argument", "target_id is required");
    }

    const pairKey = [myUid, target_id].sort().join('_');

    // Verificar se chat já existe
    const existingChat = await db
      .collection("chats")
      .where("pair_key", "==", pairKey)
      .limit(1)
      .get();

    if (!existingChat.empty) {
      return {
        success: true,
        chatId: existingChat.docs[0].id,
        isNew: false,
      };
    }

    // Buscar dados dos usuários
    const [myDoc, targetDoc] = await Promise.all([
      db.collection("users").doc(myUid).get(),
      db.collection("users").doc(target_id).get(),
    ]);

    if (!targetDoc.exists) {
      throw new HttpsError("not-found", "Target user not found");
    }

    const myData = myDoc.data();
    const targetData = targetDoc.data();

    // Criar novo chat
    const chatRef = db.collection("chats").doc();
    await chatRef.set({
      pair_key: pairKey,
      participantes_ids: [myUid, target_id],
      participantes_data: {
        [myUid]: {
          nome: myData?.nome || 'Usuário',
          foto: myData?.foto || null,
        },
        [target_id]: {
          nome: targetData?.nome || 'Usuário',
          foto: targetData?.foto || null,
        },
      },
      tipo_origem: 'direto',
      created_at: Timestamp.now(),
      updated_at: Timestamp.now(),
      last_message: null,
      last_message_at: null,
      unread_counts: {
        [myUid]: 0,
        [target_id]: 0,
      },
    });

    return {
      success: true,
      chatId: chatRef.id,
      isNew: true,
    };
  }
);
```

#### 3.1.4 onReportCreated

**Arquivo:** [`functions/src/moderation.ts`](functions/src/moderation.ts:1) (novo)

```typescript
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";

const db = getFirestore();
const REPORTS_THRESHOLD = 10;
const SUSPENSION_DAYS = 7;

export const onReportCreated = onDocumentCreated(
  "reports/{reportId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const reportData = snapshot.data();
    const alvoId = reportData.alvo_id;
    const alvoTipo = reportData.alvo_tipo; // 'user' | 'band'

    if (alvoTipo === 'user') {
      await handleUserReport(alvoId);
    } else if (alvoTipo === 'band') {
      await handleBandReport(alvoId, reportData);
    }
  }
);

async function handleUserReport(userId: string) {
  const userRef = db.collection("users").doc(userId);

  await db.runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);
    if (!userDoc.exists) return;

    const userData = userDoc.data()!;
    const currentCount = userData.report_count_total || 0;
    const newCount = currentCount + 1;

    const updateData: Record<string, unknown> = {
      report_count_total: newCount,
    };

    // Suspender se atingir threshold
    if (newCount >= REPORTS_THRESHOLD) {
      const suspensionEnd = new Date();
      suspensionEnd.setDate(suspensionEnd.getDate() + SUSPENSION_DAYS);

      updateData.status = "suspenso";
      updateData.suspension_end_date = Timestamp.fromDate(suspensionEnd);
    }

    transaction.update(userRef, updateData);
  });
}

async function handleBandReport(bandId: string, reportData: any) {
  // Para bandas, redirecionar a denúncia para o admin
  const bandDoc = await db.collection("bands").doc(bandId).get();
  if (!bandDoc.exists) return;

  const bandData = bandDoc.data()!;
  const adminId = bandData.admin_id;

  if (!adminId) return;

  // Incrementar contador do admin
  const adminRef = db.collection("users").doc(adminId);
  await adminRef.update({
    report_count_total: FieldValue.increment(1),
  });

  // Opcional: Criar notificação para o admin
  // Opcional: Criar registro de denúncia contra admin
}
```

#### 3.1.5 Scheduled Functions

**Arquivo:** [`functions/src/scheduled.ts`](functions/src/scheduled.ts:1) (novo)

```typescript
import {onSchedule} from "firebase-functions/v2/scheduler";
import {getFirestore, Timestamp} from "firebase-admin/firestore";

const db = getFirestore();

/**
 * liftSuspensions - Executa diariamente às 00:00
 * Remove suspensões de usuários que cumpriram a pena
 */
export const liftSuspensions = onSchedule(
  {
    schedule: "0 0 * * *", // Todo dia à meia-noite
    timeZone: "America/Sao_Paulo",
  },
  async () => {
    const now = Timestamp.now();

    const suspendedUsers = await db
      .collection("users")
      .where("status", "==", "suspenso")
      .where("suspension_end_date", "<=", now)
      .get();

    const batch = db.batch();
    let count = 0;

    suspendedUsers.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: "ativo",
        suspension_end_date: null,
      });
      count++;
    });

    if (count > 0) {
      await batch.commit();
      console.log(`✅ ${count} suspensões removidas`);
    }
  }
);

/**
 * pruneOldInteractions - Executa diariamente às 02:00
 * Remove dislikes antigos (>30 dias) para permitir reaparecimento
 */
export const pruneOldInteractions = onSchedule(
  {
    schedule: "0 2 * * *", // Todo dia às 2h da manhã
    timeZone: "America/Sao_Paulo",
  },
  async () => {
    const thirtyDaysAgo = Timestamp.fromMillis(
      Date.now() - 30 * 24 * 60 * 60 * 1000
    );

    const oldDislikes = await db
      .collection("interactions")
      .where("acao", "==", "dislike")
      .where("timestamp", "<", thirtyDaysAgo)
      .limit(500) // Batch limit
      .get();

    const batch = db.batch();
    let count = 0;

    oldDislikes.docs.forEach((doc) => {
      batch.delete(doc.ref);
      count++;
    });

    if (count > 0) {
      await batch.commit();
      console.log(`🗑️ ${count} interações antigas removidas`);
    }
  }
);
```

#### 3.1.6 Atualizar index.ts

**Arquivo:** [`functions/src/index.ts`](functions/src/index.ts:1)

```typescript
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

// Exportações existentes
export {migrategeohashes, updateusergeohash} from "./geohash_migration";

// Novas exportações - Matchpoint
export {submitMatchpointAction} from "./matchpoint";
export {manageBandInvite} from "./bands";
export {initiateContact} from "./chat";
export {onReportCreated} from "./moderation";
export {liftSuspensions, pruneOldInteractions} from "./scheduled";
export {onHashtagUsed, recalculateHashtagRanking} from "./hashtags";

// onMessageCreated existente (manter)
export const onMessageCreated = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    // ... código existente permanece igual
  }
);
```

---

### FASE 2: Firestore Rules (Blindada)

**Arquivo:** [`firestore.rules`](firestore.rules:1)

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ================================================================
    // FUNÇÕES AUXILIARES
    // ================================================================
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    function isParticipantByConversationId(conversationId) {
      return request.auth.uid in conversationId.split('_');
    }

    function isValidLocationUpdate() {
      return request.resource.data.location is map
        && request.resource.data.location.keys().hasAll(['lat', 'lng', 'geohash', 'updated_at'])
        && request.resource.data.location.lat is number
        && request.resource.data.location.lng is number
        && request.resource.data.location.geohash is string;
    }

    // ================================================================
    // CONFIG - Configurações do App
    // ================================================================
    match /config/{document=**} {
      allow read: if isAuthenticated();
      allow write: if false; // Apenas via Admin SDK
    }

    // ================================================================
    // USERS - Perfis de Usuários
    // ================================================================
    match /users/{userId} {
      // Leitura: qualquer autenticado pode ler
      allow read: if isAuthenticated();

      // Criação: apenas o próprio usuário
      allow create: if isOwner(userId);

      // Deleção: apenas o próprio usuário
      allow delete: if isOwner(userId);

      // Update: apenas dono, com validação de campos
      allow update: if isOwner(userId)
        // Campos imutáveis (nunca podem mudar)
        && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['uid', 'tipo_conta', 'created_at']))
        // Campos protegidos (apenas server-side)
        && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['status', 'private_stats', 'report_count_total', 'suspension_end_date']))
        // Validação de location se presente
        && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['location']) || isValidLocationUpdate());

      // ================================================================
      // FAVORITES - Subcoleção
      // ================================================================
      match /favorites/{favoriteId} {
        allow read, write: if isOwner(userId);
      }

      // ================================================================
      // BLOCKED - Usuários bloqueados
      // ================================================================
      match /blocked/{blockedId} {
        allow read, write: if isOwner(userId);
      }

      // ================================================================
      // CONVERSATION PREVIEWS - Lista de conversas
      // ================================================================
      match /conversationPreviews/{previewId} {
        allow read: if isOwner(userId);
        allow create, update: if isAuthenticated() 
          && request.auth.uid in previewId.split('_');
        allow delete: if isOwner(userId);
      }

      // ================================================================
      // NOTIFICATIONS - Histórico de notificações
      // ================================================================
      match /notifications/{notificationId} {
        allow read, write, delete: if isOwner(userId);
      }
    }

    // ================================================================
    // INTERACTIONS - Likes/Dislikes (100% Server-Side)
    // ================================================================
    match /interactions/{interactionId} {
      // Leitura: apenas o autor da interação
      allow read: if isAuthenticated() 
        && request.auth.uid == resource.data.autor_id;
      
      // Escrita: BLOQUEADA (apenas via Cloud Function)
      allow create, update, delete: if false;
    }

    // ================================================================
    // INVITES - Convites de banda (100% Server-Side)
    // ================================================================
    match /invites/{inviteId} {
      // Leitura: quem enviou ou recebeu
      allow read: if isAuthenticated()
        && (request.auth.uid == resource.data.from_user_id
            || request.auth.uid == resource.data.target_uid);
      
      // Escrita: BLOQUEADA (apenas via Cloud Function)
      allow create, update, delete: if false;
    }

    // ================================================================
    // MATCHES - Conexões confirmadas (100% Server-Side)
    // ================================================================
    match /matches/{matchId} {
      // Leitura: apenas participantes (user_id_1 ou user_id_2)
      allow read: if isAuthenticated()
        && (request.auth.uid == resource.data.user_id_1
            || request.auth.uid == resource.data.user_id_2);
      
      // Escrita: BLOQUEADA (apenas via Cloud Function)
      allow create, update, delete: if false;
    }

    // NOTA: Não criamos regra para "chats" pois usamos "conversations" (coleção existente).
    // A coleção "chats" da spec backend foi adaptada para usar "conversations".

    // ================================================================
    // CONVERSATIONS - Mensagens reais
    // ================================================================
    match /conversations/{conversationId} {
      // Leitura: participantes
      allow read: if isAuthenticated() 
        && isParticipantByConversationId(conversationId);
      
      // Criação: participantes
      allow create: if isAuthenticated()
        && isParticipantByConversationId(conversationId)
        && request.auth.uid in request.resource.data.participants;
      
      // Update: participantes
      allow update: if isAuthenticated()
        && isParticipantByConversationId(conversationId);

      match /messages/{messageId} {
        // Leitura: participantes
        allow read: if isAuthenticated()
          && isParticipantByConversationId(conversationId);
        
        // Criação: validação rigorosa
        allow create: if isAuthenticated()
          && isParticipantByConversationId(conversationId)
          && request.resource.data.senderId == request.auth.uid
          && request.resource.data.text is string
          && request.resource.data.text.size() > 0
          && request.resource.data.createdAt is timestamp;
        
        // Update/Delete: BLOQUEADO
        allow update, delete: if false;
      }
    }

    // ================================================================
    // BANDS - Entidades de banda
    // ================================================================
    match /bands/{bandId} {
      // Leitura: ativas ou admin/membros
      allow read: if isAuthenticated()
        && (resource.data.status == 'ativa'
            || request.auth.uid == resource.data.admin_id
            || request.auth.uid in resource.data.membros_ids);
      
      // Criação: apenas profissionais, admin = criador
      allow create: if isAuthenticated()
        && request.resource.data.admin_id == request.auth.uid
        && request.resource.data.status == 'draft';
      
      // Update: apenas admin, campos controlados
      allow update: if isAuthenticated()
        && request.auth.uid == resource.data.admin_id
        && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['status', 'membros_ids', 'membros_preview']));
      
      // Delete: apenas admin
      allow delete: if isAuthenticated()
        && request.auth.uid == resource.data.admin_id;
    }

    // ================================================================
    // REPORTS - Denúncias
    // ================================================================
    match /reports/{reportId} {
      // Leitura: BLOQUEADA (apenas admin)
      allow read: if false;
      
      // Criação: autenticado, com validação
      allow create: if isAuthenticated()
        && request.resource.data.autor_id == request.auth.uid
        && request.resource.data.alvo_id != request.auth.uid
        && reportId == request.auth.uid + '_' + request.resource.data.alvo_id
        && !exists(/databases/$(database)/documents/reports/$(reportId));
      
      // Update/Delete: BLOQUEADO
      allow update, delete: if false;
    }

    // ================================================================
    // HASHTAG RANKING - Ranking de hashtags
    // ================================================================
    match /hashtagRanking/{hashtagId} {
      // Leitura: qualquer autenticado
      allow read: if isAuthenticated();
      
      // Escrita: BLOQUEADA (apenas via Cloud Function/scheduled)
      allow write: if false;
    }

    // ================================================================
    // FALLBACK
    // ================================================================
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

### FASE 3: Alterações no App Flutter

#### 3.3.1 Novo Model: HashtagRanking

**Arquivo:** [`lib/src/features/matchpoint/domain/hashtag_ranking.dart`](lib/src/features/matchpoint/domain/hashtag_ranking.dart) (novo)

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'hashtag_ranking.freezed.dart';
part 'hashtag_ranking.g.dart';

@freezed
abstract class HashtagRanking with _$HashtagRanking {
  const factory HashtagRanking({
    required String id,
    required String hashtag,
    required int searchCount,
    required int previousRank,
    required int currentRank,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    required Timestamp lastUpdated,
  }) = _HashtagRanking;

  factory HashtagRanking.fromJson(Map<String, dynamic> json) =>
      _$HashtagRankingFromJson(json);

  factory HashtagRanking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HashtagRanking(
      id: doc.id,
      hashtag: data['hashtag'] as String,
      searchCount: data['search_count'] as int? ?? 0,
      previousRank: data['previous_rank'] as int? ?? 0,
      currentRank: data['current_rank'] as int? ?? 0,
      lastUpdated: data['last_updated'] as Timestamp? ?? Timestamp.now(),
    );
  }
}

Timestamp _timestampFromJson(dynamic json) => json as Timestamp;
dynamic _timestampToJson(Timestamp timestamp) => timestamp;
```

#### 3.3.2 Atualizar MatchpointRemoteDataSource

**Arquivo:** [`lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart`](lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:1)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';

import '../../../constants/firestore_constants.dart';

abstract class MatchpointRemoteDataSource {
  Future<List<AppUser>> fetchCandidates({
    required String currentUserId,
    required List<String> genres,
    required List<String> excludedUserIds,
    int limit = 20,
  });
  
  // NOVO: Usar Cloud Function em vez de escrita direta
  Future<MatchpointActionResult> submitMatchpointAction({
    required String targetUserId,
    required String targetType,
    required String action, // 'like' | 'dislike'
  });
  
  Future<List<String>> fetchExistingInteractions(String currentUserId);
  
  // NOVO: Buscar ranking de hashtags
  Future<List<HashtagRanking>> fetchHashtagRanking({int limit = 20});
}

class MatchpointActionResult {
  final bool success;
  final bool isMatch;
  final int remainingLikes;
  final String? errorCode;

  MatchpointActionResult({
    required this.success,
    required this.isMatch,
    required this.remainingLikes,
    this.errorCode,
  });
}

class MatchpointRemoteDataSourceImpl implements MatchpointRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  MatchpointRemoteDataSourceImpl(this._firestore, this._functions);

  @override
  Future<List<AppUser>> fetchCandidates({
    required String currentUserId,
    required List<String> genres,
    required List<String> excludedUserIds,
    int limit = 20,
  }) async {
    // Código existente permanece igual
    Query query = _firestore.collection(FirestoreCollections.users);

    query = query.where(
      '${FirestoreFields.matchpointProfile}.${FirestoreFields.isActive}',
      isEqualTo: true,
    );

    if (genres.isNotEmpty) {
      query = query.where(
        '${FirestoreFields.matchpointProfile}.${FirestoreFields.musicalGenres}',
        arrayContainsAny: genres.take(10).toList(),
      );
    }

    final snapshot = await query.limit(limit).get();

    return snapshot.docs
        .where((doc) => doc.id != currentUserId && !excludedUserIds.contains(doc.id))
        .map((doc) => AppUser.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MatchpointActionResult> submitMatchpointAction({
    required String targetUserId,
    required String targetType,
    required String action,
  }) async {
    final callable = _functions.httpsCallable('submitMatchpointAction');
    
    try {
      final result = await callable.call({
        'target_id': targetUserId,
        'target_type': targetType,
        'action': action,
      });

      final data = result.data as Map<String, dynamic>;
      
      return MatchpointActionResult(
        success: data['success'] as bool? ?? false,
        isMatch: data['isMatch'] as bool? ?? false,
        remainingLikes: data['remainingLikes'] as int? ?? 0,
      );
    } on FirebaseFunctionsException catch (e) {
      return MatchpointActionResult(
        success: false,
        isMatch: false,
        remainingLikes: 0,
        errorCode: e.code,
      );
    }
  }

  @override
  Future<List<String>> fetchExistingInteractions(String currentUserId) async {
    // Agora lê da coleção global interactions com filtro
    final snapshot = await _firestore
        .collection(FirestoreCollections.interactions)
        .where('autor_id', isEqualTo: currentUserId)
        .where('acao', whereIn: ['like', 'dislike'])
        .get();

    return snapshot.docs.map((doc) => doc.data()['alvo_id'] as String).toList();
  }

  @override
  Future<List<HashtagRanking>> fetchHashtagRanking({int limit = 20}) async {
    final snapshot = await _firestore
        .collection('hashtagRanking')
        .orderBy('current_rank')
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => HashtagRanking.fromFirestore(doc))
        .toList();
  }
}

final matchpointRemoteDataSourceProvider = Provider<MatchpointRemoteDataSource>(
  (ref) {
    return MatchpointRemoteDataSourceImpl(
      FirebaseFirestore.instance,
      FirebaseFunctions.instance,
    );
  },
);
```

#### 3.3.3 Atualizar MatchpointRepository

**Arquivo:** [`lib/src/features/matchpoint/data/matchpoint_repository.dart`](lib/src/features/matchpoint/data/matchpoint_repository.dart:1)

```dart
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/analytics/analytics_provider.dart';
import 'matchpoint_remote_data_source.dart';

part 'matchpoint_repository.g.dart';

class MatchpointRepository {
  final MatchpointRemoteDataSource _dataSource;
  final AnalyticsService? _analytics;

  MatchpointRepository(this._dataSource, {AnalyticsService? analytics})
    : _analytics = analytics;

  FutureResult<List<AppUser>> fetchCandidates({
    required String currentUserId,
    required List<String> genres,
    required List<String> blockedUsers,
    int limit = 20,
  }) async {
    try {
      final candidates = await _dataSource.fetchCandidates(
        currentUserId: currentUserId,
        genres: genres,
        excludedUserIds: blockedUsers,
        limit: limit,
      );

      if (candidates.isEmpty) return const Right([]);

      final existingIds = await _dataSource.fetchExistingInteractions(currentUserId);
      final filtered = candidates
          .where((u) => !existingIds.contains(u.uid))
          .toList();

      return Right(filtered);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // NOVO: Retorna resultado completo com remainingLikes
  FutureResult<MatchActionResult> saveInteraction({
    required String currentUserId,
    required String targetUserId,
    required String targetType,
    required String type, // 'like' or 'dislike'
  }) async {
    try {
      final result = await _dataSource.submitMatchpointAction(
        targetUserId: targetUserId,
        targetType: targetType,
        action: type,
      );

      if (!result.success) {
        if (result.errorCode == 'resource-exhausted') {
          return Left(QuotaExceededFailure(message: 'Limite diário de likes atingido'));
        }
        return Left(ServerFailure(message: 'Erro ao processar ação'));
      }

      // Log analytics
      await _analytics?.logEvent(
        name: 'match_interaction',
        parameters: {
          'target_user_id': targetUserId,
          'action': type,
          'is_match': result.isMatch,
          'remaining_likes': result.remainingLikes,
        },
      );

      return Right(MatchActionResult(
        isMatch: result.isMatch,
        remainingLikes: result.remainingLikes,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  FutureResult<List<HashtagRanking>> fetchHashtagRanking({int limit = 20}) async {
    try {
      final rankings = await _dataSource.fetchHashtagRanking(limit: limit);
      return Right(rankings);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

class MatchActionResult {
  final bool isMatch;
  final int remainingLikes;

  MatchActionResult({
    required this.isMatch,
    required this.remainingLikes,
  });
}

@riverpod
MatchpointRepository matchpointRepository(Ref ref) {
  final dataSource = ref.watch(matchpointRemoteDataSourceProvider);
  final analytics = ref.read(analyticsServiceProvider);
  return MatchpointRepository(dataSource, analytics: analytics);
}
```

#### 3.3.4 Atualizar MatchpointController

**Arquivo:** [`lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart`](lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart:1)

```dart
import 'dart:async';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/chat/data/chat_repository.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/utils/app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/hashtag_ranking.dart';

part 'matchpoint_controller.g.dart';

@Riverpod(keepAlive: true)
class MatchpointController extends _$MatchpointController {
  @override
  FutureOr<void> build() {
    // Initial state is void (idle)
  }

  // Estado para remaining likes
  int _remainingLikes = 50;
  int get remainingLikes => _remainingLikes;

  Future<void> saveMatchpointProfile({
    required String intent,
    required List<String> genres,
    required List<String> hashtags,
    required bool isVisibleInHome,
  }) async {
    state = const AsyncLoading();

    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;

    if (currentUser == null) {
      state = const AsyncError('Usuário não autenticado', StackTrace.empty);
      return;
    }

    final appUserAsync = ref.read(currentUserProfileProvider);
    if (!appUserAsync.hasValue || appUserAsync.value == null) {
      state = const AsyncError('Perfil não carregado', StackTrace.empty);
      return;
    }

    final appUser = appUserAsync.value!;

    final Map<String, dynamic> updatedMatchpointProfile = {
      ...appUser.matchpointProfile ?? {},
      FirestoreFields.intent: intent,
      FirestoreFields.musicalGenres: genres,
      FirestoreFields.hashtags: hashtags,
      FirestoreFields.isActive: true,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final Map<String, dynamic> updatedPrivacy = {
      ...appUser.privacySettings,
      'visible_in_home': isVisibleInHome,
    };

    final updatedUser = appUser.copyWith(
      matchpointProfile: updatedMatchpointProfile,
      privacySettings: updatedPrivacy,
    );

    final result = await authRepo.updateUser(updatedUser);

    if (result.isRight()) {
      unawaited(
        ref
            .read(analyticsServiceProvider)
            .logMatchPointFilter(instruments: [], genres: genres, distance: 0),
      );
    }

    result.fold(
      (failure) => state = AsyncError(failure.message, StackTrace.current),
      (_) => state = const AsyncData(null),
    );
  }

  Future<AppUser?> swipeRight(AppUser targetUser) async {
    return await _handleSwipe(targetUser, 'like');
  }

  Future<void> swipeLeft(AppUser targetUser) async {
    await _handleSwipe(targetUser, 'dislike');
  }

  Future<AppUser?> _handleSwipe(AppUser targetUser, String type) async {
    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;
    if (currentUser == null) return null;

    final repo = ref.read(matchpointRepositoryProvider);

    final result = await repo.saveInteraction(
      currentUserId: currentUser.uid,
      targetUserId: targetUser.uid,
      targetType: targetUser.tipoPerfil?.id ?? 'profissional',
      type: type,
    );

    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return null;
      },
      (actionResult) async {
        _remainingLikes = actionResult.remainingLikes;
        
        if (actionResult.isMatch) {
          AppLogger.info("IT'S A MATCH!");

          // Criar conversa automaticamente
          try {
            final appUserAsync = ref.read(currentUserProfileProvider);
            final appUser = appUserAsync.value;
            final myName =
                appUser?.nome ?? currentUser.displayName ?? 'Usuário';
            final myPhoto = appUser?.foto ?? currentUser.photoURL;

            final chatRepo = ref.read(chatRepositoryProvider);
            await chatRepo.getOrCreateConversation(
              myUid: currentUser.uid,
              otherUid: targetUser.uid,
              otherUserName: targetUser.nome ?? 'Usuário',
              otherUserPhoto: targetUser.foto,
              myName: myName,
              myPhoto: myPhoto,
              type: 'matchpoint',
            );
          } catch (e) {
            AppLogger.error('Erro ao criar conversa automática: $e');
          }

          return targetUser;
        }
        return null;
      },
    );
  }

  Future<void> unmatchUser(String targetUserId) async {
    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;
    if (currentUser == null) return;

    final chatRepo = ref.read(chatRepositoryProvider);
    final matchRepo = ref.read(matchpointRepositoryProvider);

    // 1. Delete conversation
    final conversationId = chatRepo.getConversationId(
      currentUser.uid,
      targetUserId,
    );

    await chatRepo.deleteConversation(
      conversationId: conversationId,
      myUid: currentUser.uid,
      otherUid: targetUserId,
    );

    // 2. Set interaction to dislike via Cloud Function
    await matchRepo.saveInteraction(
      currentUserId: currentUser.uid,
      targetUserId: targetUserId,
      targetType: 'profissional',
      type: 'dislike',
    );
    AppLogger.info('MatchpointController: Disliked $targetUserId');
  }
}

// Provider para candidatos
@riverpod
Future<List<AppUser>> matchpointCandidates(Ref ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  final currentUser = authRepo.currentUser;

  if (currentUser == null) return [];

  final userProfile = await ref.watch(currentUserProfileProvider.future);
  if (userProfile == null) return [];

  final genres = List<String>.from(
    userProfile.matchpointProfile?[FirestoreFields.musicalGenres] ?? [],
  );
  if (genres.isEmpty) {
    AppLogger.warning('⚠️ MatchPoint: User has no genres.');
    return [];
  }

  final blockedUsers = userProfile.blockedUsers;

  final repo = ref.watch(matchpointRepositoryProvider);
  final result = await repo.fetchCandidates(
    currentUserId: currentUser.uid,
    genres: genres,
    blockedUsers: blockedUsers,
  );

  return result.fold(
    (l) {
      AppLogger.error('❌ MatchPoint Query Error: ${l.message}');
      throw l.message;
    },
    (r) {
      AppLogger.info(
        '✅ MatchPoint Query Success: Found ${r.length} candidates',
      );
      return r;
    },
  );
}

// NOVO: Provider para ranking de hashtags
@riverpod
Future<List<HashtagRanking>> hashtagRanking(Ref ref, {int limit = 20}) async {
  final repo = ref.watch(matchpointRepositoryProvider);
  final result = await repo.fetchHashtagRanking(limit: limit);

  return result.fold(
    (l) => [],
    (r) => r,
  );
}
```

#### 3.3.5 Nova Tela: HashtagRankingScreen

**Arquivo:** [`lib/src/features/matchpoint/presentation/screens/hashtag_ranking_screen.dart`](lib/src/features/matchpoint/presentation/screens/hashtag_ranking_screen.dart) (novo)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/components.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../controllers/matchpoint_controller.dart';

/// Tela de ranking de hashtags.
/// NOTA: Esta tela é usada dentro do IndexedStack do MatchpointTabsScreen,
/// portanto NÃO deve ter Scaffold/AppBar próprio.
class HashtagRankingScreen extends ConsumerWidget {
  const HashtagRankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(hashtagRankingProvider(limit: 20));

    return rankingAsync.when(
        data: (rankings) {
          if (rankings.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.s16),
            itemCount: rankings.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s8),
            itemBuilder: (context, index) {
              final item = rankings[index];
              return _HashtagRankingCard(
                rank: item.currentRank,
                hashtag: item.hashtag,
                searchCount: item.searchCount,
                isTrendingUp: item.currentRank < item.previousRank,
                isTrendingDown: item.currentRank > item.previousRank,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildErrorState(ref),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Nenhuma hashtag em destaque',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Erro ao carregar ranking',
            style: AppTypography.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.s16),
          AppButton.secondary(
            text: 'Tentar novamente',
            onPressed: () => ref.refresh(hashtagRankingProvider(limit: 20)),
          ),
        ],
      ),
    );
  }
}

class _HashtagRankingCard extends StatelessWidget {
  final int rank;
  final String hashtag;
  final int searchCount;
  final bool isTrendingUp;
  final bool isTrendingDown;

  const _HashtagRankingCard({
    required this.rank,
    required this.hashtag,
    required this.searchCount,
    this.isTrendingUp = false,
    this.isTrendingDown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.all16,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all12,
        border: Border.all(
          color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Rank number
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s16),
          
          // Hashtag info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#$hashtag',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  '$searchCount buscas',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Trend indicator
          if (isTrendingUp)
            Icon(
              Icons.trending_up,
              color: AppColors.success,
            )
          else if (isTrendingDown)
            Icon(
              Icons.trending_down,
              color: AppColors.error,
            )
          else
            Icon(
              Icons.trending_flat,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return AppColors.primary.withValues(alpha: 0.3);
      case 2:
        return AppColors.primary.withValues(alpha: 0.2);
      case 3:
        return AppColors.primary.withValues(alpha: 0.1);
      default:
        return AppColors.surfaceHighlight;
    }
  }
}
```

#### 3.3.6 Atualizar MatchpointTabsScreen (3 abas)

**Arquivo:** [`lib/src/features/matchpoint/presentation/screens/matchpoint_tabs_screen.dart`](lib/src/features/matchpoint/presentation/screens/matchpoint_tabs_screen.dart:1)

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../screens/matchpoint_matches_screen.dart';
import '../screens/hashtag_ranking_screen.dart'; // NOVO
import 'matchpoint_explore_screen.dart';

class MatchpointTabsScreen extends StatefulWidget {
  const MatchpointTabsScreen({super.key});

  @override
  State<MatchpointTabsScreen> createState() => _MatchpointTabsScreenState();
}

class _MatchpointTabsScreenState extends State<MatchpointTabsScreen> {
  int _selectedIndex = 0;

  // NOVO: Adicionar terceira aba
  final List<Widget> _screens = [
    const MatchpointExploreScreen(),
    const MatchpointMatchesScreen(),
    const HashtagRankingScreen(), // NOVO
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'MatchPoint',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.primary,
            ),
            onPressed: () => context.push(RoutePaths.matchpointWizard),
          ),
          IconButton(
            icon: const Icon(
              Icons.help_outline,
              color: AppColors.textSecondary,
            ),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom Google Nav Bar (Top Menu) - ATUALIZADO com 3 abas
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s8,
              AppSpacing.s16,
              AppSpacing.s16,
            ),
            padding: AppSpacing.all4,
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight.withValues(alpha: 0.3),
              borderRadius: AppRadius.pill,
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.05),
              ),
            ),
            child: GNav(
              gap: AppSpacing.s8,
              backgroundColor: AppColors.transparent,
              color: AppColors.textSecondary,
              activeColor: AppColors.textPrimary,
              tabBackgroundColor: AppColors.primary,
              padding: AppSpacing.h16v12,
              duration: const Duration(milliseconds: 300),
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              tabs: [
                GButton(
                  icon: Icons.explore_rounded,
                  text: 'Explorar',
                  textStyle: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: AppTypography.buttonPrimary.fontWeight,
                  ),
                ),
                GButton(
                  icon: Icons.bolt_rounded,
                  text: 'Matches',
                  textStyle: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: AppTypography.buttonPrimary.fontWeight,
                  ),
                ),
                // NOVO: Terceira aba
                GButton(
                  icon: Icons.trending_up_rounded,
                  text: 'Trending',
                  textStyle: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: AppTypography.buttonPrimary.fontWeight,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Sobre o MatchPoint',
          style: AppTypography.titleLarge,
        ),
        content: Text(
          'O MatchPoint é o lugar para formar sua próxima banda ou projeto musical.\n\n'
          '1. Explorar: Descubra músicos que combinam com seus gêneros e objetivos.\n\n'
          '2. Matches: Veja suas conexões e converse com outros músicos.\n\n'
          '3. Trending: Descubra as hashtags mais populares no momento.\n\n'
          'Você tem 50 likes por dia para usar!',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendi',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 3.3.7 Adicionar QuotaExceededFailure

**Arquivo:** [`lib/src/core/errors/failures.dart`](lib/src/core/errors/failures.dart) (adicionar)

```dart
// Adicionar ao arquivo lib/src/core/errors/failures.dart

// ============================================================================
// QUOTA FAILURES
// ============================================================================

/// Represents a quota/rate-limit exceeded failure (e.g., daily like limit).
class QuotaExceededFailure extends Failure {
  const QuotaExceededFailure({
    required super.message,
    super.debugMessage,
    super.originalError,
  });

  /// Daily like limit reached.
  factory QuotaExceededFailure.dailyLikes() => const QuotaExceededFailure(
    message: 'Limite diário de likes atingido. Volte amanhã!',
    debugMessage: 'quota-exceeded-daily-likes',
  );
}
```

#### 3.3.8 Atualizar MatchpointExploreScreen (mostrar limite)

**Arquivo:** [`lib/src/features/matchpoint/presentation/screens/matchpoint_explore_screen.dart`](lib/src/features/matchpoint/presentation/screens/matchpoint_explore_screen.dart:1)

```dart
// Adicionar widget para mostrar remaining likes

Widget _buildSwipeDeck(List<AppUser> candidates) {
  return Column(
    children: [
      // NOVO: Mostrar limite diário
      Consumer(builder: (context, ref, _) {
        final controller = ref.watch(matchpointControllerProvider.notifier);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Likes restantes hoje:',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${controller.remainingLikes}/50',
                style: AppTypography.bodySmall.copyWith(
                  color: controller.remainingLikes < 10 
                    ? AppColors.error 
                    : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }),
      const SizedBox(height: AppSpacing.s8),
      
      // Deck existente
      Expanded(
        child: MatchSwipeDeck(
          candidates: candidates,
          controller: _swiperController,
          onSwipeRight: (user) async {
            // ... código existente
          },
          onSwipeLeft: (user) {
            // ... código existente
          },
        ),
      ),
    ],
  );
}
```

---

### FASE 4: Schema Firebase para Hashtag Ranking

#### 3.4.1 Coleção: `hashtagRanking`

**Documento exemplo:**
```json
{
  "id": "rock",
  "hashtag": "rock",
  "search_count": 1543,
  "current_rank": 1,
  "previous_rank": 3,
  "last_updated": "2026-02-06T10:00:00Z",
  "trending_score": 85.5
}
```

#### 3.4.2 Cloud Function para Atualização

**Arquivo:** [`functions/src/hashtags.ts`](functions/src/hashtags.ts) (novo)

```typescript
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onDocumentWrite} from "firebase-functions/v2/firestore";
import {getFirestore, FieldValue} from "firebase-admin/firestore";

const db = getFirestore();

/**
 * Atualiza contador quando usuário adiciona hashtag ao perfil.
 *
 * NOTA: Este trigger coexiste com `updateusergeohash` (geohash_migration.ts)
 * que também escuta `users/{userId}`. Ambos são triggers independentes e
 * o Firebase executa cada um separadamente. Não há conflito, mas atenção
 * ao custo: cada update em users dispara AMBOS os triggers.
 */
export const onHashtagUsed = onDocumentWrite(
  "users/{userId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    const beforeHashtags = before?.matchpoint_profile?.hashtags || [];
    const afterHashtags = after?.matchpoint_profile?.hashtags || [];

    // Identificar hashtags novas
    const newHashtags = afterHashtags.filter(
      (h: string) => !beforeHashtags.includes(h)
    );

    for (const hashtag of newHashtags) {
      const hashtagRef = db.collection("hashtagRanking").doc(hashtag);
      
      await hashtagRef.set({
        hashtag: hashtag,
        search_count: FieldValue.increment(1),
        last_updated: FieldValue.serverTimestamp(),
      }, {merge: true});
    }
  }
);

/**
 * Recalcula ranking diariamente às 03:00
 */
export const recalculateHashtagRanking = onSchedule(
  {
    schedule: "0 3 * * *",
    timeZone: "America/Sao_Paulo",
  },
  async () => {
    // Buscar todas as hashtags ordenadas por count
    const snapshot = await db
      .collection("hashtagRanking")
      .orderBy("search_count", "desc")
      .get();

    const batch = db.batch();
    let currentRank = 1;

    snapshot.docs.forEach((doc) => {
      const data = doc.data();
      const previousRank = data.current_rank || 0;
      
      batch.update(doc.ref, {
        previous_rank: previousRank,
        current_rank: currentRank,
        last_updated: FieldValue.serverTimestamp(),
      });
      
      currentRank++;
    });

    await batch.commit();
    console.log(`✅ Ranking recalculado para ${snapshot.size} hashtags`);
  }
);
```

---

## 4. ÍNDICES FIRESTORE NECESSÁRIOS

**Arquivo:** [`firestore.indexes.json`](firestore.indexes.json:1)

```json
{
  "indexes": [
    // Índices existentes mantidos...
    
    // NOVOS ÍNDICES:
    
    // Interactions - para verificar match
    {
      "collectionGroup": "interactions",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "autor_id", "order": "ASCENDING"},
        {"fieldPath": "alvo_id", "order": "ASCENDING"},
        {"fieldPath": "acao", "order": "ASCENDING"}
      ]
    },
    
    // Interactions - para buscar meus likes
    {
      "collectionGroup": "interactions",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "autor_id", "order": "ASCENDING"},
        {"fieldPath": "acao", "order": "ASCENDING"},
        {"fieldPath": "timestamp", "order": "DESCENDING"}
      ]
    },
    
    // Matches - por pair_key
    {
      "collectionGroup": "matches",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "pair_key", "order": "ASCENDING"}
      ]
    },
    
    // Chats - por pair_key
    {
      "collectionGroup": "chats",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "pair_key", "order": "ASCENDING"}
      ]
    },
    
    // Invites - por target
    {
      "collectionGroup": "invites",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "target_uid", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "created_at", "order": "DESCENDING"}
      ]
    },
    
    // Users - para suspensões
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "suspension_end_date", "order": "ASCENDING"}
      ]
    },
    
    // Hashtag Ranking
    {
      "collectionGroup": "hashtagRanking",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "current_rank", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "hashtagRanking",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "search_count", "order": "DESCENDING"}
      ]
    }
  ],
  "fieldOverrides": []
}
```

---

## 5. LISTA DE ARQUIVOS A ALTERAR

### Backend (Cloud Functions)

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| [`functions/src/index.ts`](functions/src/index.ts:1) | Modificar | Adicionar exports das novas functions |
| [`functions/src/matchpoint.ts`](functions/src/matchpoint.ts:1) | Criar | `submitMatchpointAction` + helpers |
| [`functions/src/bands.ts`](functions/src/bands.ts:1) | Criar | `manageBandInvite` |
| [`functions/src/chat.ts`](functions/src/chat.ts:1) | Criar | `initiateContact` |
| [`functions/src/moderation.ts`](functions/src/moderation.ts:1) | Criar | `onReportCreated` |
| [`functions/src/scheduled.ts`](functions/src/scheduled.ts:1) | Criar | `liftSuspensions` + `pruneOldInteractions` |
| [`functions/src/hashtags.ts`](functions/src/hashtags.ts:1) | Criar | `onHashtagUsed` + `recalculateHashtagRanking` |

### Flutter App

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| [`lib/src/core/errors/failures.dart`](lib/src/core/errors/failures.dart:1) | Modificar | Adicionar `QuotaExceededFailure` |
| [`lib/src/features/matchpoint/domain/hashtag_ranking.dart`](lib/src/features/matchpoint/domain/hashtag_ranking.dart:1) | Criar | Model de ranking |
| [`lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart`](lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:1) | Modificar | Usar Cloud Functions |
| [`lib/src/features/matchpoint/data/matchpoint_repository.dart`](lib/src/features/matchpoint/data/matchpoint_repository.dart:1) | Modificar | Novos métodos |
| [`lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart`](lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart:1) | Modificar | Lógica de likes |
| [`lib/src/features/matchpoint/presentation/screens/hashtag_ranking_screen.dart`](lib/src/features/matchpoint/presentation/screens/hashtag_ranking_screen.dart:1) | Criar | Nova tela |
| [`lib/src/features/matchpoint/presentation/screens/matchpoint_tabs_screen.dart`](lib/src/features/matchpoint/presentation/screens/matchpoint_tabs_screen.dart:1) | Modificar | 3 abas |
| [`lib/src/features/matchpoint/presentation/screens/matchpoint_explore_screen.dart`](lib/src/features/matchpoint/presentation/screens/matchpoint_explore_screen.dart:1) | Modificar | Mostrar limite |
| [`lib/src/features/settings/presentation/settings_screen.dart`](lib/src/features/settings/presentation/settings_screen.dart:347) | Modificar | Remover deleção de fakes |

### Configuração

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| [`pubspec.yaml`](pubspec.yaml:72) | Modificar | **Descomentar** `cloud_functions: ^6.0.6` (linha 72, atualmente comentado) |
| [`firestore.rules`](firestore.rules:1) | Substituir | Rules blindadas conforme seção 3.2 |
| [`firestore.indexes.json`](firestore.indexes.json:1) | Modificar | Adicionar novos índices conforme seção 4 |

---

## 6. RISCOS E VALIDAÇÕES ANTES DO DEPLOY

### 6.1 Riscos Identificados

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Quebra de compatibilidade com app antigo | Alta | Alto | Deploy gradual, feature flags |
| Migração de `interactions` subcoleção → global | Alta | Alto | Cloud Function de migração one-time, testar em staging |
| Limite de 50 likes mal calculado (timezone) | Média | Médio | Usar timezone do servidor (UTC) consistentemente |
| Performance nas Cloud Functions (cold start) | Média | Médio | Monitoramento, min instances se necessário |
| Race conditions em matches | Baixa | Alto | Transações atômicas no `processMatch` |
| Custo Firebase (triggers duplos em users) | Média | Médio | Monitorar invocações, otimizar `onHashtagUsed` |
| `initiateContact` escreve em `chats` (spec) vs `conversations` (app) | Alta | Alto | Adaptar function para usar `conversations` |
| `onMessageCreated` escuta `conversations` mas spec diz `chats` | Média | Alto | Manter `conversations`, documentar divergência |

### 6.2 Checklist de Validação

#### Pré-Deploy
- [ ] Todas as Cloud Functions compilam sem erros (`cd functions && npm run build`)
- [ ] Firestore Rules passam em testes de segurança (`firebase emulators:exec`)
- [ ] Índices foram criados no Firebase Console
- [ ] App Flutter builda sem erros (`flutter build apk --release`)
- [ ] Testes unitários passam (`flutter test`)
- [ ] Rodar `dart run build_runner build` para gerar `.g.dart` e `.freezed.dart`
- [ ] Migração de `interactions` subcoleção → global executada em staging
- [ ] `initiateContact` adaptado para usar `conversations` em vez de `chats`
- [ ] Verificar que `cloud_functions` está no `pubspec.yaml`

#### Deploy Backend (PRIMEIRO)
- [ ] Deploy das Firestore Rules (`firebase deploy --only firestore:rules`)
- [ ] Deploy dos índices (`firebase deploy --only firestore:indexes`)
- [ ] Aguardar índices ficarem ativos (pode levar minutos)
- [ ] Deploy das Cloud Functions (`firebase deploy --only functions`)
- [ ] Verificar logs das functions no Console
- [ ] Executar migração de interactions em staging

#### Deploy App (DEPOIS do backend)
- [ ] Testar em ambiente de staging com emuladores
- [ ] Verificar limite de 50 likes funcionando (testar lazy reset)
- [ ] Verificar match real criando conversa na aba Matches
- [ ] Verificar ranking de hashtags (popular dados de teste)
- [ ] Testar fluxo de unmatch (conversa some para ambos)
- [ ] Testar report (criar denúncia, verificar trigger)
- [ ] Testar que escrita direta em `interactions` é bloqueada pelas rules

#### Pós-Deploy
- [ ] Monitorar erros no Crashlytics
- [ ] Verificar métricas de uso das functions (Cloud Functions dashboard)
- [ ] Monitorar custo Firebase (billing alerts)
- [ ] Acompanhar feedback dos usuários
- [ ] Verificar que scheduled functions executam no horário correto

---

## 7. CONSIDERAÇÕES SOBRE CHATS VS CONVERSATIONS

### Análise Atual

O app atualmente usa a coleção **`conversations`** (coleção global com ID determinístico `uid1_uid2`).
A spec backend define uma coleção **`chats`** com campos diferentes (`pair_key`, `participantes_data`, `participantes_ids`).

### Decisão Tomada: Manter `conversations`

**Justificativa:**
1. O app Flutter já tem toda a infraestrutura de chat construída sobre `conversations` (repository, providers, UI)
2. A coleção `conversations` já usa ID determinístico (`uid1_uid2`) que funciona como `pair_key`
3. Migrar para `chats` exigiria reescrever: [`ChatRepository`](lib/src/features/chat/data/chat_repository.dart:1), [`chat_providers.dart`](lib/src/features/chat/data/chat_providers.dart:1), [`ConversationPreview`](lib/src/features/chat/domain/conversation_preview.dart:1), [`ChatScreen`](lib/src/features/chat/presentation/chat_screen.dart:1), [`ConversationsScreen`](lib/src/features/chat/presentation/conversations_screen.dart:1)
4. O custo de migração não justifica para o MVP

**Adaptações já aplicadas neste plano:**
- Cloud Function `createChatForMatch()` em [`functions/src/matchpoint.ts`](functions/src/matchpoint.ts:1) → escreve em `conversations` + `conversationPreviews`
- Cloud Function `initiateContact` em [`functions/src/chat.ts`](functions/src/chat.ts:1) → **PRECISA SER ADAPTADA** para usar `conversations` em vez de `chats`
- Firestore Rules → mantém regras de `conversations`, sem regra para `chats`
- O campo `type: 'matchpoint'` na conversation permite filtrar matches vs diretas (já funciona via [`matchConversationsProvider`](lib/src/features/chat/data/chat_providers.dart:21))

### ⚠️ AÇÃO PENDENTE: Adaptar `initiateContact`

O código de `initiateContact` na seção 3.1.3 ainda escreve em `chats`. Deve ser adaptado para escrever em `conversations` + `conversationPreviews`, seguindo o mesmo padrão de `createChatForMatch`.

---

## 8. RESUMO DAS MUDANÇAS CRÍTICAS

### Para o Backend
1. Implementar 8 Cloud Functions novas (6 da spec + 2 de hashtags)
2. Atualizar Firestore Rules para bloquear writes client-side
3. Criar coleção `hashtagRanking` com triggers
4. Configurar 3 scheduled functions (liftSuspensions, pruneOldInteractions, recalculateHashtagRanking)
5. Adaptar `initiateContact` para usar `conversations` em vez de `chats`

### Para o App
1. **Descomentar** `cloud_functions` no [`pubspec.yaml`](pubspec.yaml:72)
2. Migrar de escrita direta para Cloud Functions no matchpoint
3. Migrar leitura de `interactions` de subcoleção para coleção global
4. Adicionar tela de ranking de hashtags (3ª aba)
5. Mostrar contador de likes restantes (50/dia)
6. Remover funcionalidade de deletar perfis fake do settings
7. Rodar `build_runner` para gerar arquivos `.g.dart` e `.freezed.dart`

### Para o Firebase
1. Criar 8+ índices novos (interactions, matches, users, hashtagRanking)
2. Configurar quotas das functions
3. Habilitar scheduled functions (requer plano Blaze)
4. Executar migração de interactions subcoleção → global

### Ordem de Execução Recomendada
1. Backend: Cloud Functions + Rules + Índices
2. Migração: interactions subcoleção → global
3. App: Alterações Flutter + build_runner
4. Testes: Staging completo
5. Deploy: Produção

---

**Documento preparado por:** Engenharia Mube
**Versão 1.1 — Revisada com correções de consistência**
**Revisão necessária antes de implementação**
