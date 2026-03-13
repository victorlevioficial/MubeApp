import fs from 'fs';
import path from 'path';
import { fileURLToPath, pathToFileURL } from 'url';

import { chromium } from 'playwright';
import sharp from 'sharp';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const OUT_DIR = path.join(
  ROOT,
  'social_media',
  'instagram_ds_rework_20260311',
);
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

const assets = {
  brandWordmark: uri(
    'assets/images/logos_svg/brand/brand-wordmark-light.svg',
    'image/svg+xml',
  ),
  brandHorizontal: uri(
    'assets/images/logos_svg/brand/brand-horizontal-white-cutout.svg',
    'image/svg+xml',
  ),
  logoIcon: uri(
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
.page{position:relative;width:100%;height:100%;overflow:hidden;background:#0A0A0A}
.page:before{content:'';position:absolute;inset:0;background:
  radial-gradient(circle at 12% 12%,rgba(232,70,108,.18) 0%,transparent 28%),
  radial-gradient(circle at 88% 84%,rgba(59,130,246,.12) 0%,transparent 24%),
  linear-gradient(180deg,rgba(255,255,255,.02) 0%,rgba(255,255,255,0) 18%);
  z-index:0}
.page:after{content:'';position:absolute;inset:0;background-image:
  linear-gradient(rgba(255,255,255,.012) 1px, transparent 1px),
  linear-gradient(90deg, rgba(255,255,255,.012) 1px, transparent 1px);
  background-size: 64px 64px;
  mask-image: radial-gradient(circle at center, black 56%, transparent 100%);
  z-index:1}
.wrap,.brand,.eyebrow,.headline,.copy,.screen,.chip,.btn,.nav,.phone,.stat,.split,.badge,.gallery,.bubble,.list,.cta,.connector{position:absolute}
.brand img,.screen img,.phone img,.gallery img{display:block;width:100%;height:100%;object-fit:cover}
.brand img{height:auto}
.eyebrow{font-size:15px;line-height:1;font-weight:700;letter-spacing:.24em;text-transform:uppercase;color:#E8466C;z-index:4}
.headline{font-family:'Poppins Local',sans-serif;font-size:88px;line-height:.94;font-weight:700;letter-spacing:-.06em;color:#FFFFFF;z-index:4}
.copy{font-size:30px;line-height:1.32;color:rgba(255,255,255,.72);z-index:4}
.screen{background:linear-gradient(180deg,rgba(31,31,31,.98) 0%,rgba(20,20,20,.98) 100%);border:1px solid rgba(255,255,255,.08);border-radius:32px;box-shadow:0 28px 80px rgba(0,0,0,.34);overflow:hidden;z-index:3}
.screen .bar{height:72px;border-bottom:1px solid rgba(255,255,255,.06);display:flex;align-items:center;justify-content:center;padding:0 24px;font-size:28px;font-weight:700;background:rgba(10,10,10,.22)}
.screen .bar .left,.screen .bar .right{position:absolute;top:20px;width:36px;height:36px;border-radius:18px;background:#141414;border:1px solid rgba(255,255,255,.06)}
.screen .bar .left{left:22px}
.screen .bar .right{right:22px}
.screen .body{padding:24px}
.card{position:relative;background:#141414;border:1px solid #383838;border-radius:24px;box-shadow:0 12px 34px rgba(0,0,0,.22);z-index:4}
.card.soft{background:#1F1F1F}
.card.glass{background:rgba(20,20,20,.82);backdrop-filter:blur(18px);border-color:rgba(255,255,255,.08)}
.selection{display:flex;align-items:center;gap:18px;padding:22px 24px}
.selection .icon{width:56px;height:56px;border-radius:18px;display:grid;place-items:center;font-size:24px;font-weight:700;color:#FFFFFF}
.selection .title{font-size:30px;line-height:1;font-weight:700;color:#FFFFFF}
.selection .desc{margin-top:8px;font-size:20px;line-height:1.26;color:#B3B3B3}
.selection .radio{margin-left:auto;width:28px;height:28px;border-radius:14px;border:2px solid rgba(255,255,255,.18)}
.selection.selected{border:1px solid rgba(232,70,108,.7);box-shadow:0 0 0 1px rgba(232,70,108,.18)}
.selection.selected .radio{border-color:#E8466C;background:#E8466C}
.note{display:flex;gap:12px;padding:18px 20px;border-radius:20px;background:#141414;border:1px solid #383838}
.note .dot{width:18px;height:18px;border-radius:9px;background:#3B82F6;flex:0 0 auto;margin-top:2px}
.note .tx{font-size:18px;line-height:1.38;color:#B3B3B3}
.chip{display:inline-flex;align-items:center;gap:10px;padding:12px 18px;border-radius:999px;font-size:20px;line-height:1;font-weight:600;z-index:4}
.chip.filter{background:#292929;color:#FFFFFF}
.chip.filter.selected{background:rgba(232,70,108,.3);border:1px solid rgba(232,70,108,.5)}
.chip.skill{background:#1F1F1F;color:#FFFFFF}
.chip.genre{background:#292929;color:#FFFFFF}
.chip .dot{width:8px;height:8px;border-radius:4px;background:currentColor;display:block;opacity:.95}
.btn{height:56px;padding:0 32px;border-radius:999px;display:inline-flex;align-items:center;justify-content:center;font-family:'Poppins Local',sans-serif;font-size:24px;font-weight:700;letter-spacing:-.02em;z-index:4}
.btn.primary{background:#E8466C;color:#FFFFFF;box-shadow:0 8px 24px rgba(232,70,108,.22)}
.btn.secondary{background:#292929;color:#FFFFFF}
.btn.outline{background:transparent;color:#FFFFFF;border:1px solid #383838}
.nav{left:94px;bottom:76px;width:892px;padding:18px 16px;border-radius:24px;background:linear-gradient(180deg,#141414 0%,rgba(20,20,20,.98) 100%);border:1px solid rgba(255,255,255,.08);box-shadow:0 14px 40px rgba(0,0,0,.28);display:flex;justify-content:space-around;z-index:4}
.nav .item{display:flex;flex-direction:column;align-items:center;gap:8px;color:#8A8A8A;font-size:14px;font-weight:600}
.nav .icon{width:56px;height:32px;border-radius:16px;display:grid;place-items:center;background:transparent;border:1px solid transparent}
.nav .doticon{width:18px;height:18px;border-radius:9px;background:#8A8A8A;opacity:.55}
.nav .item.active{color:#E8466C}
.nav .item.active .icon{background:rgba(232,70,108,.15);border-color:rgba(232,70,108,.2)}
.nav .item.active .doticon{background:#E8466C;opacity:1}
.screen-shot{border-radius:24px;overflow:hidden;border:1px solid rgba(255,255,255,.06);background:#0A0A0A}
.screen-shot img{object-fit:cover;object-position:center top}
.stat{padding:16px 18px;border-radius:20px;background:#141414;border:1px solid #383838;z-index:4}
.stat .k{font-size:14px;letter-spacing:.18em;text-transform:uppercase;color:#8A8A8A;font-weight:700}
.stat .v{margin-top:10px;font-family:'Poppins Local',sans-serif;font-size:34px;line-height:1;font-weight:700;letter-spacing:-.04em}
.badge{display:inline-flex;align-items:center;gap:10px;padding:10px 16px;border-radius:999px;background:rgba(232,70,108,.18);border:1px solid rgba(232,70,108,.28);font-size:18px;font-weight:700;color:#E8466C;z-index:4}
.badge .point{width:10px;height:10px;border-radius:5px;background:#E8466C}
.phone{border-radius:44px;background:#141414;border:1px solid rgba(255,255,255,.12);box-shadow:0 24px 70px rgba(0,0,0,.34);padding:10px;overflow:hidden;z-index:4}
.phone .glass{position:absolute;inset:10px;border-radius:34px;overflow:hidden;background:#0A0A0A}
.phone .glass:before{content:'';position:absolute;top:12px;left:50%;transform:translateX(-50%);width:132px;height:28px;border-radius:999px;background:#0A0A0A;z-index:2}
.gallery{border-radius:28px;border:1px solid #383838;background:#141414;padding:18px;display:grid;grid-template-columns:repeat(3,1fr);gap:12px;z-index:4}
.gallery .tile{aspect-ratio:1;border-radius:16px;overflow:hidden;background:#1F1F1F}
.gallery .tile.tall{grid-row:span 2}
.bubble{padding:20px 22px;border-radius:24px;background:#141414;border:1px solid #383838;z-index:4}
.bubble .time{font-size:14px;letter-spacing:.14em;text-transform:uppercase;color:#8A8A8A;font-weight:700}
.bubble .msg{margin-top:8px;font-family:'Poppins Local',sans-serif;font-size:30px;line-height:1.02;font-weight:700;letter-spacing:-.04em}
.list{display:flex;flex-direction:column;gap:14px}
.list .row{display:flex;gap:14px;align-items:flex-start;padding:0}
.list .mark{width:12px;height:12px;border-radius:6px;margin-top:10px}
.list .name{font-size:28px;line-height:1.04;font-weight:700;color:#FFFFFF}
.list .sub{margin-top:6px;font-size:18px;line-height:1.28;color:#B3B3B3}
.connector{height:1px;background:linear-gradient(90deg,rgba(232,70,108,.35),rgba(255,255,255,0));z-index:3}
.cta{padding:22px 24px;border-radius:24px;background:#141414;border:1px solid #383838;z-index:4}
.cta .title{font-size:26px;font-weight:700;color:#FFFFFF}
.cta .sub{margin-top:6px;font-size:18px;line-height:1.28;color:#B3B3B3}
`;

const slide01 = () => `
<div class="brand" style="left:88px;top:82px;width:150px;z-index:4"><img src="${assets.brandWordmark}" alt=""></div>
<div class="eyebrow" style="left:88px;top:170px">A PLATAFORMA DA CENA</div>
<div class="headline" style="left:88px;top:214px;width:520px">a cena<br>cabe aqui.</div>
<div class="copy" style="left:88px;top:412px;width:470px">Musicos, bandas, estudios e contratantes em uma interface direta, escura e objetiva.</div>
<div class="badge" style="left:88px;top:534px"><span class="point"></span>dark-only . pt-BR . mobile-first</div>
<div class="screen" style="left:620px;top:112px;width:372px;height:790px">
  <div class="screen-shot" style="width:100%;height:100%"><img src="${assets.feed}" alt="" style="object-position:center top"></div>
</div>
<div class="chip filter selected" style="left:88px;top:1006px">musico</div>
<div class="chip filter" style="left:232px;top:1006px">banda</div>
<div class="chip filter" style="left:352px;top:1006px">estudio</div>
<div class="chip filter" style="left:502px;top:1006px">contratante</div>
<div class="btn primary" style="left:88px;top:1118px;width:310px">entrar na cena</div>
<div class="btn secondary" style="left:420px;top:1118px;width:250px">ver perfis</div>
<div class="nav">
  <div class="item active"><div class="icon"><div class="doticon"></div></div>Feed</div>
  <div class="item"><div class="icon"><div class="doticon"></div></div>Busca</div>
  <div class="item"><div class="icon"><div class="doticon"></div></div>Gigs</div>
  <div class="item"><div class="icon"><div class="doticon"></div></div>Chat</div>
  <div class="item"><div class="icon"><div class="doticon"></div></div>Conta</div>
</div>
`;

const slide02 = () => `
<div class="eyebrow" style="left:88px;top:88px">ONBOARDING</div>
<div class="headline" style="left:88px;top:132px;width:360px;font-size:74px">4 perfis.<br>1 entrada.</div>
<div class="copy" style="left:88px;top:318px;width:320px;font-size:26px">A estrutura nasce do app: selecao clara, leitura rapida e zero adivinhacao.</div>
<div class="screen" style="left:458px;top:82px;width:536px;height:1148px">
  <div class="bar"><div class="left"></div>Bem-vindo ao Mube<div class="right"></div></div>
  <div class="body">
    <div class="note"><div class="dot"></div><div class="tx">Se escolher o tipo errado, ainda da para voltar antes de concluir o cadastro.</div></div>
    <div class="card selection selected" style="margin-top:20px">
      <div class="icon" style="background:rgba(232,70,108,.24)">M</div>
      <div><div class="title">Perfil Individual</div><div class="desc">Cantor, instrumentista, DJ ou equipe tecnica</div></div>
      <div class="radio"></div>
    </div>
    <div class="card selection" style="margin-top:14px">
      <div class="icon" style="background:rgba(192,38,211,.22)">B</div>
      <div><div class="title">Banda</div><div class="desc">Grupo musical, projeto autoral ou orquestra</div></div>
      <div class="radio"></div>
    </div>
    <div class="card selection" style="margin-top:14px">
      <div class="icon" style="background:rgba(245,158,11,.18)">E</div>
      <div><div class="title">Estudio</div><div class="desc">Gravacao, mixagem e masterizacao</div></div>
      <div class="radio"></div>
    </div>
    <div class="card selection" style="margin-top:14px">
      <div class="icon" style="background:rgba(59,130,246,.18)">C</div>
      <div><div class="title">Contratante</div><div class="desc">Evento, casa, produtora ou casting</div></div>
      <div class="radio"></div>
    </div>
  </div>
  <div class="cta" style="left:24px;right:24px;bottom:24px">
    <div class="btn primary" style="position:relative;left:0;top:0;width:100%">continuar</div>
  </div>
</div>
`;

const slide03 = () => `
<div class="eyebrow" style="left:88px;top:88px">BUSCA</div>
<div class="headline" style="left:88px;top:132px;width:480px;font-size:76px">filtro de verdade.</div>
<div class="copy" style="left:88px;top:286px;width:430px;font-size:26px">Chips, busca e descoberta seguem a mesma logica visual do app.</div>
<div class="screen" style="left:88px;top:404px;width:610px;height:744px">
  <div class="bar"><div class="left"></div>Busca<div class="right"></div></div>
  <div class="body">
    <div class="card soft" style="padding:18px 20px;border-radius:18px">
      <div style="font-size:22px;color:#8A8A8A">Buscar musicos, bandas, estudios...</div>
    </div>
    <div style="display:flex;gap:10px;flex-wrap:wrap;margin-top:16px">
      <div class="chip filter selected" style="position:relative;left:0;top:0">todos</div>
      <div class="chip filter" style="position:relative;left:0;top:0">profissionais</div>
      <div class="chip filter" style="position:relative;left:0;top:0">bandas</div>
    </div>
    <div class="card" style="margin-top:20px;padding:20px">
      <div style="font-size:18px;color:#E8466C;font-weight:700;letter-spacing:.18em;text-transform:uppercase">descobrir</div>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-top:16px">
        <div class="card soft" style="position:relative;padding:18px;height:164px"><div style="width:40px;height:40px;border-radius:14px;background:rgba(192,38,211,.18)"></div><div style="margin-top:18px;font-size:24px;font-weight:700">Cantores</div><div style="margin-top:8px;font-size:18px;color:#B3B3B3">Vocais e backing</div></div>
        <div class="card soft" style="position:relative;padding:18px;height:164px"><div style="width:40px;height:40px;border-radius:14px;background:rgba(232,70,108,.18)"></div><div style="margin-top:18px;font-size:24px;font-weight:700">Guitarristas</div><div style="margin-top:8px;font-size:18px;color:#B3B3B3">Violao e guitarra</div></div>
        <div class="card soft" style="position:relative;padding:18px;height:164px"><div style="width:40px;height:40px;border-radius:14px;background:rgba(59,130,246,.18)"></div><div style="margin-top:18px;font-size:24px;font-weight:700">Bateristas</div><div style="margin-top:8px;font-size:18px;color:#B3B3B3">Percussao e batera</div></div>
        <div class="card soft" style="position:relative;padding:18px;height:164px"><div style="width:40px;height:40px;border-radius:14px;background:rgba(34,197,94,.18)"></div><div style="margin-top:18px;font-size:24px;font-weight:700">Baixistas</div><div style="margin-top:8px;font-size:18px;color:#B3B3B3">Contra e baixo</div></div>
      </div>
    </div>
  </div>
</div>
<div class="stat" style="left:744px;top:462px;width:246px">
  <div class="k">FILTROS</div>
  <div class="v">instrumento<br>perfil<br>cidade</div>
</div>
<div class="chip genre" style="left:744px;top:704px">voz</div>
<div class="chip genre" style="left:834px;top:704px">baixo</div>
<div class="chip skill" style="left:744px;top:768px">rj</div>
<div class="chip skill" style="left:818px;top:768px">pop</div>
<div class="chip skill" style="left:744px;top:832px">banda</div>
<div class="btn primary" style="left:744px;top:946px;width:246px">abrir busca</div>
`;

const slide04 = () => `
<div class="eyebrow" style="left:88px;top:88px">PERFIL + GALERIA</div>
<div class="headline" style="left:88px;top:132px;width:420px;font-size:74px">trabalho<br>visivel.</div>
<div class="copy" style="left:88px;top:292px;width:360px;font-size:26px">Avatar, badge, chips e portfolio organizados como produto, nao como poster.</div>
<div class="screen" style="left:88px;top:430px;width:426px;height:742px">
  <div class="bar"><div class="left"></div>Perfil<div class="right"></div></div>
  <div class="body">
    <div style="display:flex;flex-direction:column;align-items:center">
      <div style="width:128px;height:128px;border-radius:64px;border:3px solid #292929;overflow:hidden"><img src="${assets.profile}" alt="" style="width:100%;height:100%;object-fit:cover;object-position:center 4%"></div>
      <div style="margin-top:16px;font-size:34px;font-weight:700">Kadu Carvalho</div>
      <div class="badge" style="position:relative;left:0;top:0;margin-top:12px"><span class="point"></span>musico</div>
    </div>
    <div class="card" style="position:relative;left:0;top:0;margin-top:22px;padding:18px 20px">
      <div style="font-size:18px;color:#8A8A8A;letter-spacing:.14em;text-transform:uppercase;font-weight:700">Instrumentos</div>
      <div style="display:flex;gap:10px;flex-wrap:wrap;margin-top:14px">
        <div class="chip skill" style="position:relative;left:0;top:0">violao</div>
        <div class="chip skill" style="position:relative;left:0;top:0">guitarra</div>
        <div class="chip skill" style="position:relative;left:0;top:0">baixo</div>
      </div>
    </div>
    <div class="card" style="position:relative;left:0;top:0;margin-top:14px;padding:18px 20px">
      <div style="font-size:18px;color:#8A8A8A;letter-spacing:.14em;text-transform:uppercase;font-weight:700">Funcoes tecnicas</div>
      <div style="display:flex;gap:10px;flex-wrap:wrap;margin-top:14px">
        <div class="chip genre" style="position:relative;left:0;top:0">produtor</div>
        <div class="chip genre" style="position:relative;left:0;top:0">beatmaker</div>
        <div class="chip genre" style="position:relative;left:0;top:0">diretor musical</div>
      </div>
    </div>
  </div>
</div>
<div class="gallery" style="left:560px;top:220px;width:434px;height:660px">
  <div class="tile tall"><img src="${assets.gallery}" alt="" style="object-position:10% 18%"></div>
  <div class="tile"><img src="${assets.gallery}" alt="" style="object-position:52% 18%"></div>
  <div class="tile"><img src="${assets.gallery}" alt="" style="object-position:90% 18%"></div>
  <div class="tile"><img src="${assets.gallery}" alt="" style="object-position:12% 68%"></div>
  <div class="tile tall"><img src="${assets.gallery}" alt="" style="object-position:54% 82%"></div>
  <div class="tile"><img src="${assets.gallery}" alt="" style="object-position:90% 82%"></div>
</div>
<div class="stat" style="left:560px;top:920px;width:198px">
  <div class="k">midia</div>
  <div class="v">fotos +<br>videos</div>
</div>
<div class="stat" style="left:782px;top:920px;width:212px">
  <div class="k">perfil</div>
  <div class="v">badge<br>chips</div>
</div>
<div class="btn primary" style="left:560px;top:1106px;width:434px">montar portfolio</div>
`;

const slide05 = () => `
<div class="eyebrow" style="left:88px;top:88px">MATCH + CHAT</div>
<div class="headline" style="left:88px;top:132px;width:360px;font-size:62px">deu liga?<br>vira conversa.</div>
<div class="copy" style="left:88px;top:288px;width:300px;font-size:22px">Match e chat no mesmo fluxo visual do app.</div>
<div class="phone" style="left:88px;top:452px;width:348px;height:706px">
  <div class="glass"><img src="${assets.matchpoint}" alt="" style="object-position:center top"></div>
</div>
<div class="bubble" style="left:566px;top:500px;width:270px">
  <div class="time">10:18</div>
  <div class="msg">partiu ensaio?</div>
</div>
<div class="bubble" style="left:500px;top:664px;width:360px;background:#1F1F1F;border-color:rgba(232,70,108,.18)">
  <div class="time">10:19</div>
  <div class="msg">sim. bora fechar.</div>
</div>
<div class="bubble" style="left:630px;top:840px;width:262px;background:#1F1F1F;border-color:rgba(34,197,94,.18)">
  <div class="time">10:21</div>
  <div class="msg">quarta, 20h.</div>
</div>
<div class="connector" style="left:452px;top:642px;width:88px"></div>
<div class="connector" style="left:452px;top:808px;width:144px"></div>
<div class="btn secondary" style="left:500px;top:1110px;width:152px">voltar</div>
<div class="btn primary" style="left:670px;top:1110px;width:170px">curtir</div>
<div class="btn outline" style="left:858px;top:1110px;width:136px">passar</div>
`;

const slide06 = () => `
<div class="brand" style="left:88px;top:88px;width:320px;z-index:4"><img src="${assets.brandHorizontal}" alt=""></div>
<div class="headline" style="left:88px;top:186px;width:520px;font-size:74px">estrutura pra<br>virar corre.</div>
<div class="copy" style="left:88px;top:352px;width:410px;font-size:26px">O app fala a lingua da cena: descoberta, portfolio, conversa e oportunidade.</div>
<div class="card glass" style="position:absolute;left:88px;top:520px;width:430px;padding:26px">
  <div class="eyebrow" style="position:relative;left:0;top:0;color:#8A8A8A;font-size:14px">GIG EXEMPLO</div>
  <div style="margin-top:18px;font-family:'Poppins Local',sans-serif;font-size:44px;line-height:1;font-weight:700;letter-spacing:-.05em">casa da lapa<br>procura banda pop.</div>
  <div style="margin-top:14px;font-size:22px;line-height:1.34;color:#B3B3B3">RJ . sexta . cache a combinar . lineup enxuto</div>
  <div style="display:flex;gap:10px;flex-wrap:wrap;margin-top:20px">
    <div class="chip skill" style="position:relative;left:0;top:0">voz</div>
    <div class="chip skill" style="position:relative;left:0;top:0">baixo</div>
    <div class="chip genre" style="position:relative;left:0;top:0">set 90 min</div>
  </div>
  <div class="btn primary" style="position:relative;left:0;top:0;width:100%;margin-top:24px">iniciar conversa</div>
</div>
<div class="card" style="position:absolute;left:580px;top:490px;width:414px;padding:26px">
  <div class="list">
    <div class="row"><div class="mark" style="background:#E8466C"></div><div><div class="name">matchpoint com criterio</div><div class="sub">afinidade, genero e proximidade em vez de tentativa no escuro.</div></div></div>
    <div class="row"><div class="mark" style="background:#3B82F6"></div><div><div class="name">busca com leitura rapida</div><div class="sub">chips, filtros e cards com a mesma hierarquia do app.</div></div></div>
    <div class="row"><div class="mark" style="background:#22C55E"></div><div><div class="name">chat e portfolio no fluxo</div><div class="sub">interesse vira conversa sem sair da linguagem visual do produto.</div></div></div>
  </div>
</div>
<div class="btn primary" style="left:580px;top:978px;width:414px">quero essa versao</div>
<div class="chip filter selected" style="left:582px;top:1080px">feed</div>
<div class="chip filter" style="left:686px;top:1080px">busca</div>
<div class="chip filter" style="left:806px;top:1080px">match</div>
<div class="chip filter" style="left:920px;top:1080px">chat</div>
`;

const slides = [
  { id: '01', slug: 'capa_ds', html: slide01 },
  { id: '02', slug: 'quatro_perfis_ds', html: slide02 },
  { id: '03', slug: 'busca_ds', html: slide03 },
  { id: '04', slug: 'perfil_galeria_ds', html: slide04 },
  { id: '05', slug: 'match_chat_ds', html: slide05 },
  { id: '06', slug: 'cta_gig_ds', html: slide06 },
];

function html(body) {
  return `<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=${W},initial-scale=1"><title>Mube DS Rework</title><style>${css}</style></head><body><main class="page">${body}</main></body></html>`;
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
  const columns = 3;
  const rows = 2;
  const tileW = 360;
  const tileH = 450;
  const composites = await Promise.all(
    files.map(async (file, index) => ({
      input: await sharp(file).resize(tileW, tileH).png().toBuffer(),
      left: (index % columns) * tileW,
      top: Math.floor(index / columns) * tileH,
    })),
  );

  await sharp({
    create: {
      width: columns * tileW,
      height: rows * tileH,
      channels: 4,
      background: '#0A0A0A',
    },
  })
    .composite(composites)
    .png()
    .toFile(PREVIEW);

  await validate(PREVIEW, columns * tileW, rows * tileH);
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
      const htmlPath = path.join(HTML_DIR, `${slide.id}_${slide.slug}.html`);
      const pngPath = path.join(EXPORT_DIR, `${slide.id}_${slide.slug}.png`);
      await fs.promises.writeFile(htmlPath, html(slide.html()), 'utf8');

      const page = await context.newPage();
      await page.goto(pathToFileURL(htmlPath).href, { waitUntil: 'load' });
      await page.waitForTimeout(350);
      await page.screenshot({ path: pngPath, type: 'png' });
      await page.close();

      await validate(pngPath);
      outputs.push(pngPath);
      console.log(`Generated ${path.basename(pngPath)}`);
    }
  } finally {
    await browser.close();
  }

  await buildPreview(outputs);
  console.log(`Generated ${outputs.length} DS rework creatives in ${EXPORT_DIR}`);
  console.log(`Preview: ${PREVIEW}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
