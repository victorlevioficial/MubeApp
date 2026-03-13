import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { chromium } from "playwright";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..", "..");

const scenePath = path.resolve(__dirname, "outro_scene.html");
const outputDir = path.resolve(repoRoot, "build", "brand_outro_v2");
const framesDir = path.join(outputDir, "frames");
const posterPath = path.join(outputDir, "mube_brand_outro_v2_poster.png");

const width = 1080;
const height = 1920;
const fps = 30;
const duration = 4;
const totalFrames = fps * duration;
const posterTime = 2.26;

async function resetDirectory(dir) {
  await fs.rm(dir, { recursive: true, force: true });
  await fs.mkdir(dir, { recursive: true });
}

async function exists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function launchBrowser() {
  try {
    return await chromium.launch({
      channel: "msedge",
      headless: true,
    });
  } catch (error) {
    console.warn("msedge launch failed, falling back to bundled Chromium");
    return chromium.launch({ headless: true });
  }
}

async function main() {
  await fs.mkdir(outputDir, { recursive: true });
  await resetDirectory(framesDir);
  await fs.rm(posterPath, { force: true });

  const browser = await launchBrowser();
  const context = await browser.newContext({
    viewport: { width, height },
    deviceScaleFactor: 1,
    colorScheme: "dark",
  });
  const page = await context.newPage();

  const sceneUrl = new URL(`file:///${scenePath.replace(/\\/g, "/")}`);
  await page.goto(sceneUrl.href, { waitUntil: "load" });
  await page.waitForTimeout(120);

  for (let frame = 0; frame < totalFrames; frame += 1) {
    const time = frame / fps;
    await page.evaluate((t) => {
      window.__renderAt(t);
    }, time);

    await page.screenshot({
      path: path.join(framesDir, `frame_${String(frame).padStart(4, "0")}.png`),
      type: "png",
    });

    if (Math.abs(time - posterTime) < 0.5 / fps && !(await exists(posterPath))) {
      await page.screenshot({ path: posterPath, type: "png" });
    }

    if (frame % 15 === 0) {
      console.log(`Rendered frame ${frame + 1}/${totalFrames}`);
    }
  }

  if (!(await exists(posterPath))) {
    await page.evaluate((t) => {
      window.__renderAt(t);
    }, posterTime);
    await page.screenshot({ path: posterPath, type: "png" });
  }

  await context.close();
  await browser.close();

  console.log(`Frames saved to ${framesDir}`);
  console.log(`Poster saved to ${posterPath}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
