import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

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
    const title = ticketData.title;

    console.log(`🎟️ New ticket created: ${ticketId} by user ${userId}`);

    const db = admin.firestore();

    try {
      // Get user data to send email
      const userDoc = await db.collection("users").doc(userId).get();
      const userData = userDoc.data();
      const userEmail = userData?.email;

      if (!userEmail) {
        console.log(
          `User ${userId} has no email. Skipping email confirmation.`
        );
        return;
      }

      // TODO: Integrate with SendGrid, Mailgun, or Firebase Extension for email
      // For now, we'll log that we would send an email
      // If "Trigger Email" extension is installed,
      // we can write to 'mail' collection

      console.log(
        `📧 Sending confirmation email to ${userEmail} for ticket "${title}"`
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
