#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

function loadLocalEnv() {
  const envPath = path.resolve(".env.local");
  if (!fs.existsSync(envPath)) return;

  const content = fs.readFileSync(envPath, "utf8");
  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;

    const separatorIndex = line.indexOf("=");
    if (separatorIndex <= 0) continue;

    const key = line.slice(0, separatorIndex).trim();
    const value = line.slice(separatorIndex + 1).trim();
    if (!key || process.env[key]) continue;

    process.env[key] = value;
  }
}

loadLocalEnv();

const args = process.argv.slice(2);

if (args.includes("--help")) {
  console.log(`Usage: node scripts/upload_play_store_release.mjs [options]

Options:
  --aab <path>         Path to the Android App Bundle
  --track <name>       Google Play track (default: alpha)
  --status <status>    Release status (default: draft)
  --package <name>     Android package name
  --json-key <path>    Service account JSON path
  --name <value>       Release name shown in Play Console
`);
  process.exit(0);
}

function readOption(name, fallback) {
  const index = args.indexOf(name);
  if (index === -1) return fallback;
  return args[index + 1] ?? fallback;
}

const packageName = readOption(
  "--package",
  process.env.PLAY_STORE_PACKAGE_NAME || "com.mube.mubeoficial",
);
const track = readOption(
  "--track",
  process.env.PLAY_STORE_CLOSED_TRACK || "alpha",
);
const releaseStatus = readOption(
  "--status",
  process.env.PLAY_STORE_RELEASE_STATUS || "draft",
);
const jsonKeyPath = path.resolve(
  readOption(
    "--json-key",
    process.env.PLAY_STORE_JSON_KEY ||
      process.env.SUPPLY_JSON_KEY ||
      "android/fastlane/play-store-service-account.json",
  ),
);
const aabPath = path.resolve(
  readOption(
    "--aab",
    process.env.PLAY_STORE_AAB_PATH ||
      "build/app/outputs/bundle/release/app-release.aab",
  ),
);
const releaseName = readOption(
  "--name",
  process.env.PLAY_STORE_RELEASE_NAME || "",
);

function base64url(input) {
  return Buffer.from(input)
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

async function getAccessToken(serviceAccount) {
  const now = Math.floor(Date.now() / 1000);
  const header = {alg: "RS256", typ: "JWT"};
  const claim = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: serviceAccount.token_uri,
    iat: now,
    exp: now + 3600,
  };
  const unsignedToken = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claim))}`;
  const signer = crypto.createSign("RSA-SHA256");
  signer.update(unsignedToken);
  signer.end();
  const signature = signer
    .sign(serviceAccount.private_key)
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
  const assertion = `${unsignedToken}.${signature}`;

  const response = await fetch(serviceAccount.token_uri, {
    method: "POST",
    headers: {"Content-Type": "application/x-www-form-urlencoded"},
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`Failed to get access token (${response.status}): ${text}`);
  }

  const data = JSON.parse(text);
  return data.access_token;
}

async function apiRequest(url, {token, method = "GET", headers = {}, body} = {}) {
  const response = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      ...headers,
    },
    body,
  });
  const text = await response.text();
  let payload = null;
  try {
    payload = text ? JSON.parse(text) : null;
  } catch {
    payload = text;
  }

  if (!response.ok) {
    const prettyPayload = typeof payload === "string" ? payload : JSON.stringify(payload, null, 2);
    throw new Error(`${method} ${url}\nstatus=${response.status}\n${prettyPayload}`);
  }

  return payload;
}

async function commitEdit(token, editId) {
  const baseUrl = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/edits/${editId}:commit`;

  try {
    return await apiRequest(`${baseUrl}?changesNotSentForReview=true`, {
      token,
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: "{}",
    });
  } catch (error) {
    const message = String(error);
    if (!message.includes("changesNotSentForReview must not be set")) {
      throw error;
    }

    return await apiRequest(baseUrl, {
      token,
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: "{}",
    });
  }
}

async function main() {
  if (!fs.existsSync(jsonKeyPath)) {
    throw new Error(`Service account JSON not found: ${jsonKeyPath}`);
  }
  if (!fs.existsSync(aabPath)) {
    throw new Error(`AAB not found: ${aabPath}`);
  }

  const serviceAccount = JSON.parse(fs.readFileSync(jsonKeyPath, "utf8"));
  const token = await getAccessToken(serviceAccount);
  const aabBuffer = fs.readFileSync(aabPath);

  const edit = await apiRequest(
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/edits`,
    {
      token,
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: "{}",
    },
  );

  const upload = await apiRequest(
    `https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/${packageName}/edits/${edit.id}/bundles?uploadType=media`,
    {
      token,
      method: "POST",
      headers: {"Content-Type": "application/octet-stream"},
      body: aabBuffer,
    },
  );

  const release = {
    versionCodes: [String(upload.versionCode)],
    status: releaseStatus,
  };
  if (releaseName.trim().length > 0) {
    release.name = releaseName.trim();
  }

  const trackUpdate = await apiRequest(
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/edits/${edit.id}/tracks/${track}`,
    {
      token,
      method: "PUT",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({
        track,
        releases: [release],
      }),
    },
  );

  const commit = await commitEdit(token, edit.id);

  console.log(JSON.stringify({
    editId: edit.id,
    packageName,
    track,
    versionCode: String(upload.versionCode),
    releaseStatus,
    trackUpdate,
    commit,
  }, null, 2));
}

main().catch((error) => {
  const message = error?.stack || String(error);

  if (message.includes("has already been used")) {
    console.error(
      [
        "Play Console rejeitou o upload porque o versionCode ja foi usado.",
        "Atualize a versao em pubspec.yaml para um novo PATCH+BUILD antes de publicar novamente.",
        "",
        message,
      ].join("\n"),
    );
    process.exit(1);
  }

  console.error(message);
  process.exit(1);
});
