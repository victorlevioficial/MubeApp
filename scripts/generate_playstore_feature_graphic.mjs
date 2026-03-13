import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { chromium } from 'playwright';
import sharp from 'sharp';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const OUT_DIR = path.join(ROOT, 'assets', 'images', 'store_graphics');
const OUT = path.join(OUT_DIR, 'playstore_feature_graphic.png');
const W = 1024;
const H = 500;

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
const brandWordmarkLight = uri('assets/images/logos_svg/brand/brand-wordmark-light.svg', 'image/svg+xml');
const brandIconPrimary = uri('assets/images/logos_svg/brand/brand-icon-primary.svg', 'image/svg+xml');
const shot = uri('assets/images/screenshots/ss3.png', 'image/png');

const css = `
${fonts}
*{box-sizing:border-box}html,body{margin:0;width:${W}px;height:${H}px;overflow:hidden}
body{background:#09090c;color:#fff;font-family:'Inter Local',system-ui,sans-serif}
.art{position:relative;width:100%;height:100%;overflow:hidden;isolation:isolate;background:
  radial-gradient(circle at 18% 24%, ${a('#E8466C', .22)} 0%, transparent 34%),
  radial-gradient(circle at 62% 28%, ${a('#6E42D6', .18)} 0%, transparent 26%),
  radial-gradient(circle at 86% 72%, ${a('#2F4EA7', .22)} 0%, transparent 34%),
  linear-gradient(108deg, #150d11 0%, #0c0b15 44%, #090c16 100%)}
.art:before{content:'';position:absolute;inset:0;background-image:url("${noise}");background-size:260px 260px;opacity:.09;mix-blend-mode:soft-light}
.art:after{content:'';position:absolute;inset:0;background:
  linear-gradient(180deg, rgba(8,8,10,.06) 0%, rgba(8,8,10,0) 32%),
  linear-gradient(90deg, rgba(8,8,10,.04) 0%, rgba(8,8,10,0) 38%, rgba(8,8,10,.18) 100%)}
.orb,.ring,.grid,.wordmark,.hero,.mark-float,.phone{position:absolute}
.orb{border-radius:999px;filter:blur(58px);mix-blend-mode:screen}
.ring{border-radius:999px;border:1px solid rgba(255,255,255,.08)}
.grid{background-image:radial-gradient(circle, rgba(255,255,255,.88) 1.2px, transparent 1.3px);background-size:18px 18px;opacity:.12}
.wordmark{left:56px;top:62px;z-index:12}
.wordmark img{width:140px;height:auto;display:block}
.hero{left:56px;top:132px;width:470px;z-index:14}
.eyebrow{font-size:12px;font-weight:600;letter-spacing:.28em;text-transform:uppercase;color:rgba(232,70,108,.92)}
.headline{margin-top:18px;font-family:'Poppins Local',sans-serif;font-size:68px;line-height:.9;font-weight:700;letter-spacing:-.06em}
.sub{margin-top:18px;max-width:390px;color:rgba(255,255,255,.66);font-size:19px;line-height:1.28;letter-spacing:-.012em}
.mark-float{left:488px;top:170px;width:160px;height:160px;display:grid;place-items:center;z-index:16}
.mark-float:before{content:'';position:absolute;inset:-34px;border-radius:999px;background:radial-gradient(circle, ${a('#E8466C', .24)} 0%, ${a('#6E42D6', .14)} 42%, ${a('#2F4EA7', .1)} 66%, transparent 76%);filter:blur(18px);opacity:.95}
.mark-float:after{content:'';position:absolute;inset:-18px;border-radius:999px;border:1px solid rgba(255,255,255,.08)}
.mark-float i{position:absolute;inset:20px;border-radius:999px;border:1px solid rgba(255,255,255,.06)}
.mark-float img{position:relative;width:124px;height:124px;display:block;filter:drop-shadow(0 24px 42px rgba(0,0,0,.26))}
.phone{right:-24px;top:-82px;width:300px;height:600px;transform:rotate(8deg);transform-origin:center center;z-index:10;opacity:.9}
.phone .glow{position:absolute;left:20px;top:36px;width:264px;height:504px;border-radius:90px;background:${a('#2F4EA7', .2)};filter:blur(58px);opacity:.82}
.phone .frame{position:relative;width:100%;height:100%;padding:10px;border-radius:54px;border:1px solid rgba(255,255,255,.14);background:linear-gradient(180deg, rgba(255,255,255,.14) 0%, rgba(255,255,255,.03) 100%), rgba(15,15,18,.9);box-shadow:0 42px 100px rgba(0,0,0,.48), inset 0 1px 0 rgba(255,255,255,.08);overflow:hidden}
.phone .screen{position:relative;width:100%;height:100%;border-radius:44px;overflow:hidden;background:#050505}
.phone .screen img{display:block;width:100%;height:100%;object-fit:cover;object-position:center top}
.phone .notch{position:absolute;top:12px;left:50%;width:118px;height:24px;transform:translateX(-50%);border-radius:999px;background:rgba(8,8,10,.98);z-index:2}
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
        <div class="orb" style="left:-86px;top:164px;width:272px;height:272px;background:${a('#E8466C', .16)}"></div>
        <div class="orb" style="right:120px;top:42px;width:210px;height:210px;background:${a('#6E42D6', .14)}"></div>
        <div class="orb" style="right:-44px;bottom:-56px;width:232px;height:232px;background:${a('#2F4EA7', .18)}"></div>
        <div class="ring" style="right:136px;top:84px;width:256px;height:256px"></div>
        <div class="grid" style="left:498px;top:86px;width:72px;height:104px"></div>

        <div class="wordmark">
          <img src="${brandWordmarkLight}" alt="Mube">
        </div>

        <div class="hero">
          <div class="eyebrow">A PLATAFORMA DA CENA</div>
          <div class="headline">Tudo o que move<br>o seu som.</div>
          <div class="sub">M&uacute;sicos, bandas, est&uacute;dios e contratantes em uma experi&ecirc;ncia s&oacute;bria e direta.</div>
        </div>

        <div class="mark-float" aria-hidden="true">
          <i></i>
          <img src="${brandIconPrimary}" alt="">
        </div>

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
