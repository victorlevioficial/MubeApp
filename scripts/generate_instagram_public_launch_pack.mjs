import fs from 'fs';
import path from 'path';
import { fileURLToPath, pathToFileURL } from 'url';

import { chromium } from 'playwright';
import sharp from 'sharp';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const OUT_DIR = path.join(ROOT, 'social_media', 'instagram_public_launch_20260311');
const HTML_DIR = path.join(OUT_DIR, 'html');
const EXPORT_DIR = path.join(OUT_DIR, 'exports');
const PREVIEW = path.join(OUT_DIR, 'preview.png');
const W = 1080;
const H = 1350;

const extMime = {
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.woff2': 'font/woff2',
};

const read = (rel) => fs.readFileSync(path.join(ROOT, rel));
const uri = (
  rel,
  mime = extMime[path.extname(rel).toLowerCase()] ?? 'application/octet-stream',
) => `data:${mime};base64,${read(rel).toString('base64')}`;
const svg = (value) => `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(value)}`;
const rgb = (hex) => {
  const normalized = hex.replace('#', '');
  return [0, 2, 4].map((index) =>
    Number.parseInt(normalized.slice(index, index + 2), 16),
  );
};
const a = (hex, alpha) => {
  const [r, g, b] = rgb(hex);
  return `rgba(${r},${g},${b},${alpha})`;
};
const ff = (family, weight, rel) =>
  `@font-face{font-family:'${family}';src:url("${uri(rel, 'font/woff2')}") format('woff2');font-weight:${weight};font-style:normal;font-display:swap;}`;

const fonts = [
  ff(
    'Poppins Local',
    600,
    'node_modules/@fontsource/poppins/files/poppins-latin-600-normal.woff2',
  ),
  ff(
    'Poppins Local',
    700,
    'node_modules/@fontsource/poppins/files/poppins-latin-700-normal.woff2',
  ),
  ff(
    'Poppins Local',
    800,
    'node_modules/@fontsource/poppins/files/poppins-latin-800-normal.woff2',
  ),
  ff(
    'Inter Local',
    500,
    'node_modules/@fontsource/inter/files/inter-latin-500-normal.woff2',
  ),
  ff(
    'Inter Local',
    600,
    'node_modules/@fontsource/inter/files/inter-latin-600-normal.woff2',
  ),
  ff(
    'Inter Local',
    700,
    'node_modules/@fontsource/inter/files/inter-latin-700-normal.woff2',
  ),
].join('');

const noise = svg(
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 320"><filter id="n"><feTurbulence type="fractalNoise" baseFrequency=".84" numOctaves="2" stitchTiles="stitch"/></filter><rect width="100%" height="100%" filter="url(#n)" opacity=".82"/></svg>',
);

const assets = {
  brandVerticalPrimary: uri(
    'assets/images/logos_svg/brand/brand-vertical-primary.svg',
    'image/svg+xml',
  ),
  brandWordmarkLight: uri(
    'assets/images/logos_svg/brand/brand-wordmark-light.svg',
    'image/svg+xml',
  ),
  brandHorizontalWhite: uri(
    'assets/images/logos_svg/brand/brand-horizontal-white-cutout.svg',
    'image/svg+xml',
  ),
  logoIconPrimary: uri(
    'assets/images/logos_svg/brand/brand-icon-primary.svg',
    'image/svg+xml',
  ),
  onboarding: uri('assets/images/screenshots/ss1.png', 'image/png'),
  feed: uri('assets/images/screenshots/ss2.png', 'image/png'),
  matchpoint: uri('assets/images/screenshots/ss3.png', 'image/png'),
  profile: uri('assets/images/screenshots/ss4.png', 'image/png'),
  search: uri('assets/images/screenshots/ss5.png', 'image/png'),
  gallery: uri('assets/images/screenshots/ss6.png', 'image/png'),
};

const css = `
${fonts}
*{box-sizing:border-box}
html,body{margin:0;width:${W}px;height:${H}px;overflow:hidden}
body{background:#0A0A0A;color:#FFFFFF;font-family:'Inter Local',system-ui,sans-serif}
.page{position:relative;width:100%;height:100%;overflow:hidden;isolation:isolate;background:#0A0A0A}
.page:before{content:'';position:absolute;inset:0;background-image:url("${noise}");background-size:320px 320px;opacity:.085;mix-blend-mode:soft-light;z-index:1}
.page:after{content:'';position:absolute;inset:0;background:linear-gradient(180deg,rgba(10,10,10,.06) 0%,rgba(10,10,10,0) 24%),linear-gradient(0deg,rgba(10,10,10,.34) 0%,rgba(10,10,10,0) 26%);z-index:2}
.mesh,.orb,.ring,.grid,.txt,.word,.panel,.chip,.device,.crop,.bubble,.disc,.brand,.meter,.callout,.connector{position:absolute}
.mesh{inset:0;z-index:0}
.orb{border-radius:999px;filter:blur(86px);mix-blend-mode:screen;z-index:3}
.ring{border-radius:999px;border:1px solid rgba(255,255,255,.08);z-index:4}
.grid{background-image:radial-gradient(circle,rgba(255,255,255,.9) 1.2px,transparent 1.45px);background-size:20px 20px;opacity:.1;z-index:4}
.meter{height:60px;opacity:.46;z-index:6;background-repeat:no-repeat;background-size:100% 100%}
.txt{z-index:24}
.txt.c{text-align:center}
.txt.r{text-align:right}
.k{font-size:15px;font-weight:700;letter-spacing:.26em;text-transform:uppercase}
.h{margin-top:18px;font-family:'Poppins Local',sans-serif;font-size:108px;line-height:.9;font-weight:700;letter-spacing:-.065em}
.s{margin-top:22px;color:rgba(255,255,255,.7);font-size:31px;line-height:1.28;letter-spacing:-.018em}
.word{font-family:'Poppins Local',sans-serif;font-weight:800;letter-spacing:-.08em;color:transparent;-webkit-text-stroke:1px rgba(255,255,255,.08);z-index:5}
.panel{padding:28px;border-radius:36px;border:1px solid rgba(255,255,255,.08);background:linear-gradient(180deg,rgba(255,255,255,.06) 0%,rgba(255,255,255,.02) 100%),rgba(20,20,20,.84);box-shadow:0 30px 80px rgba(0,0,0,.3);backdrop-filter:blur(24px);z-index:20}
.panel .ey{font-size:13px;font-weight:700;letter-spacing:.18em;text-transform:uppercase;color:rgba(255,255,255,.48)}
.panel .tt{margin-top:14px;font-family:'Poppins Local',sans-serif;font-size:44px;line-height:.98;font-weight:700;letter-spacing:-.05em}
.panel .cp{margin-top:10px;color:rgba(255,255,255,.7);font-size:24px;line-height:1.28}
.panel .mini-row{display:flex;align-items:center;gap:14px;margin-top:14px}
.panel .icon{width:58px;height:58px;border-radius:18px;display:grid;place-items:center;color:#FFFFFF;font-weight:700}
.panel .list-line{display:flex;justify-content:space-between;gap:18px;padding:16px 0;border-top:1px solid rgba(255,255,255,.08);font-size:22px;color:rgba(255,255,255,.88)}
.panel .list-line:first-child{border-top:0;padding-top:0}
.panel .tiny{color:rgba(255,255,255,.52);font-size:16px;letter-spacing:.14em;text-transform:uppercase}
.chip{display:inline-flex;align-items:center;gap:10px;padding:12px 18px;border-radius:999px;border:1px solid rgba(255,255,255,.1);font-size:20px;font-weight:700;color:rgba(255,255,255,.94);box-shadow:0 16px 42px rgba(0,0,0,.22);backdrop-filter:blur(18px);z-index:24}
.chip b{width:8px;height:8px;border-radius:999px;display:block}
.crop{overflow:hidden;border-radius:34px;border:1px solid rgba(255,255,255,.1);background:linear-gradient(180deg,rgba(255,255,255,.06) 0%,rgba(255,255,255,.02) 100%),rgba(20,20,20,.84);box-shadow:0 24px 72px rgba(0,0,0,.32);z-index:18}
.crop img,.device img,.brand img,.disc img{display:block;width:100%;height:100%;object-fit:cover}
.device{transform-origin:center center;z-index:18}
.device .glow{position:absolute;left:26px;top:42px;width:calc(100% - 52px);height:calc(100% - 84px);border-radius:110px;filter:blur(64px);opacity:.86}
.device .frame{position:relative;width:100%;height:100%;padding:10px;border-radius:64px;border:1px solid rgba(255,255,255,.15);background:linear-gradient(180deg,rgba(255,255,255,.15) 0%,rgba(255,255,255,.03) 100%),rgba(15,15,18,.92);box-shadow:0 46px 120px rgba(0,0,0,.5),inset 0 1px 0 rgba(255,255,255,.08);overflow:hidden}
.device .screen{position:relative;width:100%;height:100%;border-radius:52px;overflow:hidden;background:#0A0A0A}
.device .screen:after{content:'';position:absolute;inset:0;background:linear-gradient(132deg,rgba(255,255,255,.16) 0%,rgba(255,255,255,0) 30%);mix-blend-mode:screen;opacity:.42}
.device .notch{position:absolute;top:14px;left:50%;width:132px;height:28px;transform:translateX(-50%);border-radius:999px;background:rgba(8,8,10,.98);z-index:2}
.bubble{padding:22px 24px;border-radius:34px;border:1px solid rgba(255,255,255,.08);background:linear-gradient(180deg,rgba(255,255,255,.08) 0%,rgba(255,255,255,.02) 100%),rgba(20,20,20,.84);box-shadow:0 22px 58px rgba(0,0,0,.26);backdrop-filter:blur(20px);z-index:22}
.bubble .sm{font-size:14px;font-weight:700;letter-spacing:.16em;text-transform:uppercase;color:rgba(255,255,255,.5)}
.bubble .bt{margin-top:10px;font-family:'Poppins Local',sans-serif;font-size:38px;line-height:1;letter-spacing:-.045em;font-weight:700}
.disc{display:grid;place-items:center;border-radius:999px;border:1px solid rgba(255,255,255,.1);box-shadow:0 24px 72px rgba(0,0,0,.26);z-index:20;overflow:hidden}
.callout{padding:14px 16px;border-radius:20px;border:1px solid rgba(255,255,255,.08);background:rgba(20,20,20,.82);box-shadow:0 20px 52px rgba(0,0,0,.26);z-index:24}
.callout .hd{font-size:14px;font-weight:700;letter-spacing:.16em;text-transform:uppercase;color:rgba(255,255,255,.5)}
.callout .tx{margin-top:8px;font-family:'Poppins Local',sans-serif;font-size:28px;line-height:1;font-weight:700;letter-spacing:-.04em}
.connector{height:1px;transform-origin:left center;z-index:22;opacity:.6}
.brand{z-index:20}
.brand img{width:100%;height:auto}
.feature-list{display:flex;flex-direction:column;gap:14px}
.feature-item{display:flex;align-items:flex-start;gap:16px;padding:18px 0;border-top:1px solid rgba(255,255,255,.08)}
.feature-item:first-child{padding-top:0;border-top:0}
.feature-dot{width:18px;height:18px;border-radius:999px;flex:0 0 auto;margin-top:5px}
.feature-copy strong{display:block;font-size:28px;font-weight:700;line-height:1.05}
.feature-copy span{display:block;margin-top:6px;font-size:18px;line-height:1.28;color:rgba(255,255,255,.68)}
`;

const meterSvg = (color) =>
  svg(
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 60">${Array.from({
      length: 48,
    })
      .map((_, index) => {
        const x = 10 + index * 16;
        const height = [12, 18, 28, 22, 36, 16, 30, 14][index % 8];
        const y = 60 - height;
        return `<rect x="${x}" y="${y}" width="10" height="${height}" rx="5" fill="${color}" opacity="${
          0.28 + (index % 5) * 0.08
        }"/>`;
      })
      .join('')}</svg>`,
  );

const mesh = (slide) =>
  `background:
    radial-gradient(circle at ${slide.mesh[0]},${a(slide.primary, 0.2)} 0%,transparent 34%),
    radial-gradient(circle at ${slide.mesh[1]},${a(slide.secondary, 0.16)} 0%,transparent 30%),
    radial-gradient(circle at ${slide.mesh[2]},${a(slide.tertiary, 0.14)} 0%,transparent 36%),
    linear-gradient(${slide.angle}deg,#1F1F1F 0%,#141414 42%,#0A0A0A 100%)`;

const hero = ({
  l,
  t,
  w,
  k,
  h,
  s = '',
  c = '#E8466C',
  align = 'left',
  size = 108,
  sub = 31,
}) =>
  `<div class="txt${align === 'center' ? ' c' : align === 'right' ? ' r' : ''}" style="left:${l}px;top:${t}px;width:${w}px;text-align:${align};"><div class="k" style="color:${c}">${k}</div><div class="h" style="font-size:${size}px">${h}</div>${s ? `<div class="s" style="font-size:${sub}px">${s}</div>` : ''}</div>`;

const orb = (style) => `<div class="orb" style="${style}"></div>`;
const ring = (style) => `<div class="ring" style="${style}"></div>`;
const grid = (style) => `<div class="grid" style="${style}"></div>`;
const meter = ({ l, t, w, c, o = 0.48 }) =>
  `<div class="meter" style="left:${l}px;top:${t}px;width:${w}px;background-image:url('${meterSvg(
    c,
  )}');opacity:${o}"></div>`;
const word = ({ l, t, txt, size, rot = 0, o = 0.08 }) =>
  `<div class="word" style="left:${l}px;top:${t}px;font-size:${size}px;transform:rotate(${rot}deg);-webkit-text-stroke:1px rgba(255,255,255,${o})">${txt}</div>`;
const chip = ({ l, t, txt, c, rot = 0, alpha = 0.12, z = 24 }) =>
  `<div class="chip" style="left:${l}px;top:${t}px;transform:rotate(${rot}deg);background:${a(
    c,
    alpha,
  )};box-shadow:0 16px 42px ${a(c, 0.14)};z-index:${z}"><b style="background:${c}"></b>${txt}</div>`;
const panel = ({
  l,
  t,
  w,
  h,
  body,
  c,
  rot = 0,
  z = 20,
  pad = 28,
  rad = 36,
  alpha = 0.16,
}) =>
  `<div class="panel" style="left:${l}px;top:${t}px;width:${w}px;${
    h ? `height:${h}px;` : ''
  }transform:rotate(${rot}deg);border-color:${a(c, 0.16)};background:linear-gradient(180deg,${a(
    c,
    alpha,
  )} 0%,rgba(255,255,255,.02) 100%),rgba(20,20,20,.84);padding:${pad}px;border-radius:${rad}px;z-index:${z}">${body}</div>`;
const crop = ({
  l,
  t,
  w,
  h,
  src,
  rot = 0,
  z = 18,
  pos = 'center center',
  rad = 34,
}) =>
  `<div class="crop" style="left:${l}px;top:${t}px;width:${w}px;height:${h}px;border-radius:${rad}px;transform:rotate(${rot}deg);z-index:${z}"><img src="${src}" alt="" style="object-position:${pos}"></div>`;
const device = ({ l, t, w, src, c, rot = 0, z = 18, pos = 'center top' }) => {
  const h = Math.round(w * 2.02);
  return `<div class="device" style="left:${l}px;top:${t}px;width:${w}px;height:${h}px;transform:rotate(${rot}deg);z-index:${z}"><div class="glow" style="background:${a(
    c,
    0.22,
  )}"></div><div class="frame"><div class="screen"><div class="notch"></div><img src="${src}" alt="" style="object-position:${pos}"></div></div></div>`;
};
const bubble = ({ l, t, w, txt, c, small = '', rot = 0, z = 22 }) =>
  `<div class="bubble" style="left:${l}px;top:${t}px;width:${w}px;transform:rotate(${rot}deg);border-color:${a(
    c,
    0.16,
  )};background:linear-gradient(180deg,${a(
    c,
    0.16,
  )} 0%,rgba(255,255,255,.02) 100%),rgba(20,20,20,.84);z-index:${z}">${
    small ? `<div class="sm">${small}</div>` : ''
  }<div class="bt">${txt}</div></div>`;
const disc = ({ l, t, s, c, body, z = 20 }) =>
  `<div class="disc" style="left:${l}px;top:${t}px;width:${s}px;height:${s}px;background:radial-gradient(circle at 28% 22%,rgba(255,255,255,.09) 0%,transparent 34%),linear-gradient(160deg,${a(
    c,
    0.28,
  )} 0%,rgba(20,20,20,.84) 100%);border-color:${a(c, 0.16)};z-index:${z}">${body}</div>`;
const callout = ({ l, t, w, title, text, c }) =>
  `<div class="callout" style="left:${l}px;top:${t}px;width:${w}px;border-color:${a(
    c,
    0.16,
  )};background:linear-gradient(180deg,${a(
    c,
    0.12,
  )} 0%,rgba(20,20,20,.84) 100%)"><div class="hd">${title}</div><div class="tx">${text}</div></div>`;
const connector = ({ l, t, w, rot = 0, c }) =>
  `<div class="connector" style="left:${l}px;top:${t}px;width:${w}px;transform:rotate(${rot}deg);background:linear-gradient(90deg,${a(
    c,
    0.5,
  )} 0%,rgba(255,255,255,0) 100%)"></div>`;

const slide01 = (slide) => `
${orb(`left:-140px;top:-20px;width:420px;height:420px;background:${a(slide.primary, 0.24)}`)}
${orb(`right:-110px;top:180px;width:360px;height:360px;background:${a(slide.secondary, 0.18)}`)}
${orb(`right:70px;bottom:60px;width:300px;height:300px;background:${a(slide.tertiary, 0.14)}`)}
${grid('left:820px;top:126px;width:120px;height:180px')}
${word({ l: 690, t: 866, txt: 'CENA', size: 246, rot: -90, o: 0.12 })}
${meter({ l: 86, t: 1236, w: 380, c: slide.primary, o: 0.42 })}
${hero({
  l: 86,
  t: 118,
  w: 760,
  k: 'PRA QUEM VIVE DE MUSICA',
  h: 'a cena nao<br>precisa mais<br>pedir licenca.',
  s: 'Mube conecta musicos, bandas, estudios e contratantes sem virar vitrine vazia.',
  c: slide.primary,
  size: 112,
  sub: 32,
})}
${panel({
  l: 616,
  t: 1028,
  w: 348,
  c: slide.primary,
  rot: -4,
  body: '<div class="ey">SEM CERIMONIA</div><div class="tt" style="font-size:42px">projeto,<br>palco,<br>oportunidade.</div>',
})}
${disc({
  l: 748,
  t: 434,
  s: 176,
  c: slide.primary,
  body: `<div style="width:88px;height:88px"><img src="${assets.logoIconPrimary}" alt=""></div>`,
})}
${chip({ l: 86, t: 1100, txt: 'menos ruido', c: slide.primary })}
${chip({ l: 282, t: 1128, txt: 'mais contexto', c: slide.secondary, rot: 2 })}
${chip({ l: 494, t: 1092, txt: 'mais cena real', c: slide.tertiary, rot: -2 })}
`;

const slide02 = (slide) => `
${orb(`left:-110px;top:370px;width:340px;height:340px;background:${a(slide.primary, 0.18)}`)}
${orb(`right:-80px;top:560px;width:360px;height:360px;background:${a(slide.tertiary, 0.14)}`)}
${grid('left:742px;top:182px;width:110px;height:150px')}
${hero({
  l: 86,
  t: 102,
  w: 688,
  k: 'SEM TIPO CERTO NAO TEM JEITO ERRADO',
  h: 'voce entra<br>do seu jeito.',
  s: 'Perfil individual, banda, estudio ou contratante. O resto se conecta depois.',
  c: slide.primary,
  size: 94,
  sub: 29,
})}
${crop({
  l: 780,
  t: 448,
  w: 214,
  h: 736,
  src: assets.onboarding,
  pos: 'center top',
  rot: 6,
  rad: 36,
  z: 14,
})}
${panel({
  l: 86,
  t: 516,
  w: 378,
  h: 214,
  c: slide.primary,
  rot: -3,
  body: '<div class="icon" style="background:rgba(232,70,108,.28)">M</div><div class="tt">musico solo</div><div class="cp">voz, instrumento, producao ou tecnica.</div>',
})}
${panel({
  l: 522,
  t: 474,
  w: 386,
  h: 222,
  c: slide.secondary,
  rot: 4,
  body: '<div class="icon" style="background:rgba(192,38,211,.28)">B</div><div class="tt">banda</div><div class="cp">grupo, projeto autoral ou som de estrada.</div>',
})}
${panel({
  l: 104,
  t: 792,
  w: 388,
  h: 214,
  c: slide.warning,
  rot: 2,
  body: '<div class="icon" style="background:rgba(245,158,11,.24)">E</div><div class="tt">estudio</div><div class="cp">gravacao, mix, master e estrutura pra valer.</div>',
})}
${panel({
  l: 540,
  t: 834,
  w: 388,
  h: 214,
  c: slide.info,
  rot: -2,
  body: '<div class="icon" style="background:rgba(59,130,246,.24)">C</div><div class="tt">contratante</div><div class="cp">evento, casa, produtora ou corre de casting.</div>',
})}
`;

const slide03 = (slide) => `
${orb(`left:-100px;top:650px;width:340px;height:340px;background:${a(slide.primary, 0.22)}`)}
${orb(`right:66px;top:420px;width:320px;height:320px;background:${a(slide.info, 0.16)}`)}
${ring(`left:126px;top:596px;width:280px;height:280px;border-color:${a(slide.primary, 0.12)}`)}
${ring(`left:86px;top:556px;width:360px;height:360px;border-color:${a(slide.secondary, 0.09)}`)}
${hero({
  l: 86,
  t: 110,
  w: 520,
  k: 'MATCHPOINT',
  h: 'deu liga?<br>vira match.',
  s: 'Descoberta com contexto, afinidade e gente perto de voce.',
  c: slide.primary,
  size: 102,
  sub: 29,
})}
${disc({
  l: 104,
  t: 622,
  s: 224,
  c: slide.primary,
  body: '<div style="font-family:\'Poppins Local\',sans-serif;font-size:58px;line-height:.94;letter-spacing:-.06em;text-align:center">deu<br>liga?</div>',
})}
${panel({
  l: 86,
  t: 954,
  w: 404,
  c: slide.secondary,
  body: '<div class="ey">SEM DRAMA</div><div class="tt">curte, volta<br>ou passa.</div><div class="cp">A decisao aparece rapido quando o perfil diz algo de verdade.</div>',
})}
${chip({ l: 86, t: 1198, txt: 'curte', c: slide.primary })}
${chip({ l: 222, t: 1220, txt: 'volta', c: slide.secondary, rot: 2 })}
${chip({ l: 360, t: 1192, txt: 'passa', c: slide.info, rot: -2 })}
${device({
  l: 642,
  t: 356,
  w: 316,
  src: assets.matchpoint,
  c: slide.primary,
  rot: 8,
  pos: 'center top',
})}
`;

const slide04 = (slide) => `
${orb(`right:-80px;top:140px;width:360px;height:360px;background:${a(slide.info, 0.18)}`)}
${orb(`left:-120px;bottom:160px;width:320px;height:320px;background:${a(slide.primary, 0.14)}`)}
${meter({ l: 720, t: 1228, w: 280, c: slide.info, o: 0.38 })}
${hero({
  l: 86,
  t: 110,
  w: 520,
  k: 'BUSCA INTELIGENTE',
  h: 'filtra a cena<br>do seu jeito.',
  s: 'Categoria, instrumento, genero e especialidade sem virar busca cega.',
  c: slide.primary,
  size: 96,
  sub: 29,
})}
${panel({
  l: 86,
  t: 412,
  w: 908,
  c: slide.info,
  body: '<div class="ey">FILTROS VIVOS</div><div class="tt" style="font-size:38px">voz + banda + rj + pop</div>',
})}
${crop({
  l: 86,
  t: 566,
  w: 438,
  h: 654,
  src: assets.search,
  pos: 'center top',
  rot: -3,
  rad: 42,
})}
${panel({
  l: 588,
  t: 622,
  w: 340,
  c: slide.primary,
  body: '<div class="ey">SEM EXCESSO</div><div class="tt" style="font-size:40px">cantores,<br>DJs,<br>guitarristas,<br>produtores.</div>',
})}
${chip({ l: 604, t: 1118, txt: 'baixo', c: slide.info })}
${chip({ l: 714, t: 1146, txt: 'rj', c: slide.primary, rot: 2 })}
${chip({ l: 790, t: 1104, txt: 'pop', c: slide.secondary, rot: -2 })}
${chip({ l: 632, t: 1204, txt: 'estudio', c: slide.warning })}
`;

const slide05 = (slide) => `
${orb(`left:240px;top:240px;width:320px;height:320px;background:${a(slide.primary, 0.16)}`)}
${orb(`right:80px;bottom:190px;width:320px;height:320px;background:${a(slide.info, 0.12)}`)}
${grid('left:842px;top:178px;width:120px;height:140px')}
${hero({
  l: 86,
  t: 110,
  w: 730,
  k: 'PERFIL COMPLETO',
  h: 'o que voce faz<br>fica evidente.',
  s: 'Instrumentos, funcoes, cidade e contexto numa leitura rapida.',
  c: slide.primary,
  size: 92,
  sub: 29,
})}
${crop({
  l: 554,
  t: 318,
  w: 410,
  h: 846,
  src: assets.profile,
  pos: 'center top',
  rot: 4,
  rad: 42,
})}
${callout({ l: 92, t: 544, w: 308, title: 'INSTRUMENTOS', text: 'violao, guitarra, baixo', c: slide.primary })}
${connector({ l: 392, t: 620, w: 156, rot: 6, c: slide.primary })}
${callout({ l: 122, t: 742, w: 328, title: 'FUNCOES TECNICAS', text: 'produtor, beatmaker, diretor musical', c: slide.secondary })}
${connector({ l: 438, t: 816, w: 136, rot: 14, c: slide.secondary })}
${callout({ l: 92, t: 972, w: 282, title: 'CIDADE', text: 'Rio de Janeiro', c: slide.info })}
${connector({ l: 370, t: 1034, w: 186, rot: -6, c: slide.info })}
`;

const slide06 = (slide) => `
${orb(`left:-90px;top:120px;width:360px;height:360px;background:${a(slide.primary, 0.18)}`)}
${orb(`right:-60px;top:560px;width:320px;height:320px;background:${a(slide.secondary, 0.14)}`)}
${meter({ l: 86, t: 1224, w: 340, c: slide.primary, o: 0.36 })}
${hero({
  l: 86,
  t: 108,
  w: 470,
  k: 'GALERIA VIVA',
  h: 'mostre palco,<br>bastidor e entrega.',
  s: 'Fotos e videos fazem o perfil parecer gente, nao cadastro.',
  c: slide.primary,
  size: 88,
  sub: 28,
})}
${chip({ l: 86, t: 458, txt: 'fotos', c: slide.primary })}
${chip({ l: 200, t: 486, txt: 'videos', c: slide.info, rot: 2 })}
${crop({ l: 556, t: 140, w: 388, h: 496, src: assets.gallery, pos: 'center 16%', rot: 5, rad: 38 })}
${crop({ l: 94, t: 612, w: 314, h: 242, src: assets.gallery, pos: 'center 46%', rot: -4, rad: 30 })}
${crop({ l: 440, t: 676, w: 250, h: 206, src: assets.gallery, pos: 'center 64%', rot: 3, rad: 28 })}
${crop({ l: 726, t: 730, w: 284, h: 382, src: assets.gallery, pos: 'center 82%', rot: -5, rad: 32 })}
${crop({ l: 148, t: 916, w: 422, h: 270, src: assets.gallery, pos: 'center 94%', rot: 2, rad: 32 })}
`;

const slide07 = (slide) => `
${orb(`left:-120px;top:600px;width:340px;height:340px;background:${a(slide.primary, 0.18)}`)}
${orb(`right:-80px;top:500px;width:340px;height:340px;background:${a(slide.info, 0.14)}`)}
${word({ l: 586, t: 1020, txt: 'GIG', size: 182, rot: 0, o: 0.08 })}
${hero({
  l: 86,
  t: 110,
  w: 760,
  k: 'OPORTUNIDADE REAL',
  h: 'do match ao papo.<br>do papo a gig.',
  s: 'Conversa direta pra ensaio, show, projeto novo ou contratacao.',
  c: slide.primary,
  size: 90,
  sub: 29,
})}
${panel({
  l: 86,
  t: 474,
  w: 422,
  h: 554,
  c: slide.primary,
  body: `
    <div class="ey">GIG ABERTA</div>
    <div class="tt">Casa da Lapa quer banda pop ao vivo.</div>
    <div class="cp">RJ . sexta . cache a combinar . lineup enxuto.</div>
    <div class="mini-row"><div class="icon" style="background:rgba(232,70,108,.28)">1</div><div class="tiny">VOCAL + BAIXO</div></div>
    <div class="mini-row"><div class="icon" style="background:rgba(59,130,246,.24)">2</div><div class="tiny">SET DE 90 MIN</div></div>
    <div class="mini-row"><div class="icon" style="background:rgba(34,197,94,.24)">3</div><div class="tiny">MONTAGEM RAPIDA</div></div>
    <div style="margin-top:28px;padding:20px 22px;border-radius:24px;background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.06)">
      <div class="tiny">CTA</div>
      <div class="tt" style="font-size:32px;margin-top:8px">iniciar conversa</div>
    </div>`,
})}
${bubble({ l: 596, t: 578, w: 314, txt: 'tem batera?', c: slide.info, small: '10:18' })}
${bubble({ l: 492, t: 758, w: 402, txt: 'sim. e fecha set rapido.', c: slide.primary, small: '10:19', rot: -2 })}
${bubble({ l: 638, t: 968, w: 286, txt: 'vamos fechar.', c: slide.success, small: '10:21', rot: 2 })}
${chip({ l: 580, t: 1172, txt: 'ensaio', c: slide.primary })}
${chip({ l: 706, t: 1202, txt: 'show', c: slide.info, rot: 2 })}
${chip({ l: 816, t: 1164, txt: 'banda', c: slide.secondary, rot: -2 })}
`;

const slide08 = (slide) => `
${orb(`left:-140px;top:160px;width:420px;height:420px;background:${a(slide.primary, 0.22)}`)}
${orb(`right:-110px;top:120px;width:360px;height:360px;background:${a(slide.secondary, 0.16)}`)}
${orb(`right:120px;bottom:110px;width:300px;height:300px;background:${a(slide.info, 0.14)}`)}
${grid('left:826px;top:174px;width:120px;height:180px')}
${hero({
  l: 138,
  t: 114,
  w: 812,
  k: 'SEM POSE DE REDE SOCIAL',
  h: 'bora fazer a<br>cena se encontrar?',
  s: 'O resto a gente deixa tocar.',
  c: slide.primary,
  size: 100,
  sub: 31,
  align: 'center',
})}
<div class="brand" style="left:340px;top:476px;width:400px"><img src="${assets.brandHorizontalWhite}" alt="Mube"></div>
${panel({
  l: 150,
  t: 690,
  w: 780,
  c: slide.primary,
  alpha: 0.1,
  body: `
    <div class="feature-list">
      <div class="feature-item">
        <div class="feature-dot" style="background:${slide.primary}"></div>
        <div class="feature-copy"><strong>matchpoint sem escuro</strong><span>descoberta por afinidade, genero e proximidade.</span></div>
      </div>
      <div class="feature-item">
        <div class="feature-dot" style="background:${slide.info}"></div>
        <div class="feature-copy"><strong>busca que corta ruido</strong><span>filtros por instrumento, perfil, cidade e especialidade.</span></div>
      </div>
      <div class="feature-item">
        <div class="feature-dot" style="background:${slide.secondary}"></div>
        <div class="feature-copy"><strong>perfil, chat e portfolio</strong><span>mostre trabalho e transforme interesse em conversa.</span></div>
      </div>
    </div>`,
})}
${chip({ l: 304, t: 1182, txt: 'entra', c: slide.primary })}
${chip({ l: 430, t: 1208, txt: 'monta', c: slide.secondary, rot: 2 })}
${chip({ l: 574, t: 1180, txt: 'conversa', c: slide.info, rot: -2 })}
`;

const slides = [
  {
    id: '01',
    slug: 'manifesto',
    primary: '#E8466C',
    secondary: '#C026D3',
    tertiary: '#3B82F6',
    info: '#3B82F6',
    success: '#22C55E',
    warning: '#F59E0B',
    angle: 178,
    mesh: ['16% 18%', '80% 20%', '82% 80%'],
    draw: slide01,
  },
  {
    id: '02',
    slug: 'quatro_perfis',
    primary: '#E8466C',
    secondary: '#C026D3',
    tertiary: '#3B82F6',
    info: '#3B82F6',
    success: '#22C55E',
    warning: '#F59E0B',
    angle: 164,
    mesh: ['18% 22%', '84% 24%', '54% 84%'],
    draw: slide02,
  },
  {
    id: '03',
    slug: 'matchpoint',
    primary: '#E8466C',
    secondary: '#C026D3',
    tertiary: '#3B82F6',
    info: '#3B82F6',
    success: '#22C55E',
    warning: '#F59E0B',
    angle: 176,
    mesh: ['18% 22%', '82% 24%', '70% 84%'],
    draw: slide03,
  },
  {
    id: '04',
    slug: 'busca_inteligente',
    primary: '#E8466C',
    secondary: '#C026D3',
    tertiary: '#3B82F6',
    info: '#3B82F6',
    success: '#22C55E',
    warning: '#F59E0B',
    angle: 188,
    mesh: ['14% 18%', '88% 18%', '82% 84%'],
    draw: slide04,
  },
  {
    id: '05',
    slug: 'perfil_completo',
    primary: '#E8466C',
    secondary: '#C026D3',
    tertiary: '#3B82F6',
    info: '#3B82F6',
    success: '#22C55E',
    warning: '#F59E0B',
    angle: 172,
    mesh: ['18% 18%', '84% 20%', '76% 84%'],
    draw: slide05,
  },
  {
    id: '06',
    slug: 'galeria_viva',
    primary: '#E8466C',
    secondary: '#C026D3',
    tertiary: '#3B82F6',
    info: '#3B82F6',
    success: '#22C55E',
    warning: '#F59E0B',
    angle: 170,
    mesh: ['16% 18%', '80% 20%', '88% 84%'],
    draw: slide06,
  },
  {
    id: '07',
    slug: 'gigs_e_chat',
    primary: '#E8466C',
    secondary: '#C026D3',
    tertiary: '#3B82F6',
    info: '#3B82F6',
    success: '#22C55E',
    warning: '#F59E0B',
    angle: 182,
    mesh: ['18% 18%', '82% 16%', '56% 84%'],
    draw: slide07,
  },
  {
    id: '08',
    slug: 'cta_final',
    primary: '#E8466C',
    secondary: '#C026D3',
    tertiary: '#3B82F6',
    info: '#3B82F6',
    success: '#22C55E',
    warning: '#F59E0B',
    angle: 178,
    mesh: ['16% 18%', '84% 18%', '78% 82%'],
    draw: slide08,
  },
];

function html(slide, body) {
  return `<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=${W},initial-scale=1"><title>Mube Instagram Public Launch ${slide.id}</title><style>${css}</style></head><body><main class="page"><div class="mesh" style="${mesh(
    slide,
  )}"></div>${body}</main></body></html>`;
}

async function ensureOut() {
  await fs.promises.mkdir(HTML_DIR, { recursive: true });
  await fs.promises.mkdir(EXPORT_DIR, { recursive: true });
}

async function validate(file, expectedWidth = W, expectedHeight = H) {
  const metadata = await sharp(file).metadata();
  if (metadata.width !== expectedWidth || metadata.height !== expectedHeight) {
    throw new Error(
      `Unexpected size for ${path.basename(file)}: ${metadata.width}x${metadata.height}`,
    );
  }
}

async function buildPreview(files) {
  const columns = 4;
  const rows = 2;
  const tileW = 270;
  const tileH = 337;
  const composites = await Promise.all(
    files.map(async (file, index) => ({
      input: await sharp(file).resize(tileW, tileH).png().toBuffer(),
      left: (index % columns) * tileW,
      top: Math.floor(index / columns) * tileH,
    })),
  );

  await sharp({
    create: {
      width: tileW * columns,
      height: tileH * rows,
      channels: 4,
      background: '#0A0A0A',
    },
  })
    .composite(composites)
    .png()
    .toFile(PREVIEW);

  await validate(PREVIEW, tileW * columns, tileH * rows);
}

async function main() {
  await ensureOut();

  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: W, height: H },
    deviceScaleFactor: 1,
    colorScheme: 'dark',
  });

  const outputs = [];

  try {
    for (const slide of slides) {
      const htmlContent = html(slide, slide.draw(slide));
      const htmlName = `${slide.id}_${slide.slug}.html`;
      const pngName = `${slide.id}_${slide.slug}.png`;
      const htmlPath = path.join(HTML_DIR, htmlName);
      const pngPath = path.join(EXPORT_DIR, pngName);
      await fs.promises.writeFile(htmlPath, htmlContent, 'utf8');

      const page = await context.newPage();
      await page.goto(pathToFileURL(htmlPath).href, { waitUntil: 'load' });
      await page.waitForTimeout(350);
      await page.screenshot({ path: pngPath, type: 'png' });
      await page.close();

      await validate(pngPath);
      outputs.push(pngPath);
      console.log(`Generated ${pngName}`);
    }
  } finally {
    await browser.close();
  }

  await buildPreview(outputs);
  console.log(`Generated ${outputs.length} instagram creatives in ${EXPORT_DIR}`);
  console.log(`Preview: ${PREVIEW}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
