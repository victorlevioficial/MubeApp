/**
 * Cloud Functions para painel Admin.
 *
 * Todas as funções verificam `context.auth.token.admin === true`
 * antes de executar qualquer operação.
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {Timestamp} from "firebase-admin/firestore";

const db = admin.firestore();

// ================================================================
// HELPER: Verifica se o caller é admin
// ================================================================
/**
 * Verifica se a requisição veio de um admin.
 * @param {Object} context Contexto da requisição.
 */
function assertAdmin(context: { auth?: { token?: Record<string, unknown> } }) {
  if (!context.auth || !context.auth.token?.admin) {
    throw new HttpsError(
      "permission-denied",
      "Acesso restrito a administradores."
    );
  }
}

// ================================================================
// AUTH: Definir custom claim admin
// ================================================================
export const setAdminClaim = onCall(
  {region: "southamerica-east1", memory: "256MiB"},
  async (request) => {
    // Bootstrap: permite que o primeiro admin se configure
    // OR já é admin e está configurando outro
    const callerUid = request.auth?.uid;
    const targetEmail = request.data?.email as string;

    if (!targetEmail) {
      throw new HttpsError("invalid-argument", "Email é obrigatório.");
    }

    // Se já existe algum admin, exigir que o caller seja admin
    const isCallerAdmin = request.auth?.token?.admin === true;
    if (!isCallerAdmin) {
      // Verificar se é o bootstrap (nenhum admin existe)
      const configRef = db.collection("config").doc("admin");
      const configDoc = await configRef.get();
      if (configDoc.exists) {
        throw new HttpsError(
          "permission-denied",
          "Admin já configurado. Peça a um admin existente."
        );
      }
    }

    try {
      const userRecord = await admin.auth().getUserByEmail(targetEmail);
      await admin.auth().setCustomUserClaims(userRecord.uid, {admin: true});

      // Gravar registro no Firestore
      await db.collection("config").doc("admin").set(
        {
          adminUids: admin.firestore.FieldValue.arrayUnion(userRecord.uid),
          updatedAt: Timestamp.now(),
          updatedBy: callerUid || "bootstrap",
        },
        {merge: true}
      );

      console.log(
        `Admin claim definido para ${targetEmail} (${userRecord.uid})`
      );
      return {success: true, uid: userRecord.uid};
    } catch (error) {
      console.error("Erro ao definir admin claim:", error);
      throw new HttpsError("internal", "Erro ao configurar admin.");
    }
  }
);

// ================================================================
// FEATURED PROFILES
// ================================================================
export const setFeaturedProfiles = onCall(
  {region: "southamerica-east1", memory: "256MiB"},
  async (request) => {
    assertAdmin(request);

    const uids = request.data?.uids as string[];
    if (!Array.isArray(uids)) {
      throw new HttpsError("invalid-argument", "uids deve ser um array.");
    }

    // Validar que os UIDs existem
    const validUids: string[] = [];
    for (const uid of uids) {
      const userDoc = await db.collection("users").doc(uid).get();
      if (userDoc.exists) {
        validUids.push(uid);
      } else {
        console.warn(`UID ${uid} não encontrado, ignorando.`);
      }
    }

    await db.collection("config").doc("featuredProfiles").set({
      uids: validUids,
      updatedAt: Timestamp.now(),
      updatedBy: request.auth?.uid || "unknown",
    });

    console.log(`Featured profiles atualizados: ${validUids.length} perfis`);
    return {success: true, uids: validUids};
  }
);

export const getFeaturedProfiles = onCall(
  {region: "southamerica-east1", memory: "256MiB"},
  async (request) => {
    assertAdmin(request);

    const doc = await db.collection("config").doc("featuredProfiles").get();
    if (!doc.exists) {
      return {uids: [], profiles: []};
    }

    const data = doc.data() || {};
    const uids = (data.uids as string[]) || [];

    // Buscar dados de cada perfil
    const profiles = [];
    for (const uid of uids) {
      const userDoc = await db.collection("users").doc(uid).get();
      if (userDoc.exists) {
        const userData = userDoc.data() || {};
        profiles.push({
          uid,
          nome: userData.nome || userData.name || "",
          foto: userData.foto || userData.photoUrl || "",
          tipoPerfil: userData.tipo_perfil || userData.tipoPerfil || "",
          likeCount: userData.likeCount || 0,
          cidade: userData.cidade || "",
        });
      }
    }

    return {uids, profiles};
  }
);

// ================================================================
// USER LOOKUP & SEARCH
// ================================================================
export const lookupUser = onCall(
  {region: "southamerica-east1", memory: "256MiB"},
  async (request) => {
    assertAdmin(request);

    const uid = request.data?.uid as string;
    if (!uid) {
      throw new HttpsError("invalid-argument", "UID é obrigatório.");
    }

    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
      throw new HttpsError("not-found", "Usuário não encontrado.");
    }

    const userData = userDoc.data() || {};

    // Buscar moderação
    const modDoc = await db.collection("userModerations").doc(uid).get();
    const modData = modDoc.exists ? modDoc.data() : null;

    return {
      uid,
      nome: userData.nome || userData.name || "",
      email: userData.email || "",
      foto: userData.foto || userData.photoUrl || "",
      tipoPerfil: userData.tipo_perfil || userData.tipoPerfil || "",
      status: userData.status || "active",
      likeCount: userData.likeCount || 0,
      cidade: userData.cidade || "",
      estado: userData.estado || "",
      bio: userData.bio || "",
      createdAt: userData.createdAt || null,
      suspendedUntil: userData.suspended_until || null,
      reportCount: modData?.report_count || 0,
      suspensionCount: modData?.suspension_count || 0,
    };
  }
);

export const searchUsers = onCall(
  {region: "southamerica-east1", memory: "256MiB"},
  async (request) => {
    assertAdmin(request);

    const query = request.data?.query as string;
    const limit = Math.min((request.data?.limit as number) || 20, 50);

    if (!query || query.length < 2) {
      throw new HttpsError(
        "invalid-argument",
        "Query deve ter pelo menos 2 caracteres."
      );
    }

    const queryLower = query.toLowerCase();
    const results: Record<string, unknown>[] = [];

    // Busca por nome (prefixo)
    const nameSnap = await db
      .collection("users")
      .where("searchName", ">=", queryLower)
      .where("searchName", "<=", queryLower + "\uf8ff")
      .limit(limit)
      .get();

    for (const doc of nameSnap.docs) {
      const data = doc.data();
      results.push({
        uid: doc.id,
        nome: data.nome || data.name || "",
        email: data.email || "",
        foto: data.foto || data.photoUrl || "",
        tipoPerfil: data.tipo_perfil || data.tipoPerfil || "",
        status: data.status || "active",
      });
    }

    return {results, total: results.length};
  }
);

// ================================================================
// REPORTS / DENÚNCIAS
// ================================================================
export const listReports = onCall(
  {region: "southamerica-east1", memory: "256MiB"},
  async (request) => {
    assertAdmin(request);

    const status = (request.data?.status as string) || "processed";
    const limit = Math.min((request.data?.limit as number) || 20, 100);

    let query = db.collection("reports")
      .orderBy("created_at", "desc") as FirebaseFirestore.Query;

    if (status !== "all") {
      query = query.where("status", "==", status);
    }

    const snap = await query.limit(limit).get();
    const reports = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        reporterUserId: data.reporter_user_id || "",
        reportedItemId: data.reported_item_id || "",
        reportedItemType: data.reported_item_type || "",
        reason: data.reason || "",
        description: data.description || "",
        status: data.status || "pending",
        createdAt: data.created_at || null,
        processedAt: data.processed_at || null,
      };
    });

    return {reports, total: reports.length};
  }
);

export const updateReportStatus = onCall(
  {region: "southamerica-east1", memory: "256MiB"},
  async (request) => {
    assertAdmin(request);

    const reportId = request.data?.reportId as string;
    const newStatus = request.data?.status as string;

    if (!reportId || !newStatus) {
      throw new HttpsError(
        "invalid-argument",
        "reportId e status são obrigatórios."
      );
    }

    const validStatuses = ["pending", "processing", "processed",
      "rejected", "invalid"];
    if (!validStatuses.includes(newStatus)) {
      throw new HttpsError("invalid-argument", "Status inválido.");
    }

    await db.collection("reports").doc(reportId).update({
      status: newStatus,
      processed_at: Timestamp.now(),
      processed_by: request.auth?.uid,
    });

    return {success: true};
  }
);

// ================================================================
// SUSPENSÕES
// ================================================================
export const listSuspensions = onCall(
  {region: "southamerica-east1", memory: "256MiB"},
  async (request) => {
    assertAdmin(request);

    const statusFilter = (request.data?.status as string) || "active";
    const limit = Math.min((request.data?.limit as number) || 20, 100);

    let query = db.collection("suspensions")
      .orderBy("created_at", "desc") as FirebaseFirestore.Query;

    if (statusFilter !== "all") {
      query = query.where("status", "==", statusFilter);
    }

    const snap = await query.limit(limit).get();
    const suspensions = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        userId: data.user_id || "",
        reason: data.reason || "",
        status: data.status || "active",
        createdAt: data.created_at || null,
        suspendedUntil: data.suspended_until || null,
        liftedAt: data.lifted_at || null,
        liftedBy: data.lifted_by || null,
      };
    });

    return {suspensions, total: suspensions.length};
  }
);

export const manageSuspension = onCall(
  {region: "southamerica-east1", memory: "256MiB"},
  async (request) => {
    assertAdmin(request);

    const action = request.data?.action as string;

    if (action === "create") {
      const userId = request.data?.userId as string;
      const reason = request.data?.reason as string;
      const durationDays = (request.data?.durationDays as number) || 7;

      if (!userId || !reason) {
        throw new HttpsError(
          "invalid-argument",
          "userId e reason são obrigatórios."
        );
      }

      const now = Timestamp.now();
      const suspendedUntil = Timestamp.fromDate(
        new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000)
      );

      await db.collection("suspensions").add({
        user_id: userId,
        reason,
        status: "active",
        created_at: now,
        suspended_until: suspendedUntil,
        lifted_at: null,
        lifted_by: null,
        created_by: request.auth?.uid,
      });

      await db.collection("users").doc(userId).update({
        status: "suspended",
        suspended_until: suspendedUntil,
        updated_at: now,
      });

      return {success: true, action: "created"};
    }

    if (action === "lift") {
      const suspensionId = request.data?.suspensionId as string;
      if (!suspensionId) {
        throw new HttpsError(
          "invalid-argument",
          "suspensionId é obrigatório."
        );
      }

      const now = Timestamp.now();
      const suspDoc = await db
        .collection("suspensions").doc(suspensionId).get();
      if (!suspDoc.exists) {
        throw new HttpsError("not-found", "Suspensão não encontrada.");
      }

      const suspData = suspDoc.data() || {};
      const userId = suspData.user_id as string;

      await db.collection("suspensions").doc(suspensionId).update({
        status: "lifted",
        lifted_at: now,
        lifted_by: request.auth?.uid,
      });

      await db.collection("users").doc(userId).update({
        status: "active",
        suspended_until: null,
        updated_at: now,
      });

      return {success: true, action: "lifted"};
    }

    throw new HttpsError(
      "invalid-argument",
      "action deve ser 'create' ou 'lift'."
    );
  }
);

// ================================================================
// TICKETS DE SUPORTE
// ================================================================
export const listTickets = onCall(
  {region: "southamerica-east1", memory: "256MiB"},
  async (request) => {
    assertAdmin(request);

    const statusFilter = (request.data?.status as string) || "all";
    const limit = Math.min((request.data?.limit as number) || 20, 100);

    let query = db.collection("tickets")
      .orderBy("createdAt", "desc") as FirebaseFirestore.Query;

    if (statusFilter !== "all") {
      query = query.where("status", "==", statusFilter);
    }

    const snap = await query.limit(limit).get();
    const tickets = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        userId: data.userId || "",
        subject: data.subject || "",
        message: data.message || "",
        status: data.status || "open",
        category: data.category || "",
        createdAt: data.createdAt || null,
        updatedAt: data.updatedAt || null,
        adminResponse: data.adminResponse || null,
      };
    });

    return {tickets, total: tickets.length};
  }
);

export const updateTicket = onCall(
  {region: "southamerica-east1", memory: "256MiB"},
  async (request) => {
    assertAdmin(request);

    const ticketId = request.data?.ticketId as string;
    const newStatus = request.data?.status as string;
    const response = request.data?.response as string;

    if (!ticketId) {
      throw new HttpsError("invalid-argument", "ticketId é obrigatório.");
    }

    const updateData: Record<string, unknown> = {
      updatedAt: Timestamp.now(),
      updatedBy: request.auth?.uid,
    };

    if (newStatus) updateData.status = newStatus;
    if (response) updateData.adminResponse = response;

    await db.collection("tickets").doc(ticketId).update(updateData);

    return {success: true};
  }
);

// ================================================================
// DASHBOARD STATS
// ================================================================
export const getDashboardStats = onCall(
  {region: "southamerica-east1", memory: "512MiB"},
  async (request) => {
    assertAdmin(request);

    const now = new Date();
    const oneDayAgo = Timestamp.fromDate(
      new Date(now.getTime() - 24 * 60 * 60 * 1000)
    );
    const sevenDaysAgo = Timestamp.fromDate(
      new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
    );

    // Total users (approximation via count)
    const usersSnap = await db.collection("users").count().get();
    const totalUsers = usersSnap.data().count;

    // New users last 24h
    const newUsers24h = await db.collection("users")
      .where("createdAt", ">=", oneDayAgo)
      .count().get();

    // New users last 7d
    const newUsers7d = await db.collection("users")
      .where("createdAt", ">=", sevenDaysAgo)
      .count().get();

    // Pending reports
    const pendingReports = await db.collection("reports")
      .where("status", "==", "pending")
      .count().get();

    // Active suspensions
    const activeSuspensions = await db.collection("suspensions")
      .where("status", "==", "active")
      .count().get();

    // Open tickets
    const openTickets = await db.collection("tickets")
      .where("status", "==", "open")
      .count().get();

    return {
      totalUsers: totalUsers || 0,
      newUsers24h: newUsers24h.data().count || 0,
      newUsers7d: newUsers7d.data().count || 0,
      pendingReports: pendingReports.data().count || 0,
      activeSuspensions: activeSuspensions.data().count || 0,
      openTickets: openTickets.data().count || 0,
    };
  }
);
