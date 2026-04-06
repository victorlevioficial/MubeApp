import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const PUBLIC_SUPPORT_CATEGORIES = new Set([
  "bug",
  "feedback",
  "account",
  "other",
]);

const PUBLIC_SUPPORT_COOLDOWN_MS = 5 * 60 * 1000;
function sanitizeText(value: unknown, maxLength: number): string {
  return String(value ?? "").trim().replace(/\s+/g, " ").slice(0, maxLength);
}

function sanitizeMultilineText(value: unknown, maxLength: number): string {
  return String(value ?? "").trim().replace(/\r\n/g, "\n").slice(0, maxLength);
}

function sanitizeEmail(value: unknown): string {
  return String(value ?? "").trim().toLowerCase().slice(0, 160);
}

function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export const submitSupportTicket = onCall(
  {
    region: "southamerica-east1",
    memory: "256MiB",
    invoker: "public",
    cors: true,
  },
  async (request) => {
    const name = sanitizeText(request.data?.name, 80);
    const email = sanitizeEmail(request.data?.email);
    const title = sanitizeText(request.data?.title, 120);
    const description = sanitizeMultilineText(request.data?.description, 2_000);
    const category = sanitizeText(request.data?.category, 32);
    const honeypot = sanitizeText(request.data?.website, 120);
    if (honeypot) {
      throw new HttpsError("invalid-argument", "Solicitação inválida.");
    }

    if (name.length < 2) {
      throw new HttpsError("invalid-argument", "Informe seu nome.");
    }

    if (!isValidEmail(email)) {
      throw new HttpsError("invalid-argument", "Informe um e-mail válido.");
    }

    if (!PUBLIC_SUPPORT_CATEGORIES.has(category.toLowerCase())) {
      throw new HttpsError("invalid-argument", "Categoria inválida.");
    }

    if (title.length < 4) {
      throw new HttpsError("invalid-argument", "Informe um assunto válido.");
    }

    if (description.length < 10) {
      throw new HttpsError(
        "invalid-argument",
        "Descreva o problema com mais detalhes."
      );
    }

    const db = admin.firestore();
    const ticketRef = db.collection("tickets").doc();
    const rateLimitRef = db
      .collection("support_public_rate_limits")
      .doc(encodeURIComponent(email));
    const now = admin.firestore.Timestamp.now();

    await db.runTransaction(async (transaction) => {
      const rateLimitSnap = await transaction.get(rateLimitRef);
      const lastSubmittedAt = rateLimitSnap.data()?.lastSubmittedAt as
        | admin.firestore.Timestamp
        | undefined;

      if (
        lastSubmittedAt &&
        now.toMillis() - lastSubmittedAt.toMillis() < PUBLIC_SUPPORT_COOLDOWN_MS
      ) {
        throw new HttpsError(
          "resource-exhausted",
          "Você acabou de abrir um ticket. Aguarde alguns minutos antes de enviar outro."
        );
      }

      transaction.set(ticketRef, {
        id: ticketRef.id,
        userId: `web:${encodeURIComponent(email)}`,
        title,
        description,
        subject: title,
        message: description,
        category,
        status: "open",
        imageUrls: [],
        hasUnreadMessages: false,
        contactName: name,
        contactEmail: email,
        source: "website",
        createdAt: now,
        updatedAt: now,
      });

      transaction.set(
        rateLimitRef,
        {
          email,
          lastSubmittedAt: now,
          lastTicketId: ticketRef.id,
          updatedAt: now,
        },
        {merge: true}
      );
    });

    return {
      success: true,
      ticketId: ticketRef.id,
    };
  }
);

/**
 * Trigger: When a new ticket is created in the tickets collection.
 * Path: tickets/{ticketId}
 *
 * Actions:
 * 1. Send confirmation email to user.
 * 2. (Optional) Notify admin.
 */
export const onTicketCreated = onDocumentCreated(
  "tickets/{ticketId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No data associated with the event");
      return;
    }

    const ticketId = event.params.ticketId;
    const ticketData = snapshot.data();
    const userId = ticketData.userId;
    const title = ticketData.title || ticketData.subject || "Novo ticket";
    const contactEmail = ticketData.contactEmail;
    const source = ticketData.source || "app";

    console.log(
      `New ticket created: ${ticketId} by ${userId || contactEmail || "unknown"} via ${source}`
    );

    const db = admin.firestore();

    try {
      let userEmail = contactEmail;

      if (!userEmail && userId && !String(userId).startsWith("web:")) {
        const userDoc = await db.collection("users").doc(userId).get();
        const userData = userDoc.data();
        userEmail = userData?.email;
      }

      if (!userEmail) {
        console.log(
          `Ticket ${ticketId} has no contact email. Skipping email confirmation.`
        );
        return;
      }

      // TODO: Integrate with SendGrid, Mailgun, or Firebase Extension for email.
      // For now, log that we would send an email. If the "Trigger Email"
      // extension is installed, we can write to the 'mail' collection.
      console.log(
        `Sending confirmation email to ${userEmail} for ticket "${title}"`
      );

      // Example: Write to 'mail' collection if using Firebase Email Extension
      /*
      await db.collection("mail").add({
        to: userEmail,
        message: {
          subject: `Recebemos seu ticket: ${title}`,
          text: `Olá, recebemos sua solicitação de suporte. ` +
                `O ID do seu ticket é ${ticketId}. ` +
                `Em breve entraremos em contato.`,
          html: `<p>Olá,</p><p>Recebemos sua solicitação de suporte.</p>` +
                `<p><strong>Assunto:</strong> ${title}</p>` +
                `<p>O ID do seu ticket é <code>${ticketId}</code>.</p>` +
                `<p>Em breve entraremos em contato.</p>`,
        },
      });
      */
    } catch (error) {
      console.error("Error processing onTicketCreated:", error);
    }
  }
);
