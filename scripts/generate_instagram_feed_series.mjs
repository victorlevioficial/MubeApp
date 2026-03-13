import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { chromium } from 'playwright';
import sharp from 'sharp';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const OUT_DIR = path.join(ROOT, 'assets', 'images', 'instagram_feed_series');
const PREVIEW = path.join(OUT_DIR, 'feed_preview.png');
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
const shots = {
  1: uri('assets/images/screenshots/ss1.png', 'image/png'),
  2: uri('assets/images/screenshots/ss2.png', 'image/png'),
  3: uri('assets/images/screenshots/ss3.png', 'image/png'),
  5: uri('assets/images/screenshots/ss5.png', 'image/png'),
  6: uri('assets/images/screenshots/ss6.png', 'image/png'),
};

const css = `
${fonts}
*{box-sizing:border-box}
html,body{margin:0;width:${W}px;height:${H}px;overflow:hidden}
body{background:#08080a;color:#fff;font-family:'Inter Local',system-ui,sans-serif}
.page{position:relative;width:100%;height:100%;overflow:hidden;isolation:isolate}
.page:before{content:'';position:absolute;inset:0;background-image:url("${noise}");background-size:300px 300px;opacity:.09;mix-blend-mode:soft-light;z-index:1}
.page:after{content:'';position:absolute;inset:0;background:linear-gradient(180deg,rgba(8,8,10,.06) 0%,rgba(8,8,10,0) 22%),linear-gradient(0deg,rgba(8,8,10,.28) 0%,rgba(8,8,10,0) 24%);z-index:2}
.mesh,.orb,.ring,.grid,.txt,.word,.panel,.chip,.device,.crop,.bubble,.disc,.brand{position:absolute}
.mesh{inset:0;z-index:0}
.orb{border-radius:999px;filter:blur(76px);mix-blend-mode:screen;z-index:3}
.ring{border-radius:999px;border:1px solid rgba(255,255,255,.08);z-index:4}
.grid{background-image:radial-gradient(circle,rgba(255,255,255,.88) 1.25px,transparent 1.4px);background-size:20px 20px;opacity:.12;z-index:4}
.txt{z-index:22}
.txt.c{text-align:center}
.k{font-size:16px;font-weight:600;letter-spacing:.26em;text-transform:uppercase}
.h{margin-top:20px;font-family:'Poppins Local',sans-serif;font-size:108px;line-height:.9;font-weight:700;letter-spacing:-.065em}
.s{margin-top:24px;color:rgba(255,255,255,.68);font-size:34px;line-height:1.26;letter-spacing:-.018em}
.word{font-family:'Poppins Local',sans-serif;font-weight:800;letter-spacing:-.08em;color:transparent;-webkit-text-stroke:1px rgba(255,255,255,.08);z-index:4}
.panel{padding:28px;border-radius:36px;border:1px solid rgba(255,255,255,.08);background:linear-gradient(180deg,rgba(255,255,255,.06) 0%,rgba(255,255,255,.02) 100%),rgba(18,18,18,.82);box-shadow:0 30px 80px rgba(0,0,0,.28);backdrop-filter:blur(22px);z-index:20}
.panel .ey{font-size:13px;font-weight:600;letter-spacing:.18em;text-transform:uppercase;color:rgba(255,255,255,.46)}
.panel .tt{margin-top:16px;font-family:'Poppins Local',sans-serif;font-size:44px;line-height:.98;font-weight:700;letter-spacing:-.05em}
.panel .cp{margin-top:10px;color:rgba(255,255,255,.68);font-size:24px;line-height:1.28}
.panel .icon{width:58px;height:58px;border-radius:18px}
.chip{display:inline-flex;align-items:center;gap:10px;padding:12px 18px;border-radius:999px;border:1px solid rgba(255,255,255,.1);font-size:20px;font-weight:600;color:rgba(255,255,255,.92);box-shadow:0 16px 42px rgba(0,0,0,.22);backdrop-filter:blur(18px);z-index:24}
.chip b{width:8px;height:8px;border-radius:999px;display:block}
.crop{overflow:hidden;border-radius:34px;border:1px solid rgba(255,255,255,.1);background:linear-gradient(180deg,rgba(255,255,255,.06) 0%,rgba(255,255,255,.02) 100%),rgba(18,18,18,.84);box-shadow:0 24px 70px rgba(0,0,0,.3);z-index:18}
.crop img,.device img{display:block;width:100%;height:100%;object-fit:cover}
.device{transform-origin:center center;z-index:18}
.device .glow{position:absolute;left:26px;top:40px;width:calc(100% - 52px);height:calc(100% - 82px);border-radius:110px;filter:blur(64px);opacity:.84}
.device .frame{position:relative;width:100%;height:100%;padding:10px;border-radius:64px;border:1px solid rgba(255,255,255,.14);background:linear-gradient(180deg,rgba(255,255,255,.14) 0%,rgba(255,255,255,.03) 100%),rgba(15,15,18,.9);box-shadow:0 46px 110px rgba(0,0,0,.48),inset 0 1px 0 rgba(255,255,255,.08);overflow:hidden}
.device .screen{position:relative;width:100%;height:100%;border-radius:52px;overflow:hidden;background:#050505}
.device .screen:after{content:'';position:absolute;inset:0;background:linear-gradient(132deg,rgba(255,255,255,.16) 0%,rgba(255,255,255,0) 28%);mix-blend-mode:screen;opacity:.42}
.device .notch{position:absolute;top:14px;left:50%;width:132px;height:28px;transform:translateX(-50%);border-radius:999px;background:rgba(8,8,10,.98);z-index:2}
.bubble{padding:22px 24px;border-radius:34px;border:1px solid rgba(255,255,255,.08);background:linear-gradient(180deg,rgba(255,255,255,.08) 0%,rgba(255,255,255,.02) 100%),rgba(18,18,18,.82);box-shadow:0 22px 56px rgba(0,0,0,.26);backdrop-filter:blur(20px);z-index:22}
.bubble .sm{font-size:14px;font-weight:600;letter-spacing:.16em;text-transform:uppercase;color:rgba(255,255,255,.48)}
.bubble .bt{margin-top:10px;font-family:'Poppins Local',sans-serif;font-size:38px;line-height:1;letter-spacing:-.045em;font-weight:700}
.disc{display:grid;place-items:center;border-radius:999px;border:1px solid rgba(255,255,255,.1);box-shadow:0 24px 72px rgba(0,0,0,.26);z-index:20}
.brand img{display:block;width:100%;height:auto}
`;

const mesh = (slide) =>
  `background:radial-gradient(circle at ${slide.mesh[0]},${a(slide.p, .2)} 0%,transparent 34%),radial-gradient(circle at ${slide.mesh[1]},${a(slide.s, .16)} 0%,transparent 28%),radial-gradient(circle at ${slide.mesh[2]},${a(slide.t, .14)} 0%,transparent 36%),linear-gradient(${slide.angle}deg,#170d12 0%,#0c0b15 42%,#080b14 100%)`;

const hero = ({ l, t, w, k, h, s = '', c = '#E8466C', align = 'left', size = 108, sub = 34 }) =>
  `<div class="txt${align === 'center' ? ' c' : ''}" style="left:${l}px;top:${t}px;width:${w}px;text-align:${align};"><div class="k" style="color:${c}">${k}</div><div class="h" style="font-size:${size}px">${h}</div>${s ? `<div class="s" style="font-size:${sub}px">${s}</div>` : ''}</div>`;

const orb = (style) => `<div class="orb" style="${style}"></div>`;
const ring = (style) => `<div class="ring" style="${style}"></div>`;
const grid = (style) => `<div class="grid" style="${style}"></div>`;
const word = ({ l, t, txt, size, rot = 0, o = .08 }) =>
  `<div class="word" style="left:${l}px;top:${t}px;font-size:${size}px;transform:rotate(${rot}deg);-webkit-text-stroke:1px rgba(255,255,255,${o})">${txt}</div>`;
const chip = ({ l, t, txt, c, rot = 0, alpha = .12, z = 24 }) =>
  `<div class="chip" style="left:${l}px;top:${t}px;transform:rotate(${rot}deg);background:${a(c, alpha)};box-shadow:0 16px 42px ${a(c, .14)};z-index:${z}"><b style="background:${c}"></b>${txt}</div>`;
const panel = ({ l, t, w, h, body, c, rot = 0, z = 20, pad = 28, rad = 36, alpha = .16 }) =>
  `<div class="panel" style="left:${l}px;top:${t}px;width:${w}px;${h ? `height:${h}px;` : ''}transform:rotate(${rot}deg);border-color:${a(c, .16)};background:linear-gradient(180deg,${a(c, alpha)} 0%,rgba(255,255,255,.02) 100%),rgba(18,18,18,.82);padding:${pad}px;border-radius:${rad}px;z-index:${z}">${body}</div>`;
const crop = ({ l, t, w, h, src, rot = 0, z = 18, pos = 'center center', rad = 34 }) =>
  `<div class="crop" style="left:${l}px;top:${t}px;width:${w}px;height:${h}px;border-radius:${rad}px;transform:rotate(${rot}deg);z-index:${z}"><img src="${src}" alt="" style="object-position:${pos}"></div>`;
const device = ({ l, t, w, src, c, rot = 0, z = 18, pos = 'center top' }) => {
  const h = Math.round(w * 2.02);
  return `<div class="device" style="left:${l}px;top:${t}px;width:${w}px;height:${h}px;transform:rotate(${rot}deg);z-index:${z}"><div class="glow" style="background:${a(c, .22)}"></div><div class="frame"><div class="screen"><div class="notch"></div><img src="${src}" alt="" style="object-position:${pos}"></div></div></div>`;
};
const bubble = ({ l, t, w, txt, c, small = '', rot = 0, z = 22 }) =>
  `<div class="bubble" style="left:${l}px;top:${t}px;width:${w}px;transform:rotate(${rot}deg);border-color:${a(c, .16)};background:linear-gradient(180deg,${a(c, .16)} 0%,rgba(255,255,255,.02) 100%),rgba(18,18,18,.82);z-index:${z}">${small ? `<div class="sm">${small}</div>` : ''}<div class="bt">${txt}</div></div>`;
const disc = ({ l, t, s, c, body, z = 20 }) =>
  `<div class="disc" style="left:${l}px;top:${t}px;width:${s}px;height:${s}px;background:radial-gradient(circle at 28% 22%,rgba(255,255,255,.09) 0%,transparent 34%),linear-gradient(160deg,${a(c, .28)} 0%,rgba(18,18,18,.82) 100%);border-color:${a(c, .16)};z-index:${z}">${body}</div>`;

const scene1 = (s) => `
${orb(`left:-120px;top:-40px;width:420px;height:420px;background:${a(s.p, .22)}`)}
${orb(`right:-110px;top:160px;width:360px;height:360px;background:${a(s.s, .16)}`)}
${orb(`right:80px;bottom:80px;width:280px;height:280px;background:${a(s.t, .14)}`)}
${grid('left:810px;top:118px;width:120px;height:180px')}
${word({ l: 696, t: 860, txt: 'CENA', size: 238, rot: -90, o: .12 })}
${hero({
  l: 86,
  t: 118,
  w: 770,
  k: 'PRA QUEM VIVE DE MUSICA',
  h: 'a cena nao cabe<br>num direct<br>perdido',
  s: 'Mube junta musicos, bandas, estudios e contratantes no mesmo corre.',
  c: s.p,
  size: 118,
  sub: 34,
})}
${panel({
  l: 628,
  t: 1032,
  w: 322,
  c: s.p,
  rot: -4,
  body: `<div class="ey">SEM CERIMONIA</div><div class="tt" style="font-size:40px">projeto,<br>palco,<br>oportunidade.</div>`,
})}
${chip({ l: 86, t: 1114, txt: 'menos ruido', c: s.p })}
${chip({ l: 274, t: 1138, txt: 'mais contexto', c: s.s, rot: 2 })}
`;

const scene2 = (s) => `
${orb(`left:-140px;top:340px;width:360px;height:360px;background:${a(s.p, .18)}`)}
${orb(`right:-100px;top:560px;width:340px;height:340px;background:${a(s.t, .12)}`)}
${grid('left:770px;top:178px;width:110px;height:150px')}
${hero({
  l: 86,
  t: 108,
  w: 700,
  k: 'SEM TIPO CERTO NAO TEM JEITO ERRADO',
  h: 'entra do<br>seu jeito.',
  s: 'solo, banda, estudio ou contratante. o ponto e chegar com contexto.',
  c: s.p,
  size: 96,
  sub: 30,
})}
${panel({
  l: 86,
  t: 562,
  w: 410,
  h: 224,
  c: s.p,
  rot: -3,
  body: `<div class="icon" style="background:${a(s.p, .28)}"></div><div class="tt">musico solo</div><div class="cp">voz, instrumento, producao ou tecnica.</div>`,
})}
${panel({
  l: 562,
  t: 514,
  w: 404,
  h: 236,
  c: s.s,
  rot: 4,
  body: `<div class="icon" style="background:${a(s.s, .28)}"></div><div class="tt">banda</div><div class="cp">grupo, projeto autoral ou som de estrada.</div>`,
})}
${panel({
  l: 120,
  t: 850,
  w: 392,
  h: 226,
  c: s.p,
  rot: 2,
  body: `<div class="icon" style="background:${a(s.p, .22)}"></div><div class="tt">estudio</div><div class="cp">gravacao, mix, master ou estrutura de verdade.</div>`,
})}
${panel({
  l: 570,
  t: 864,
  w: 392,
  h: 226,
  c: s.t,
  rot: -2,
  body: `<div class="icon" style="background:${a(s.t, .22)}"></div><div class="tt">contratante</div><div class="cp">evento, casa, produtora ou corre de casting.</div>`,
})}
`;

const scene3 = (s) => `
${orb(`left:-80px;top:640px;width:340px;height:340px;background:${a(s.p, .22)}`)}
${orb(`right:60px;top:420px;width:320px;height:320px;background:${a(s.t, .16)}`)}
${ring(`left:118px;top:578px;width:268px;height:268px;border-color:${a(s.p, .12)}`)}
${hero({
  l: 86,
  t: 112,
  w: 520,
  k: 'MATCHPOINT',
  h: 'deu liga?<br>vira match.',
  s: 'quando faz sentido, nao precisa insistir no escuro.',
  c: s.p,
  size: 102,
  sub: 30,
})}
${disc({
  l: 102,
  t: 600,
  s: 246,
  c: s.p,
  body: `<div style="font-family:'Poppins Local',sans-serif;font-size:62px;line-height:.94;letter-spacing:-.06em;text-align:center">deu<br>liga?</div>`,
})}
${panel({
  l: 86,
  t: 938,
  w: 396,
  c: s.s,
  body: `<div class="ey">SEM DRAMA</div><div class="tt">curte, volta ou passa.</div><div class="cp">o ponto e nao perder tempo com o que nao encaixa.</div>`,
})}
${chip({ l: 86, t: 1180, txt: 'curte', c: s.p })}
${chip({ l: 222, t: 1202, txt: 'volta', c: s.s, rot: 2 })}
${chip({ l: 358, t: 1174, txt: 'passa', c: s.t, rot: -2 })}
${device({ l: 646, t: 364, w: 316, src: shots[3], c: s.p, rot: 8, pos: 'center top' })}
`;

const scene4 = (s) => `
${orb(`right:-60px;top:120px;width:320px;height:320px;background:${a(s.p, .18)}`)}
${orb(`left:-120px;bottom:160px;width:300px;height:300px;background:${a(s.t, .12)}`)}
${panel({
  l: 86,
  t: 96,
  w: 504,
  c: s.p,
  body: `<div class="ey">BUSCA</div><div class="tt" style="font-size:34px">baixo + rj + pop</div>`,
})}
${hero({
  l: 416,
  t: 198,
  w: 576,
  k: 'SEM RUIDO',
  h: 'buscar sem<br>ruido.',
  s: 'categoria, instrumento, genero e cena local sem perder tempo.',
  c: s.p,
  size: 98,
  sub: 30,
  align: 'right',
})}
${crop({ l: 86, t: 468, w: 448, h: 744, src: shots[5], pos: 'center top', rot: -3, rad: 44 })}
${panel({
  l: 604,
  t: 676,
  w: 336,
  c: s.p,
  body: `<div class="ey">FILTROS</div><div class="tt" style="font-size:42px">voz,<br>banda,<br>estudio.</div><div class="cp">o app corta o excesso antes de voce cansar.</div>`,
})}
${chip({ l: 612, t: 1044, txt: 'rj', c: s.p })}
${chip({ l: 706, t: 1070, txt: 'baixo', c: s.s, rot: 2 })}
${chip({ l: 812, t: 1036, txt: 'pop', c: s.t, rot: -2 })}
${chip({ l: 640, t: 1138, txt: 'banda', c: s.p })}
`;

const scene5 = (s) => `
${orb(`left:160px;top:220px;width:320px;height:320px;background:${a(s.p, .16)}`)}
${orb(`right:120px;bottom:180px;width:320px;height:320px;background:${a(s.t, .12)}`)}
${word({ l: 126, t: 986, txt: 'PAPO', size: 206, rot: 0, o: .08 })}
${hero({
  l: 176,
  t: 124,
  w: 728,
  k: 'CHAT',
  h: 'quando encaixa,<br>a conversa anda.',
  s: 'sem textao torto. sem insistencia no escuro.',
  c: s.p,
  size: 90,
  sub: 30,
  align: 'center',
})}
${bubble({ l: 112, t: 578, w: 360, txt: 'partiu ensaio?', c: s.s, small: '10:18' })}
${bubble({ l: 586, t: 706, w: 258, txt: 'fechou.', c: s.p, small: '10:19', rot: 2 })}
${bubble({ l: 164, t: 880, w: 420, txt: 'quarta, 20h?', c: s.t, small: '10:20', rot: -2 })}
${bubble({ l: 612, t: 1030, w: 222, txt: 'bora.', c: s.p, small: '10:21' })}
`;

const scene6 = (s) => `
${orb(`left:-80px;top:120px;width:340px;height:340px;background:${a(s.p, .18)}`)}
${orb(`right:-60px;top:560px;width:320px;height:320px;background:${a(s.s, .14)}`)}
${hero({
  l: 86,
  t: 108,
  w: 440,
  k: 'PRESENCA VISUAL',
  h: 'perfil que<br>mostra palco.',
  s: 'foto, video, bastidor e entrega no mesmo lugar.',
  c: s.p,
  size: 94,
  sub: 30,
})}
${crop({ l: 564, t: 132, w: 388, h: 520, src: shots[6], pos: 'center 20%', rot: 6, rad: 42 })}
${crop({ l: 94, t: 660, w: 304, h: 250, src: shots[6], pos: 'center 62%', rot: -4, rad: 30 })}
${crop({ l: 446, t: 718, w: 242, h: 196, src: shots[6], pos: 'center 38%', rot: 3, rad: 28 })}
${crop({ l: 724, t: 786, w: 280, h: 370, src: shots[6], pos: 'center 82%', rot: -5, rad: 32 })}
${crop({ l: 140, t: 950, w: 404, h: 256, src: shots[6], pos: 'center 90%', rot: 2, rad: 32 })}
${chip({ l: 86, t: 540, txt: 'palco', c: s.p })}
${chip({ l: 212, t: 570, txt: 'bastidor', c: s.s, rot: 2 })}
${chip({ l: 360, t: 536, txt: 'entrega', c: s.t, rot: -2 })}
`;

const scene7 = (s) => `
${orb(`left:-100px;top:460px;width:340px;height:340px;background:${a(s.p, .18)}`)}
${orb(`right:-80px;top:520px;width:340px;height:340px;background:${a(s.s, .14)}`)}
${ring(`left:388px;top:606px;width:304px;height:304px;border-color:${a(s.p, .12)}`)}
${hero({
  l: 136,
  t: 120,
  w: 808,
  k: 'PROJETO NOVO',
  h: 'banda nao nasce<br>no improviso.',
  s: 'entra, forma, chama gente certa e faz a ideia ganhar corpo.',
  c: s.p,
  size: 92,
  sub: 30,
  align: 'center',
})}
${panel({
  l: 98,
  t: 566,
  w: 392,
  h: 326,
  c: s.p,
  rot: -4,
  body: `<div class="ey">QUERO ENTRAR</div><div class="tt">entrar em banda</div><div class="cp">pra somar em projeto que ja esta rodando.</div>`,
})}
${panel({
  l: 588,
  t: 562,
  w: 392,
  h: 326,
  c: s.s,
  rot: 4,
  body: `<div class="ey">QUERO MONTAR</div><div class="tt">formar banda</div><div class="cp">pra chamar gente certa e tirar ideia do rascunho.</div>`,
})}
${chip({ l: 122, t: 964, txt: 'indie', c: s.p })}
${chip({ l: 250, t: 1002, txt: 'soul', c: s.s, rot: 2 })}
${chip({ l: 360, t: 952, txt: 'rock alt', c: s.p, rot: -3 })}
${chip({ l: 570, t: 980, txt: 'voz', c: s.t })}
${chip({ l: 668, t: 1012, txt: 'baixo', c: s.p, rot: -2 })}
${chip({ l: 790, t: 966, txt: 'batera', c: s.s, rot: 3 })}
`;

const scene8 = (s) => `
${orb(`left:-120px;top:760px;width:360px;height:360px;background:${a(s.p, .18)}`)}
${orb(`right:60px;top:180px;width:320px;height:320px;background:${a(s.t, .14)}`)}
${ring(`left:138px;top:658px;width:286px;height:286px;border-color:${a(s.p, .12)}`)}
${ring(`left:186px;top:706px;width:190px;height:190px;border-color:${a(s.t, .14)}`)}
${hero({
  l: 86,
  t: 126,
  w: 520,
  k: 'CENA LOCAL',
  h: 'menos aleatorio.<br>mais perto.',
  s: 'gente por perto, genero certo e chance real de acontecer.',
  c: s.p,
  size: 96,
  sub: 30,
})}
${disc({
  l: 186,
  t: 752,
  s: 180,
  c: s.p,
  body: `<div style="font-family:'Poppins Local',sans-serif;font-size:54px;line-height:.94;letter-spacing:-.06em;text-align:center">1 km<br>sabe?</div>`,
})}
${panel({
  l: 84,
  t: 1038,
  w: 380,
  c: s.p,
  body: `<div class="ey">POR PERTO</div><div class="tt" style="font-size:40px">rio, taquara,<br>pop, baixo.</div>`,
})}
${chip({ l: 110, t: 1188, txt: 'rj', c: s.p })}
${chip({ l: 194, t: 1210, txt: 'taquara', c: s.s, rot: 2 })}
${chip({ l: 334, t: 1180, txt: 'pop', c: s.t, rot: -2 })}
${device({ l: 664, t: 318, w: 304, src: shots[2], c: s.t, rot: 5, pos: 'center top' })}
`;

const scene9 = (s) => `
${orb(`left:-120px;top:180px;width:420px;height:420px;background:${a(s.p, .2)}`)}
${orb(`right:-100px;top:120px;width:360px;height:360px;background:${a(s.s, .14)}`)}
${orb(`right:180px;bottom:120px;width:280px;height:280px;background:${a(s.t, .14)}`)}
${grid('left:840px;top:170px;width:120px;height:180px')}
${hero({
  l: 130,
  t: 116,
  w: 820,
  k: 'SEM POSE DE REDE SOCIAL',
  h: 'bora fazer a<br>cena se encontrar?',
  s: 'o resto a gente deixa tocar.',
  c: s.p,
  size: 102,
  sub: 32,
  align: 'center',
})}
<div class="brand" style="left:388px;top:760px;width:304px;z-index:20"><img src="${brandVerticalPrimary}" alt="Mube"></div>
${chip({ l: 300, t: 1144, txt: 'entra', c: s.p })}
${chip({ l: 426, t: 1174, txt: 'monta', c: s.s, rot: 2 })}
${chip({ l: 566, t: 1140, txt: 'conversa', c: s.t, rot: -2 })}
`;

const slides = [
  { id: 1, file: '01_manifesto.png', p: '#E8466C', s: '#C026D3', t: '#2F4EA7', angle: 180, mesh: ['16% 18%', '76% 18%', '82% 78%'], draw: scene1 },
  { id: 2, file: '02_tipos_de_perfil.png', p: '#E8466C', s: '#C026D3', t: '#2F4EA7', angle: 164, mesh: ['18% 20%', '84% 22%', '50% 84%'], draw: scene2 },
  { id: 3, file: '03_matchpoint.png', p: '#E8466C', s: '#C026D3', t: '#2F4EA7', angle: 176, mesh: ['18% 22%', '82% 24%', '68% 82%'], draw: scene3 },
  { id: 4, file: '04_busca_sem_ruido.png', p: '#E8466C', s: '#C026D3', t: '#2F4EA7', angle: 188, mesh: ['14% 18%', '88% 18%', '84% 82%'], draw: scene4 },
  { id: 5, file: '05_chat.png', p: '#E8466C', s: '#C026D3', t: '#2F4EA7', angle: 180, mesh: ['32% 18%', '84% 22%', '18% 84%'], draw: scene5 },
  { id: 6, file: '06_galeria.png', p: '#E8466C', s: '#C026D3', t: '#2F4EA7', angle: 172, mesh: ['16% 18%', '80% 18%', '86% 84%'], draw: scene6 },
  { id: 7, file: '07_formar_banda.png', p: '#E8466C', s: '#C026D3', t: '#2F4EA7', angle: 184, mesh: ['18% 18%', '82% 16%', '52% 82%'], draw: scene7 },
  { id: 8, file: '08_cena_local.png', p: '#E8466C', s: '#C026D3', t: '#2F4EA7', angle: 170, mesh: ['14% 24%', '88% 20%', '72% 86%'], draw: scene8 },
  { id: 9, file: '09_cta_final.png', p: '#E8466C', s: '#C026D3', t: '#2F4EA7', angle: 180, mesh: ['18% 18%', '82% 20%', '78% 84%'], draw: scene9 },
];

function html(slide, body) {
  return `<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=${W},initial-scale=1"><style>${css}</style></head><body><main class="page"><div class="mesh" style="${mesh(slide)}"></div>${body}</main></body></html>`;
}

async function ensureOut() {
  await fs.promises.mkdir(OUT_DIR, { recursive: true });
}

async function validate(file, expectedWidth = W, expectedHeight = H) {
  const metadata = await sharp(file).metadata();
  if (metadata.width !== expectedWidth || metadata.height !== expectedHeight) {
    throw new Error(`Unexpected size for ${path.basename(file)}: ${metadata.width}x${metadata.height}`);
  }
}

async function buildPreview(files) {
  const tileW = 360;
  const tileH = 450;
  const composites = await Promise.all(
    files.map(async (file, index) => ({
      input: await sharp(file).resize(tileW, tileH).png().toBuffer(),
      left: (index % 3) * tileW,
      top: Math.floor(index / 3) * tileH,
    })),
  );

  await sharp({
    create: {
      width: tileW * 3,
      height: tileH * 3,
      channels: 4,
      background: '#08080a',
    },
  })
    .composite(composites)
    .png()
    .toFile(PREVIEW);

  await validate(PREVIEW, tileW * 3, tileH * 3);
}

async function main() {
  await ensureOut();

  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: W, height: H },
    deviceScaleFactor: 1,
  });

  const outputs = [];

  try {
    for (const slide of slides) {
      const page = await context.newPage();
      const file = path.join(OUT_DIR, slide.file);
      console.log(`Generating ${slide.file}...`);
      await page.setContent(html(slide, slide.draw(slide)), { waitUntil: 'load' });
      await page.screenshot({ path: file });
      await page.close();
      await validate(file);
      outputs.push(file);
    }
  } finally {
    await browser.close();
  }

  await buildPreview(outputs);
  console.log(`Generated ${outputs.length} instagram feed posts in ${OUT_DIR}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
