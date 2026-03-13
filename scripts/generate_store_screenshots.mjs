import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { chromium } from 'playwright';
import sharp from 'sharp';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const OUT = path.join(ROOT, 'assets', 'images', 'store_screenshots');
const W = 1242;
const H = 2688;
const R = 1206 / 2622;
const TOTAL = 7;

const extMime = {
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.woff2': 'font/woff2',
};

const read = (rel) => fs.readFileSync(path.join(ROOT, rel));
const uri = (rel, mime = extMime[path.extname(rel).toLowerCase()] ?? 'application/octet-stream') =>
  `data:${mime};base64,${read(rel).toString('base64')}`;
const svg = (v) => `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(v)}`;
const rgb = (hex) => {
  const v = hex.replace('#', '');
  return [0, 2, 4].map((i) => Number.parseInt(v.slice(i, i + 2), 16));
};
const a = (hex, alpha) => {
  const [r, g, b] = rgb(hex);
  return `rgba(${r},${g},${b},${alpha})`;
};
const ff = (family, weight, rel) =>
  `@font-face{font-family:'${family}';src:url("${uri(rel, 'font/woff2')}") format('woff2');font-weight:${weight};font-style:normal;font-display:swap;}`;

const fonts = [
  ff('Poppins Local', 500, 'node_modules/@fontsource/poppins/files/poppins-latin-500-normal.woff2'),
  ff('Poppins Local', 600, 'node_modules/@fontsource/poppins/files/poppins-latin-600-normal.woff2'),
  ff('Poppins Local', 700, 'node_modules/@fontsource/poppins/files/poppins-latin-700-normal.woff2'),
  ff('Poppins Local', 800, 'node_modules/@fontsource/poppins/files/poppins-latin-800-normal.woff2'),
  ff('Poppins Local', 900, 'node_modules/@fontsource/poppins/files/poppins-latin-900-normal.woff2'),
  ff('Inter Local', 500, 'node_modules/@fontsource/inter/files/inter-latin-500-normal.woff2'),
  ff('Inter Local', 600, 'node_modules/@fontsource/inter/files/inter-latin-600-normal.woff2'),
].join('');

const noise = svg(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 320"><filter id="n"><feTurbulence type="fractalNoise" baseFrequency=".78" numOctaves="2" stitchTiles="stitch"/></filter><rect width="100%" height="100%" filter="url(#n)" opacity=".88"/></svg>`);
const brandIcon = uri('assets/images/logos_svg/brand/brand-icon-white-cutout.svg', 'image/svg+xml');
const brandWordmark = uri('assets/images/logos_svg/brand/brand-horizontal-white-cutout.svg', 'image/svg+xml');
const brandHorizontalPrimary = uri('assets/images/logos_svg/brand/brand-horizontal-primary.svg', 'image/svg+xml');
const brandSquarePrimary = uri('assets/images/logos_svg/brand/brand-square-primary.svg', 'image/svg+xml');
const shots = Object.fromEntries(Array.from({ length: TOTAL }, (_, i) => [i + 1, uri(`assets/images/screenshots/ss${i + 1}.png`, 'image/png')]));

const css = `
${fonts}
*{box-sizing:border-box}html,body{margin:0;width:${W}px;height:${H}px;overflow:hidden}body{background:#0a0a0a;color:#fff;font-family:'Inter Local',system-ui,sans-serif}
.page{position:relative;width:100%;height:100%;overflow:hidden;isolation:isolate}
.page:before{content:'';position:absolute;inset:0;background-image:url("${noise}");background-size:420px 420px;opacity:.09;mix-blend-mode:soft-light;z-index:1}
.page:after{content:'';position:absolute;inset:0;background:linear-gradient(180deg,rgba(10,10,10,.08) 0%,rgba(10,10,10,0) 22%),linear-gradient(0deg,rgba(10,10,10,.46) 0%,rgba(10,10,10,0) 18%);z-index:2}
.mesh,.orb,.ring,.grid,.brand,.meta,.txt,.word,.chip,.card,.d,.m,.tile,.search,.act,.logo-stage{position:absolute}
.mesh{inset:0;z-index:0}.orb{border-radius:999px;filter:blur(70px);mix-blend-mode:screen;z-index:3}.ring{border-radius:999px;border:1px solid rgba(255,255,255,.08);z-index:4}.grid{background-image:radial-gradient(circle,rgba(255,255,255,.9) 1.4px,transparent 1.5px);background-size:22px 22px;opacity:.12;z-index:4}
.brand{display:flex;align-items:center;gap:16px;padding:14px 24px 14px 14px;border-radius:999px;border:1px solid rgba(255,255,255,.1);background:rgba(20,20,20,.72);box-shadow:0 18px 40px rgba(0,0,0,.34);backdrop-filter:blur(22px);z-index:30}
.brand .mark{display:grid;place-items:center;width:44px;height:44px;border-radius:999px;background:rgba(232,70,108,.18)}.brand .mark img{width:28px;height:28px}.brand .name{font-family:'Poppins Local',sans-serif;font-size:34px;font-weight:700;letter-spacing:-.04em;line-height:1}
.meta{padding:14px 18px;border-radius:999px;border:1px solid rgba(255,255,255,.08);background:rgba(255,255,255,.04);color:rgba(255,255,255,.74);font-size:20px;font-weight:600;letter-spacing:.16em;text-transform:uppercase;backdrop-filter:blur(18px);z-index:30}
.txt{z-index:28}.txt.c{text-align:center}.k{margin:0 0 26px;font-size:24px;font-weight:600;letter-spacing:.24em;text-transform:uppercase}.h{font-family:'Poppins Local',sans-serif;font-size:114px;line-height:.98;font-weight:700;letter-spacing:-.035em}.s{margin-top:28px;color:rgba(255,255,255,.72);font-size:37px;line-height:1.38;font-weight:500;letter-spacing:-.01em}
.word{font-family:'Poppins Local',sans-serif;font-weight:800;letter-spacing:-.08em;color:transparent;-webkit-text-stroke:1px rgba(255,255,255,.08);z-index:4}
.chip{display:inline-flex;align-items:center;gap:12px;padding:16px 24px;border-radius:999px;border:1px solid rgba(255,255,255,.1);font-size:24px;font-weight:600;color:rgba(255,255,255,.94);letter-spacing:-.02em;box-shadow:0 14px 40px rgba(0,0,0,.22);backdrop-filter:blur(18px);z-index:22}.chip b{width:10px;height:10px;border-radius:999px;display:block}
.card{padding:28px;border-radius:32px;border:1px solid rgba(255,255,255,.09);background:linear-gradient(180deg,rgba(255,255,255,.08) 0%,rgba(255,255,255,.02) 100%),rgba(20,20,20,.68);box-shadow:0 26px 60px rgba(0,0,0,.3);backdrop-filter:blur(24px);z-index:24}.card .tt{margin:0 0 10px;font-family:'Poppins Local',sans-serif;font-size:38px;font-weight:700;letter-spacing:-.04em;line-height:1.02}.card .cp{color:rgba(255,255,255,.74);font-size:25px;line-height:1.35;letter-spacing:-.02em}.tags{display:flex;flex-wrap:wrap;gap:12px;margin-top:22px}.tags span{display:inline-flex;align-items:center;gap:10px;padding:12px 18px;border-radius:999px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08);font-size:21px;font-weight:600;line-height:1}.tags span:before{content:'';width:8px;height:8px;border-radius:999px;background:var(--t,#e8466c)}
.d{transform-origin:center center;z-index:16}.d .gl{position:absolute;inset:26px 24px 24px 24px;border-radius:64px;filter:blur(56px);opacity:.92;z-index:0}.d .fr{position:relative;width:100%;height:100%;padding:18px;border-radius:74px;border:1px solid rgba(255,255,255,.15);background:linear-gradient(180deg,rgba(255,255,255,.16) 0%,rgba(255,255,255,.03) 100%),rgba(14,14,14,.9);box-shadow:0 40px 90px rgba(0,0,0,.5),inset 0 1px 0 rgba(255,255,255,.08);overflow:hidden;z-index:1}.d .sc{position:relative;width:100%;height:100%;overflow:hidden;border-radius:58px;background:#111}.d .sc img,.m img{display:block;width:100%;height:100%;object-fit:cover}.d .no{position:absolute;top:18px;left:50%;width:214px;height:34px;transform:translateX(-50%);border-radius:999px;background:rgba(10,10,10,.98);z-index:4}.d .sh{position:absolute;inset:0;background:linear-gradient(130deg,rgba(255,255,255,.16) 0%,transparent 32%);mix-blend-mode:screen;opacity:.5}
.m{overflow:hidden;border-radius:34px;border:1px solid rgba(255,255,255,.11);background:linear-gradient(180deg,rgba(255,255,255,.06) 0%,rgba(255,255,255,.01) 100%),rgba(16,16,16,.82);box-shadow:0 24px 64px rgba(0,0,0,.35);z-index:17}
.tile{padding:24px;border-radius:30px;border:1px solid rgba(255,255,255,.08);background:linear-gradient(180deg,rgba(255,255,255,.08) 0%,rgba(255,255,255,.02) 100%),rgba(16,16,16,.84);box-shadow:0 18px 44px rgba(0,0,0,.26);backdrop-filter:blur(20px);z-index:22}.tile .ic{width:48px;height:48px;border-radius:16px;margin-bottom:16px}.tile .tt{font-family:'Poppins Local',sans-serif;font-size:30px;font-weight:700;letter-spacing:-.04em;line-height:1.02}.tile .cp{margin-top:8px;color:rgba(255,255,255,.66);font-size:21px;line-height:1.28}
.search{display:flex;align-items:center;gap:16px;padding:20px 28px;border-radius:999px;border:1px solid rgba(255,255,255,.1);background:rgba(20,20,20,.74);box-shadow:0 18px 44px rgba(0,0,0,.28);backdrop-filter:blur(22px);font-size:26px;font-weight:500;color:rgba(255,255,255,.56);z-index:23}.search i{width:18px;height:18px;border:2px solid rgba(255,255,255,.48);border-radius:999px;display:block;position:relative}.search i:after{content:'';position:absolute;right:-7px;bottom:-7px;width:10px;height:2px;border-radius:999px;background:rgba(255,255,255,.48);transform:rotate(45deg)}
.act{display:grid;place-items:center;border-radius:999px;border:1px solid rgba(255,255,255,.12);background:linear-gradient(180deg,rgba(255,255,255,.08) 0%,rgba(255,255,255,.02) 100%),rgba(18,18,18,.85);box-shadow:0 24px 56px rgba(0,0,0,.36);backdrop-filter:blur(18px);font-family:'Poppins Local',sans-serif;font-size:48px;font-weight:700;line-height:1;z-index:20}
.logo-stage{z-index:22}.logo-stage .glow{position:absolute;left:22px;top:22px;width:320px;height:320px;border-radius:72px;filter:blur(64px);opacity:.52}.logo-stage .disc{position:relative;display:grid;place-items:center;width:364px;height:364px;border-radius:84px;border:1px solid rgba(255,255,255,.14);background:linear-gradient(180deg,rgba(255,255,255,.1) 0%,rgba(255,255,255,.02) 100%),rgba(20,20,20,.82);box-shadow:0 34px 90px rgba(0,0,0,.36),inset 0 1px 0 rgba(255,255,255,.08)}.logo-stage .disc:before{content:'';position:absolute;inset:28px;border-radius:64px;background:${a('#E8466C', .14)};border:1px solid rgba(255,255,255,.06)}.logo-stage .disc img{position:relative;width:158px;height:158px}.logo-stage .wordmark{margin-top:34px}.logo-stage .wordmark img{width:356px;height:auto;display:block}.logo-stage .copy{margin-top:18px;max-width:380px;color:rgba(255,255,255,.7);font-size:30px;line-height:1.3;letter-spacing:-.01em}
`;

const brand = (l = 72, t = 72) => `<div class="brand" style="left:${l}px;top:${t}px"><div class="mark"><img src="${brandIcon}" alt=""></div><div class="name">Mube</div></div>`;
const meta = (id, r = 72, t = 78) => `<div class="meta" style="right:${r}px;top:${t}px">${String(id).padStart(2, '0')} / ${String(TOTAL).padStart(2, '0')}</div>`;
const text = ({ l, t, w, k, h, s, c, center = false }) => `<div class="txt${center ? ' c' : ''}" style="left:${l}px;top:${t}px;width:${w}px"><div class="k" style="color:${c}">${k}</div><div class="h">${h}</div><div class="s">${s}</div></div>`;
const word = ({ l, t, txt, size, rot = 0, o = .08 }) => `<div class="word" style="left:${l}px;top:${t}px;font-size:${size}px;transform:rotate(${rot}deg);-webkit-text-stroke:1px rgba(255,255,255,${o})">${txt}</div>`;
const orb = (style) => `<div class="orb" style="${style}"></div>`;
const ring = (style) => `<div class="ring" style="${style}"></div>`;
const grid = (style) => `<div class="grid" style="${style}"></div>`;
const chip = ({ l, t, txt, c, rot = 0, alpha = .12, z = 22 }) => `<div class="chip" style="left:${l}px;top:${t}px;transform:rotate(${rot}deg);background:${a(c, alpha)};box-shadow:0 14px 40px ${a(c, .16)};z-index:${z}"><b style="background:${c}"></b>${txt}</div>`;
const tags = (list, c) => `<div class="tags">${list.map((v) => `<span style="--t:${c}">${v}</span>`).join('')}</div>`;
const card = ({ l, t, w, tt, cp = '', c, rot = 0, body = '', z = 24 }) => `<div class="card" style="left:${l}px;top:${t}px;width:${w}px;transform:rotate(${rot}deg);box-shadow:0 26px 60px rgba(0,0,0,.3),0 0 0 1px ${a(c, .12)} inset;z-index:${z}"><div class="tt">${tt}</div>${cp ? `<div class="cp">${cp}</div>` : ''}${body}</div>`;
const dev = ({ l, t, w, src, c, rot = 0, z = 16, pos = 'center top' }) => { const h = Math.round(w / R); return `<div class="d" style="left:${l}px;top:${t}px;width:${w}px;height:${h}px;transform:rotate(${rot}deg);z-index:${z}"><div class="gl" style="background:${a(c, .28)}"></div><div class="fr"><div class="no"></div><div class="sc"><img src="${src}" alt="" style="object-position:${pos}"></div><div class="sh"></div></div></div>`; };
const media = ({ l, t, w, h, src, rot = 0, z = 17, pos = 'center center', rad = 34 }) => `<div class="m" style="left:${l}px;top:${t}px;width:${w}px;height:${h}px;border-radius:${rad}px;transform:rotate(${rot}deg);z-index:${z}"><img src="${src}" alt="" style="object-position:${pos}"></div>`;
const tile = ({ l, t, w, tt, cp, c, rot = 0 }) => `<div class="tile" style="left:${l}px;top:${t}px;width:${w}px;transform:rotate(${rot}deg)"><div class="ic" style="background:${a(c, .2)}"></div><div class="tt">${tt}</div><div class="cp">${cp}</div></div>`;
const search = ({ l, t, w, txt }) => `<div class="search" style="left:${l}px;top:${t}px;width:${w}px"><i></i><span>${txt}</span></div>`;
const act = ({ l, t, s, txt, c, color = '#fff' }) => `<div class="act" style="left:${l}px;top:${t}px;width:${s}px;height:${s}px;color:${color};box-shadow:0 24px 56px rgba(0,0,0,.36),0 0 0 1px ${a(c, .16)} inset">${txt}</div>`;
const logoStage = ({ l, t, c, copy }) => `<div class="logo-stage" style="left:${l}px;top:${t}px"><div class="glow" style="background:${a(c, .28)}"></div><div class="disc"><img src="${brandIcon}" alt=""></div><div class="wordmark"><img src="${brandWordmark}" alt="Mube"></div><div class="copy">${copy}</div></div>`;
const brandPanel = ({ l, t, w, h, p, s, c, copy }) => `
<div style="position:absolute;left:${l}px;top:${t}px;width:${w}px;height:${h}px;padding:44px;border-radius:48px;border:1px solid rgba(255,255,255,.1);background:linear-gradient(155deg,${a(p, .2)} 0%,${a(s, .2)} 46%,${a(c, .18)} 100%),rgba(16,16,16,.84);box-shadow:0 38px 100px rgba(0,0,0,.34),inset 0 1px 0 rgba(255,255,255,.06);overflow:hidden;z-index:22">
  <div style="position:absolute;right:-54px;top:-34px;width:240px;height:240px;border-radius:999px;border:1px solid ${a('#ffffff', .08)}"></div>
  <div style="position:absolute;left:-80px;bottom:-110px;width:280px;height:280px;border-radius:999px;background:${a(p, .14)};filter:blur(40px)"></div>
  <div style="position:absolute;right:-50px;bottom:120px;width:210px;height:210px;border-radius:999px;background:${a(c, .16)};filter:blur(44px)"></div>
  <div style="position:absolute;inset:22px;border-radius:34px;border:1px solid rgba(255,255,255,.05)"></div>
  <div style="position:relative;height:100%;display:flex;flex-direction:column">
    <div style="display:flex;align-items:center;justify-content:space-between">
      <div style="width:108px;height:8px;border-radius:999px;background:${a('#ffffff', .1)}"></div>
      <div style="padding:10px 14px;border-radius:999px;background:${a('#ffffff', .05)};border:1px solid rgba(255,255,255,.08);font-size:18px;font-weight:600;letter-spacing:.14em;text-transform:uppercase;color:rgba(255,255,255,.58)">identidade</div>
    </div>
    <div style="margin-top:58px;position:relative;width:100%;height:420px;border-radius:40px;background:linear-gradient(150deg,${a(p, .32)} 0%,${a(s, .24)} 58%,${a(c, .28)} 100%),rgba(22,22,22,.9);border:1px solid rgba(255,255,255,.1);box-shadow:inset 0 1px 0 rgba(255,255,255,.06)">
      <div style="position:absolute;inset:26px;border-radius:28px;background:radial-gradient(circle at 50% 28%,${a('#ffffff', .08)} 0%,transparent 38%),linear-gradient(180deg,rgba(255,255,255,.02) 0%,rgba(255,255,255,0) 100%)"></div>
      <div style="position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);width:258px;height:258px;border-radius:64px;background:rgba(255,255,255,.06);display:grid;place-items:center;box-shadow:0 28px 60px rgba(0,0,0,.28),inset 0 1px 0 rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08)">
        <img src="${brandSquarePrimary}" alt="" style="width:188px;height:188px" />
      </div>
    </div>
    <div style="margin-top:42px">
      <img src="${brandHorizontalPrimary}" alt="Mube" style="width:332px;height:auto;display:block" />
      <div style="margin-top:20px;max-width:360px;color:rgba(255,255,255,.76);font-size:29px;line-height:1.28;letter-spacing:-.01em">${copy}</div>
    </div>
    <div style="margin-top:auto;display:flex;flex-wrap:wrap;gap:12px">
      <div class="chip" style="position:relative;left:auto;top:auto;transform:none;background:${a(p, .14)};box-shadow:none"><b style="background:${p}"></b>descoberta</div>
      <div class="chip" style="position:relative;left:auto;top:auto;transform:none;background:${a(s, .14)};box-shadow:none"><b style="background:${s}"></b>matchpoint</div>
      <div class="chip" style="position:relative;left:auto;top:auto;transform:none;background:${a(c, .14)};box-shadow:none"><b style="background:${c}"></b>chat</div>
    </div>
  </div>
</div>`;
const featureBand = ({ l, t, w, h, items }) => `
<div style="position:absolute;left:${l}px;top:${t}px;width:${w}px;height:${h}px;padding:28px;border-radius:44px;border:1px solid rgba(255,255,255,.09);background:linear-gradient(180deg,rgba(255,255,255,.06) 0%,rgba(255,255,255,.02) 100%),rgba(16,16,16,.8);box-shadow:0 30px 80px rgba(0,0,0,.28);backdrop-filter:blur(24px);z-index:24">
  <div style="display:grid;grid-template-columns:repeat(${items.length},1fr);gap:18px;height:100%">
    ${items
      .map(
        (item) => `
      <div style="padding:28px;border-radius:30px;background:linear-gradient(180deg,${a(item.c, .16)} 0%,rgba(255,255,255,.02) 100%),rgba(20,20,20,.84);border:1px solid ${a(item.c, .16)};display:flex;flex-direction:column">
        <div style="width:46px;height:46px;border-radius:14px;background:${a(item.c, .22)};box-shadow:inset 0 1px 0 rgba(255,255,255,.06)"></div>
        <div style="margin-top:20px;font-family:'Poppins Local',sans-serif;font-size:34px;font-weight:700;line-height:1.02;letter-spacing:-.035em">${item.tt}</div>
        <div style="margin-top:12px;color:rgba(255,255,255,.72);font-size:22px;line-height:1.32">${item.cp}</div>
        <div style="margin-top:auto;padding-top:24px;color:${item.c};font-size:18px;font-weight:600;letter-spacing:.12em;text-transform:uppercase">${item.k}</div>
      </div>`,
      )
      .join('')}
  </div>
</div>`;
const footerBand = ({ l, t, w, items }) => `
<div style="position:absolute;left:${l}px;top:${t}px;width:${w}px;padding:20px 24px;border-radius:38px;border:1px solid rgba(255,255,255,.08);background:linear-gradient(180deg,rgba(255,255,255,.05) 0%,rgba(255,255,255,.015) 100%),rgba(14,14,14,.84);box-shadow:0 28px 70px rgba(0,0,0,.28);backdrop-filter:blur(24px);z-index:24">
  <div style="display:grid;grid-template-columns:repeat(${items.length},1fr);gap:14px">
    ${items
      .map(
        (item) => `
      <div style="padding:20px 18px;border-radius:26px;background:linear-gradient(180deg,${a(item.c, .14)} 0%,rgba(255,255,255,.02) 100%),rgba(18,18,18,.84);border:1px solid ${a(item.c, .14)}">
        <div style="width:18px;height:18px;border-radius:8px;background:${a(item.c, .28)};margin-bottom:14px"></div>
        <div style="font-family:'Poppins Local',sans-serif;font-size:30px;font-weight:700;letter-spacing:-.035em;line-height:1.02">${item.tt}</div>
        <div style="margin-top:10px;color:rgba(255,255,255,.6);font-size:16px;font-weight:600;letter-spacing:.14em;text-transform:uppercase">${item.k}</div>
      </div>`,
      )
      .join('')}
  </div>
</div>`;
const mesh = (s) => `background:radial-gradient(circle at ${s.mesh[0]},${a(s.p, .18)} 0%,transparent 34%),radial-gradient(circle at ${s.mesh[1]},${a(s.s, .14)} 0%,transparent 28%),radial-gradient(circle at ${s.mesh[2]},${a(s.t, .1)} 0%,transparent 36%),linear-gradient(180deg,#141414 0%,#0a0a0a 42%,#070707 100%)`;

function html(slide, body) {
  return `<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=${W},initial-scale=1"><style>${css}</style></head><body><main class="page"><div class="mesh" style="${mesh(slide)}"></div>${body}</main></body></html>`;
}

const scene1 = (s) => `
${grid('left:940px;top:270px;width:210px;height:260px')}${orb(`left:-110px;top:1420px;width:440px;height:440px;background:${a(s.s, .2)}`)}${orb(`right:-120px;top:880px;width:360px;height:360px;background:${a(s.p, .18)}`)}
${ring(`left:110px;top:1050px;width:930px;height:930px;border-color:${a(s.p, .1)}`)}${ring(`left:830px;top:980px;width:220px;height:220px;border-color:${a(s.s, .14)}`)}
${text({ l: 76, t: 238, w: 950, c: s.p, k: 'COMECE DO SEU JEITO', h: 'Seu perfil entra<br>no palco certo', s: 'M&uacute;sico, banda, est&uacute;dio ou contratante. O Mube come&ccedil;a do seu jeito.' })}
${chip({ l: 76, t: 760, txt: 'M&Uacute;SICO', c: s.p, rot: -3 })}${chip({ l: 318, t: 724, txt: 'BANDA', c: s.s, rot: 2 })}${chip({ l: 536, t: 786, txt: 'EST&Uacute;DIO', c: s.t, rot: -2 })}${chip({ l: 790, t: 738, txt: 'CONTRATANTE', c: s.p, rot: 4 })}
${card({ l: 822, t: 914, w: 292, tt: '4 perfis', cp: 'uma plataforma feita para conectar a sua pr&oacute;xima fase.', c: s.p, rot: 4 })}
${dev({ l: 258, t: 1018, w: 724, src: shots[1], c: s.p, rot: -2.3 })}
`;

const scene2 = (s) => `
${grid('left:72px;top:820px;width:220px;height:260px')}${orb(`left:-120px;top:230px;width:420px;height:420px;background:${a(s.p, .15)}`)}${orb(`right:-70px;top:1230px;width:320px;height:320px;background:${a(s.s, .14)}`)}
${text({ l: 76, t: 238, w: 860, c: s.p, k: 'DESCUBRA A SUA CENA', h: 'Talentos reais,<br>prontos pra conectar', s: 'Encontre profissionais, bandas e equipes perto de voc&ecirc;.' })}
${chip({ l: 82, t: 770, txt: 'ROCK', c: s.p, rot: -4 })}${chip({ l: 252, t: 810, txt: 'POP', c: s.s, rot: 5 })}${chip({ l: 400, t: 758, txt: 'T&Eacute;CNICO', c: s.t, rot: -3 })}
${card({ l: 76, t: 980, w: 404, tt: '+12 favoritos', cp: 'Descoberta r&aacute;pida, visual forte e contexto suficiente para decidir.', c: s.p, body: tags(['Baixo', 'Viol&atilde;o', 'Rap', 'Reggae'], s.p) })}
${dev({ l: 560, t: 856, w: 620, src: shots[2], c: s.p, rot: 6 })}${dev({ l: 98, t: 1512, w: 330, src: shots[4], c: s.s, rot: -8, z: 19, pos: 'center 12%' })}
`;

const scene3 = (s) => `
${orb(`left:210px;top:820px;width:820px;height:820px;background:${a(s.p, .18)};filter:blur(96px)`)}${ring(`left:170px;top:770px;width:900px;height:900px;border-color:${a(s.p, .1)}`)}${ring(`left:312px;top:920px;width:620px;height:620px;border-color:${a(s.s, .12)}`)}${grid('left:930px;top:330px;width:180px;height:220px')}
${text({ l: 121, t: 232, w: 1000, c: s.p, center: true, k: 'MATCHPOINT', h: 'Swipe com inten&ccedil;&atilde;o.<br>Match com futuro.', s: 'Curta, passe ou volte. O que importa aparece com contexto suficiente para virar projeto.' })}
${chip({ l: 108, t: 884, txt: 'EXPLORAR', c: s.p, rot: -2 })}${chip({ l: 850, t: 876, txt: 'PRODUTOR', c: s.s, rot: 2 })}
${dev({ l: 232, t: 884, w: 778, src: shots[3], c: s.p, rot: -1.1, z: 18 })}
${act({ l: 286, t: 2260, s: 128, txt: '&#10005;', c: '#4b5563', color: '#d1d5db' })}${act({ l: 557, t: 2248, s: 132, txt: '&#8634;', c: s.s })}${act({ l: 835, t: 2258, s: 128, txt: '&#9829;', c: s.p, color: s.p })}
`;

const scene4 = (s) => `
${orb(`left:-90px;top:1160px;width:380px;height:380px;background:${a(s.s, .14)}`)}${orb(`right:-120px;top:380px;width:360px;height:360px;background:${a(s.p, .14)}`)}
${text({ l: 76, t: 238, w: 560, c: s.p, k: 'PERFIS COMPLETOS', h: 'O que voc&ecirc; faz<br>fica evidente', s: 'Instrumentos, fun&ccedil;&otilde;es t&eacute;cnicas, cidade e favoritos em uma leitura r&aacute;pida.' })}
${card({ l: 80, t: 922, w: 428, tt: 'Instrumentos', cp: 'Tudo o que voc&ecirc; toca aparece sem ru&iacute;do.', c: s.p, body: tags(['Viol&atilde;o', 'Guitarra', 'Baixo'], s.p) })}
${card({ l: 124, t: 1298, w: 466, tt: 'Fun&ccedil;&otilde;es t&eacute;cnicas', cp: 'Da produ&ccedil;&atilde;o ao palco, o perfil conta a hist&oacute;ria certa.', c: s.s, rot: -3, body: tags(['Diretor Musical', 'Produtor Musical', 'Beatmaker'], s.s) })}
${card({ l: 94, t: 1820, w: 352, tt: 'Rio de Janeiro', cp: 'Cidade, favoritos e contexto logo de cara.', c: s.t, rot: 2 })}
${dev({ l: 650, t: 760, w: 530, src: shots[4], c: s.p, rot: 4.5, z: 18 })}
`;

const scene5 = (s) => `
${orb(`left:780px;top:1450px;width:320px;height:320px;background:${a(s.s, .14)}`)}${orb(`left:-80px;top:520px;width:340px;height:340px;background:${a(s.p, .16)}`)}
${text({ l: 76, t: 238, w: 980, c: s.p, k: 'BUSCA INTELIGENTE', h: 'Filtre a cena<br>do seu jeito', s: 'Pesquise por categoria, instrumento, g&ecirc;nero e especialidade sem perder velocidade.' })}
${search({ l: 76, t: 722, w: 660, txt: 'Buscar m&uacute;sicos, bandas e est&uacute;dios...' })}
${tile({ l: 758, t: 854, w: 330, tt: 'Cantores', cp: 'Vocais e backing', c: s.s })}${tile({ l: 818, t: 1170, w: 314, tt: 'DJs', cp: 'Eletr&ocirc;nica e mix', c: s.p, rot: 3 })}${tile({ l: 724, t: 1490, w: 344, tt: 'Baixistas', cp: 'Contrabaixo e baixo', c: s.t, rot: -4 })}${tile({ l: 854, t: 1810, w: 292, tt: 'Guitarras', cp: 'Solo, base e timbre', c: s.p, rot: 4 })}
${dev({ l: 92, t: 944, w: 596, src: shots[5], c: s.p, rot: -4, z: 18 })}${dev({ l: 794, t: 1136, w: 312, src: shots[2], c: s.s, rot: 8, z: 19, pos: 'center 18%' })}
`;

const scene6 = (s) => `
${orb(`left:-120px;top:1260px;width:420px;height:420px;background:${a(s.s, .15)}`)}${orb(`right:-130px;top:1640px;width:420px;height:420px;background:${a(s.t, .12)}`)}${grid('left:920px;top:330px;width:200px;height:240px')}
${text({ l: 76, t: 238, w: 920, c: s.p, k: 'GALERIA', h: 'Mostre palco,<br>bastidor e identidade', s: 'Fotos e v&iacute;deos deixam seu perfil mais vivo e mais convincente.' })}
${chip({ l: 78, t: 758, txt: 'FOTOS', c: s.p, rot: -2 })}${chip({ l: 278, t: 746, txt: 'V&Iacute;DEOS', c: s.s, rot: 3 })}
${dev({ l: 86, t: 898, w: 520, src: shots[6], c: s.p, rot: -3.2, z: 18 })}
${media({ l: 670, t: 940, w: 470, h: 318, src: shots[6], pos: 'center 26%', rot: 6, z: 20 })}${media({ l: 700, t: 1368, w: 390, h: 286, src: shots[6], pos: 'center 60%', rot: -7, z: 19 })}${media({ l: 632, t: 1780, w: 500, h: 340, src: shots[6], pos: 'center 83%', rot: 5, z: 20 })}
${card({ l: 744, t: 2210, w: 346, tt: 'Portf&oacute;lio visual', cp: 'Um perfil com prova real do que voc&ecirc; entrega.', c: s.s, rot: -3 })}
`;

const scene7 = (s) => `
${orb(`right:-120px;top:140px;width:500px;height:500px;background:${a(s.t, .18)}`)}
${orb(`left:-180px;top:980px;width:420px;height:420px;background:${a(s.p, .16)}`)}
${orb(`right:80px;bottom:240px;width:380px;height:380px;background:${a(s.s, .16)}`)}
${ring(`left:862px;top:734px;width:260px;height:260px;border-color:${a(s.t, .12)}`)}
${grid('left:1006px;top:208px;width:124px;height:200px')}
<div class="txt" style="left:76px;top:180px;width:780px">
  <div class="k" style="color:${s.p}">A PLATAFORMA DA CENA</div>
  <div class="h" style="font-size:96px;line-height:.92;letter-spacing:-.045em">Tudo o que move<br>o seu som,<br>em um lugar</div>
  <div class="s" style="max-width:560px">Descoberta, match e conversa com identidade forte.</div>
</div>
<div style="position:absolute;left:76px;top:786px;width:1090px;height:1088px;padding:46px 48px;border-radius:58px;border:1px solid rgba(255,255,255,.1);background:linear-gradient(165deg,${a(s.p, .16)} 0%,${a(s.s, .14)} 48%,${a(s.t, .16)} 100%),rgba(16,16,16,.86);box-shadow:0 42px 120px rgba(0,0,0,.34),inset 0 1px 0 rgba(255,255,255,.06);overflow:hidden;z-index:22">
  <div style="position:absolute;right:-80px;top:-48px;width:280px;height:280px;border-radius:999px;border:1px solid ${a('#ffffff', .08)}"></div>
  <div style="position:absolute;left:-110px;bottom:-120px;width:320px;height:320px;border-radius:999px;background:${a(s.p, .14)};filter:blur(42px)"></div>
  <div style="position:absolute;right:60px;bottom:80px;width:280px;height:280px;border-radius:999px;background:${a(s.t, .16)};filter:blur(54px)"></div>
  <div style="position:relative;height:100%;display:flex;flex-direction:column">
    <div style="display:flex;align-items:center;justify-content:space-between">
      <div style="font-size:18px;letter-spacing:.16em;text-transform:uppercase;color:rgba(255,255,255,.56)">identidade oficial</div>
      <div style="width:112px;height:8px;border-radius:999px;background:${a('#ffffff', .1)}"></div>
    </div>
    <div style="margin-top:54px;display:grid;grid-template-columns:1.08fr .92fr;gap:48px;align-items:center">
      <div style="min-height:650px;padding:34px;border-radius:42px;background:linear-gradient(155deg,${a(s.p, .24)} 0%,${a(s.s, .2)} 46%,${a(s.t, .22)} 100%),rgba(22,22,22,.92);border:1px solid rgba(255,255,255,.09);position:relative;overflow:hidden">
        <div style="position:absolute;inset:18px;border-radius:30px;border:1px solid rgba(255,255,255,.05)"></div>
        <div style="position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);width:380px;height:380px;border-radius:92px;background:rgba(255,255,255,.07);display:grid;place-items:center;border:1px solid rgba(255,255,255,.08);box-shadow:0 32px 72px rgba(0,0,0,.28),inset 0 1px 0 rgba(255,255,255,.05)">
          <img src="${brandSquarePrimary}" alt="" style="width:280px;height:280px" />
        </div>
      </div>
      <div style="display:flex;flex-direction:column;justify-content:center;padding-right:8px">
        <img src="${brandHorizontalPrimary}" alt="Mube" style="width:420px;height:auto;display:block" />
        <div style="margin-top:32px;max-width:370px;color:rgba(255,255,255,.8);font-size:40px;line-height:1.16;letter-spacing:-.025em">Marca forte para conectar talentos reais.</div>
        <div style="display:flex;gap:12px;flex-wrap:wrap;margin-top:34px">
          <div class="chip" style="position:relative;left:auto;top:auto;transform:none;background:${a(s.p, .14)};box-shadow:none"><b style="background:${s.p}"></b>descoberta</div>
          <div class="chip" style="position:relative;left:auto;top:auto;transform:none;background:${a(s.s, .14)};box-shadow:none"><b style="background:${s.s}"></b>matchpoint</div>
          <div class="chip" style="position:relative;left:auto;top:auto;transform:none;background:${a(s.t, .14)};box-shadow:none"><b style="background:${s.t}"></b>chat</div>
        </div>
      </div>
    </div>
  </div>
</div>
<div style="position:absolute;left:76px;top:2098px;width:1090px;display:flex;align-items:flex-end;justify-content:space-between">
  <div style="max-width:520px;font-family:'Poppins Local',sans-serif;font-size:52px;font-weight:700;line-height:.98;letter-spacing:-.04em">Perfis, busca e conversa no mesmo fluxo.</div>
  <div style="max-width:340px;color:rgba(255,255,255,.62);font-size:24px;line-height:1.3;text-align:right">M&uacute;sicos, bandas, est&uacute;dios e contratantes em uma experi&ecirc;ncia s&oacute;bria e direta.</div>
</div>
`;

const slides = [
  { id: 1, p: '#E8466C', s: '#6E42D6', t: '#2F4EA7', mesh: ['18% 16%', '84% 24%', '50% 84%'], draw: scene1 },
  { id: 2, p: '#E8466C', s: '#6E42D6', t: '#2F4EA7', mesh: ['12% 22%', '88% 16%', '74% 82%'], draw: scene2 },
  { id: 3, p: '#E8466C', s: '#6E42D6', t: '#2F4EA7', mesh: ['50% 18%', '82% 48%', '32% 78%'], draw: scene3 },
  { id: 4, p: '#E8466C', s: '#6E42D6', t: '#2F4EA7', mesh: ['16% 14%', '88% 28%', '18% 86%'], draw: scene4 },
  { id: 5, p: '#E8466C', s: '#6E42D6', t: '#2F4EA7', mesh: ['14% 18%', '84% 18%', '82% 82%'], draw: scene5 },
  { id: 6, p: '#E8466C', s: '#6E42D6', t: '#2F4EA7', mesh: ['20% 18%', '86% 24%', '88% 80%'], draw: scene6 },
  { id: 7, p: '#E8466C', s: '#6E42D6', t: '#2F4EA7', mesh: ['16% 20%', '88% 22%', '82% 84%'], draw: scene7 },
];

async function ensureOut() {
  await fs.promises.mkdir(OUT, { recursive: true });
}

async function validate(file) {
  const m = await sharp(file).metadata();
  if (m.width !== W || m.height !== H) {
    throw new Error(`Unexpected size for ${path.basename(file)}: ${m.width}x${m.height}`);
  }
}

async function main() {
  await ensureOut();
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
  try {
    for (const slide of slides) {
      const page = await ctx.newPage();
      const out = path.join(OUT, `store_${slide.id}.png`);
      console.log(`Generating ${path.basename(out)}...`);
      await page.setContent(html(slide, slide.draw(slide)), { waitUntil: 'load' });
      await page.evaluate(async () => { await document.fonts.ready; });
      await page.waitForTimeout(120);
      await page.screenshot({ path: out, type: 'png' });
      await validate(out);
      await page.close();
    }
  } finally {
    await browser.close();
  }
  console.log(`Generated ${TOTAL} screenshots in ${OUT}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
