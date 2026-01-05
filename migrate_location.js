// Script para migrar 'lng' para 'long' na coleção 'users' do Firestore
// Usa Application Default Credentials (funciona após firebase login)
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

// Inicializa usando credenciais do ambiente (firebase login)
initializeApp({
    credential: applicationDefault(),
    projectId: 'mube-63a93'
});

const db = getFirestore();

async function migrateLocationField() {
    console.log('Iniciando migração de lng -> long...');
    console.log('Projeto: mube-63a93');
    console.log('');

    const usersRef = db.collection('users');
    const snapshot = await usersRef.get();

    console.log(`Total de usuários encontrados: ${snapshot.size}`);

    let updated = 0;
    let skipped = 0;

    for (const doc of snapshot.docs) {
        const data = doc.data();
        const location = data.location;

        // Verifica se tem 'lng' mas não tem 'long'
        if (location && location.lng !== undefined && location.long === undefined) {
            const newLocation = {
                ...location,
                long: location.lng
            };
            delete newLocation.lng;

            await usersRef.doc(doc.id).update({ location: newLocation });
            console.log(`✅ Atualizado: ${doc.id.substring(0, 8)}...`);
            updated++;
        } else if (location && location.long !== undefined) {
            console.log(`⏭️  Já está ok: ${doc.id.substring(0, 8)}...`);
            skipped++;
        } else {
            console.log(`⚠️  Sem location: ${doc.id.substring(0, 8)}...`);
            skipped++;
        }
    }

    console.log('');
    console.log('Migração concluída!');
    console.log(`- Atualizados: ${updated}`);
    console.log(`- Ignorados: ${skipped}`);

    process.exit(0);
}

migrateLocationField().catch(err => {
    console.error('Erro:', err);
    process.exit(1);
});
