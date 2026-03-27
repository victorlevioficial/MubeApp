#!/usr/bin/env node

const { createRequire } = require('module');
const path = require('path');

const functionsRequire = createRequire(
  path.join(__dirname, '../../functions/package.json'),
);

const {
  initializeApp,
  applicationDefault,
} = functionsRequire('firebase-admin/app');
const {
  getFirestore,
  FieldPath,
} = functionsRequire('firebase-admin/firestore');
const {
  getStorage,
  getDownloadURL,
} = functionsRequire('firebase-admin/storage');

const projectId = 'mube-63a93';
const storageBucket = 'mube-63a93.firebasestorage.app';
const usersCollection = 'users';
const defaultPageSize = 100;

function parseArgs(argv) {
  const args = {
    mode: 'dry-run',
    help: false,
    uid: null,
    limit: null,
    pageSize: defaultPageSize,
    verbose: false,
  };

  for (const arg of argv) {
    if (arg === '--apply') {
      args.mode = 'apply';
      continue;
    }

    if (arg === '--dry-run') {
      args.mode = 'dry-run';
      continue;
    }

    if (arg === '--help' || arg === '-h') {
      args.help = true;
      continue;
    }

    if (arg === '--verbose') {
      args.verbose = true;
      continue;
    }

    if (arg.startsWith('--uid=')) {
      args.uid = arg.slice('--uid='.length).trim() || null;
      continue;
    }

    if (arg.startsWith('--limit=')) {
      const parsed = Number.parseInt(arg.slice('--limit='.length), 10);
      if (!Number.isFinite(parsed) || parsed <= 0) {
        throw new Error(`Valor invalido para --limit: ${arg}`);
      }
      args.limit = parsed;
      continue;
    }

    if (arg.startsWith('--page-size=')) {
      const parsed = Number.parseInt(arg.slice('--page-size='.length), 10);
      if (!Number.isFinite(parsed) || parsed <= 0) {
        throw new Error(`Valor invalido para --page-size: ${arg}`);
      }
      args.pageSize = parsed;
      continue;
    }

    throw new Error(`Argumento nao suportado: ${arg}`);
  }

  return args;
}

function printHelp() {
  console.log('Backfill de foto_thumb para perfis');
  console.log('');
  console.log('Uso:');
  console.log(
    '  node scripts/migrations/backfill_profile_photo_thumbnails.cjs --dry-run',
  );
  console.log(
    '  node scripts/migrations/backfill_profile_photo_thumbnails.cjs --apply',
  );
  console.log(
    '  node scripts/migrations/backfill_profile_photo_thumbnails.cjs --dry-run --uid=<uid>',
  );
  console.log('');
  console.log('Opcoes:');
  console.log('  --apply            Aplica alteracoes no Firestore');
  console.log('  --dry-run          So simula (padrao)');
  console.log('  --uid=<uid>        Processa apenas um usuario');
  console.log('  --limit=<n>        Limita a quantidade de usuarios processados');
  console.log('  --page-size=<n>    Tamanho do lote de leitura (padrao: 100)');
  console.log('  --verbose          Log detalhado');
}

function createStats() {
  return {
    usersScanned: 0,
    usersChanged: 0,
    usersAlreadyComplete: 0,
    usersWithoutPhoto: 0,
    usersLegacySingleFile: 0,
    usersWithoutThumbnailInStorage: 0,
    warnings: 0,
  };
}

function isNonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function decodeUrl(url) {
  if (!isNonEmptyString(url)) return '';
  try {
    return decodeURIComponent(url);
  } catch (_) {
    return String(url);
  }
}

function extractCacheVersion(url) {
  if (!isNonEmptyString(url)) return null;
  try {
    const parsed = new URL(url);
    return parsed.searchParams.get('v');
  } catch (_) {
    return null;
  }
}

function appendCacheVersion(url, version) {
  if (!isNonEmptyString(url) || !isNonEmptyString(version)) {
    return url;
  }

  const separator = url.includes('?') ? '&' : '?';
  return `${url}${separator}v=${version}`;
}

function parseProfilePhotoDescriptor(uid, photoUrl) {
  const decoded = decodeUrl(photoUrl);
  if (!decoded) return null;

  const folderMatch = decoded.match(
    /profile_photos\/([^/?]+)\/(large|thumbnail)\.webp/i,
  );
  if (folderMatch) {
    return {
      kind: 'folder',
      userId: folderMatch[1],
      variant: folderMatch[2].toLowerCase(),
    };
  }

  const legacyMatch = decoded.match(
    /profile_photos\/([^/?]+)\.(webp|jpg|jpeg)(?:\?|$)/i,
  );
  if (legacyMatch) {
    return {
      kind: 'legacy-single-file',
      userId: legacyMatch[1],
    };
  }

  if (isNonEmptyString(uid)) {
    return {
      kind: 'uid-only',
      userId: uid,
    };
  }

  return null;
}

async function loadThumbnailUrl(bucket, storagePath) {
  const file = bucket.file(storagePath);
  const [exists] = await file.exists();
  if (!exists) return null;
  return getDownloadURL(file);
}

async function processUserDoc({ doc, bucket, mode, stats, verbose }) {
  const data = doc.data() || {};
  const currentPhotoUrl = data.foto;
  const currentPhotoThumb = data.foto_thumb;

  if (isNonEmptyString(currentPhotoThumb)) {
    stats.usersAlreadyComplete += 1;
    if (verbose) {
      console.log(`- ${doc.id}: foto_thumb ja preenchido`);
    }
    return;
  }

  if (!isNonEmptyString(currentPhotoUrl)) {
    stats.usersWithoutPhoto += 1;
    if (verbose) {
      console.log(`- ${doc.id}: sem foto de perfil`);
    }
    return;
  }

  const descriptor = parseProfilePhotoDescriptor(doc.id, currentPhotoUrl);
  if (descriptor == null) {
    stats.warnings += 1;
    if (verbose) {
      console.log(`- ${doc.id}: URL de foto nao reconhecida`);
    }
    return;
  }

  if (descriptor.userId && descriptor.userId !== doc.id) {
    stats.warnings += 1;
    if (verbose) {
      console.log(`- ${doc.id}: URL de foto aponta para outro usuario`);
    }
    return;
  }

  if (descriptor.kind === 'legacy-single-file') {
    stats.usersLegacySingleFile += 1;
    if (verbose) {
      console.log(`- ${doc.id}: foto legada sem thumbnail dedicada`);
    }
    return;
  }

  const thumbnailPath = `profile_photos/${doc.id}/thumbnail.webp`;
  let thumbnailUrl = await loadThumbnailUrl(bucket, thumbnailPath);
  if (!isNonEmptyString(thumbnailUrl) &&
      descriptor.kind === 'folder' &&
      descriptor.variant === 'thumbnail') {
    thumbnailUrl = currentPhotoUrl;
  }

  if (!isNonEmptyString(thumbnailUrl)) {
    stats.usersWithoutThumbnailInStorage += 1;
    if (verbose) {
      console.log(`- ${doc.id}: thumbnail ausente no Storage`);
    }
    return;
  }

  const cacheVersion = extractCacheVersion(currentPhotoUrl);
  const persistedThumbnailUrl = appendCacheVersion(thumbnailUrl, cacheVersion);

  if (mode === 'apply') {
    await doc.ref.update({ foto_thumb: persistedThumbnailUrl });
  }

  stats.usersChanged += 1;
  if (verbose) {
    console.log(
      `- ${doc.id}: ${mode === 'apply' ? 'foto_thumb atualizado' : 'dry-run com alteracao'}`,
    );
  }
}

async function* iterateUsers(db, { uid, pageSize, limit }) {
  if (uid) {
    const doc = await db.collection(usersCollection).doc(uid).get();
    if (doc.exists) {
      yield doc;
    }
    return;
  }

  let remaining = limit ?? Number.POSITIVE_INFINITY;
  let lastDoc = null;

  while (remaining > 0) {
    const currentPageSize = Math.min(pageSize, remaining);
    let query = db
      .collection(usersCollection)
      .orderBy(FieldPath.documentId())
      .limit(currentPageSize);

    if (lastDoc != null) {
      query = query.startAfter(lastDoc.id);
    }

    const snapshot = await query.get();
    if (snapshot.empty) {
      return;
    }

    for (const doc of snapshot.docs) {
      yield doc;
      remaining -= 1;
      if (remaining <= 0) {
        return;
      }
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1];
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    return;
  }

  initializeApp({
    credential: applicationDefault(),
    projectId,
    storageBucket,
  });

  const db = getFirestore();
  const bucket = getStorage().bucket(storageBucket);
  const stats = createStats();

  console.log(`Projeto: ${projectId}`);
  console.log(`Bucket: ${storageBucket}`);
  console.log(`Modo: ${args.mode}`);
  if (args.uid) {
    console.log(`Usuario alvo: ${args.uid}`);
  }
  if (args.limit != null) {
    console.log(`Limite de usuarios: ${args.limit}`);
  }
  console.log('');

  for await (const doc of iterateUsers(db, args)) {
    stats.usersScanned += 1;
    await processUserDoc({
      doc,
      bucket,
      mode: args.mode,
      stats,
      verbose: args.verbose,
    });
  }

  console.log('');
  console.log('Resumo:');
  console.log(`- usuarios processados: ${stats.usersScanned}`);
  console.log(`- usuarios com alteracao: ${stats.usersChanged}`);
  console.log(`- usuarios ja completos: ${stats.usersAlreadyComplete}`);
  console.log(`- usuarios sem foto: ${stats.usersWithoutPhoto}`);
  console.log(
    `- usuarios em formato legado sem thumbnail: ${stats.usersLegacySingleFile}`,
  );
  console.log(
    `- usuarios sem thumbnail no Storage: ${stats.usersWithoutThumbnailInStorage}`,
  );
  console.log(`- avisos: ${stats.warnings}`);
}

main().catch((error) => {
  console.error('');
  console.error('Falha ao executar backfill de foto_thumb.');
  console.error(error);
  process.exit(1);
});
