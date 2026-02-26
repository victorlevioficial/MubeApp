const admin = require('firebase-admin');

// Inicializa com as credenciais padrão do Google (funciona se estiver logado via firebase CLI ou gcloud auth)
admin.initializeApp();

async function setAdmin(email) {
    try {
        const user = await admin.auth().getUserByEmail(email);
        await admin.auth().setCustomUserClaims(user.uid, { admin: true });

        // Configura o admin
        const db = admin.firestore();
        await db.collection("config").doc("admin").set(
            {
                adminUids: admin.firestore.FieldValue.arrayUnion(user.uid),
                updatedAt: admin.firestore.Timestamp.now(),
                updatedBy: "local_script_automation"
            },
            { merge: true }
        );

        console.log(`Sucesso: O usuário ${email} (UID: ${user.uid}) agora é Admin.`);
        process.exit(0);
    } catch (error) {
        console.error('Erro ao definir admin:', error);
        process.exit(1);
    }
}

setAdmin('victorlevioficial@icloud.com');
