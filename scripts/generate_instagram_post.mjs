import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { chromium } from 'playwright';
import sharp from 'sharp';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const OUT_DIR = path.join(ROOT, 'assets', 'images', 'store_graphics');
const OUT = path.join(OUT_DIR, 'instagram_feed_post.png');
const W = 1080;
const H = 1350;

const extMime = {
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.woff2': 'font/woff2',
};

const read = (rel) => fs.readFileSync(path.join(ROOT, rel));
const uri = (rel, mime = extMime[path.extname(rel).toLowerCase()] ?? 'application/octet-stream') =>
  `data:${mime};base64,${read(rel).toString('base64')}`;
const svg = (value) => `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(value)}`;
const rgb = (hex) => {
  const normalized = hex.replace('#', '');
  return [0, 2, 4].map((index) => Number.parseInt(normalized.slice(index, index + 2), 16));
};
const a = (hex, alpha) => {
  const [r, g, b] = rgb(hex);
  return `rgba(${r},${g},${b},${alpha})`;
};
const ff = (family, weight, rel) =>
  `@font-face{font-family:'${family}';src:url("${uri(rel, 'font/woff2')}") format('woff2');font-weight:${weight};font-style:normal;font-display:swap;}`;

const fonts = [
  ff('Poppins Local', 600, 'node_modules/@fontsource/poppins/files/poppins-latin-600-normal.woff2'),
  ff('Poppins Local', 700, 'node_modules/@fontsource/poppins/files/poppins-latin-700-normal.woff2'),
  ff('Poppins Local', 800, 'node_modules/@fontsource/poppins/files/poppins-latin-800-normal.woff2'),
  ff('Inter Local', 500, 'node_modules/@fontsource/inter/files/inter-latin-500-normal.woff2'),
  ff('Inter Local', 600, 'node_modules/@fontsource/inter/files/inter-latin-600-normal.woff2'),
].join('');

const noise = svg(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 320"><filter id="n"><feTurbulence type="fractalNoise" baseFrequency=".78" numOctaves="2" stitchTiles="stitch"/></filter><rect width="100%" height="100%" filter="url(#n)" opacity=".88"/></svg>`);
const brandVerticalPrimary = uri('assets/images/logos_svg/brand/brand-vertical-primary.svg', 'image/svg+xml');
const shot = uri('assets/images/screenshots/ss3.png', 'image/png');

const css = `
${fonts}
*{box-sizing:border-box}html,body{margin:0;width:${W}px;height:${H}px;overflow:hidden}
body{background:#09090c;color:#fff;font-family:'Inter Local',system-ui,sans-serif}
.art{position:relative;width:100%;height:100%;overflow:hidden;isolation:isolate;background:
  radial-gradient(circle at 14% 16%, ${a('#E8466C', .24)} 0%, transparent 32%),
  radial-gradient(circle at 76% 18%, ${a('#6E42D6', .18)} 0%, transparent 24%),
  radial-gradient(circle at 78% 74%, ${a('#2F4EA7', .22)} 0%, transparent 36%),
  linear-gradient(180deg, #140d12 0%, #0b0a14 42%, #080b14 100%)}
.art:before{content:'';position:absolute;inset:0;background-image:url("${noise}");background-size:300px 300px;opacity:.09;mix-blend-mode:soft-light}
.art:after{content:'';position:absolute;inset:0;background:
  linear-gradient(180deg, rgba(8,8,10,.08) 0%, rgba(8,8,10,0) 24%),
  linear-gradient(0deg, rgba(8,8,10,.22) 0%, rgba(8,8,10,0) 28%)}
.orb,.ring,.grid,.brand-vertical,.hero,.phone{position:absolute}
.orb{border-radius:999px;filter:blur(76px);mix-blend-mode:screen}
.ring{border-radius:999px;border:1px solid rgba(255,255,255,.08)}
.grid{background-image:radial-gradient(circle, rgba(255,255,255,.88) 1.25px, transparent 1.4px);background-size:20px 20px;opacity:.12}
.hero{left:96px;top:164px;width:620px;z-index:14}
.eyebrow{font-size:16px;font-weight:600;letter-spacing:.26em;text-transform:uppercase;color:rgba(232,70,108,.92)}
.headline{margin-top:20px;font-family:'Poppins Local',sans-serif;font-size:112px;line-height:.9;font-weight:700;letter-spacing:-.065em}
.sub{margin-top:24px;max-width:540px;color:rgba(255,255,255,.68);font-size:34px;line-height:1.26;letter-spacing:-.018em}
.brand-vertical{left:92px;bottom:92px;width:236px;height:auto;display:block;z-index:13;filter:drop-shadow(0 22px 56px rgba(0,0,0,.26))}
.phone{right:10px;bottom:-6px;width:438px;height:876px;transform:rotate(8deg);transform-origin:center center;z-index:10;opacity:.94}
.phone .glow{position:absolute;left:26px;top:58px;width:392px;height:780px;border-radius:110px;background:${a('#2F4EA7', .22)};filter:blur(72px);opacity:.86}
.phone .frame{position:relative;width:100%;height:100%;padding:12px;border-radius:72px;border:1px solid rgba(255,255,255,.14);background:linear-gradient(180deg, rgba(255,255,255,.14) 0%, rgba(255,255,255,.03) 100%), rgba(15,15,18,.9);box-shadow:0 56px 130px rgba(0,0,0,.5), inset 0 1px 0 rgba(255,255,255,.08);overflow:hidden}
.phone .screen{position:relative;width:100%;height:100%;border-radius:58px;overflow:hidden;background:#050505}
.phone .screen img{display:block;width:100%;height:100%;object-fit:cover;object-position:center top}
.phone .notch{position:absolute;top:14px;left:50%;width:156px;height:30px;transform:translateX(-50%);border-radius:999px;background:rgba(8,8,10,.98);z-index:2}
.phone .screen:after{content:'';position:absolute;inset:0;background:linear-gradient(132deg, rgba(255,255,255,.16) 0%, rgba(255,255,255,0) 28%);mix-blend-mode:screen;opacity:.44}
`;

function html() {
  return `<!doctype html>
  <html lang="pt-BR">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=${W},initial-scale=1">
      <style>${css}</style>
    </head>
    <body>
      <main class="art">
        <div class="orb" style="left:-120px;top:220px;width:320px;height:320px;background:${a('#E8466C', .18)}"></div>
        <div class="orb" style="right:60px;top:100px;width:260px;height:260px;background:${a('#6E42D6', .14)}"></div>
        <div class="orb" style="right:-60px;bottom:120px;width:320px;height:320px;background:${a('#2F4EA7', .18)}"></div>
        <div class="ring" style="left:610px;top:562px;width:300px;height:300px"></div>
        <div class="grid" style="left:760px;top:252px;width:88px;height:132px"></div>

        <div class="hero">
          <div class="eyebrow">A PLATAFORMA DA CENA</div>
          <div class="headline">Tudo o que move<br>o seu som.</div>
          <div class="sub">M&uacute;sicos, bandas, est&uacute;dios e contratantes em uma experi&ecirc;ncia s&oacute;bria e direta.</div>
        </div>

        <img class="brand-vertical" src="${brandVerticalPrimary}" alt="Mube">

        <div class="phone">
          <div class="glow"></div>
          <div class="frame">
            <div class="screen">
              <div class="notch"></div>
              <img src="${shot}" alt="">
            </div>
          </div>
        </div>
      </main>
    </body>
  </html>`;
}

async function ensureOut() {
  await fs.promises.mkdir(OUT_DIR, { recursive: true });
}

async function validate() {
  const metadata = await sharp(OUT).metadata();
  if (metadata.width !== W || metadata.height !== H) {
    throw new Error(`Unexpected size for ${path.basename(OUT)}: ${metadata.width}x${metadata.height}`);
  }
}

async function main() {
  await ensureOut();
  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: W, height: H },
    deviceScaleFactor: 1,
  });

  try {
    const page = await context.newPage();
    await page.setContent(html(), { waitUntil: 'load' });
    await page.screenshot({ path: OUT });
  } finally {
    await browser.close();
  }

  await validate();
  console.log(`Generated ${OUT}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
