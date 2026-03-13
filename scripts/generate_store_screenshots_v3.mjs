/**
 * generate_store_screenshots_v3.mjs
 *
 * Mube App Store screenshots — V3 redesign.
 * Changes from v2:
 *  - Removed logo badge & page counter (top-header was repetitive)
 *  - Removed bottom stats strip (bottom cards were repetitive)
 *  - Darker backgrounds — near-black base, rich deep shadows
 *  - More primary (#E8466C) — stronger orbs, glow, accents, bottom signature
 *  - Unique bottom statement per slide instead of uniform stats cards
 *  - All content raised ~100px (freed top-header space)
 *
 * Output: assets/images/store_screenshots_v3/
 * Run:    node scripts/generate_store_screenshots_v3.mjs
 */

import fs   from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { chromium } from 'playwright';
import sharp from 'sharp';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT  = path.resolve(__dirname, '..');
const OUT   = path.join(ROOT, 'assets', 'images', 'store_screenshots_v3');
const W     = 1242;
const H     = 2688;
const TOTAL = 7;
const DR    = 1206 / 2622; // phone aspect ratio (width / height)

// ─── Asset helpers ────────────────────────────────────────────────────────────
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
const ICON_WHITE     = dataUri('assets/images/logos_svg/brand/brand-icon-white-cutout.svg', 'image/svg+xml');
const HORIZ_WHITE    = dataUri('assets/images/logos_svg/brand/brand-horizontal-white-cutout.svg', 'image/svg+xml');
const SQUARE_PRIMARY = dataUri('assets/images/logos_svg/brand/brand-square-primary.svg', 'image/svg+xml');
const SHOTS = Object.fromEntries(
  Array.from({ length: TOTAL }, (_, i) => [i+1, dataUri(`assets/images/screenshots/ss${i+1}.png`,'image/png')])
);

// ─── Design tokens ────────────────────────────────────────────────────────────
const C = {
  primary: '#E8466C',   // brand pink-red
  violet:  '#7C3AED',
  electric:'#3B82F6',
  teal:    '#0EA5E9',
  green:   '#10B981',
  amber:   '#F59E0B',
};

// ─── Noise texture (subtle film grain) ───────────────────────────────────────
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
.noise{position:absolute;inset:0;background-image:url("${NOISE}");background-size:512px;opacity:.045;mix-blend-mode:overlay;z-index:8;pointer-events:none}
`;

// ─── Slide backgrounds — very dark, primary-forward ──────────────────────────
// Base: near-black (#030108 range). Orbs provide color — primary dominates.
const BG = [
  // 1 – Primary dominant, top-right bloom
  `radial-gradient(ellipse 72% 54% at 92% 20%,${rgba(C.primary,0.42)} 0%,transparent 60%),`+
  `radial-gradient(ellipse 46% 38% at 12% 82%,${rgba(C.primary,0.16)} 0%,transparent 55%),`+
  `linear-gradient(160deg,#050108 0%,#030106 55%,#050108 100%)`,

  // 2 – Violet left, primary right
  `radial-gradient(ellipse 66% 52% at 6% 18%,${rgba(C.violet,0.32)} 0%,transparent 58%),`+
  `radial-gradient(ellipse 52% 44% at 92% 74%,${rgba(C.primary,0.3)} 0%,transparent 55%),`+
  `linear-gradient(148deg,#04010A 0%,#03020C 58%,#05020A 100%)`,

  // 3 – Centered primary eruption
  `radial-gradient(ellipse 82% 62% at 50% 52%,${rgba(C.primary,0.4)} 0%,transparent 60%),`+
  `radial-gradient(ellipse 48% 42% at 16% 22%,${rgba(C.violet,0.2)} 0%,transparent 50%),`+
  `linear-gradient(170deg,#050108 0%,#030106 52%,#050106 100%)`,

  // 4 – Deep violet right, primary accent left
  `radial-gradient(ellipse 62% 52% at 98% 20%,${rgba(C.violet,0.36)} 0%,transparent 58%),`+
  `radial-gradient(ellipse 50% 44% at 8% 70%,${rgba(C.primary,0.24)} 0%,transparent 52%),`+
  `linear-gradient(154deg,#03010A 0%,#03030E 52%,#03010A 100%)`,

  // 5 – Electric blue dominant, very dark
  `radial-gradient(ellipse 66% 52% at 94% 28%,${rgba(C.electric,0.34)} 0%,transparent 58%),`+
  `radial-gradient(ellipse 50% 44% at 10% 78%,${rgba(C.teal,0.2)} 0%,transparent 52%),`+
  `radial-gradient(ellipse 40% 36% at 50% 50%,${rgba(C.primary,0.1)} 0%,transparent 50%),`+
  `linear-gradient(150deg,#020308 0%,#020306 56%,#020408 100%)`,

  // 6 – Warm dark crimson + primary bloom
  `radial-gradient(ellipse 64% 54% at 92% 18%,${rgba(C.primary,0.38)} 0%,transparent 58%),`+
  `radial-gradient(ellipse 50% 44% at 14% 82%,${rgba('#6B0D0D',0.28)} 0%,transparent 52%),`+
  `linear-gradient(154deg,#0A0202 0%,#060102 56%,#0A0202 100%)`,

  // 7 – Premium dark: primary left, violet right, electric bottom
  `radial-gradient(ellipse 62% 52% at 16% 18%,${rgba(C.primary,0.42)} 0%,transparent 52%),`+
  `radial-gradient(ellipse 54% 48% at 86% 22%,${rgba(C.violet,0.3)} 0%,transparent 52%),`+
  `radial-gradient(ellipse 46% 44% at 50% 86%,${rgba(C.electric,0.16)} 0%,transparent 50%),`+
  `linear-gradient(160deg,#050108 0%,#030106 52%,#03030A 100%)`,
];

// ─── Primitives ───────────────────────────────────────────────────────────────

/** Glowing orb */
const orb = (cx, cy, size, color, alpha = 0.22, blur = 90) =>
  `<div style="position:absolute;left:${cx-size/2}px;top:${cy-size/2}px;width:${size}px;height:${size}px;border-radius:999px;background:${rgba(color,alpha)};filter:blur(${blur}px);z-index:1;pointer-events:none"></div>`;

/** Dot grid */
const dots = (x, y, w, h, alpha = 0.09) =>
  `<div style="position:absolute;left:${x}px;top:${y}px;width:${w}px;height:${h}px;background-image:radial-gradient(circle,rgba(255,255,255,.9) 1.5px,transparent 1.5px);background-size:24px 24px;opacity:${alpha};z-index:3;pointer-events:none"></div>`;

/** EQ bars (SVG decorative) */
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

/** Ring circle */
const ring = (cx, cy, size, color, alpha = 0.1) =>
  `<div style="position:absolute;left:${cx-size/2}px;top:${cy-size/2}px;width:${size}px;height:${size}px;border-radius:999px;border:1px solid ${rgba(color,alpha)};z-index:4;pointer-events:none"></div>`;

/** Headline block */
const headline = ({ x, y, w, kicker, h, sub, kickerColor = C.primary, size = 118, center = false }) =>
  `<div style="position:absolute;left:${x}px;top:${y}px;width:${w}px;z-index:28;${center?'text-align:center;':''}">
    <div style="font-size:21px;font-weight:600;letter-spacing:.22em;text-transform:uppercase;color:${kickerColor};margin-bottom:18px;font-family:'Inter'">${kicker}</div>
    <div style="font-family:'Poppins';font-size:${size}px;line-height:.93;font-weight:800;letter-spacing:-.048em;color:#fff">${h}</div>
    ${sub ? `<div style="margin-top:28px;font-size:35px;line-height:1.38;font-weight:500;color:rgba(255,255,255,0.62);letter-spacing:-.01em;font-family:'Inter'">${sub}</div>` : ''}
  </div>`;

/** Phone mockup */
const phone = ({ x, y, w, src, rot = 0, z = 20, pos = 'center top', glowColor, glowAlpha = 0.28 }) => {
  const h = Math.round(w / DR);
  const pad = 16;
  const glow = glowColor
    ? `<div style="position:absolute;inset:-80px -60px;border-radius:90px;background:${rgba(glowColor, glowAlpha)};filter:blur(90px);z-index:0"></div>`
    : '';
  return `<div style="position:absolute;left:${x}px;top:${y}px;width:${w}px;height:${h}px;transform:rotate(${rot}deg);transform-origin:center top;z-index:${z}">
    ${glow}
    <div style="position:relative;width:100%;height:100%;border-radius:70px;border:1.5px solid rgba(255,255,255,0.18);background:#060606;box-shadow:0 70px 140px rgba(0,0,0,0.85),inset 0 1px 0 rgba(255,255,255,0.08);overflow:hidden;z-index:1">
      <div style="position:absolute;top:14px;left:50%;width:152px;height:26px;transform:translateX(-50%);background:#000;border-radius:14px;z-index:5"></div>
      <div style="position:absolute;inset:${pad}px;border-radius:58px;overflow:hidden;background:#0A0A0A">
        <img src="${src}" alt="" style="display:block;width:100%;height:100%;object-fit:cover;object-position:${pos}">
      </div>
    </div>
  </div>`;
};

/** Glass card */
const card = ({ x, y, w, children, rot = 0, z = 26, accent = 'rgba(255,255,255,0.08)' }) =>
  `<div style="position:absolute;left:${x}px;top:${y}px;width:${w}px;transform:rotate(${rot}deg);border-radius:32px;border:1px solid ${accent};background:linear-gradient(160deg,rgba(255,255,255,0.065) 0%,rgba(255,255,255,0.015) 100%),rgba(10,8,18,0.9);box-shadow:0 32px 72px rgba(0,0,0,0.5);backdrop-filter:blur(22px);padding:28px 30px;z-index:${z}">
    ${children}
  </div>`;

/** Pill chip */
const pill = ({ x, y, txt, color, rot = 0, z = 26, alpha = 0.12 }) =>
  `<div style="position:absolute;left:${x}px;top:${y}px;display:inline-flex;align-items:center;gap:12px;padding:16px 28px;border-radius:999px;border:1px solid ${rgba(color,0.28)};background:${rgba(color,alpha)};backdrop-filter:blur(14px);font-size:22px;font-weight:700;letter-spacing:-.005em;transform:rotate(${rot}deg);z-index:${z}">
    <span style="width:10px;height:10px;border-radius:999px;background:${color};flex-shrink:0;display:block"></span>${txt}
  </div>`;

/** Tag row */
const tagRow = (items, color) =>
  `<div style="display:flex;flex-wrap:wrap;gap:10px;margin-top:18px">${items.map(t =>
    `<span style="display:inline-flex;align-items:center;gap:8px;padding:10px 18px;border-radius:999px;background:${rgba(color,0.14)};border:1px solid ${rgba(color,0.24)};font-size:20px;font-weight:600"><span style="width:7px;height:7px;border-radius:999px;background:${color};display:block;flex-shrink:0"></span>${t}</span>`
  ).join('')}</div>`;

/** Floating stat badge */
const statBadge = ({ x, y, val, lbl, color, z = 30 }) =>
  `<div style="position:absolute;left:${x}px;top:${y}px;padding:26px 32px;border-radius:28px;border:1px solid ${rgba(color,0.26)};background:linear-gradient(145deg,${rgba(color,0.2)} 0%,rgba(0,0,0,0) 100%),rgba(8,6,16,0.92);backdrop-filter:blur(22px);box-shadow:0 28px 70px rgba(0,0,0,0.5),0 0 0 1px ${rgba(color,0.1)};z-index:${z}">
    <div style="font-family:'Poppins';font-size:80px;font-weight:800;line-height:1;letter-spacing:-.05em;color:#fff">${val}</div>
    <div style="margin-top:10px;font-size:23px;font-weight:500;color:rgba(255,255,255,0.55)">${lbl}</div>
  </div>`;

/** Inline search bar */
const searchBar = (x, y, right, txt) =>
  `<div style="position:absolute;left:${x}px;top:${y}px;right:${right}px;display:flex;align-items:center;gap:18px;padding:22px 30px;border-radius:999px;border:1px solid rgba(255,255,255,0.1);background:rgba(255,255,255,0.05);backdrop-filter:blur(20px);z-index:26">
    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" style="flex-shrink:0"><circle cx="10" cy="10" r="7" stroke="rgba(255,255,255,0.4)" stroke-width="2"/><line x1="15.5" y1="15.5" x2="21" y2="21" stroke="rgba(255,255,255,0.4)" stroke-width="2" stroke-linecap="round"/></svg>
    <span style="font-size:27px;color:rgba(255,255,255,0.36);font-weight:500">${txt}</span>
  </div>`;

/** Feature list row */
const featRow = ({ title, desc, color }) =>
  `<div style="display:flex;align-items:flex-start;gap:20px;padding:24px;border-radius:22px;background:rgba(255,255,255,0.035);border:1px solid rgba(255,255,255,0.065);margin-bottom:12px">
    <div style="width:52px;height:52px;border-radius:18px;background:${rgba(color,0.24)};border:1px solid ${rgba(color,0.32)};flex-shrink:0;display:flex;align-items:center;justify-content:center">
      <div style="width:20px;height:20px;border-radius:999px;background:${color}"></div>
    </div>
    <div style="flex:1">
      <div style="font-family:'Poppins';font-size:32px;font-weight:700;letter-spacing:-.025em;line-height:1.1">${title}</div>
      <div style="margin-top:6px;font-size:23px;color:rgba(255,255,255,0.54);line-height:1.3">${desc}</div>
    </div>
  </div>`;

/**
 * Bottom signature — replaces statsStrip.
 * A thin primary-colored divider + bold statement + subtle subtext.
 * Unique per slide, no repeated card grid.
 */
const bottomSignature = ({ line1, line1Accent = '', line2 = '', accentColor = C.primary }) =>
  `<div style="position:absolute;left:76px;right:76px;bottom:80px;z-index:36">
    <div style="height:1px;background:linear-gradient(90deg,transparent 0%,${rgba(accentColor,0.6)} 30%,${rgba(accentColor,0.6)} 70%,transparent 100%);margin-bottom:34px"></div>
    <div style="font-family:'Poppins';font-size:46px;font-weight:800;letter-spacing:-.035em;text-align:center;line-height:1.08;color:#fff">
      ${line1Accent ? `<span style="color:${accentColor}">${line1Accent}</span> ` : ''}${line1}
    </div>
    ${line2 ? `<div style="margin-top:14px;font-size:26px;text-align:center;color:rgba(255,255,255,0.36);font-weight:500;letter-spacing:-.01em">${line2}</div>` : ''}
  </div>`;

// ─── Scene builders ───────────────────────────────────────────────────────────

const scene1 = () => `
  ${eqBars(76, 2420, 1090, C.primary, 0.16)}
  ${orb(980,  430, 640, C.primary, 0.32, 100)}
  ${orb(160, 1500, 500, C.primary, 0.14, 90)}
  ${orb(600, 1200, 380, C.violet,  0.12, 80)}
  ${ring(980,  430,  900, C.primary, 0.1)}
  ${ring(980,  430,  560, C.primary, 0.07)}
  ${dots(860, 200, 320, 270, 0.09)}
  ${headline({
    x: 76, y: 148, w: 940,
    kicker: 'COMECE DO SEU JEITO',
    h: 'Seu perfil,<br>o palco certo',
    sub: 'M&uacute;sico, banda, est&uacute;dio<br>ou contratante.',
    size: 118,
  })}
  ${pill({ x: 76,  y: 656, txt: 'M&Uacute;SICO',       color: C.primary,  rot: -2.5 })}
  ${pill({ x: 318, y: 620, txt: 'BANDA',                color: C.violet,   rot:  3 })}
  ${pill({ x: 550, y: 660, txt: 'EST&Uacute;DIO',       color: '#C026D3',  rot: -2 })}
  ${pill({ x: 826, y: 628, txt: 'CONTRATANTE',          color: C.primary,  rot:  3.5 })}
  ${phone({ x: 221, y: 810, w: 810, src: SHOTS[1], glowColor: C.primary, glowAlpha: 0.32 })}
  ${statBadge({ x: 860, y: 888, val: '4', lbl: 'tipos de perfil', color: C.primary })}
  ${bottomSignature({
    line1: 'músicos de verdade.',
    line1Accent: 'Para',
    line2: 'iOS &amp; Android — gratuito pra começar',
    accentColor: C.primary,
  })}
`;

const scene2 = () => `
  ${orb(120,  280, 540, C.violet,   0.28, 90)}
  ${orb(1100, 1620, 480, C.primary, 0.26, 90)}
  ${orb(600,  900, 360, C.primary,  0.14, 80)}
  ${ring(120,  280,  760, C.violet,  0.08)}
  ${ring(1100, 1620, 640, C.primary, 0.08)}
  ${dots(76,   280, 240, 200, 0.1)}
  ${headline({
    x: 76, y: 148, w: 880,
    kicker: 'DESCUBRA A CENA',
    h: 'Talentos reais,<br>pra conectar',
    sub: 'Encontre profissionais, bandas<br>e equipes perto de voc&ecirc;.',
    size: 112,
  })}
  ${pill({ x: 76,  y: 676, txt: 'ROCK',           color: C.primary,  rot: -3 })}
  ${pill({ x: 274, y: 716, txt: 'POP',             color: C.violet,   rot:  4.5 })}
  ${pill({ x: 424, y: 672, txt: 'T&Eacute;CNICO', color: C.electric, rot: -2 })}
  ${phone({ x: 510, y: 780, w: 700, src: SHOTS[2], rot:  4.5, glowColor: C.primary,  glowAlpha: 0.28, pos: 'center top' })}
  ${phone({ x: 58,  y: 950, w: 440, src: SHOTS[4], rot: -5.5, glowColor: C.violet,   glowAlpha: 0.2,  pos: 'center 12%', z: 19 })}
  ${statBadge({ x: 76, y: 2030, val: '+12', lbl: 'adicionados aos favoritos', color: C.primary, z: 28 })}
  ${bottomSignature({
    line1: 'sua cena, do seu jeito.',
    line1Accent: 'A',
    line2: 'Match em segundos — em qualquer cidade',
    accentColor: C.primary,
  })}
`;

const scene3 = () => `
  ${orb(621, 1160, 920, C.primary, 0.28, 120)}
  ${orb(140,  1900, 420, C.violet,  0.18, 85)}
  ${orb(1100, 800,  400, C.violet,  0.18, 85)}
  ${ring(621, 1160, 1140, C.primary, 0.08)}
  ${ring(621, 1160,  720, C.primary, 0.12)}
  ${dots(920, 220, 250, 200, 0.09)}
  ${eqBars(76, 2340, 1090, C.primary, 0.1)}
  ${headline({
    x: 76, y: 148, w: 1090,
    kicker: 'MATCHPOINT',
    h: 'Swipe com<br>inten&ccedil;&atilde;o.',
    sub: 'Curta, passe ou volte. O que importa<br>aparece com contexto suficiente.',
    size: 128,
  })}
  ${pill({ x: 76,  y: 768, txt: 'EXPLORAR', color: C.primary, rot: -2 })}
  ${pill({ x: 856, y: 758, txt: 'PRODUTOR', color: C.violet,  rot:  2.5 })}
  ${phone({ x: 221, y: 840, w: 810, src: SHOTS[3], glowColor: C.primary, glowAlpha: 0.36, z: 18 })}
  <!-- Swipe action buttons -->
  <div style="position:absolute;left:50%;bottom:360px;transform:translateX(-50%);display:flex;align-items:center;gap:28px;z-index:36">
    <div style="width:138px;height:138px;border-radius:999px;border:2px solid rgba(255,255,255,0.1);background:rgba(255,255,255,0.05);backdrop-filter:blur(14px);display:grid;place-items:center;font-size:52px;color:rgba(255,255,255,0.6)">&#10005;</div>
    <div style="width:126px;height:126px;border-radius:999px;border:2px solid ${rgba(C.violet,0.34)};background:${rgba(C.violet,0.14)};backdrop-filter:blur(14px);display:grid;place-items:center;font-size:48px;color:${C.violet}">&#8635;</div>
    <div style="width:150px;height:150px;border-radius:999px;border:2px solid ${rgba(C.primary,0.5)};background:${rgba(C.primary,0.22)};backdrop-filter:blur(14px);display:grid;place-items:center;font-size:62px;color:${C.primary};box-shadow:0 0 40px ${rgba(C.primary,0.3)}">&#9829;</div>
  </div>
  ${bottomSignature({
    line1: 'quem combina, conecta.',
    line1Accent: 'Aqui,',
    line2: 'Curta · Passe · Volte — sem algoritmo escondido',
    accentColor: C.primary,
  })}
`;

const scene4 = () => `
  ${eqBars(700, 2380, 542, C.primary, 0.13)}
  ${orb(1100, 320,  540, C.violet,   0.3, 92)}
  ${orb(100,  1680, 460, C.primary,  0.22, 85)}
  ${orb(500,  1400, 340, C.primary,  0.1, 75)}
  ${dots(820, 260, 320, 270, 0.09)}
  ${headline({
    x: 76, y: 148, w: 610,
    kicker: 'PERFIS COMPLETOS',
    h: 'O que voc&ecirc;<br>faz fica<br>evidente',
    sub: 'Instrumentos, fun&ccedil;&otilde;es<br>t&eacute;cnicas e cidade<br>numa leitura r&aacute;pida.',
    size: 96,
  })}
  ${phone({ x: 628, y: 690, w: 580, src: SHOTS[4], rot: 3.5, glowColor: C.primary, glowAlpha: 0.28, z: 18 })}
  ${card({
    x: 76, y: 828, w: 498,
    accent: rgba(C.primary, 0.26),
    children: `
      <div style="font-family:'Poppins';font-size:36px;font-weight:700;letter-spacing:-.035em;margin-bottom:8px">Instrumentos</div>
      <div style="font-size:23px;color:rgba(255,255,255,0.58)">Tudo que voc&ecirc; toca, sem ru&iacute;do.</div>
      ${tagRow(['Viol&atilde;o','Guitarra','Baixo'], C.primary)}
    `,
  })}
  ${card({
    x: 76, y: 1168, w: 498, rot: -1.5,
    accent: rgba(C.violet, 0.26),
    children: `
      <div style="font-family:'Poppins';font-size:36px;font-weight:700;letter-spacing:-.035em;margin-bottom:8px">Fun&ccedil;&otilde;es t&eacute;cnicas</div>
      <div style="font-size:23px;color:rgba(255,255,255,0.58)">Do palco &agrave; produ&ccedil;&atilde;o.</div>
      ${tagRow(['Diretor Musical','Produtor','Beatmaker'], C.violet)}
    `,
  })}
  ${card({
    x: 76, y: 1598, w: 420, rot: 1.5,
    accent: rgba(C.primary, 0.2),
    children: `
      <div style="font-family:'Poppins';font-size:36px;font-weight:700;letter-spacing:-.035em;margin-bottom:8px">Rio de Janeiro</div>
      <div style="font-size:23px;color:rgba(255,255,255,0.58)">Cidade, favoritos e contexto.</div>
    `,
  })}
  ${statBadge({ x: 628, y: 1880, val: '3+', lbl: 'tipos de função técnica', color: C.violet, z: 28 })}
  ${statBadge({ x: 76,  y: 2080, val: '10+', lbl: 'estilos musicais', color: C.primary, z: 28 })}
  ${bottomSignature({
    line1: 'em um perfil só.',
    line1Accent: 'Tudo',
    line2: 'Instrumentos · Funções · Cidade',
    accentColor: C.primary,
  })}
`;

const scene5 = () => `
  ${orb(1080, 260,  560, C.electric, 0.3, 95)}
  ${orb(120,  1860, 440, C.teal,     0.2, 85)}
  ${orb(200,  600,  360, C.primary,  0.16, 80)}
  ${dots(76,  240, 200, 200, 0.1)}
  ${eqBars(76, 2290, 1090, C.electric, 0.1)}
  ${headline({
    x: 76, y: 148, w: 900,
    kicker: 'BUSCA INTELIGENTE',
    h: 'Filtre a cena<br>do seu jeito',
    sub: 'Por categoria, instrumento,<br>g&ecirc;nero e especialidade.',
    size: 112,
  })}
  ${searchBar(76, 696, 76, 'Buscar m&uacute;sicos, bandas e est&uacute;dios...')}
  ${phone({ x: 76, y: 862, w: 610, src: SHOTS[5], rot: -3, glowColor: C.electric, glowAlpha: 0.26, z: 18 })}
  <!-- Category tiles right -->
  <div style="position:absolute;right:76px;top:866px;width:492px;display:flex;flex-direction:column;gap:20px;z-index:26">
    ${[
      { label: 'Cantores',     color: C.primary  },
      { label: 'DJs',          color: C.violet   },
      { label: 'Guitarristas', color: C.electric },
      { label: 'Bateristas',   color: C.teal     },
      { label: 'Produtores',   color: C.green    },
      { label: 'Sopros',       color: C.amber    },
    ].map(({ label, color }) =>
      `<div style="padding:30px 28px;border-radius:24px;border:1px solid ${rgba(color,0.22)};background:linear-gradient(145deg,${rgba(color,0.14)} 0%,rgba(0,0,0,0) 100%),rgba(10,8,20,0.84);backdrop-filter:blur(14px);display:flex;align-items:center;gap:18px">
        <div style="width:44px;height:44px;border-radius:14px;background:${rgba(color,0.24)};border:1px solid ${rgba(color,0.3)};flex-shrink:0;display:grid;place-items:center">
          <div style="width:16px;height:16px;border-radius:999px;background:${color}"></div>
        </div>
        <span style="font-family:'Poppins';font-size:30px;font-weight:700;letter-spacing:-.02em">${label}</span>
      </div>`
    ).join('')}
  </div>
  ${bottomSignature({
    line1: 'quem você procura.',
    line1Accent: 'Encontre',
    line2: 'Por instrumento · Gênero · Cidade · Especialidade',
    accentColor: C.primary,
  })}
`;

const scene6 = () => `
  ${orb(180,  1360, 540, C.primary, 0.26, 90)}
  ${orb(1100, 1800, 480, C.primary, 0.18, 85)}
  ${orb(600,  600,  380, C.primary, 0.12, 80)}
  ${dots(900, 240, 250, 220, 0.1)}
  ${eqBars(76, 2410, 1090, C.primary, 0.11)}
  ${headline({
    x: 76, y: 148, w: 920,
    kicker: 'GALERIA',
    h: 'Mostre palco,<br>bastidor e<br>identidade',
    sub: 'Fotos e v&iacute;deos deixam<br>seu perfil mais convincente.',
    size: 108,
  })}
  ${pill({ x: 76,  y: 762, txt: 'FOTOS',          color: C.primary, rot: -2 })}
  ${pill({ x: 292, y: 752, txt: 'V&Iacute;DEOS',  color: C.violet,  rot:  3 })}
  ${phone({ x: 76, y: 820, w: 590, src: SHOTS[6], rot: -2.5, glowColor: C.primary, glowAlpha: 0.26, z: 18 })}
  <!-- Media grid — right side, taller without statsStrip -->
  <div style="position:absolute;right:76px;top:816px;width:494px;display:flex;flex-direction:column;gap:14px;z-index:24">
    <div style="height:316px;border-radius:28px;border:1px solid ${rgba(C.primary,0.14)};overflow:hidden;box-shadow:0 28px 70px rgba(0,0,0,0.5)"><img src="${SHOTS[6]}" alt="" style="width:100%;height:100%;object-fit:cover;object-position:center 20%"></div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px">
      <div style="height:218px;border-radius:22px;border:1px solid rgba(255,255,255,0.08);overflow:hidden;box-shadow:0 20px 50px rgba(0,0,0,0.45)"><img src="${SHOTS[6]}" alt="" style="width:100%;height:100%;object-fit:cover;object-position:center 52%"></div>
      <div style="height:218px;border-radius:22px;border:1px solid rgba(255,255,255,0.08);overflow:hidden;box-shadow:0 20px 50px rgba(0,0,0,0.45)"><img src="${SHOTS[6]}" alt="" style="width:100%;height:100%;object-fit:cover;object-position:center 76%"></div>
    </div>
    <div style="height:256px;border-radius:28px;border:1px solid ${rgba(C.primary,0.14)};overflow:hidden;box-shadow:0 24px 60px rgba(0,0,0,0.5)"><img src="${SHOTS[6]}" alt="" style="width:100%;height:100%;object-fit:cover;object-position:center 42%"></div>
    <div style="height:220px;border-radius:22px;border:1px solid rgba(255,255,255,0.08);overflow:hidden;box-shadow:0 20px 50px rgba(0,0,0,0.4)"><img src="${SHOTS[6]}" alt="" style="width:100%;height:100%;object-fit:cover;object-position:center 60%"></div>
  </div>
  ${statBadge({ x: 76,  y: 2130, val: '6+',  lbl: 'fotos por perfil',          color: C.primary, z: 28 })}
  ${statBadge({ x: 700, y: 2190, val: '3+',  lbl: 'vídeos de performance',      color: C.violet,  z: 28 })}
  ${bottomSignature({
    line1: 'quem você é na música.',
    line1Accent: 'Mostre',
    line2: 'Fotos HD · Vídeos de performance',
    accentColor: C.primary,
  })}
`;

const scene7 = () => `
  ${orb(280,  440,  760, C.primary, 0.3,  110)}
  ${orb(980,  320,  660, C.violet,  0.24, 100)}
  ${orb(621, 1940,  600, C.electric,0.16, 105)}
  ${ring(280,  440, 1020, C.primary, 0.08)}
  ${ring(980,  320,  920, C.violet,  0.07)}
  ${dots(900,  80,  280, 300, 0.08)}
  ${eqBars(76, 1580, 1090, C.primary, 0.09)}
  <!-- Logo hero -->
  <div style="position:absolute;left:50%;top:180px;transform:translateX(-50%);display:flex;flex-direction:column;align-items:center;z-index:32">
    <div style="width:240px;height:240px;border-radius:64px;border:1px solid rgba(255,255,255,0.14);background:linear-gradient(145deg,${rgba(C.primary,0.28)} 0%,${rgba(C.violet,0.2)} 100%),rgba(10,8,20,0.92);box-shadow:0 50px 110px rgba(0,0,0,0.65),inset 0 1px 0 rgba(255,255,255,0.08),0 0 0 1px ${rgba(C.primary,0.15)};display:grid;place-items:center">
      <img src="${SQUARE_PRIMARY}" alt="" style="width:176px;height:176px">
    </div>
    <div style="margin-top:38px"><img src="${HORIZ_WHITE}" alt="mube" style="height:58px;width:auto"></div>
    <div style="margin-top:20px;font-size:34px;color:rgba(255,255,255,0.6);text-align:center;max-width:640px;line-height:1.36;font-weight:500;font-family:'Inter'">A plataforma musical que conecta<br>m&uacute;sicos, bandas e contratantes.</div>
  </div>
  <!-- Feature list -->
  <div style="position:absolute;left:76px;top:830px;right:76px;z-index:28">
    ${[
      { title: 'Matchpoint',              desc: 'Swipe com inten&ccedil;&atilde;o, match com futuro',  color: C.primary  },
      { title: 'Busca inteligente',       desc: 'Filtre por instrumento, g&ecirc;nero e cidade',       color: C.electric },
      { title: 'Chat direto',             desc: 'Conecte e converse sem intermedi&aacute;rios',        color: C.violet   },
      { title: '4 tipos de perfil',       desc: 'M&uacute;sico, banda, est&uacute;dio ou contratante', color: C.teal     },
      { title: 'Galeria de m&iacute;dia', desc: 'Mostre seu talento com fotos e v&iacute;deos',        color: C.green    },
      { title: 'Conex&otilde;es reais',   desc: 'Parcerias, shows e projetos que acontecem',           color: C.amber    },
    ].map(featRow).join('')}
  </div>
  <!-- Central tagline -->
  <div style="position:absolute;left:76px;right:76px;top:1668px;z-index:28">
    <div style="height:1px;background:linear-gradient(90deg,transparent 0%,${rgba(C.primary,0.5)} 30%,${rgba(C.violet,0.5)} 70%,transparent 100%);margin-bottom:48px"></div>
    <div style="font-family:'Poppins';font-size:80px;font-weight:800;letter-spacing:-.045em;line-height:.96;text-align:center">Conecte.<br><span style="color:${C.primary}">Toque.</span><br>Cresça.</div>
  </div>
  <!-- Stats row -->
  <div style="position:absolute;left:76px;right:76px;top:2140px;display:grid;grid-template-columns:repeat(3,1fr);gap:18px;z-index:30">
    ${[
      { val: '500+',      lbl: 'm&uacute;sicos cadastrados', color: C.primary  },
      { val: 'RJ&middot;SP', lbl: 'cidades principais',     color: C.violet   },
      { val: 'Grátis',    lbl: 'pra come&ccedil;ar',        color: C.electric },
    ].map(({ val, lbl, color }) =>
      `<div style="padding:26px 22px;border-radius:26px;border:1px solid ${rgba(color,0.24)};background:linear-gradient(145deg,${rgba(color,0.18)} 0%,rgba(0,0,0,0) 100%),rgba(8,6,16,0.88)">
        <div style="font-family:'Poppins';font-size:52px;font-weight:800;letter-spacing:-.04em;line-height:1;color:#fff">${val}</div>
        <div style="margin-top:10px;font-size:20px;color:rgba(255,255,255,0.5);font-weight:500">${lbl}</div>
      </div>`
    ).join('')}
  </div>
  <!-- Bottom tagline -->
  <div style="position:absolute;left:76px;right:76px;bottom:72px;z-index:30;text-align:center">
    <div style="font-family:'Poppins';font-size:54px;font-weight:800;letter-spacing:-.035em;line-height:1.06">Perfis, busca e conversa<br>no mesmo fluxo.</div>
    <div style="margin-top:16px;font-size:29px;color:rgba(255,255,255,0.4);font-weight:500">Dispon&iacute;vel para iOS e Android</div>
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
      await page.waitForTimeout(180);
      await page.screenshot({ path: outFile, type: 'png' });
      await validate(outFile);
      await page.close();
      console.log(`  store_${slide.id}.png ✓`);
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
