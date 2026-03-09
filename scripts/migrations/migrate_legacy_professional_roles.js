#!/usr/bin/env node

const fs = require('fs');
const os = require('os');
const path = require('path');

const PROJECT_ID = 'mube-63a93';
const DEFAULT_MODE = 'dry-run';

const MIGRATIONS = {
  TkXLXE2JxXX2StHCdVom3dlelss1: {
    name: 'Fabiano Camargo',
    replacements: {
      'Produtor': ['Produtor Técnico'],
    },
  },
  w2rU3kY6AHcCxOCvZDNBwuwqoDT2: {
    name: 'Felipe Leira',
    replacements: {
      'Produtor': ['Produtor Artístico'],
    },
  },
  FSASRdvbF1SxRDBl1VhZeNB73CA3: {
    name: 'Gustavo Alves',
    replacements: {
      'Backline Tech': [],
    },
  },
  FHaN7uMIu4TWl4iywu57q8IP6By2: {
    name: 'Hygor Tomaz',
    replacements: {
      'Diretor Musical': [],
    },
  },
  bn5giwfsflcYRNehkfh3ZDVEg9a2: {
    name: 'Julia Farias',
    replacements: {
      'Produtor': ['Produtor Artístico'],
    },
  },
  YGiZ3835mQdfy0bTF2VXmdWxyvD3: {
    name: 'Kadu Carvalho',
    replacements: {
      'Diretor Musical': [],
    },
  },
  '0U0f5x1LmoZEYzEj8sOmLr6ZDEx2': {
    name: 'Kauan Calazans',
    replacements: {
      'Produtor': [],
      'Diretor Musical': [],
    },
  },
  M4TW5FUEnWSIXMEn6LHOyRsc4y22: {
    name: 'Lohran Leucas',
    replacements: {
      'Produtor': [],
      'Diretor Musical': [],
    },
  },
  yKAocwXexaYD4p1a1iWgVIyCmZI2: {
    name: 'Lua Nolasco',
    replacements: {
      'Produtor': ['Produtor Executivo'],
    },
  },
  mnNV4WlO7MNHaEmQV9y46j6Opph1: {
    name: 'Raphael Dieguez “Moitz.”',
    replacements: {
      'Diretor Musical': [],
    },
  },
  '1EaEeERiPMNUsbBUbfjmvgG20Zn1': {
    name: 'Sick Bhering',
    replacements: {
      'Produtor': ['Produtor Técnico'],
      'Backline Tech': [],
    },
  },
  goviW30XLNMm0qDekz5RB6ezM783: {
    name: 'Victor Levi',
    replacements: {
      'Produtor': ['Produtor Artístico'],
      'Diretor Musical': [],
    },
  },
  '4Z74eUjhSVbnn0qh7lJAMiNrB452': {
    name: 'Wally',
    replacements: {
      'Produtor': ['Produtor Artístico', 'Produtor Técnico'],
    },
  },
  ifKLEsVjydXbzp10FED3AfUvRgF2: {
    name: 'Yuri Christ',
    replacements: {
      'Produtor': ['Produtor Técnico'],
    },
  },
};

function parseArgs(argv) {
  const apply = argv.includes('--apply');
  const dryRun = argv.includes('--dry-run') || !apply;
  return {
    mode: apply ? 'apply' : (dryRun ? 'dry-run' : DEFAULT_MODE),
  };
}

function readFirebaseAccessToken() {
  const configPath = path.join(
    os.homedir(),
    '.config',
    'configstore',
    'firebase-tools.json',
  );
  const raw = fs.readFileSync(configPath, 'utf8');
  const config = JSON.parse(raw);
  const token = config?.tokens?.access_token;
  if (!token) {
    throw new Error(
      `Token do Firebase CLI não encontrado em ${configPath}. Rode 'firebase login' e tente novamente.`,
    );
  }
  return token;
}

function decodeValue(value) {
  if (!value) return null;
  if ('stringValue' in value) return value.stringValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return Number(value.doubleValue);
  if ('booleanValue' in value) return Boolean(value.booleanValue);
  if ('timestampValue' in value) return value.timestampValue;
  if ('nullValue' in value) return null;
  if ('arrayValue' in value) {
    return (value.arrayValue.values || []).map(decodeValue);
  }
  if ('mapValue' in value) {
    const out = {};
    for (const [key, item] of Object.entries(value.mapValue.fields || {})) {
      out[key] = decodeValue(item);
    }
    return out;
  }
  return value;
}

function encodeValue(value) {
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  }
  if (typeof value === 'boolean') return { booleanValue: value };
  if (value === null) return { nullValue: null };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(encodeValue) } };
  }
  if (typeof value === 'object') {
    const fields = {};
    for (const [key, item] of Object.entries(value)) {
      fields[key] = encodeValue(item);
    }
    return { mapValue: { fields } };
  }
  throw new Error(`Tipo não suportado para encodeValue: ${typeof value}`);
}

function applyReplacements(currentRoles, replacements) {
  const nextRoles = [];
  const seen = new Set();

  for (const role of currentRoles) {
    if (Object.prototype.hasOwnProperty.call(replacements, role)) {
      for (const replacement of replacements[role]) {
        if (!seen.has(replacement)) {
          nextRoles.push(replacement);
          seen.add(replacement);
        }
      }
      continue;
    }

    if (!seen.has(role)) {
      nextRoles.push(role);
      seen.add(role);
    }
  }

  return nextRoles;
}

async function fetchUser(token, uid) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}`;
  const res = await fetch(url, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Falha ao buscar usuário ${uid}: ${res.status} ${text}`);
  }

  const doc = await res.json();
  return {
    raw: doc,
    data: decodeValue({ mapValue: { fields: doc.fields || {} } }),
  };
}

async function updateUserRoles(token, uid, nextRoles) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}?updateMask.fieldPaths=profissional.funcoes`;
  const body = {
    fields: {
      profissional: {
        mapValue: {
          fields: {
            funcoes: encodeValue(nextRoles),
          },
        },
      },
    },
  };

  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Falha ao atualizar usuário ${uid}: ${res.status} ${text}`);
  }
}

function formatDiff(before, after) {
  const removed = before.filter((role) => !after.includes(role));
  const added = after.filter((role) => !before.includes(role));
  return { removed, added };
}

async function main() {
  const { mode } = parseArgs(process.argv.slice(2));
  const token = readFirebaseAccessToken();

  console.log(`Projeto: ${PROJECT_ID}`);
  console.log(`Modo: ${mode}`);
  console.log('');

  let changedCount = 0;

  for (const [uid, migration] of Object.entries(MIGRATIONS)) {
    const { data } = await fetchUser(token, uid);
    const professional = data.profissional || {};
    const currentRoles = Array.isArray(professional.funcoes)
      ? professional.funcoes
      : [];
    const nextRoles = applyReplacements(currentRoles, migration.replacements);
    const { removed, added } = formatDiff(currentRoles, nextRoles);
    const changed = JSON.stringify(currentRoles) !== JSON.stringify(nextRoles);
    const displayName = professional.nomeArtistico || data.nome || migration.name;

    console.log(`- ${displayName} (${uid})`);
    console.log(`  atual: ${currentRoles.join(', ') || '[vazio]'}`);
    console.log(`  novo : ${nextRoles.join(', ') || '[vazio]'}`);
    console.log(`  remove: ${removed.join(', ') || '-'}`);
    console.log(`  adiciona: ${added.join(', ') || '-'}`);

    if (changed) {
      changedCount++;
      if (mode === 'apply') {
        await updateUserRoles(token, uid, nextRoles);
        console.log('  status: atualizado');
      } else {
        console.log('  status: dry-run');
      }
    } else {
      console.log('  status: sem mudança');
    }

    console.log('');
  }

  console.log(`Perfis processados: ${Object.keys(MIGRATIONS).length}`);
  console.log(`Perfis com alteração: ${changedCount}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
