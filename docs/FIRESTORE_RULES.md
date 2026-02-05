# Firestore Security Rules

## Overview

Este documento detalha as regras de segurança do Firestore para o MubeApp. As regras são organizadas por coleção e seguem o princípio de **menor privilégio**.

## Estrutura das Regras

### 1. Config (`/config/{document}`)

**Acesso:**
- ✅ **Read**: Qualquer usuário autenticado
- ❌ **Write**: Ninguém (apenas Admin SDK ou Cloud Functions)

**Justificativa:** Configurações do app não devem ser modificadas por clientes.

---

### 2. Users (`/users/{userId}`)

**Acesso:**
- ✅ **Read**: Qualquer usuário autenticado
- ✅ **Create**: Qualquer usuário autenticado (durante onboarding)
- ✅ **Update**: 
  - Próprio usuário
  - Atualização de `likeCount` (qualquer usuário)
  - Atualização de `members` (para entrar em banda)
- ✅ **Delete**: Apenas o próprio usuário

**Subcoleções:**

#### 2.1 Favorites (`/users/{userId}/favorites/{favoriteId}`)
- ✅ **Read/Write**: Apenas o dono da coleção (`userId`)

#### 2.2 Blocked (`/users/{userId}/blocked/{blockedId}`)
- ✅ **Read/Write**: Apenas o dono da coleção

#### 2.3 Interactions (`/users/{userId}/interactions/{interactionId}`)
- ✅ **Read**: 
  - Dono da coleção (`userId`)
  - Usuário que foi interagido (`interactionId`) - para verificar match mútuo
- ✅ **Write**: Apenas o dono da coleção

#### 2.4 ConversationPreviews (`/users/{userId}/conversationPreviews/{previewId}`)
- ✅ **Read**: Apenas o dono (`userId`)
- ✅ **Create/Update**: Qualquer participante da conversa
- ✅ **Delete**: Apenas o dono

#### 2.5 Notifications (`/users/{userId}/notifications/{notificationId}`)
- ✅ **Read/Write/Delete**: Apenas o dono

---

### 3. Conversations (`/conversations/{conversationId}`)

**Formato do ID:** `{uid1}_{uid2}` (UIDs ordenados alfabeticamente)

**Acesso:**
- ✅ **Read**: Participantes da conversa
- ✅ **Create**: Participantes da conversa
- ✅ **Update**: Participantes da conversa

**Subcoleção Messages:**
- ✅ **Read/Write**: Apenas participantes da conversa

**Validações:**
- Usuário deve estar no `conversationId`
- Ao criar, usuário deve estar na lista de `participants`

---

### 4. Invites (`/invites/{inviteId}`)

**Acesso:**
- ✅ **Read**: 
  - Usuário alvo do convite (`target_uid`)
  - Banda que enviou (`band_id`)
- ✅ **Create**: Qualquer usuário autenticado
- ✅ **Update**: 
  - Alvo (aceitar/recusar)
  - Banda (cancelar)
- ✅ **Delete**: Apenas a banda

---

### 5. Profiles (`/profiles/{profileId}`)

**Acesso:**
- ✅ **Read**: Qualquer usuário autenticado
- ✅ **Update**: Qualquer usuário autenticado (apenas campo `likeCount`)
- ❌ **Create/Delete**: Restrito (Cloud Functions ou Admin SDK)

**Observação:** Coleção espelho para contadores públicos.

---

### 6. Reports (`/reports/{reportId}`)

**Acesso:**
- ✅ **Create**: Qualquer usuário autenticado
- ❌ **Read/Update/Delete**: Apenas admins (não implementado no cliente)

---

## Funções Auxiliares

### `isParticipantByConversationId()`
Verifica se o usuário autenticado é participante de uma conversa baseado no ID.

```javascript
function isParticipantByConversationId() {
  return request.auth.uid in conversationId.split('_');
}
```

## Validações de Dados

### Validação de Update Parcial
Permite atualizar apenas campos específicos:

```javascript
// Apenas likeCount pode ser atualizado
request.resource.data.diff(resource.data).affectedKeys().hasOnly(['likeCount'])
```

### Validação de Participantes
Garante que o usuário criando uma conversa está na lista de participantes:

```javascript
request.auth.uid in request.resource.data.participants
```

## Boas Práticas Implementadas

1. **Autenticação Obrigatória**: Todas as operações exigem `request.auth != null`

2. **Ownership Verification**: Sempre verificar se o usuário é dono do recurso:
   ```javascript
   request.auth.uid == userId
   ```

3. **Validação de Campos**: Usar `diff().affectedKeys().hasOnly()` para updates parciais

4. **Segurança de Conversas**: 
   - IDs de conversa contêm ambos os UIDs
   - Validação dupla: ID da conversa + lista de participantes

5. **Privacidade de Dados**:
   - Users só podem ver seus próprios favoritos/bloqueados
   - Mensagens só acessíveis por participantes
   - Interações só legíveis pelos envolvidos

## Testes de Regras

Para testar as regras localmente:

```bash
# Instalar emulator
firebase setup:emulators:firestore

# Iniciar emulator
firebase emulators:start --only firestore

# Rodar testes
firebase emulators:exec --only firestore "npm test"
```

## Deploy das Regras

```bash
# Deploy das regras
firebase deploy --only firestore:rules

# Verificar regras
firebase firestore:rules:get
```

## Monitoramento

Recomendações para monitoramento em produção:

1. **Habilitar logs de auditoria** do Firestore
2. **Monitorar rejeições** de regras no Firebase Console
3. **Revisar logs** periodicamente para tentativas de acesso indevido
4. **Usar Firebase App Check** para validar origem das requisições

## Troubleshooting

### Erro: "Missing or insufficient permissions"

**Causas comuns:**
1. Usuário não autenticado
2. UID não corresponde ao recurso
3. Campo não permitido em update parcial
4. Validação de participante falhou

**Solução:**
Verificar logs de debug e comparar com as regras documentadas acima.

### Erro: "Invalid data"

**Causas comuns:**
1. Campo obrigatório ausente
2. Tipo de dado incorreto
3. Validação de string/d número falhou

**Solução:**
Validar dados no cliente antes de enviar para o Firestore.

## Changelog

### v1.0.0 (Current)
- ✅ Regras iniciais implementadas
- ✅ Suporte a todas as coleções principais
- ✅ Validações de ownership
- ✅ Proteção de subcoleções

### Próximas Melhorias
- [ ] Rate limiting nas regras
- [ ] Validação de tamanho de campos
- [ ] Regras específicas para admins
- [ ] Sanitização de dados
