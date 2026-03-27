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
const profileFields = ['profissional', 'banda', 'estudio', 'contratante'];
const supportedPhotoVariants = ['thumbnail', 'medium', 'large'];

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
  console.log('Backfill de variantes de fotos da galeria');
  console.log('');
  console.log('Uso:');
  console.log(
    '  node scripts/migrations/backfill_gallery_photo_variants.cjs --dry-run',
  );
  console.log(
    '  node scripts/migrations/backfill_gallery_photo_variants.cjs --apply',
  );
  console.log(
    '  node scripts/migrations/backfill_gallery_photo_variants.cjs --dry-run --uid=<uid>',
  );
  console.log('');
  console.log('Opcoes:');
  console.log('  --apply            Aplica alteracoes no Firestore');
  console.log('  --dry-run          So simula (padrao)');
  console.log('  --uid=<uid>        Processa apenas um usuario');
  console.log('  --limit=<n>        Limita a quantidade de usuarios processados');
  console.log('  --page-size=<n>    Tamanho do lote de leitura (padrao: 100)');
  console.log('  --verbose          Log detalhado de usuarios/itens');
  console.log('');
  console.log('Requisitos:');
  console.log(
    '  - GOOGLE_APPLICATION_CREDENTIALS configurado, ou gcloud auth application-default login',
  );
}

function createStats() {
  return {
    usersScanned: 0,
    usersChanged: 0,
    profileGalleriesScanned: 0,
    photoItemsScanned: 0,
    photoItemsChanged: 0,
    photoItemsAlreadyComplete: 0,
    photoItemsWithoutDescriptor: 0,
    photoItemsLegacySingleFile: 0,
    photoItemsWithoutVariantsInStorage: 0,
    variantFieldsFilled: 0,
    variantFileLookups: 0,
    warnings: 0,
  };
}

function isNonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function isPhotoItem(item) {
  return item && item.type === 'photo';
}

function hasVariant(item, fieldName) {
  return isNonEmptyString(item?.[fieldName]);
}

function decodeUrl(url) {
  if (!isNonEmptyString(url)) return '';
  try {
    return decodeURIComponent(url);
  } catch (_) {
    return String(url);
  }
}

function parseGalleryPhotoPath(url) {
  const decoded = decodeUrl(url);
  if (!decoded) return null;

  const folderMatch = decoded.match(
    /gallery_photos\/([^/?]+)\/([^/?]+)\/(thumbnail|medium|large|full)\.webp/i,
  );
  if (folderMatch) {
    return {
      kind: 'folder',
      userId: folderMatch[1],
      mediaId: folderMatch[2],
      variant: folderMatch[3].toLowerCase(),
    };
  }

  const legacyMatch = decoded.match(
    /gallery_photos\/([^/?]+)\/([^/?]+)\.webp(?:\?|$)/i,
  );
  if (legacyMatch) {
    return {
      kind: 'legacy-single-file',
      userId: legacyMatch[1],
      mediaId: legacyMatch[2],
    };
  }

  return null;
}

function resolvePhotoDescriptor(userId, item) {
  const parsedPath = parseGalleryPhotoPath(item.url);
  if (parsedPath?.userId && parsedPath.userId !== userId) {
    return { kind: 'mismatched-user', mediaId: parsedPath.mediaId };
  }

  if (parsedPath?.kind === 'legacy-single-file') {
    return parsedPath;
  }

  if (parsedPath?.kind === 'folder') {
    return parsedPath;
  }

  if (isNonEmptyString(item.id)) {
    return {
      kind: 'id-only',
      userId,
      mediaId: item.id.trim(),
    };
  }

  return null;
}

async function loadVariantUrl(bucket, storagePath, stats) {
  stats.variantFileLookups += 1;
  const file = bucket.file(storagePath);
  const [exists] = await file.exists();
  if (!exists) {
    return null;
  }

  return getDownloadURL(file);
}

async function enrichPhotoItem({ bucket, userId, item, stats }) {
  stats.photoItemsScanned += 1;

  const descriptor = resolvePhotoDescriptor(userId, item);
  if (descriptor == null) {
    stats.photoItemsWithoutDescriptor += 1;
    return { changed: false, nextItem: item };
  }

  if (descriptor.kind === 'mismatched-user') {
    stats.warnings += 1;
    return { changed: false, nextItem: item };
  }

  if (descriptor.kind === 'legacy-single-file') {
    stats.photoItemsLegacySingleFile += 1;
    return { changed: false, nextItem: item };
  }

  const missingFields = supportedPhotoVariants.filter(
    (fieldName) => !hasVariant(item, `${fieldName}Url`),
  );

  if (missingFields.length === 0) {
    stats.photoItemsAlreadyComplete += 1;
    return { changed: false, nextItem: item };
  }

  const variantEntries = await Promise.all(
    missingFields.map(async (variant) => {
      const storagePath = `gallery_photos/${userId}/${descriptor.mediaId}/${variant}.webp`;
      const url = await loadVariantUrl(bucket, storagePath, stats);
      return [variant, url];
    }),
  );

  const nextItem = { ...item };
  let changed = false;

  for (const [variant, url] of variantEntries) {
    if (!isNonEmptyString(url)) {
      continue;
    }
    nextItem[`${variant}Url`] = url;
    stats.variantFieldsFilled += 1;
    changed = true;
  }

  if (!changed) {
    stats.photoItemsWithoutVariantsInStorage += 1;
    return { changed: false, nextItem: item };
  }

  stats.photoItemsChanged += 1;
  return { changed: true, nextItem };
}

async function processGallery({ bucket, userId, gallery, stats }) {
  if (!Array.isArray(gallery) || gallery.length === 0) {
    return { changed: false, nextGallery: gallery };
  }

  stats.profileGalleriesScanned += 1;
  const nextGallery = [];
  let galleryChanged = false;

  for (const rawItem of gallery) {
    if (!rawItem || typeof rawItem !== 'object' || Array.isArray(rawItem)) {
      nextGallery.push(rawItem);
      continue;
    }

    const item = { ...rawItem };
    if (!isPhotoItem(item)) {
      nextGallery.push(item);
      continue;
    }

    const result = await enrichPhotoItem({ bucket, userId, item, stats });
    if (result.changed) {
      galleryChanged = true;
    }
    nextGallery.push(result.nextItem);
  }

  return { changed: galleryChanged, nextGallery };
}

async function processUserDoc({ doc, bucket, mode, stats, verbose }) {
  const data = doc.data();
  const updates = {};
  let userChanged = false;

  for (const profileField of profileFields) {
    const profileData = data?.[profileField];
    if (!profileData || typeof profileData !== 'object') {
      continue;
    }

    const gallery = profileData.gallery;
    const result = await processGallery({
      bucket,
      userId: doc.id,
      gallery,
      stats,
    });

    if (!result.changed) {
      continue;
    }

    updates[`${profileField}.gallery`] = result.nextGallery;
    userChanged = true;
  }

  if (!userChanged) {
    if (verbose) {
      console.log(`- ${doc.id}: sem mudanca`);
    }
    return;
  }

  stats.usersChanged += 1;
  if (verbose) {
    console.log(
      `- ${doc.id}: ${mode === 'apply' ? 'atualizando Firestore' : 'dry-run com alteracoes'}`,
    );
  }

  if (mode === 'apply') {
    await doc.ref.update(updates);
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
  console.log(`- galerias processadas: ${stats.profileGalleriesScanned}`);
  console.log(`- fotos analisadas: ${stats.photoItemsScanned}`);
  console.log(`- fotos atualizadas: ${stats.photoItemsChanged}`);
  console.log(
    `- fotos ja completas: ${stats.photoItemsAlreadyComplete}`,
  );
  console.log(
    `- fotos sem descriptor suficiente: ${stats.photoItemsWithoutDescriptor}`,
  );
  console.log(
    `- fotos em formato legado de arquivo unico: ${stats.photoItemsLegacySingleFile}`,
  );
  console.log(
    `- fotos sem variantes no Storage: ${stats.photoItemsWithoutVariantsInStorage}`,
  );
  console.log(`- campos de variante preenchidos: ${stats.variantFieldsFilled}`);
  console.log(`- consultas a arquivos no Storage: ${stats.variantFileLookups}`);
  console.log(`- avisos: ${stats.warnings}`);
}

main().catch((error) => {
  console.error('');
  console.error('Falha ao executar backfill de variantes da galeria.');
  console.error(error);
  process.exit(1);
});
