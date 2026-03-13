/**
 * generate_store_screenshots_v2.mjs
 *
 * Redesigned store screenshots for Mube — Apple App Store & Google Play.
 * Output: assets/images/store_screenshots_v2/
 * Run:    node scripts/generate_store_screenshots_v2.mjs
 *
 * Design changes vs v1:
 *  - Richer, more vibrant gradient backgrounds per slide
 *  - Larger phone mockups as the visual hero
 *  - EQ bar decorative elements (music theme)
 *  - Bottom stats strip on every slide (no empty black zones)
 *  - Tighter, cleaner typography hierarchy
 *  - Better glassmorphism cards with accent borders
 */

import fs   from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { chromium } from 'playwright';
import sharp from 'sharp';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT  = path.resolve(__dirname, '..');
const OUT   = path.join(ROOT, 'assets', 'images', 'store_screenshots_v2');
const W     = 1242;
const H     = 2688;
const TOTAL = 7;
const DR    = 1206 / 2622; // phone width/height ratio

// ─── Asset loading ────────────────────────────────────────────────────────────
const EXT_MIME = { '.png': 'image/png', '.svg': 'image/svg+xml', '.woff2': 'font/woff2' };
const readFile = (rel) => fs.readFileSync(path.join(ROOT, rel));
const dataUri  = (rel, mime = EXT_MIME[path.extname(rel).toLowerCase()] ?? 'application/octet-stream') =>
  `data:${mime};base64,${readFile(rel).toString('base64')}`;

// ─── Color helpers ────────────────────────────────────────────────────────────
const hexRgb = (hex) => { const v = hex.replace('#',''); return [0,2,4].map(i => parseInt(v.slice(i,i+2),16)); };
const rgba   = (hex, a) => { const [r,g,b] = hexRgb(hex); return `rgba(${r},${g},${b},${a})`; };

// ─── Fonts ────────────────────────────────────────────────────────────────────
const ff = (fam, wt, rel) =>
  `@font-face{font-family:'${fam}';src:url("${dataUri(rel,'font/woff2')}") format('woff2');font-weight:${wt};font-display:swap;}`;

const FONTS = [
  ff('Poppins', 500, 'node_modules/@fontsource/poppins/files/poppins-latin-500-normal.woff2'),
  ff('Poppins', 600, 'node_modules/@fontsource/poppins/files/poppins-latin-600-normal.woff2'),
  ff('Poppins', 700, 'node_modules/@fontsource/poppins/files/poppins-latin-700-normal.woff2'),
  ff('Poppins', 800, 'node_modules/@fontsource/poppins/files/poppins-latin-800-normal.woff2'),
  ff('Poppins', 900, 'node_modules/@fontsource/poppins/files/poppins-latin-900-normal.woff2'),
  ff('Inter',   500, 'node_modules/@fontsource/inter/files/inter-latin-500-normal.woff2'),
  ff('Inter',   600, 'node_modules/@fontsource/inter/files/inter-latin-600-normal.woff2'),
].join('');

// ─── Brand assets ─────────────────────────────────────────────────────────────
const ICON_WHITE    = dataUri('assets/images/logos_svg/brand/brand-icon-white-cutout.svg', 'image/svg+xml');
const HORIZ_WHITE   = dataUri('assets/images/logos_svg/brand/brand-horizontal-white-cutout.svg', 'image/svg+xml');
const HORIZ_PRIMARY = dataUri('assets/images/logos_svg/brand/brand-horizontal-primary.svg', 'image/svg+xml');
const SQUARE_PRIMARY= dataUri('assets/images/logos_svg/brand/brand-square-primary.svg', 'image/svg+xml');
const SHOTS = Object.fromEntries(
  Array.from({ length: TOTAL }, (_, i) => [i+1, dataUri(`assets/images/screenshots/ss${i+1}.png`,'image/png')])
);

// ─── Design tokens ────────────────────────────────────────────────────────────
const C = {
  primary: '#E8466C',
  violet:  '#7C3AED',
  electric:'#3B82F6',
  teal:    '#0EA5E9',
  green:   '#10B981',
  amber:   '#F59E0B',
};

// ─── Noise grain SVG (inline) ─────────────────────────────────────────────────
const NOISE = `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><filter id="f"><feTurbulence type="fractalNoise" baseFrequency=".75" numOctaves="3" stitchTiles="stitch"/></filter><rect width="100%" height="100%" filter="url(#f)" opacity=".9"/></svg>'
)}`;

// ─── Base CSS ─────────────────────────────────────────────────────────────────
const CSS = `
${FONTS}
*{box-sizing:border-box;margin:0;padding:0}
html,body{width:${W}px;height:${H}px;overflow:hidden}
body{color:#fff;font-family:'Inter',system-ui,sans-serif}
.slide{position:relative;width:100%;height:100%;overflow:hidden;isolation:isolate}
.noise{position:absolute;inset:0;background-image:url("${NOISE}");background-size:512px;opacity:.055;mix-blend-mode:overlay;z-index:8;pointer-events:none}
`;

// ─── Reusable primitives ──────────────────────────────────────────────────────

/** Glowing orb */
const orb = (cx, cy, size, color, alpha = 0.22, blur = 90) =>
  `<div style="position:absolute;left:${cx-size/2}px;top:${cy-size/2}px;width:${size}px;height:${size}px;border-radius:999px;background:${rgba(color,alpha)};filter:blur(${blur}px);z-index:1;pointer-events:none"></div>`;

/** Dot grid */
const dots = (x, y, w, h, alpha = 0.09) =>
  `<div style="position:absolute;left:${x}px;top:${y}px;width:${w}px;height:${h}px;background-image:radial-gradient(circle,rgba(255,255,255,.9) 1.5px,transparent 1.5px);background-size:24px 24px;opacity:${alpha};z-index:3;pointer-events:none"></div>`;

/** EQ bars (SVG, decorative) */
const eqBars = (x, y, totalW, color, alpha = 0.13) => {
  const n = 22;
  const bw = Math.floor((totalW / n) * 0.52);
  const step = totalW / n;
  const maxH = 120;
  const heights = [42,74,30,90,56,98,40,78,58,84,32,88,64,44,94,52,70,36,80,48,66,38];
  const rects = heights.slice(0,n).map((h,i) => {
    const bx = x + i * step;
    const by = y + maxH - h;
    const op = (alpha * (0.55 + (i % 5) * 0.1)).toFixed(3);
    return `<rect x="${bx.toFixed(1)}" y="${by.toFixed(1)}" width="${bw}" height="${h}" rx="${Math.floor(bw/2)}" fill="${color}" opacity="${op}"/>`;
  }).join('');
  return `<svg xmlns="http://www.w3.org/2000/svg" style="position:absolute;left:0;top:0;width:${W}px;height:${H}px;z-index:3;pointer-events:none" viewBox="0 0 ${W} ${H}" preserveAspectRatio="xMidYMid meet">${rects}</svg>`;
};

/** Ring circle (decorative) */
const ring = (cx, cy, size, color, alpha = 0.1) =>
  `<div style="position:absolute;left:${cx-size/2}px;top:${cy-size/2}px;width:${size}px;height:${size}px;border-radius:999px;border:1px solid ${rgba(color,alpha)};z-index:4;pointer-events:none"></div>`;

/** Logo badge (top-left on every slide) */
const logoBadge = (x = 76, y = 80) =>
  `<div style="position:absolute;left:${x}px;top:${y}px;display:flex;align-items:center;gap:14px;padding:12px 20px 12px 12px;border-radius:999px;border:1px solid rgba(255,255,255,0.1);background:rgba(255,255,255,0.05);backdrop-filter:blur(16px);z-index:40">
    <div style="width:44px;height:44px;border-radius:14px;background:${rgba(C.primary,0.2)};border:1px solid ${rgba(C.primary,0.3)};display:grid;place-items:center;flex-shrink:0">
      <img src="${ICON_WHITE}" style="width:28px;height:28px" alt="">
    </div>
    <img src="${HORIZ_WHITE}" style="height:24px;width:auto" alt="mube">
  </div>`;

/** Page counter pill */
const pageCounter = (id, right = 76, top = 90) =>
  `<div style="position:absolute;right:${right}px;top:${top}px;padding:12px 20px;border-radius:999px;border:1px solid rgba(255,255,255,0.1);background:rgba(255,255,255,0.05);font-size:19px;font-weight:600;letter-spacing:.18em;color:rgba(255,255,255,0.45);z-index:40">${String(id).padStart(2,'0')} / ${String(TOTAL).padStart(2,'0')}</div>`;

/** Headline block */
const headline = ({ x, y, w, kicker, h, sub, kickerColor = C.primary, size = 118, center = false }) =>
  `<div style="position:absolute;left:${x}px;top:${y}px;width:${w}px;z-index:28;${center?'text-align:center;':''}">
    <div style="font-size:21px;font-weight:600;letter-spacing:.22em;text-transform:uppercase;color:${kickerColor};margin-bottom:18px;font-family:'Inter'">${kicker}</div>
    <div style="font-family:'Poppins';font-size:${size}px;line-height:.94;font-weight:800;letter-spacing:-.045em;color:#fff">${h}</div>
    ${sub ? `<div style="margin-top:26px;font-size:35px;line-height:1.4;font-weight:500;color:rgba(255,255,255,0.66);letter-spacing:-.01em;font-family:'Inter'">${sub}</div>` : ''}
  </div>`;

/** Phone mockup */
const phone = ({ x, y, w, src, rot = 0, z = 20, pos = 'center top', glowColor, glowAlpha = 0.25 }) => {
  const h = Math.round(w / DR);
  const pad = 16;
  const innerR = 58;
  const glow = glowColor
    ? `<div style="position:absolute;inset:-60px -50px;border-radius:90px;background:${rgba(glowColor, glowAlpha)};filter:blur(80px);z-index:0"></div>`
    : '';
  return `<div style="position:absolute;left:${x}px;top:${y}px;width:${w}px;height:${h}px;transform:rotate(${rot}deg);transform-origin:center top;z-index:${z}">
    ${glow}
    <div style="position:relative;width:100%;height:100%;border-radius:70px;border:1.5px solid rgba(255,255,255,0.2);background:#090909;box-shadow:0 60px 120px rgba(0,0,0,0.75),inset 0 1px 0 rgba(255,255,255,0.1);overflow:hidden;z-index:1">
      <div style="position:absolute;top:14px;left:50%;width:152px;height:26px;transform:translateX(-50%);background:#000;border-radius:14px;z-index:5"></div>
      <div style="position:absolute;inset:${pad}px;border-radius:${innerR}px;overflow:hidden;background:#111">
        <img src="${src}" alt="" style="display:block;width:100%;height:100%;object-fit:cover;object-position:${pos}">
      </div>
    </div>
  </div>`;
};

/** Glass card */
const card = ({ x, y, w, children, rot = 0, z = 26, accent = 'rgba(255,255,255,0.08)' }) =>
  `<div style="position:absolute;left:${x}px;top:${y}px;width:${w}px;transform:rotate(${rot}deg);border-radius:32px;border:1px solid ${accent};background:linear-gradient(160deg,rgba(255,255,255,0.07) 0%,rgba(255,255,255,0.02) 100%),rgba(14,12,24,0.85);box-shadow:0 28px 64px rgba(0,0,0,0.38);backdrop-filter:blur(22px);padding:28px 30px;z-index:${z}">
    ${children}
  </div>`;

/** Pill chip */
const pill = ({ x, y, txt, color, rot = 0, z = 26, alpha = 0.1 }) =>
  `<div style="position:absolute;left:${x}px;top:${y}px;display:inline-flex;align-items:center;gap:12px;padding:16px 26px;border-radius:999px;border:1px solid ${rgba(color,0.26)};background:${rgba(color,alpha)};backdrop-filter:blur(14px);font-size:22px;font-weight:700;letter-spacing:-.005em;transform:rotate(${rot}deg);z-index:${z}">
    <span style="width:10px;height:10px;border-radius:999px;background:${color};flex-shrink:0;display:block"></span>${txt}
  </div>`;

/** Tag tokens */
const tagRow = (items, color) =>
  `<div style="display:flex;flex-wrap:wrap;gap:10px;margin-top:18px">${items.map(t =>
    `<span style="display:inline-flex;align-items:center;gap:8px;padding:10px 18px;border-radius:999px;background:${rgba(color,0.12)};border:1px solid ${rgba(color,0.22)};font-size:20px;font-weight:600"><span style="width:7px;height:7px;border-radius:999px;background:${color};display:block;flex-shrink:0"></span>${t}</span>`
  ).join('')}</div>`;

/** Bottom stats strip (fills the bottom zone so it never looks empty) */
const statsStrip = (items) =>
  `<div style="position:absolute;left:76px;right:76px;bottom:72px;display:grid;grid-template-columns:repeat(${items.length},1fr);gap:16px;z-index:32">
    ${items.map(({ val, lbl, color }) =>
      `<div style="padding:26px 22px;border-radius:26px;border:1px solid ${rgba(color,0.2)};background:linear-gradient(145deg,${rgba(color,0.14)} 0%,rgba(0,0,0,0) 100%),rgba(12,10,22,0.82);backdrop-filter:blur(14px)">
        <div style="font-family:'Poppins';font-size:52px;font-weight:800;line-height:1;letter-spacing:-.04em;color:#fff">${val}</div>
        <div style="margin-top:10px;font-size:20px;font-weight:500;color:rgba(255,255,255,0.54);line-height:1.25">${lbl}</div>
      </div>`
    ).join('')}
  </div>`;

/** Floating stat badge */
const statBadge = ({ x, y, val, lbl, color, z = 30 }) =>
  `<div style="position:absolute;left:${x}px;top:${y}px;padding:26px 32px;border-radius:28px;border:1px solid ${rgba(color,0.22)};background:linear-gradient(145deg,${rgba(color,0.16)} 0%,rgba(0,0,0,0) 100%),rgba(10,8,20,0.88);backdrop-filter:blur(22px);box-shadow:0 24px 60px rgba(0,0,0,0.4);z-index:${z}">
    <div style="font-family:'Poppins';font-size:80px;font-weight:800;line-height:1;letter-spacing:-.05em;color:#fff">${val}</div>
    <div style="margin-top:10px;font-size:23px;font-weight:500;color:rgba(255,255,255,0.58)">${lbl}</div>
  </div>`;

/** Inline search bar */
const searchBar = (x, y, right, txt) =>
  `<div style="position:absolute;left:${x}px;top:${y}px;right:${right}px;display:flex;align-items:center;gap:18px;padding:22px 30px;border-radius:999px;border:1px solid rgba(255,255,255,0.12);background:rgba(255,255,255,0.06);backdrop-filter:blur(20px);z-index:26">
    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" style="flex-shrink:0"><circle cx="10" cy="10" r="7" stroke="rgba(255,255,255,0.45)" stroke-width="2"/><line x1="15.5" y1="15.5" x2="21" y2="21" stroke="rgba(255,255,255,0.45)" stroke-width="2" stroke-linecap="round"/></svg>
    <span style="font-size:27px;color:rgba(255,255,255,0.4);font-weight:500">${txt}</span>
  </div>`;

/** Feature list row */
const featRow = ({ dot, title, desc, color }) =>
  `<div style="display:flex;align-items:flex-start;gap:20px;padding:24px;border-radius:22px;background:rgba(255,255,255,0.04);border:1px solid rgba(255,255,255,0.07);margin-bottom:14px">
    <div style="width:52px;height:52px;border-radius:18px;background:${rgba(color,0.22)};border:1px solid ${rgba(color,0.28)};flex-shrink:0;display:flex;align-items:center;justify-content:center">
      <div style="width:20px;height:20px;border-radius:999px;background:${color}"></div>
    </div>
    <div style="flex:1">
      <div style="font-family:'Poppins';font-size:32px;font-weight:700;letter-spacing:-.025em;line-height:1.1">${title}</div>
      <div style="margin-top:6px;font-size:23px;color:rgba(255,255,255,0.58);line-height:1.3">${desc}</div>
    </div>
  </div>`;

// ─── Slide backgrounds (rich gradients, unique per slide) ─────────────────────
const BG = [
  // 1 – Warm pink-violet
  `radial-gradient(ellipse 72% 58% at 88% 18%,${rgba(C.primary,0.26)} 0%,transparent 65%),radial-gradient(ellipse 60% 52% at 12% 80%,${rgba(C.violet,0.2)} 0%,transparent 62%),linear-gradient(160deg,#0E0818 0%,#080613 55%,#0C0510 100%)`,
  // 2 – Cool violet-electric
  `radial-gradient(ellipse 68% 56% at 8% 14%,${rgba(C.violet,0.28)} 0%,transparent 60%),radial-gradient(ellipse 58% 46% at 92% 76%,${rgba(C.electric,0.2)} 0%,transparent 58%),linear-gradient(148deg,#090618 0%,#06080F 58%,#0A060F 100%)`,
  // 3 – Dramatic centered pink
  `radial-gradient(ellipse 82% 64% at 50% 52%,${rgba(C.primary,0.3)} 0%,transparent 64%),radial-gradient(ellipse 52% 46% at 18% 18%,${rgba(C.violet,0.22)} 0%,transparent 54%),linear-gradient(170deg,#0C0610 0%,#080613 52%,#0A0408 100%)`,
  // 4 – Deep indigo
  `radial-gradient(ellipse 62% 56% at 94% 18%,${rgba(C.violet,0.28)} 0%,transparent 60%),radial-gradient(ellipse 56% 50% at 8% 72%,${rgba(C.electric,0.2)} 0%,transparent 55%),linear-gradient(154deg,#07060F 0%,#060A18 52%,#08060F 100%)`,
  // 5 – Electric blue
  `radial-gradient(ellipse 66% 56% at 90% 28%,${rgba(C.electric,0.28)} 0%,transparent 60%),radial-gradient(ellipse 56% 46% at 10% 78%,${rgba(C.teal,0.2)} 0%,transparent 55%),linear-gradient(150deg,#04060F 0%,#060810 56%,#050808 100%)`,
  // 6 – Warm amber-pink
  `radial-gradient(ellipse 62% 56% at 88% 14%,${rgba(C.primary,0.26)} 0%,transparent 60%),radial-gradient(ellipse 56% 46% at 12% 82%,${rgba('#C84B11',0.18)} 0%,transparent 55%),linear-gradient(154deg,#100A08 0%,#0C0608 56%,#0E0608 100%)`,
  // 7 – Premium multi-color
  `radial-gradient(ellipse 62% 56% at 18% 18%,${rgba(C.primary,0.3)} 0%,transparent 55%),radial-gradient(ellipse 56% 50% at 82% 22%,${rgba(C.violet,0.26)} 0%,transparent 54%),radial-gradient(ellipse 50% 46% at 50% 84%,${rgba(C.electric,0.2)} 0%,transparent 55%),linear-gradient(160deg,#0A0614 0%,#08060F 52%,#080814 100%)`,
];

// ─── Scene builders ───────────────────────────────────────────────────────────

const scene1 = () => `
  ${logoBadge()}
  ${pageCounter(1)}
  ${eqBars(76, 2420, 1090, C.primary, 0.13)}
  ${orb(960,  480, 580, C.primary, 0.2,  90)}
  ${orb(180, 1460, 460, C.violet,  0.16, 80)}
  ${ring(960, 480, 820, C.primary, 0.08)}
  ${dots(840, 240, 320, 270, 0.09)}
  ${headline({
    x: 76, y: 248, w: 920,
    kicker: 'COMECE DO SEU JEITO',
    h: 'Seu perfil,<br>o palco certo',
    sub: 'M&uacute;sico, banda, est&uacute;dio<br>ou contratante.',
    size: 118,
  })}
  ${pill({ x: 76,  y: 756, txt: 'M&Uacute;SICO',       color: C.primary, rot: -2.5 })}
  ${pill({ x: 318, y: 720, txt: 'BANDA',                color: C.violet,  rot:  3 })}
  ${pill({ x: 550, y: 764, txt: 'EST&Uacute;DIO',       color: C.electric,rot: -2 })}
  ${pill({ x: 820, y: 726, txt: 'CONTRATANTE',          color: C.primary, rot:  3.5 })}
  ${phone({ x: 221, y: 912, w: 800, src: SHOTS[1], glowColor: C.primary, glowAlpha: 0.24 })}
  ${statBadge({ x: 860, y: 990, val: '4', lbl: 'tipos de perfil', color: C.primary })}
  ${statsStrip([
    { val: '500+', lbl: 'm&uacute;sicos ativos',         color: C.primary  },
    { val: '24h',  lbl: 'para o 1&ordm; match',          color: C.violet   },
    { val: '100%', lbl: 'gratuito pra come&ccedil;ar',   color: C.electric },
  ])}
`;

const scene2 = () => `
  ${logoBadge()}
  ${pageCounter(2)}
  ${eqBars(76, 2420, 1090, C.violet, 0.12)}
  ${orb(140, 320, 500, C.violet,  0.22, 86)}
  ${orb(1100,1650, 440, C.electric, 0.17, 80)}
  ${ring(140, 320, 720, C.violet,  0.08)}
  ${dots(76,  340, 240, 200, 0.1)}
  ${headline({
    x: 76, y: 248, w: 860,
    kicker: 'DESCUBRA A CENA',
    h: 'Talentos reais,<br>pra conectar',
    sub: 'Encontre profissionais, bandas<br>e equipes perto de voc&ecirc;.',
    size: 112,
  })}
  ${pill({ x: 76,  y: 776, txt: 'ROCK',     color: C.primary, rot: -3 })}
  ${pill({ x: 268, y: 814, txt: 'POP',      color: C.violet,  rot:  4.5 })}
  ${pill({ x: 418, y: 770, txt: 'T&Eacute;CNICO', color: C.electric, rot: -2 })}
  ${phone({ x: 510, y: 872, w: 690, src: SHOTS[2], rot:  4.5, glowColor: C.violet,   glowAlpha: 0.22, pos: 'center top' })}
  ${phone({ x: 66,  y: 1050, w: 430, src: SHOTS[4], rot: -5.5, glowColor: C.electric, glowAlpha: 0.18, pos: 'center 12%', z: 19 })}
  ${statBadge({ x: 76, y: 1760, val: '+12', lbl: 'adicionados aos favoritos', color: C.primary, z: 28 })}
  ${statsStrip([
    { val: '200+', lbl: 'g&ecirc;neros musicais',   color: C.primary  },
    { val: '5s',   lbl: 'para achar seu match',      color: C.violet   },
    { val: 'RJ+SP',lbl: 'cidades principais',        color: C.electric },
    { val: 'Live', lbl: 'perfis verificados',         color: C.teal     },
  ])}
`;

const scene3 = () => `
  ${logoBadge()}
  ${pageCounter(3)}
  ${orb(621, 1180, 880, C.primary, 0.22, 110)}
  ${orb(150,  1860, 400, C.violet,  0.16, 80)}
  ${orb(1100, 820,  380, C.violet,  0.16, 80)}
  ${ring(621, 1180, 1100, C.primary, 0.07)}
  ${ring(621, 1180, 700,  C.violet,  0.1)}
  ${dots(920, 270, 250, 200, 0.09)}
  ${headline({
    x: 76, y: 248, w: 1090,
    kicker: 'MATCHPOINT',
    h: 'Swipe com<br>inten&ccedil;&atilde;o.',
    sub: 'Curta, passe ou volte. O que importa<br>aparece com contexto suficiente.',
    size: 128,
  })}
  ${pill({ x: 76,  y: 872, txt: 'EXPLORAR', color: C.primary, rot: -2 })}
  ${pill({ x: 856, y: 862, txt: 'PRODUTOR', color: C.violet,  rot:  2.5 })}
  ${phone({ x: 221, y: 930, w: 800, src: SHOTS[3], glowColor: C.primary, glowAlpha: 0.3, z: 18 })}
  <!-- Swipe action buttons -->
  <div style="position:absolute;left:50%;bottom:188px;transform:translateX(-50%);display:flex;align-items:center;gap:26px;z-index:32">
    <div style="width:132px;height:132px;border-radius:999px;border:2px solid rgba(255,255,255,0.12);background:rgba(255,255,255,0.06);backdrop-filter:blur(14px);display:grid;place-items:center;font-size:50px;color:rgba(255,255,255,0.7)">&#10005;</div>
    <div style="width:122px;height:122px;border-radius:999px;border:2px solid ${rgba(C.violet,0.32)};background:${rgba(C.violet,0.12)};backdrop-filter:blur(14px);display:grid;place-items:center;font-size:46px;color:${C.violet}">&#8635;</div>
    <div style="width:144px;height:144px;border-radius:999px;border:2px solid ${rgba(C.primary,0.44)};background:${rgba(C.primary,0.18)};backdrop-filter:blur(14px);display:grid;place-items:center;font-size:58px;color:${C.primary}">&#9829;</div>
  </div>
`;

const scene4 = () => `
  ${logoBadge()}
  ${pageCounter(4)}
  ${eqBars(700, 2400, 542, C.violet, 0.11)}
  ${orb(1100, 340, 500, C.violet,  0.24, 88)}
  ${orb(100,  1640, 420, C.primary, 0.15, 80)}
  ${dots(820, 300, 320, 270, 0.09)}
  ${headline({
    x: 76, y: 248, w: 600,
    kicker: 'PERFIS COMPLETOS',
    h: 'O que voc&ecirc;<br>faz fica<br>evidente',
    sub: 'Instrumentos, fun&ccedil;&otilde;es<br>t&eacute;cnicas e cidade<br>numa leitura r&aacute;pida.',
    size: 96,
  })}
  ${phone({ x: 628, y: 790, w: 570, src: SHOTS[4], rot: 3.5, glowColor: C.violet, glowAlpha: 0.24, z: 18 })}
  ${card({
    x: 76, y: 912, w: 490,
    accent: rgba(C.primary, 0.22),
    children: `
      <div style="font-family:'Poppins';font-size:36px;font-weight:700;letter-spacing:-.035em;margin-bottom:8px">Instrumentos</div>
      <div style="font-size:23px;color:rgba(255,255,255,0.6)">Tudo que voc&ecirc; toca, sem ru&iacute;do.</div>
      ${tagRow(['Viol&atilde;o','Guitarra','Baixo'], C.primary)}
    `,
  })}
  ${card({
    x: 76, y: 1248, w: 490, rot: -1.5,
    accent: rgba(C.violet, 0.22),
    children: `
      <div style="font-family:'Poppins';font-size:36px;font-weight:700;letter-spacing:-.035em;margin-bottom:8px">Fun&ccedil;&otilde;es t&eacute;cnicas</div>
      <div style="font-size:23px;color:rgba(255,255,255,0.6)">Do palco &agrave; produ&ccedil;&atilde;o.</div>
      ${tagRow(['Diretor Musical','Produtor','Beatmaker'], C.violet)}
    `,
  })}
  ${card({
    x: 76, y: 1670, w: 410, rot: 1.5,
    accent: rgba(C.electric, 0.2),
    children: `
      <div style="font-family:'Poppins';font-size:36px;font-weight:700;letter-spacing:-.035em;margin-bottom:8px">Rio de Janeiro</div>
      <div style="font-size:23px;color:rgba(255,255,255,0.6)">Cidade, favoritos e contexto.</div>
    `,
  })}
  ${statsStrip([
    { val: '4',   lbl: 'categorias de perfil',   color: C.primary  },
    { val: '20+', lbl: 'fun&ccedil;&otilde;es t&eacute;cnicas', color: C.violet   },
    { val: '10+', lbl: 'instrumentos poss&iacute;veis', color: C.electric },
  ])}
`;

const scene5 = () => `
  ${logoBadge()}
  ${pageCounter(5)}
  ${eqBars(76, 2420, 1090, C.electric, 0.12)}
  ${orb(1060, 280, 520, C.electric, 0.24, 90)}
  ${orb(120,  1820, 400, C.teal,    0.17, 80)}
  ${dots(76,  280, 200, 200, 0.1)}
  ${headline({
    x: 76, y: 248, w: 880,
    kicker: 'BUSCA INTELIGENTE',
    h: 'Filtre a cena<br>do seu jeito',
    sub: 'Por categoria, instrumento,<br>g&ecirc;nero e especialidade.',
    size: 112,
  })}
  ${searchBar(76, 800, 76, 'Buscar m&uacute;sicos, bandas e est&uacute;dios...')}
  ${phone({ x: 76, y: 960, w: 600, src: SHOTS[5], rot: -3, glowColor: C.electric, glowAlpha: 0.22, z: 18 })}
  <!-- Category tiles right -->
  <div style="position:absolute;right:76px;top:970px;width:488px;display:flex;flex-direction:column;gap:16px;z-index:26">
    ${[
      { label: 'Cantores',    color: C.primary  },
      { label: 'DJs',         color: C.violet   },
      { label: 'Guitarristas',color: C.electric },
      { label: 'Bateristas',  color: C.teal     },
      { label: 'Produtores',  color: C.green    },
      { label: 'Sopros',      color: C.amber    },
    ].map(({ label, color }) =>
      `<div style="padding:24px 28px;border-radius:24px;border:1px solid ${rgba(color,0.2)};background:linear-gradient(145deg,${rgba(color,0.12)} 0%,rgba(0,0,0,0) 100%),rgba(14,12,22,0.78);backdrop-filter:blur(14px);display:flex;align-items:center;gap:18px">
        <div style="width:42px;height:42px;border-radius:14px;background:${rgba(color,0.22)};border:1px solid ${rgba(color,0.28)};flex-shrink:0;display:grid;place-items:center">
          <div style="width:16px;height:16px;border-radius:999px;background:${color}"></div>
        </div>
        <span style="font-family:'Poppins';font-size:30px;font-weight:700;letter-spacing:-.02em">${label}</span>
      </div>`
    ).join('')}
  </div>
`;

const scene6 = () => `
  ${logoBadge()}
  ${pageCounter(6)}
  ${orb(200,  1320, 500, C.primary,    0.17, 86)}
  ${orb(1100, 1740, 440, '#C84B11',    0.14, 80)}
  ${dots(900, 280, 250, 220, 0.1)}
  ${headline({
    x: 76, y: 248, w: 900,
    kicker: 'GALERIA',
    h: 'Mostre palco,<br>bastidor e<br>identidade',
    sub: 'Fotos e v&iacute;deos deixam<br>seu perfil mais convincente.',
    size: 108,
  })}
  ${pill({ x: 76,  y: 862, txt: 'FOTOS',   color: C.primary, rot: -2 })}
  ${pill({ x: 292, y: 852, txt: 'V&Iacute;DEOS',  color: C.violet,  rot:  3 })}
  ${phone({ x: 76, y: 980, w: 558, src: SHOTS[6], rot: -2.5, glowColor: C.primary, glowAlpha: 0.2, z: 18 })}
  <!-- Media grid right side -->
  <div style="position:absolute;right:76px;top:978px;width:490px;display:flex;flex-direction:column;gap:16px;z-index:24">
    <div style="height:328px;border-radius:28px;border:1px solid rgba(255,255,255,0.1);overflow:hidden;box-shadow:0 24px 60px rgba(0,0,0,0.4)"><img src="${SHOTS[6]}" alt="" style="width:100%;height:100%;object-fit:cover;object-position:center 20%"></div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px">
      <div style="height:228px;border-radius:22px;border:1px solid rgba(255,255,255,0.1);overflow:hidden;box-shadow:0 20px 50px rgba(0,0,0,0.38)"><img src="${SHOTS[6]}" alt="" style="width:100%;height:100%;object-fit:cover;object-position:center 52%"></div>
      <div style="height:228px;border-radius:22px;border:1px solid rgba(255,255,255,0.1);overflow:hidden;box-shadow:0 20px 50px rgba(0,0,0,0.38)"><img src="${SHOTS[6]}" alt="" style="width:100%;height:100%;object-fit:cover;object-position:center 76%"></div>
    </div>
    <div style="height:268px;border-radius:28px;border:1px solid rgba(255,255,255,0.1);overflow:hidden;box-shadow:0 24px 60px rgba(0,0,0,0.4)"><img src="${SHOTS[6]}" alt="" style="width:100%;height:100%;object-fit:cover;object-position:center 42%"></div>
  </div>
  ${statsStrip([
    { val: 'HD', lbl: 'fotos de alta qualidade', color: C.primary },
    { val: '60s', lbl: 'v&iacute;deos de performance',  color: C.violet  },
    { val: '3D',  lbl: 'impacto visual real',      color: C.electric},
  ])}
`;

const scene7 = () => `
  ${orb(300,  480,  700, C.primary, 0.22, 100)}
  ${orb(960,  340,  620, C.violet,  0.2,  96)}
  ${orb(621, 1900,  580, C.electric,0.16, 100)}
  ${ring(300,  480,  960, C.primary, 0.07)}
  ${ring(960,  340,  880, C.violet,  0.07)}
  ${dots(900, 100, 280, 300, 0.08)}
  ${eqBars(76, 1560, 1090, C.primary, 0.08)}
  <!-- Logo hero -->
  <div style="position:absolute;left:50%;top:200px;transform:translateX(-50%);display:flex;flex-direction:column;align-items:center;z-index:32">
    <div style="width:230px;height:230px;border-radius:60px;border:1px solid rgba(255,255,255,0.16);background:linear-gradient(145deg,${rgba(C.primary,0.22)} 0%,${rgba(C.violet,0.18)} 100%),rgba(14,12,24,0.88);box-shadow:0 40px 90px rgba(0,0,0,0.56),inset 0 1px 0 rgba(255,255,255,0.08);display:grid;place-items:center">
      <img src="${SQUARE_PRIMARY}" alt="" style="width:168px;height:168px">
    </div>
    <div style="margin-top:36px"><img src="${HORIZ_WHITE}" alt="mube" style="height:58px;width:auto"></div>
    <div style="margin-top:18px;font-size:34px;color:rgba(255,255,255,0.66);text-align:center;max-width:620px;line-height:1.36;font-weight:500;font-family:'Inter'">A plataforma musical que conecta<br>m&uacute;sicos, bandas e contratantes.</div>
  </div>
  <!-- Feature list -->
  <div style="position:absolute;left:76px;top:800px;right:76px;z-index:28">
    ${[
      { dot: C.primary,  title: 'Matchpoint',              desc: 'Swipe com inten&ccedil;&atilde;o, match com futuro',  color: C.primary  },
      { dot: C.electric, title: 'Busca inteligente',       desc: 'Filtre por instrumento, g&ecirc;nero e cidade',       color: C.electric },
      { dot: C.violet,   title: 'Chat direto',             desc: 'Conecte e converse sem intermedi&aacute;rios',        color: C.violet   },
      { dot: C.teal,     title: '4 tipos de perfil',       desc: 'M&uacute;sico, banda, est&uacute;dio ou contratante', color: C.teal     },
      { dot: C.green,    title: 'Galeria de m&iacute;dia', desc: 'Mostre seu talento com fotos e v&iacute;deos',        color: C.green    },
      { dot: C.amber,    title: 'Conex&otilde;es reais',   desc: 'Parcerias, shows e projetos que acontecem',           color: C.amber    },
    ].map(featRow).join('')}
  </div>
  <!-- Mid accent: horizontal divider + brand statement -->
  <div style="position:absolute;left:76px;right:76px;top:1642px;z-index:28">
    <div style="height:1px;background:linear-gradient(90deg,transparent 0%,${rgba(C.primary,0.4)} 30%,${rgba(C.violet,0.4)} 70%,transparent 100%);margin-bottom:44px"></div>
    <div style="font-family:'Poppins';font-size:72px;font-weight:800;letter-spacing:-.04em;line-height:1;text-align:center">Conecte.<br><span style="color:${C.primary}">Toque.</span><br>Cresça.</div>
  </div>
  <!-- Stats row -->
  <div style="position:absolute;left:76px;right:76px;top:2100px;display:grid;grid-template-columns:repeat(3,1fr);gap:18px;z-index:30">
    ${[
      { val: '500+', lbl: 'm&uacute;sicos cadastrados', color: C.primary  },
      { val: 'RJ&middot;SP', lbl: 'cidades principais', color: C.violet   },
      { val: 'Free', lbl: 'custo pra come&ccedil;ar',   color: C.electric },
    ].map(({ val, lbl, color }) =>
      `<div style="padding:24px 22px;border-radius:24px;border:1px solid ${rgba(color,0.22)};background:linear-gradient(145deg,${rgba(color,0.14)} 0%,rgba(0,0,0,0) 100%),rgba(12,10,22,0.82)">
        <div style="font-family:'Poppins';font-size:52px;font-weight:800;letter-spacing:-.04em;line-height:1">${val}</div>
        <div style="margin-top:10px;font-size:20px;color:rgba(255,255,255,0.54);font-weight:500">${lbl}</div>
      </div>`
    ).join('')}
  </div>
  <!-- Bottom tagline -->
  <div style="position:absolute;left:76px;right:76px;bottom:76px;z-index:30;text-align:center">
    <div style="font-family:'Poppins';font-size:52px;font-weight:800;letter-spacing:-.035em;line-height:1.08">Perfis, busca e conversa<br>no mesmo fluxo.</div>
    <div style="margin-top:16px;font-size:29px;color:rgba(255,255,255,0.54);font-weight:500">Dispon&iacute;vel para iOS e Android</div>
  </div>
`;

// ─── HTML builder ─────────────────────────────────────────────────────────────
const buildHtml = (bg, body) => `<!doctype html>
<html lang="pt-BR"><head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=${W},initial-scale=1">
  <style>${CSS}</style>
</head><body>
  <div class="slide" style="background:${bg}">
    <div class="noise"></div>
    ${body}
  </div>
</body></html>`;

// ─── Slide registry ───────────────────────────────────────────────────────────
const SLIDES = [
  { id: 1, draw: scene1 },
  { id: 2, draw: scene2 },
  { id: 3, draw: scene3 },
  { id: 4, draw: scene4 },
  { id: 5, draw: scene5 },
  { id: 6, draw: scene6 },
  { id: 7, draw: scene7 },
];

// ─── Validation ───────────────────────────────────────────────────────────────
async function validate(file) {
  const meta = await sharp(file).metadata();
  if (meta.width !== W || meta.height !== H) {
    throw new Error(`Bad size ${meta.width}x${meta.height} in ${path.basename(file)}`);
  }
}

// ─── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  await fs.promises.mkdir(OUT, { recursive: true });
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });

  try {
    for (const slide of SLIDES) {
      const page = await ctx.newPage();
      const outFile = path.join(OUT, `store_${slide.id}.png`);
      console.log(`  Gerando store_${slide.id}.png...`);
      await page.setContent(buildHtml(BG[slide.id - 1], slide.draw()), { waitUntil: 'load' });
      await page.evaluate(() => document.fonts.ready);
      await page.waitForTimeout(160);
      await page.screenshot({ path: outFile, type: 'png' });
      await validate(outFile);
      await page.close();
      console.log(`  store_${slide.id}.png OK`);
    }
  } finally {
    await browser.close();
  }

  console.log(`\nPronto! ${TOTAL} screenshots em:\n  ${OUT}`);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
