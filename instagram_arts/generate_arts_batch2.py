#!/usr/bin/env python3
"""
Mube Instagram Arts — Lote 2 (22 artes)
11 dark + 11 light | Humor | Personagens fictícios | Stop-scroll
"""

import asyncio
import base64
from pathlib import Path
from playwright.async_api import async_playwright

BASE = Path(__file__).parent.parent
ASSETS = BASE / "assets" / "images"
OUT = Path(__file__).parent / "output"
OUT.mkdir(exist_ok=True)


def b64(path):
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def img_uri(path):
    return f"data:image/png;base64,{b64(path)}"


print("⏳ Carregando screenshots...")
SS = {i: img_uri(ASSETS / "screenshots" / f"ss{i}.png") for i in range(1, 8)
      if (ASSETS / "screenshots" / f"ss{i}.png").exists()}
print(f"   ✓ {len(SS)} screenshots")

ICON_PATH = "M586.09,443.47c0,37.28-30.22,67.5-67.5,67.5-9.54,0-18.61-1.98-26.84-5.55-23.92-10.37-40.66-34.21-40.66-61.95v-241.87c0-4.81-1.97-9.19-5.14-12.36-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,.47-.01.94-.04,1.41v6.23c-.08,37.22-30.27,67.36-67.5,67.36-6.04,0-11.89-.79-17.45-2.28-28.09-7.49-48.96-32.65-50-62.85v-194.24c0-.43-.02-.86-.05-1.28-.31-4.3-2.2-8.19-5.09-11.08-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,13.75-11.25,25-25,25s-25-11.25-25-25v-284.37c.08-37.22,30.27-67.36,67.5-67.36,6.03,0,11.88.79,17.45,2.29,28.09,7.48,48.96,32.64,50,62.84v194.24c0,.43.02.86.05,1.28.31,4.3,2.2,8.19,5.09,11.08,3.17,3.17,7.55,5.14,12.36,5.14,9.62,0,17.5-7.87,17.5-17.5V209.24c0-.47,0-.94.04-1.41v-6.23c.08-37.22,30.27-67.36,67.5-67.36s67.42,30.14,67.5,67.36v176.66c5.58-1.49,11.45-2.29,17.5-2.29,37.28,0,67.5,30.22,67.5,67.5Z"


def mube_icon(size=32, bg="#e8466c", icon_color="#fff"):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 750" width="{size}" height="{size}"><circle cx="375" cy="375" r="375" fill="{bg}"/><path d="{ICON_PATH}" fill="{icon_color}"/></svg>'


FONTS = "@import url('https://fonts.googleapis.com/css2?family=Poppins:ital,wght@0,400;0,500;0,600;0,700;0,800;0,900;1,400;1,700;1,800;1,900&family=Inter:wght@400;500;600;700;800&display=swap');"
RESET = "*,*::before,*::after{margin:0;padding:0;box-sizing:border-box} html,body{width:1080px;height:1080px;overflow:hidden;-webkit-font-smoothing:antialiased;font-family:'Inter',sans-serif;text-rendering:optimizeLegibility}"

# Light mode tokens
LBG = "#F7F6F2"       # Background
LSURF = "#FFFFFF"     # Surface / cards
LTEXT = "#0D0D0D"     # Primary text
LMUTED = "#6B6B6B"    # Secondary text
LBORDER = "#E5E4E0"   # Borders
PRIMARY = "#E8466C"   # Brand


def wrap(style, body):
    return f"""<!DOCTYPE html><html><head><meta charset="UTF-8">
<style>{FONTS}{RESET}{style}</style></head><body>{body}</body></html>"""


# ══════════════════════════════════════════════
# DARK MODE (b01–b11)
# ══════════════════════════════════════════════

def b01_algoritmo():
    """Instagram te mostra receita de bolo. Mube te mostra músico."""
    style = """
body{background:#080808;display:flex;flex-direction:column;justify-content:center;padding:80px;position:relative;overflow:hidden}
.vs-row{display:flex;align-items:stretch;gap:24px;margin-bottom:48px}
.vs-col{flex:1;display:flex;flex-direction:column;gap:0}
.col-label{font-size:13px;font-weight:700;letter-spacing:4px;text-transform:uppercase;margin-bottom:18px;padding:0 4px}
.col-label.bad{color:#4A4A4A}
.col-label.good{color:#E8466C}
.feed-item{background:#141414;border-radius:14px;padding:20px 24px;margin-bottom:10px;display:flex;align-items:center;gap:14px;border:1px solid #1A1A1A}
.fi-emoji{font-size:36px;flex-shrink:0}
.fi-title{font-size:17px;font-weight:600;color:#6A6A6A;margin-bottom:3px}
.fi-sub{font-size:14px;color:#3A3A3A}
.good-col .feed-item{background:rgba(232,70,108,0.07);border:1px solid rgba(232,70,108,0.18)}
.good-col .fi-title{color:#fff}
.good-col .fi-sub{color:#B0B0B0}
.vs-div{display:flex;align-items:center;justify-content:center;width:56px;flex-shrink:0}
.vs-badge{font-family:'Poppins',sans-serif;font-size:28px;font-weight:900;color:#E8466C;background:#1A0810;border:2px solid rgba(232,70,108,0.3);width:52px;height:52px;border-radius:50%;display:flex;align-items:center;justify-content:center}
.headline{font-family:'Poppins',sans-serif;font-size:46px;font-weight:900;letter-spacing:-2px;line-height:1;text-align:center}
.headline em{font-style:italic;color:#E8466C}
.logo-row{display:flex;align-items:center;gap:12px;justify-content:center;margin-top:20px}
.logo-row span{font-family:'Poppins',sans-serif;font-weight:700;font-size:20px}
"""
    body = f"""
<div class="vs-row">
  <div class="vs-col">
    <div class="col-label bad">📱 Instagram / TikTok</div>
    <div class="feed-item"><div class="fi-emoji">🍕</div><div><div class="fi-title">Receita de bolo de cenoura</div><div class="fi-sub">que vai mudar sua vida</div></div></div>
    <div class="feed-item"><div class="fi-emoji">🐈</div><div><div class="fi-title">Gatinho fofo dormindo</div><div class="fi-sub">4.2 milhões de views</div></div></div>
    <div class="feed-item"><div class="fi-emoji">💪</div><div><div class="fi-title">Motivação das 6h da manhã</div><div class="fi-sub">"você consegue, guerreiro!"</div></div></div>
  </div>
  <div class="vs-div"><div class="vs-badge">vs</div></div>
  <div class="vs-col good-col">
    <div class="col-label good">🎵 Mube</div>
    <div class="feed-item"><div class="fi-emoji">🥁</div><div><div class="fi-title">Rafael Drummond · Baterista</div><div class="fi-sub">800m de você · disponível</div></div></div>
    <div class="feed-item"><div class="fi-emoji">🎹</div><div><div class="fi-title">Estúdio Onda Livre</div><div class="fi-sub">Gravação + mix disponível agora</div></div></div>
    <div class="feed-item"><div class="fi-emoji">🎸</div><div><div class="fi-title">Banda Os Estranhos</div><div class="fi-sub">Procurando vocalista em SP</div></div></div>
  </div>
</div>
<div class="headline">Às vezes o algoritmo acerta.<br><em>Aqui sempre.</em></div>
<div class="logo-row">{mube_icon(26)} <span>mube</span></div>
"""
    return wrap(style, body)


def b02_carlos():
    """Carlos, 34, guitarrista que vive no grupo do WhatsApp."""
    style = """
body{background:#0A0A0A;display:flex;align-items:center;justify-content:center;overflow:hidden;position:relative}
.card{background:#0F0F0F;border-radius:28px;padding:60px 64px;width:920px;border:1px solid #1A1A1A;position:relative}
.stamp{position:absolute;top:40px;right:48px;font-size:11px;font-weight:700;letter-spacing:5px;color:#292929;text-transform:uppercase}
.avatar-row{display:flex;align-items:center;gap:28px;margin-bottom:36px}
.av{width:104px;height:104px;border-radius:50%;background:linear-gradient(135deg,#1a0810,#2d1220);border:3px solid #E8466C;display:flex;align-items:center;justify-content:center;font-size:48px;flex-shrink:0}
.av-info .name{font-family:'Poppins',sans-serif;font-size:40px;font-weight:900;letter-spacing:-1.5px;color:#fff}
.av-info .meta{font-size:18px;color:#8A8A8A;margin-top:6px}
.quote-box{background:#080808;border-left:4px solid #E8466C;border-radius:0 16px 16px 0;padding:24px 28px;margin-bottom:32px}
.quote-text{font-size:23px;line-height:1.5;color:#C0C0C0;font-style:italic}
.quote-text em{font-style:normal;color:#E8466C;font-weight:700}
.stats{display:grid;grid-template-columns:repeat(3,1fr);gap:16px}
.stat{background:#141414;border-radius:14px;padding:20px;text-align:center;border:1px solid #1A1A1A}
.stat-n{font-family:'Poppins',sans-serif;font-size:40px;font-weight:800;color:#E8466C}
.stat-l{font-size:15px;color:#8A8A8A;margin-top:4px}
.logo-badge{position:absolute;bottom:44px;right:64px;display:flex;align-items:center;gap:8px}
.logo-badge span{font-family:'Poppins',sans-serif;font-weight:700;font-size:17px;color:#E8466C}
"""
    body = f"""
<div class="card">
  <div class="stamp">PERSONAGEM REAL (FICTÍCIO)</div>
  <div class="avatar-row">
    <div class="av">🎸</div>
    <div class="av-info">
      <div class="name">Carlos Mendes</div>
      <div class="meta">Guitarrista · 34 anos · Rio de Janeiro</div>
    </div>
  </div>
  <div class="quote-box">
    <p class="quote-text">"Criei <em>7 grupos no WhatsApp</em> procurando baterista.<br>Mandei mensagem pra 43 pessoas.<br>Achei um. <em>Ele sumiu antes do show.</em>"</p>
  </div>
  <div class="stats">
    <div class="stat"><div class="stat-n">7</div><div class="stat-l">grupos criados</div></div>
    <div class="stat"><div class="stat-n">43</div><div class="stat-l">mensagens enviadas</div></div>
    <div class="stat"><div class="stat-n">0</div><div class="stat-l">shows que aconteceram</div></div>
  </div>
  <div class="logo-badge">{mube_icon(24)} <span>mube resolve</span></div>
</div>
"""
    return wrap(style, body)


def b03_antes_depois():
    """Before/After: WhatsApp chaos vs Mube."""
    style = """
body{background:#0A0A0A;display:flex;flex-direction:column;overflow:hidden}
.split{display:grid;grid-template-columns:1fr 1fr;flex:1}
.panel{padding:60px 52px;display:flex;flex-direction:column}
.panel.before{border-right:1px solid #1A1A1A}
.plabel{font-size:12px;font-weight:700;letter-spacing:5px;text-transform:uppercase;margin-bottom:28px}
.panel.before .plabel{color:#4A4A4A}
.panel.after .plabel{color:#E8466C}
.ptitle{font-family:'Poppins',sans-serif;font-size:48px;font-weight:900;letter-spacing:-2px;line-height:.9;margin-bottom:32px}
.panel.before .ptitle{color:#383838}
.panel.after .ptitle{color:#E8466C}
.item{display:flex;align-items:flex-start;gap:14px;margin-bottom:20px}
.item-i{font-size:26px;flex-shrink:0;margin-top:2px}
.item-t{font-size:19px;line-height:1.35;color:#8A8A8A}
.panel.after .item-t{color:#fff}
.bar{background:#E8466C;padding:28px 64px;display:flex;align-items:center;justify-content:space-between}
.bar-text{font-family:'Poppins',sans-serif;font-size:30px;font-weight:800;color:#fff}
.logo-r{display:flex;align-items:center;gap:10px}
.logo-r span{font-family:'Poppins',sans-serif;font-weight:700;font-size:20px;color:#fff}
"""
    body = f"""
<div class="split">
  <div class="panel before">
    <div class="plabel">😵 ANTES DO MUBE</div>
    <div class="ptitle">O caos do<br>WhatsApp</div>
    <div class="item"><div class="item-i">💬</div><div class="item-t">"Alguém conhece baterista?" — sem resposta por 3 dias</div></div>
    <div class="item"><div class="item-i">🔁</div><div class="item-t">Encaminhado pro grupo errado de novo</div></div>
    <div class="item"><div class="item-i">👻</div><div class="item-t">Músico sumiu na véspera do show</div></div>
    <div class="item"><div class="item-i">😤</div><div class="item-t">Show cancelado. De novo.</div></div>
  </div>
  <div class="panel after">
    <div class="plabel">✅ COM O MUBE</div>
    <div class="ptitle">Paz.<br>Música.</div>
    <div class="item"><div class="item-i">🔍</div><div class="item-t">Busca por instrumento, gênero e cidade</div></div>
    <div class="item"><div class="item-i">👤</div><div class="item-t">Perfil completo com portfólio real</div></div>
    <div class="item"><div class="item-i">💬</div><div class="item-t">Chat direto, sem intermediário</div></div>
    <div class="item"><div class="item-i">🎵</div><div class="item-t">Show aconteceu. Todo mundo feliz.</div></div>
  </div>
</div>
<div class="bar">
  <div class="bar-text">A diferença é enorme.</div>
  <div class="logo-r">{mube_icon(28, '#fff', '#E8466C')} <span>mube</span></div>
</div>
"""
    return wrap(style, body)


def b04_love_story():
    """Fernanda + Paulo = match no Mube."""
    style = """
body{background:#080808;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:72px;overflow:hidden;position:relative}
.glow{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);width:380px;height:380px;background:radial-gradient(circle,rgba(232,70,108,0.14),transparent 70%);border-radius:50%}
.tag{font-size:12px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:28px;text-align:center;position:relative}
.title{font-family:'Poppins',sans-serif;font-size:58px;font-weight:900;letter-spacing:-2.5px;text-align:center;line-height:1;margin-bottom:52px;position:relative}
.title em{font-style:italic;color:#E8466C}
.story{display:flex;align-items:center;gap:0;width:100%;justify-content:center;position:relative}
.char{display:flex;flex-direction:column;align-items:center;gap:14px;width:270px}
.char-av{width:96px;height:96px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:44px;border:3px solid #292929}
.char-name{font-family:'Poppins',sans-serif;font-size:26px;font-weight:700}
.char-role{font-size:17px;color:#8A8A8A}
.char-need{background:#141414;border-radius:12px;padding:14px 18px;font-size:16px;color:#B0B0B0;text-align:center;border:1px solid #1A1A1A;line-height:1.4}
.connector{display:flex;flex-direction:column;align-items:center;gap:6px;padding:0 20px}
.heart{font-size:60px;line-height:1}
.conn-text{font-size:12px;color:#E8466C;font-weight:700;letter-spacing:3px;text-transform:uppercase}
.result{background:rgba(232,70,108,0.07);border:1px solid rgba(232,70,108,0.22);border-radius:20px;padding:26px 44px;margin-top:44px;text-align:center;display:flex;align-items:center;gap:20px;position:relative}
.res-emoji{font-size:40px}
.res-main{font-family:'Poppins',sans-serif;font-size:26px;font-weight:700;color:#E8466C}
.res-sub{font-size:16px;color:#B0B0B0;margin-top:4px}
"""
    body = f"""
<div class="glow"></div>
<div class="tag">HISTÓRIA REAL (FICTÍCIA) · MUBE</div>
<h1 class="title">O match<br>que <em>mudou tudo.</em></h1>
<div class="story">
  <div class="char">
    <div class="char-av" style="background:#1a0810">🎸</div>
    <div class="char-name">Fernanda Luz</div>
    <div class="char-role">Violonista · São Paulo</div>
    <div class="char-need">Precisava de produtor pro seu primeiro EP</div>
  </div>
  <div class="connector">
    <div class="heart">❤️</div>
    <div class="conn-text">match</div>
  </div>
  <div class="char">
    <div class="char-av" style="background:#0a0d1a">🎛️</div>
    <div class="char-name">Paulo Silva</div>
    <div class="char-role">Produtor · São Paulo</div>
    <div class="char-need">Procurava artista com voz autoral</div>
  </div>
</div>
<div class="result">
  <div class="res-emoji">🎵</div>
  <div>
    <div class="res-main">EP lançado. 40k streams.</div>
    <div class="res-sub">Tudo começou num match no Mube.</div>
  </div>
</div>
"""
    return wrap(style, body)


def b05_ghosting():
    """O músico fantasma — humor timeline."""
    style = """
body{background:#0A0A0A;display:flex;flex-direction:column;justify-content:center;padding:80px;overflow:hidden;position:relative}
.ghost-deco{position:absolute;right:-60px;top:50%;transform:translateY(-50%);font-size:420px;opacity:.022;line-height:1}
.tag{font-size:12px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#8A8A8A;margin-bottom:24px}
.title{font-family:'Poppins',sans-serif;font-size:88px;font-weight:900;letter-spacing:-5px;line-height:.85;margin-bottom:44px}
.title em{color:#E8466C;font-style:italic}
.timeline{display:flex;flex-direction:column;gap:0;margin-bottom:44px;position:relative}
.timeline::before{content:'';position:absolute;left:19px;top:0;bottom:0;width:2px;background:#141414}
.tl{display:flex;align-items:flex-start;gap:24px;padding-bottom:24px;position:relative}
.tl-dot{width:40px;height:40px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:17px;flex-shrink:0;z-index:1;border:2px solid transparent;background:#0A0A0A}
.tl-dot.ok{border-color:#22C55E;background:#081a0d}
.tl-dot.warn{border-color:#F59E0B;background:#1a1200}
.tl-dot.rip{border-color:#E8466C;background:#1a0810}
.tl-body{padding-top:6px}
.tl-day{font-size:12px;font-weight:700;letter-spacing:3px;color:#3A3A3A;text-transform:uppercase;margin-bottom:4px}
.tl-text{font-size:21px;line-height:1.35;color:#C0C0C0}
.sol{background:rgba(232,70,108,0.08);border:1px solid rgba(232,70,108,0.2);border-radius:16px;padding:22px 28px;display:flex;align-items:flex-start;gap:16px}
.sol-icon{font-size:36px;flex-shrink:0}
.sol-text{font-size:19px;color:#fff;line-height:1.45}
.sol-text strong{color:#E8466C}
"""
    body = f"""
<div class="ghost-deco">👻</div>
<div class="tag">O MÚSICO FANTASMA · UMA HISTÓRIA FAMILIAR</div>
<h1 class="title">Sumiu<br>antes do<br><em>show.</em></h1>
<div class="timeline">
  <div class="tl"><div class="tl-dot ok">🤝</div><div class="tl-body"><div class="tl-day">Semana 1</div><div class="tl-text">Fechou tudo. "Pode contar comigo, irmão!"</div></div></div>
  <div class="tl"><div class="tl-dot warn">👀</div><div class="tl-body"><div class="tl-day">Semana 2</div><div class="tl-text">Viu a mensagem. Entrou online. Não respondeu.</div></div></div>
  <div class="tl"><div class="tl-dot rip">👻</div><div class="tl-body"><div class="tl-day">Véspera do show</div><div class="tl-text">Desapareceu. Saiu do grupo. Bloqueou.</div></div></div>
</div>
<div class="sol">
  <div class="sol-icon">💡</div>
  <div class="sol-text">No Mube você vê <strong>portfólio real</strong> e histórico de cada músico antes de fechar. Menos susto, mais show.</div>
</div>
"""
    return wrap(style, body)


def b06_ratings():
    """Reviews fictícias 5 estrelas — dark."""
    style = """
body{background:#0A0A0A;display:flex;flex-direction:column;padding:72px 80px;overflow:hidden}
.tag{font-size:12px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:18px}
.title{font-family:'Poppins',sans-serif;font-size:64px;font-weight:900;letter-spacing:-3px;line-height:.9;margin-bottom:44px}
.title em{font-style:italic;color:#E8466C}
.reviews{display:flex;flex-direction:column;gap:20px;flex:1;justify-content:center}
.rv{background:#0F0F0F;border-radius:20px;padding:28px 32px;border:1px solid #1A1A1A}
.stars{font-size:22px;letter-spacing:3px;margin-bottom:12px}
.rv-text{font-size:22px;line-height:1.45;color:#fff;margin-bottom:16px}
.rv-text em{font-style:italic;color:#E8466C}
.rv-author{display:flex;align-items:center;gap:12px}
.rv-av{width:38px;height:38px;border-radius:50%;border:1px solid #292929;display:flex;align-items:center;justify-content:center;font-size:18px}
.rv-name{font-size:15px;font-weight:700;color:#fff}
.rv-role{font-size:13px;color:#8A8A8A}
.bottom{display:flex;align-items:flex-end;justify-content:space-between;margin-top:28px}
.rating-n{font-family:'Poppins',sans-serif;font-size:80px;font-weight:900;color:#E8466C;line-height:1}
.rating-sub{font-size:16px;color:#8A8A8A;margin-top:4px}
.logo-sm{display:flex;align-items:center;gap:10px}
.logo-sm span{font-family:'Poppins',sans-serif;font-weight:700;font-size:20px}
"""
    body = f"""
<div class="tag">AVALIAÇÕES · O QUE ESTÃO DIZENDO</div>
<h1 class="title">O público<br><em>amou.</em></h1>
<div class="reviews">
  <div class="rv">
    <div class="stars">⭐⭐⭐⭐⭐</div>
    <div class="rv-text">"Achei guitarrista, tecladista e ainda conheci minha <em>banda dos sonhos</em>. Nunca mais uso grupo de zap."</div>
    <div class="rv-author"><div class="rv-av" style="background:#1a0810">🎵</div><div><div class="rv-name">Marina Costa</div><div class="rv-role">Cantora · Belo Horizonte</div></div></div>
  </div>
  <div class="rv">
    <div class="stars">⭐⭐⭐⭐⭐</div>
    <div class="rv-text">"Postei meu perfil na segunda. Na quarta já tinha <em>3 propostas de show.</em> Fiquei desconfiado."</div>
    <div class="rv-author"><div class="rv-av" style="background:#0a0d1a">🥁</div><div><div class="rv-name">Rodrigo Batista</div><div class="rv-role">Baterista · São Paulo</div></div></div>
  </div>
</div>
<div class="bottom">
  <div><div class="rating-n">5.0</div><div class="rating-sub">⭐ média dos usuários fictícios</div></div>
  <div class="logo-sm">{mube_icon(28)} <span>mube</span></div>
</div>
"""
    return wrap(style, body)


def b07_pitch():
    """Se o Mube fosse um pitch de startup."""
    style = """
body{background:#080808;display:flex;flex-direction:column;justify-content:center;padding:80px;overflow:hidden;position:relative}
.slide-tag{position:absolute;top:44px;right:80px;font-size:12px;color:#292929;letter-spacing:3px;text-transform:uppercase}
.tag{font-size:12px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:28px}
.title{font-family:'Poppins',sans-serif;font-size:68px;font-weight:900;letter-spacing:-3px;line-height:.9;margin-bottom:36px}
.title em{font-style:italic;color:#E8466C}
.box{border-radius:0 18px 18px 0;padding:22px 28px;margin-bottom:18px}
.box-label{font-size:12px;font-weight:700;letter-spacing:3px;text-transform:uppercase;margin-bottom:8px}
.box.prob{background:#1A0800;border-left:4px solid #F59E0B}
.box.prob .box-label{color:#F59E0B}
.box.sol{background:#0A1A10;border-left:4px solid #22C55E}
.box.sol .box-label{color:#22C55E}
.box-text{font-size:21px;line-height:1.4;color:#fff}
.market{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin-top:32px}
.m-card{background:#0F0F0F;border:1px solid #1A1A1A;border-radius:16px;padding:20px;text-align:center}
.m-num{font-family:'Poppins',sans-serif;font-size:36px;font-weight:800;color:#E8466C}
.m-lab{font-size:15px;color:#8A8A8A;margin-top:6px;line-height:1.3}
.logo-row{display:flex;align-items:center;gap:10px;margin-top:28px}
.logo-row span{font-family:'Poppins',sans-serif;font-weight:700;font-size:18px}
"""
    body = f"""
<div class="slide-tag">SLIDE 1 DE 1</div>
<div class="tag">SE O MUBE FOSSE UM PITCH</div>
<h1 class="title">O problema<br>era <em>óbvio.</em></h1>
<div class="box prob">
  <div class="box-label">🔴 Problema</div>
  <div class="box-text">Músicos talentosos invisíveis enquanto grupos de WhatsApp explodem sem resultado.</div>
</div>
<div class="box sol">
  <div class="box-label">✅ Solução</div>
  <div class="box-text">Plataforma dedicada ao mercado musical brasileiro. Perfis, busca, match e chat — num só app.</div>
</div>
<div class="market">
  <div class="m-card"><div class="m-num">+1M</div><div class="m-lab">músicos no Brasil sem plataforma dedicada</div></div>
  <div class="m-card"><div class="m-num">R$ 0</div><div class="m-lab">para criar seu perfil completo</div></div>
  <div class="m-card"><div class="m-num">∞</div><div class="m-lab">conexões possíveis</div></div>
</div>
<div class="logo-row">{mube_icon(26)} <span>mube · a solução óbvia</span></div>
"""
    return wrap(style, body)


def b08_fomo():
    """FOMO: Enquanto você lê isso..."""
    style = """
body{background:#080808;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:72px;overflow:hidden;position:relative}
.ring1{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);width:480px;height:480px;border-radius:50%;border:1px solid rgba(232,70,108,0.08)}
.ring2{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);width:720px;height:720px;border-radius:50%;border:1px solid rgba(232,70,108,0.04)}
.counter{font-family:'Poppins',sans-serif;font-size:180px;font-weight:900;color:#E8466C;line-height:1;letter-spacing:-8px;text-align:center;position:relative}
.counter-sub{font-size:20px;color:#8A8A8A;text-align:center;margin-top:4px;margin-bottom:44px;position:relative}
.events{display:flex;flex-direction:column;gap:12px;width:100%;max-width:700px;position:relative}
.ev{display:flex;align-items:center;gap:16px;background:#0F0F0F;border-radius:14px;padding:16px 22px;border:1px solid #1A1A1A}
.ev-dot{width:10px;height:10px;border-radius:50%;background:#22C55E;flex-shrink:0;box-shadow:0 0 8px rgba(34,197,94,0.8)}
.ev-text{font-size:19px;color:#fff}
.ev-time{margin-left:auto;font-size:13px;color:#4A4A4A;white-space:nowrap}
.cta{font-family:'Poppins',sans-serif;font-size:34px;font-weight:800;letter-spacing:-1px;text-align:center;margin-top:36px;position:relative}
.cta em{font-style:italic;color:#E8466C}
.footnote{font-size:13px;color:#2A2A2A;text-align:center;margin-top:12px;position:relative}
"""
    body = f"""
<div class="ring1"></div>
<div class="ring2"></div>
<div class="counter">73</div>
<div class="counter-sub">conexões no Mube enquanto você dormia*</div>
<div class="events">
  <div class="ev"><div class="ev-dot"></div><div class="ev-text">Beatriz encontrou banda em SP</div><div class="ev-time">agora mesmo</div></div>
  <div class="ev"><div class="ev-dot"></div><div class="ev-text">Estúdio Focal fechou 2 gravações</div><div class="ev-time">3 min atrás</div></div>
  <div class="ev"><div class="ev-dot"></div><div class="ev-text">DJ Rafa fez match com contratante</div><div class="ev-time">8 min atrás</div></div>
</div>
<div class="cta">E você ainda não<br>tem <em>perfil?</em></div>
<div class="footnote">*número fictício. o sentimento é real.</div>
"""
    return wrap(style, body)


def b09_mitos():
    """Mitos vs Realidade — dark."""
    style = """
body{background:#0A0A0A;display:flex;flex-direction:column;padding:72px 80px;overflow:hidden}
.tag{font-size:12px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:18px}
.title{font-family:'Poppins',sans-serif;font-size:68px;font-weight:900;letter-spacing:-3px;line-height:.9;margin-bottom:44px}
.title em{font-style:italic;color:#E8466C}
.rows{display:flex;flex-direction:column;gap:14px;flex:1;justify-content:center}
.pair{display:grid;grid-template-columns:1fr 1fr;gap:14px}
.box{background:#0F0F0F;border-radius:16px;padding:22px 26px;border-top:3px solid transparent}
.box.myth{border-top-color:#E8466C}
.box.fact{border-top-color:#22C55E}
.badge{font-size:11px;font-weight:700;letter-spacing:3px;text-transform:uppercase;margin-bottom:10px}
.box.myth .badge{color:#E8466C}
.box.fact .badge{color:#22C55E}
.box-text{font-size:19px;line-height:1.4;color:#fff}
.box.myth .box-text{color:#4A4A4A;text-decoration:line-through;font-size:18px}
.logo-row{display:flex;align-items:center;justify-content:flex-end;gap:10px;margin-top:24px}
.logo-row span{font-family:'Poppins',sans-serif;font-weight:700;font-size:18px}
"""
    body = f"""
<div class="tag">MITOS & VERDADES</div>
<h1 class="title">Deixa eu<br><em>te contar.</em></h1>
<div class="rows">
  <div class="pair">
    <div class="box myth"><div class="badge">❌ Mito</div><div class="box-text">"É só pra músico famoso"</div></div>
    <div class="box fact"><div class="badge">✅ Verdade</div><div class="box-text">Qualquer músico, do iniciante ao profissional.</div></div>
  </div>
  <div class="pair">
    <div class="box myth"><div class="badge">❌ Mito</div><div class="box-text">"Tem que pagar caro"</div></div>
    <div class="box fact"><div class="badge">✅ Verdade</div><div class="box-text">Criar perfil e buscar músicos é completamente grátis.</div></div>
  </div>
  <div class="pair">
    <div class="box myth"><div class="badge">❌ Mito</div><div class="box-text">"Não tem ninguém da minha cidade"</div></div>
    <div class="box fact"><div class="badge">✅ Verdade</div><div class="box-text">Busca por localização. Filtra pela sua cidade agora.</div></div>
  </div>
</div>
<div class="logo-row">{mube_icon(24)} <span>mube</span></div>
"""
    return wrap(style, body)


def b10_quiz_dark():
    """Quiz: Qual tipo você é? — dark."""
    style = """
body{background:#0A0A0A;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:64px;overflow:hidden;position:relative}
.tag{font-size:12px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:20px;text-align:center;position:relative}
.title{font-family:'Poppins',sans-serif;font-size:62px;font-weight:900;letter-spacing:-2.5px;line-height:1;text-align:center;margin-bottom:44px;position:relative}
.title em{font-style:italic;color:#E8466C}
.opts{display:grid;grid-template-columns:1fr 1fr;gap:16px;width:100%;position:relative}
.opt{background:#0F0F0F;border:2px solid #1A1A1A;border-radius:22px;padding:32px 28px;display:flex;flex-direction:column;align-items:center;text-align:center;gap:12px}
.opt-e{font-size:52px}
.opt-t{font-family:'Poppins',sans-serif;font-size:24px;font-weight:700}
.opt-d{font-size:17px;color:#8A8A8A;line-height:1.35}
.opt.a{border-color:rgba(232,70,108,0.35);background:rgba(232,70,108,0.04)} .opt.a .opt-t{color:#E8466C}
.opt.b{border-color:rgba(192,38,211,0.35);background:rgba(192,38,211,0.04)} .opt.b .opt-t{color:#C026D3}
.opt.c{border-color:rgba(59,130,246,0.35);background:rgba(59,130,246,0.04)} .opt.c .opt-t{color:#3B82F6}
.opt.d{border-color:rgba(245,158,11,0.35);background:rgba(245,158,11,0.04)} .opt.d .opt-t{color:#F59E0B}
.bottom{font-size:20px;color:#8A8A8A;text-align:center;margin-top:32px;position:relative}
.bottom strong{color:#fff}
"""
    body = f"""
<div class="tag">QUIZ · DESCUBRA SEU PERFIL</div>
<h1 class="title">Qual é o<br>seu <em>papel?</em></h1>
<div class="opts">
  <div class="opt a"><div class="opt-e">🎸</div><div class="opt-t">Músico</div><div class="opt-d">Toca, canta ou produz. É individual e talentoso.</div></div>
  <div class="opt b"><div class="opt-e">🎵</div><div class="opt-t">Banda</div><div class="opt-d">Grupo unido por um som. Busca oportunidade juntos.</div></div>
  <div class="opt c"><div class="opt-e">🎙️</div><div class="opt-t">Estúdio</div><div class="opt-d">Oferece gravação, mix ou masterização.</div></div>
  <div class="opt d"><div class="opt-e">🎤</div><div class="opt-t">Contratante</div><div class="opt-d">Organiza eventos. Precisa dos artistas certos.</div></div>
</div>
<div class="bottom"><strong>Todos têm espaço no Mube.</strong> Qual é o seu?</div>
"""
    return wrap(style, body)


def b11_manifesto2():
    """Manifesto 2 — irreverente, direto."""
    style = """
body{background:#080808;display:flex;flex-direction:column;justify-content:space-between;padding:88px;overflow:hidden;position:relative}
.big-m{position:absolute;right:-40px;bottom:-60px;font-family:'Poppins',sans-serif;font-size:540px;font-weight:900;color:#fff;opacity:.017;line-height:1;pointer-events:none;user-select:none}
.eyebrow{font-size:12px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:40px;position:relative}
.manifesto{display:flex;flex-direction:column;gap:4px;position:relative}
.line{font-family:'Poppins',sans-serif;font-weight:900;line-height:.87;letter-spacing:-4px}
.line.xl{font-size:116px;color:#fff}
.line.lg{font-size:88px;color:#fff}
.line.accent{color:#E8466C}
.line.crossed{color:#232323;text-decoration:line-through;font-size:56px;letter-spacing:-2px}
.bottom-row{display:flex;align-items:flex-end;justify-content:space-between;position:relative}
.sub{font-size:19px;color:#8A8A8A;line-height:1.6;max-width:400px}
.logo-col{display:flex;flex-direction:column;align-items:flex-end;gap:8px}
.logo-col span{font-family:'Poppins',sans-serif;font-weight:700;font-size:22px}
"""
    body = f"""
<div class="big-m">M</div>
<div>
  <div class="eyebrow">MUBE · DECLARAÇÃO PÚBLICA</div>
  <div class="manifesto">
    <div class="line crossed">grupo do whatsapp</div>
    <div class="line xl">Mube.</div>
    <div class="line lg">É diferente.</div>
    <div class="line lg accent">É melhor.</div>
  </div>
</div>
<div class="bottom-row">
  <p class="sub">Pare de procurar músico em lugar de comida. A gente tem um lugar certo pra isso.</p>
  <div class="logo-col">{mube_icon(36)} <span>mube</span></div>
</div>
"""
    return wrap(style, body)


# ══════════════════════════════════════════════
# LIGHT MODE (b12–b22)
# ══════════════════════════════════════════════

def b12_dj_rafa():
    """DJ Rafa — personagem card (light)."""
    style = f"""
body{{background:{LBG};display:flex;align-items:center;justify-content:center;overflow:hidden;position:relative}}
.deco{{position:absolute;top:-120px;right:-120px;width:520px;height:520px;border-radius:50%;background:rgba(232,70,108,0.06)}}
.card{{background:{LSURF};border-radius:32px;padding:64px;width:920px;box-shadow:0 4px 48px rgba(0,0,0,0.08);position:relative}}
.ctag{{font-size:11px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};margin-bottom:28px}}
.top-row{{display:flex;align-items:center;gap:32px;margin-bottom:36px}}
.av{{width:108px;height:108px;border-radius:50%;background:linear-gradient(135deg,{PRIMARY},#C026D3);display:flex;align-items:center;justify-content:center;font-size:48px;box-shadow:0 8px 32px rgba(232,70,108,0.3);flex-shrink:0}}
.info .iname{{font-family:'Poppins',sans-serif;font-size:44px;font-weight:900;letter-spacing:-2px;color:{LTEXT}}}
.info .irole{{font-size:19px;color:{LMUTED};margin-top:6px}}
.info .iloc{{font-size:18px;color:{LMUTED};margin-top:3px}}
.quote{{background:{LBG};border-left:4px solid {PRIMARY};border-radius:0 16px 16px 0;padding:22px 28px;margin-bottom:28px}}
.qt{{font-size:22px;line-height:1.5;color:{LTEXT};font-style:italic}}
.qt em{{font-style:normal;color:{PRIMARY};font-weight:700}}
.chips{{display:flex;flex-wrap:wrap;gap:10px;margin-bottom:28px}}
.chip{{padding:10px 20px;border-radius:999px;font-size:16px;font-weight:600;background:{LBG};color:{LTEXT};border:1.5px solid {LBORDER}}}
.chip.hot{{background:rgba(232,70,108,0.07);border-color:rgba(232,70,108,0.25);color:{PRIMARY}}}
.footer{{display:flex;align-items:center;justify-content:space-between}}
.cta-btn{{background:{PRIMARY};border-radius:999px;padding:14px 32px;font-family:'Poppins',sans-serif;font-size:18px;font-weight:700;color:#fff}}
.logo-sm{{display:flex;align-items:center;gap:8px}}
.logo-sm span{{font-family:'Poppins',sans-serif;font-weight:700;font-size:18px;color:{LTEXT}}}
"""
    body = f"""
<div class="deco"></div>
<div class="card">
  <div class="ctag">CONHEÇA · USUÁRIO MUBE</div>
  <div class="top-row">
    <div class="av">🎛️</div>
    <div class="info">
      <div class="iname">DJ Rafa Santos</div>
      <div class="irole">DJ · Produtor Musical</div>
      <div class="iloc">📍 Belo Horizonte, MG</div>
    </div>
  </div>
  <div class="quote">
    <p class="qt">"Entrei no Mube sem expectativa. Em 2 semanas já tinha <em>4 propostas de evento</em>. Meu calendário tá cheio."</p>
  </div>
  <div class="chips">
    <div class="chip hot">House</div><div class="chip hot">Techno</div><div class="chip hot">DJ Set</div>
    <div class="chip">Produção</div><div class="chip">Eventos</div>
  </div>
  <div class="footer">
    <div class="cta-btn">Ver perfil completo →</div>
    <div class="logo-sm">{mube_icon(28)} <span>mube</span></div>
  </div>
</div>
"""
    return wrap(style, body)


def b13_mari():
    """Mari Costa — cantora (light + screenshot)."""
    style = f"""
body{{background:#FDF8F4;display:flex;flex-direction:column;overflow:hidden}}
.top-accent{{background:{PRIMARY};height:7px}}
.main{{flex:1;display:flex;align-items:center;padding:56px 80px;gap:64px}}
.left{{flex:1;display:flex;flex-direction:column}}
.eyebrow{{font-size:12px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};margin-bottom:24px}}
.name{{font-family:'Poppins',sans-serif;font-size:84px;font-weight:900;letter-spacing:-4px;line-height:.88;color:{LTEXT};margin-bottom:14px}}
.role{{font-size:22px;color:{LMUTED};margin-bottom:28px}}
.story{{font-size:23px;line-height:1.5;color:{LTEXT};max-width:440px;margin-bottom:28px}}
.story em{{font-style:normal;color:{PRIMARY};font-weight:700}}
.chips{{display:flex;flex-wrap:wrap;gap:10px;margin-bottom:32px}}
.chip{{padding:10px 20px;border-radius:999px;font-size:16px;font-weight:600;background:#fff;color:{LTEXT};border:1.5px solid {LBORDER};box-shadow:0 2px 8px rgba(0,0,0,0.05)}}
.logo-row{{display:flex;align-items:center;gap:10px}}
.logo-row span{{font-family:'Poppins',sans-serif;font-weight:700;font-size:18px;color:{LTEXT}}}
.right{{width:300px;flex-shrink:0}}
.phone{{width:300px;height:508px;border-radius:38px;background:#fff;border:2px solid {LBORDER};overflow:hidden;box-shadow:0 16px 56px rgba(0,0,0,0.1)}}
.phone img{{width:100%;height:100%;object-fit:cover;object-position:top}}
"""
    ss_data = SS.get(4, "")
    body = f"""
<div class="top-accent"></div>
<div class="main">
  <div class="left">
    <div class="eyebrow">PERSONAGEM · MUBE</div>
    <div class="name">Mari<br>Costa</div>
    <div class="role">Cantora de MPB · Recife, PE</div>
    <div class="story">Ficou <em>6 meses</em> tentando achar produtora pelo Instagram. Criou perfil no Mube. Em <em>3 semanas</em> fechou álbum.</div>
    <div class="chips">
      <div class="chip">Voz</div><div class="chip">MPB</div><div class="chip">Bossa Nova</div><div class="chip">Compositora</div>
    </div>
    <div class="logo-row">{mube_icon(28)} <span>mube</span></div>
  </div>
  <div class="right">
    <div class="phone"><img src="{ss_data}" alt=""/></div>
  </div>
</div>
"""
    return wrap(style, body)


def b14_tinder_parody():
    """Tinder parody musical — light."""
    style = f"""
body{{background:{LBG};display:flex;flex-direction:column;align-items:center;justify-content:center;padding:60px;overflow:hidden}}
.tag{{font-size:12px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};margin-bottom:18px;text-align:center}}
.title{{font-family:'Poppins',sans-serif;font-size:54px;font-weight:900;letter-spacing:-2.5px;text-align:center;line-height:1;color:{LTEXT};margin-bottom:44px}}
.title em{{font-style:italic;color:{PRIMARY}}}
.stack{{position:relative;width:380px;height:360px;margin-bottom:40px}}
.c-back2{{position:absolute;background:{LSURF};border-radius:28px;width:340px;height:340px;top:20px;left:40px;transform:rotate(6deg);box-shadow:0 4px 20px rgba(0,0,0,0.07);border:1.5px solid {LBORDER}}}
.c-back1{{position:absolute;background:{LSURF};border-radius:28px;width:340px;height:340px;top:10px;left:20px;transform:rotate(3deg);box-shadow:0 4px 20px rgba(0,0,0,0.07);border:1.5px solid {LBORDER}}}
.c-front{{position:absolute;background:{LSURF};border-radius:28px;width:340px;height:340px;top:0;left:0;box-shadow:0 12px 40px rgba(0,0,0,0.1);border:1.5px solid {LBORDER};display:flex;flex-direction:column;align-items:center;justify-content:center;gap:14px;padding:32px}}
.c-emoji{{font-size:80px}}
.c-name{{font-family:'Poppins',sans-serif;font-size:28px;font-weight:800;color:{LTEXT}}}
.c-info{{font-size:17px;color:{LMUTED};text-align:center;line-height:1.4}}
.actions{{display:flex;gap:24px;align-items:center;margin-bottom:36px}}
.btn-no{{width:68px;height:68px;border-radius:50%;background:{LSURF};border:2px solid {LBORDER};display:flex;align-items:center;justify-content:center;font-size:26px;box-shadow:0 4px 14px rgba(0,0,0,0.08)}}
.btn-yes{{width:84px;height:84px;border-radius:50%;background:{PRIMARY};display:flex;align-items:center;justify-content:center;font-size:36px;box-shadow:0 8px 24px rgba(232,70,108,0.4)}}
.disc{{font-size:17px;color:{LMUTED};text-align:center;max-width:500px;line-height:1.5}}
.disc strong{{color:{LTEXT}}}
.logo-row{{display:flex;align-items:center;gap:8px;margin-top:18px}}
.logo-row span{{font-family:'Poppins',sans-serif;font-weight:700;font-size:16px;color:{LTEXT}}}
"""
    body = f"""
<div class="tag">MATCHPOINT · FUNCIONA IGUAL, MAS PRO QUE IMPORTA</div>
<h1 class="title">Deu match<br>com o <em>som certo.</em></h1>
<div class="stack">
  <div class="c-back2"></div>
  <div class="c-back1"></div>
  <div class="c-front">
    <div class="c-emoji">🎸</div>
    <div class="c-name">João Guitarrista</div>
    <div class="c-info">26 anos · São Paulo<br>Rock Alternativo · Blues</div>
  </div>
</div>
<div class="actions">
  <div class="btn-no">✕</div>
  <div class="btn-yes">♥</div>
</div>
<div class="disc"><strong>Não é app de namoro.</strong> É melhor: aqui você acha o músico com quem vai criar algo incrível.</div>
<div class="logo-row">{mube_icon(22)} <span>mube · matchpoint</span></div>
"""
    return wrap(style, body)


def b15_instrucoes():
    """3 passos. Isso. — light humor."""
    style = f"""
body{{background:{LSURF};display:flex;flex-direction:column;padding:80px;overflow:hidden}}
.tag{{font-size:12px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};margin-bottom:22px}}
.title{{font-family:'Poppins',sans-serif;font-size:74px;font-weight:900;letter-spacing:-3px;line-height:.88;color:{LTEXT};margin-bottom:52px}}
.title em{{font-style:italic;color:{PRIMARY}}}
.steps{{display:flex;flex-direction:column;flex:1;justify-content:center}}
.step{{display:grid;grid-template-columns:80px 1fr;align-items:center;gap:28px}}
.step-n{{width:80px;height:80px;border-radius:50%;background:{PRIMARY};display:flex;align-items:center;justify-content:center;font-family:'Poppins',sans-serif;font-size:40px;font-weight:900;color:#fff;flex-shrink:0}}
.step-title{{font-family:'Poppins',sans-serif;font-size:28px;font-weight:800;color:{LTEXT};margin-bottom:6px}}
.step-desc{{font-size:19px;color:{LMUTED};line-height:1.4}}
.step-desc em{{font-style:normal;color:{PRIMARY};font-weight:600}}
.connector{{width:2px;height:22px;background:{LBORDER};margin-left:39px}}
.footer{{display:flex;align-items:center;justify-content:space-between;margin-top:36px;padding-top:28px;border-top:1.5px solid {LBORDER}}}
.f-note{{font-size:18px;color:{LMUTED}}}
.f-note strong{{color:{LTEXT}}}
.logo-sm{{display:flex;align-items:center;gap:8px}}
.logo-sm span{{font-family:'Poppins',sans-serif;font-weight:700;font-size:18px;color:{LTEXT}}}
"""
    body = f"""
<div class="tag">TUTORIAL · SEM COMPLICAÇÃO</div>
<h1 class="title">3 passos.<br><em>Isso.</em></h1>
<div class="steps">
  <div class="step">
    <div class="step-n">1</div>
    <div><div class="step-title">Crie seu perfil</div><div class="step-desc">Instrumento, gênero, cidade. <em>5 minutos.</em> Sério.</div></div>
  </div>
  <div class="connector"></div>
  <div class="step">
    <div class="step-n">2</div>
    <div><div class="step-title">Busque ou seja encontrado</div><div class="step-desc">Procure quem você precisa <em>ou</em> deixe as oportunidades chegarem.</div></div>
  </div>
  <div class="connector"></div>
  <div class="step">
    <div class="step-n">3</div>
    <div><div class="step-title">Conecte e faça música</div><div class="step-desc">Chat direto. <em>Vá fazer música de verdade.</em> A gente cuida do resto.</div></div>
  </div>
</div>
<div class="footer">
  <div class="f-note"><strong>Tempo médio pra criar conta:</strong> menos de 5 minutos</div>
  <div class="logo-sm">{mube_icon(28)} <span>mube</span></div>
</div>
"""
    return wrap(style, body)


def b16_testimonial():
    """Depoimento impactante — light mode."""
    style = f"""
body{{background:{LBG};display:flex;flex-direction:column;align-items:center;justify-content:center;padding:80px;overflow:hidden;position:relative}}
.circle{{position:absolute;bottom:-160px;left:-160px;width:440px;height:440px;border-radius:50%;background:rgba(232,70,108,0.05)}}
.qmark{{font-family:'Poppins',sans-serif;font-size:240px;font-weight:900;color:{PRIMARY};line-height:1;opacity:.1;position:absolute;top:20px;left:56px}}
.content{{position:relative;max-width:900px;text-align:center}}
.stars{{font-size:32px;letter-spacing:4px;margin-bottom:28px}}
.qt{{font-family:'Poppins',sans-serif;font-size:46px;font-weight:700;letter-spacing:-1.5px;line-height:1.15;color:{LTEXT};margin-bottom:44px}}
.qt em{{font-style:italic;color:{PRIMARY}}}
.author{{display:flex;align-items:center;gap:20px;justify-content:center;margin-bottom:36px}}
.av{{width:72px;height:72px;border-radius:50%;background:linear-gradient(135deg,{PRIMARY},#C026D3);display:flex;align-items:center;justify-content:center;font-size:32px}}
.aname{{font-family:'Poppins',sans-serif;font-size:22px;font-weight:700;color:{LTEXT};text-align:left}}
.arole{{font-size:17px;color:{LMUTED};text-align:left}}
.logo-row{{display:flex;align-items:center;gap:10px;justify-content:center}}
.logo-row span{{font-family:'Poppins',sans-serif;font-weight:700;font-size:18px;color:{LTEXT}}}
"""
    body = f"""
<div class="circle"></div>
<div class="qmark">"</div>
<div class="content">
  <div class="stars">⭐⭐⭐⭐⭐</div>
  <div class="qt">"Tentei achar produtor pelo Instagram por <em>4 meses</em>. Entrei no Mube, <em>uma semana depois</em> tava gravando."</div>
  <div class="author">
    <div class="av">🎵</div>
    <div><div class="aname">Beatriz Almeida</div><div class="arole">Cantora Independente · Curitiba, PR</div></div>
  </div>
  <div class="logo-row">{mube_icon(28)} <span>mube</span></div>
</div>
"""
    return wrap(style, body)


def b17_features_light():
    """Features limpas — light."""
    style = f"""
body{{background:{LSURF};display:flex;flex-direction:column;padding:80px;overflow:hidden}}
.tag{{font-size:12px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};margin-bottom:16px}}
.title{{font-family:'Poppins',sans-serif;font-size:66px;font-weight:900;letter-spacing:-3px;line-height:.88;color:{LTEXT};margin-bottom:48px}}
.title em{{font-style:italic;color:{PRIMARY}}}
.feats{{display:grid;grid-template-columns:1fr 1fr;gap:18px;flex:1}}
.feat{{background:{LBG};border-radius:24px;padding:34px;border:1.5px solid {LBORDER}}}
.feat.hi{{background:rgba(232,70,108,0.04);border-color:rgba(232,70,108,0.22)}}
.feat-ico{{font-size:48px;margin-bottom:18px}}
.feat-t{{font-family:'Poppins',sans-serif;font-size:26px;font-weight:800;color:{LTEXT};margin-bottom:8px}}
.feat.hi .feat-t{{color:{PRIMARY}}}
.feat-d{{font-size:18px;color:{LMUTED};line-height:1.45}}
.feat-d strong{{color:{LTEXT}}}
.footer{{display:flex;align-items:center;justify-content:space-between;margin-top:28px;padding-top:22px;border-top:1.5px solid {LBORDER}}}
.f-note{{font-size:18px;color:{LMUTED}}} .f-note strong{{color:{LTEXT}}}
.logo-sm{{display:flex;align-items:center;gap:8px}}
.logo-sm span{{font-family:'Poppins',sans-serif;font-weight:700;font-size:18px;color:{LTEXT}}}
"""
    body = f"""
<div class="tag">FUNCIONALIDADES</div>
<h1 class="title">Simples.<br>Completo.<br><em>Musical.</em></h1>
<div class="feats">
  <div class="feat hi"><div class="feat-ico">🎯</div><div class="feat-t">Matchpoint</div><div class="feat-d">Explore perfis e dê match com quem <strong>toca na mesma frequência.</strong></div></div>
  <div class="feat"><div class="feat-ico">🔍</div><div class="feat-t">Busca avançada</div><div class="feat-d">Filtre por instrumento, gênero ou cidade. <strong>Sem algoritmo escondido.</strong></div></div>
  <div class="feat"><div class="feat-ico">💬</div><div class="feat-t">Chat direto</div><div class="feat-d">Do match à parceria em <strong>poucos minutos.</strong> Sem intermediário.</div></div>
  <div class="feat"><div class="feat-ico">🖼️</div><div class="feat-t">Portfólio</div><div class="feat-d">Fotos, vídeos e links do seu trabalho. <strong>Tudo no perfil.</strong></div></div>
</div>
<div class="footer">
  <div class="f-note"><strong>100% gratuito</strong> para criar seu perfil</div>
  <div class="logo-sm">{mube_icon(28)} <span>mube</span></div>
</div>
"""
    return wrap(style, body)


def b18_perda():
    """O que você perde sem o Mube — FOMO light."""
    style = f"""
body{{background:{LBG};display:flex;flex-direction:column;justify-content:center;padding:80px;overflow:hidden}}
.title{{font-family:'Poppins',sans-serif;font-size:76px;font-weight:900;letter-spacing:-3.5px;line-height:.88;color:{LTEXT};margin-bottom:44px}}
.title em{{font-style:italic;color:{PRIMARY}}}
.list{{display:flex;flex-direction:column;gap:14px;margin-bottom:40px}}
.item{{display:flex;align-items:center;gap:20px;background:{LSURF};border-radius:16px;padding:20px 26px;border:1.5px solid {LBORDER};box-shadow:0 2px 8px rgba(0,0,0,0.04)}}
.item-e{{font-size:36px;flex-shrink:0}}
.item-main{{font-size:22px;color:{LTEXT};font-weight:600}}
.item-sub{{font-size:15px;color:{LMUTED};margin-top:2px}}
.cta-row{{display:flex;align-items:center;justify-content:space-between}}
.cta{{background:{PRIMARY};border-radius:999px;padding:16px 40px;font-family:'Poppins',sans-serif;font-size:20px;font-weight:700;color:#fff}}
.logo-sm{{display:flex;align-items:center;gap:8px}}
.logo-sm span{{font-family:'Poppins',sans-serif;font-weight:700;font-size:18px;color:{LTEXT}}}
"""
    body = f"""
<h1 class="title">Sem o Mube,<br>você <em>perde...</em></h1>
<div class="list">
  <div class="item"><div class="item-e">🥁</div><div><div class="item-main">O baterista perfeito da sua cidade</div><div class="item-sub">que você nunca vai descobrir no grupo de zap</div></div></div>
  <div class="item"><div class="item-e">🎛️</div><div><div class="item-main">O produtor que ia mudar seu som</div><div class="item-sub">estava a 3km de você. Não se conheceram.</div></div></div>
  <div class="item"><div class="item-e">🎤</div><div><div class="item-main">O show que não vai acontecer</div><div class="item-sub">porque faltava só um músico. Que estava aqui.</div></div></div>
</div>
<div class="cta-row">
  <div class="cta">Entrar no Mube agora</div>
  <div class="logo-sm">{mube_icon(28)} <span>mube</span></div>
</div>
"""
    return wrap(style, body)


def b19_qual_voce_light():
    """Qual tipo? — light clean."""
    style = f"""
body{{background:{LBG};display:flex;flex-direction:column;align-items:center;justify-content:center;padding:60px;overflow:hidden}}
.tag{{font-size:12px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};margin-bottom:18px;text-align:center}}
.title{{font-family:'Poppins',sans-serif;font-size:60px;font-weight:900;letter-spacing:-2.5px;line-height:1;color:{LTEXT};text-align:center;margin-bottom:44px}}
.title em{{font-style:italic;color:{PRIMARY}}}
.grid{{display:grid;grid-template-columns:1fr 1fr;gap:14px;width:100%;margin-bottom:32px}}
.card{{background:{LSURF};border-radius:24px;padding:34px 24px;border:2px solid {LBORDER};display:flex;flex-direction:column;align-items:center;text-align:center;gap:12px;box-shadow:0 4px 16px rgba(0,0,0,0.05)}}
.card-e{{font-size:52px}}
.card-t{{font-family:'Poppins',sans-serif;font-size:24px;font-weight:800;color:{LTEXT}}}
.card-d{{font-size:16px;color:{LMUTED};line-height:1.35}}
.card.a{{border-color:rgba(232,70,108,0.3);background:rgba(232,70,108,0.025)}} .card.a .card-t{{color:{PRIMARY}}}
.card.b{{border-color:rgba(192,38,211,0.3);background:rgba(192,38,211,0.025)}} .card.b .card-t{{color:#C026D3}}
.card.c{{border-color:rgba(59,130,246,0.3);background:rgba(59,130,246,0.025)}} .card.c .card-t{{color:#3B82F6}}
.card.d{{border-color:rgba(245,158,11,0.3);background:rgba(245,158,11,0.025)}} .card.d .card-t{{color:#D97706}}
.bottom{{font-family:'Poppins',sans-serif;font-size:24px;font-weight:700;color:{LTEXT};text-align:center}}
.bottom em{{color:{PRIMARY};font-style:normal}}
"""
    body = f"""
<div class="tag">QUIZ · QUAL É O SEU PERFIL?</div>
<h1 class="title">Com qual você<br>se <em>identifica?</em></h1>
<div class="grid">
  <div class="card a"><div class="card-e">🎸</div><div class="card-t">Músico</div><div class="card-d">Individual. Toca, canta ou produz seu som.</div></div>
  <div class="card b"><div class="card-e">🎵</div><div class="card-t">Banda</div><div class="card-d">Grupo unido. Busca oportunidade junto.</div></div>
  <div class="card c"><div class="card-e">🎙️</div><div class="card-t">Estúdio</div><div class="card-d">Oferece gravação, mix ou masterização.</div></div>
  <div class="card d"><div class="card-e">🎤</div><div class="card-t">Contratante</div><div class="card-d">Organiza eventos. Precisa dos artistas certos.</div></div>
</div>
<div class="bottom"><em>Todos têm espaço</em> no Mube.</div>
"""
    return wrap(style, body)


def b20_banda_certa():
    """A banda certa existe — light inspiracional."""
    style = f"""
body{{background:{LSURF};display:flex;flex-direction:column;justify-content:space-between;padding:88px;overflow:hidden;position:relative}}
.deco1{{position:absolute;top:-100px;right:-100px;width:600px;height:600px;border-radius:50%;border:1px solid rgba(232,70,108,0.08)}}
.deco2{{position:absolute;top:-200px;right:-200px;width:900px;height:900px;border-radius:50%;border:1px solid rgba(232,70,108,0.04)}}
.eyebrow{{font-size:12px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};margin-bottom:32px;position:relative}}
.main{{flex:1;display:flex;flex-direction:column;justify-content:center;position:relative}}
.hl{{font-family:'Poppins',sans-serif;font-weight:900;letter-spacing:-5px;line-height:.87}}
.hl1{{font-size:104px;color:{LTEXT}}}
.hl2{{font-size:80px;color:{PRIMARY}}}
.hl3{{font-size:104px;color:{LTEXT}}}
.body-t{{font-size:23px;color:{LMUTED};line-height:1.6;max-width:560px;margin-top:32px}}
.body-t strong{{color:{LTEXT}}}
.footer{{display:flex;align-items:center;justify-content:space-between;position:relative}}
.pill{{background:{PRIMARY};border-radius:999px;padding:16px 36px;font-family:'Poppins',sans-serif;font-size:20px;font-weight:700;color:#fff}}
.logo-sm{{display:flex;align-items:center;gap:10px}}
.logo-sm span{{font-family:'Poppins',sans-serif;font-weight:700;font-size:20px;color:{LTEXT}}}
"""
    body = f"""
<div class="deco1"></div>
<div class="deco2"></div>
<div class="eyebrow">MUBE · PARA QUEM LEVA A SÉRIO</div>
<div class="main">
  <div class="hl hl1">A banda</div>
  <div class="hl hl2">certa</div>
  <div class="hl hl3">existe.</div>
  <div class="body-t">Ela ainda não te achou porque você não está no lugar certo. <strong>O Mube é esse lugar.</strong></div>
</div>
<div class="footer">
  <div class="pill">Criar meu perfil</div>
  <div class="logo-sm">{mube_icon(28)} <span>mube</span></div>
</div>
"""
    return wrap(style, body)


def b21_mensagem():
    """A mensagem que mudou tudo — light story."""
    style = f"""
body{{background:#FDF9F6;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:64px;overflow:hidden}}
.tag{{font-size:12px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};margin-bottom:18px;text-align:center}}
.title{{font-family:'Poppins',sans-serif;font-size:54px;font-weight:900;letter-spacing:-2.5px;line-height:1;color:{LTEXT};text-align:center;margin-bottom:40px}}
.title em{{font-style:italic;color:{PRIMARY}}}
.chat-card{{background:{LSURF};border-radius:28px;padding:36px;width:720px;box-shadow:0 8px 48px rgba(0,0,0,0.08);border:1.5px solid {LBORDER};margin-bottom:32px}}
.chat-hdr{{display:flex;align-items:center;gap:16px;margin-bottom:24px;padding-bottom:20px;border-bottom:1px solid {LBORDER}}}
.hdr-av{{width:52px;height:52px;border-radius:50%;background:linear-gradient(135deg,{PRIMARY},#C026D3);display:flex;align-items:center;justify-content:center;font-size:24px}}
.hdr-name{{font-family:'Poppins',sans-serif;font-size:20px;font-weight:700;color:{LTEXT}}}
.hdr-status{{font-size:14px;color:#22C55E;font-weight:600}}
.msgs{{display:flex;flex-direction:column;gap:14px}}
.msg{{max-width:78%}}.msg.recv{{align-self:flex-start}}.msg.sent{{align-self:flex-end}}
.bubble{{padding:13px 19px;border-radius:18px;font-size:18px;line-height:1.4}}
.msg.recv .bubble{{background:{LBG};color:{LTEXT};border-bottom-left-radius:4px}}
.msg.sent .bubble{{background:{PRIMARY};color:#fff;border-bottom-right-radius:4px}}
.tick{{font-size:12px;color:#B0AFA8;margin-top:3px;text-align:right}}
.bottom{{text-align:center}}
.b-text{{font-family:'Poppins',sans-serif;font-size:30px;font-weight:800;letter-spacing:-1px;color:{LTEXT};margin-bottom:14px}}
.b-text em{{color:{PRIMARY};font-style:normal}}
.logo-row{{display:flex;align-items:center;gap:8px;justify-content:center}}
.logo-row span{{font-family:'Poppins',sans-serif;font-weight:700;font-size:16px;color:{LTEXT}}}
"""
    body = f"""
<div class="tag">CHAT · COMEÇA COM UMA MENSAGEM</div>
<h1 class="title">A mensagem<br>que <em>mudou tudo.</em></h1>
<div class="chat-card">
  <div class="chat-hdr">
    <div class="hdr-av">🎛️</div>
    <div><div class="hdr-name">Lucas Produtor</div><div class="hdr-status">● online agora</div></div>
  </div>
  <div class="msgs" style="display:flex;flex-direction:column">
    <div class="msg recv"><div class="bubble">Oi! Vi seu perfil no Mube. Amei sua voz no portfólio! 🎵</div></div>
    <div class="msg sent"><div class="bubble">Oi Lucas! Obrigada! Tô procurando produtor pro meu EP 🙌</div><div class="tick">✓✓</div></div>
    <div class="msg recv"><div class="bubble">Perfeito. Tenho estúdio livre essa semana. Bora? 🎙️</div></div>
    <div class="msg sent"><div class="bubble">Manda o endereço! Vou adorar 🎵</div><div class="tick">✓✓</div></div>
  </div>
</div>
<div class="bottom">
  <div class="b-text">Sua <em>próxima parceria</em> começa assim.</div>
  <div class="logo-row">{mube_icon(22)} <span>mube</span></div>
</div>
"""
    return wrap(style, body)


def b22_cta_light():
    """CTA final bold — light com metade primária."""
    style = f"""
body{{background:{LBG};display:flex;flex-direction:column;overflow:hidden}}
.top{{background:{PRIMARY};flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:64px;position:relative}}
.t-circle{{position:absolute;bottom:-100px;left:50%;transform:translateX(-50%);width:280px;height:280px;border-radius:50%;background:rgba(255,255,255,0.06)}}
.t-headline{{font-family:'Poppins',sans-serif;font-size:88px;font-weight:900;letter-spacing:-4px;line-height:.88;color:#fff;text-align:center;position:relative}}
.t-sub{{font-size:22px;color:rgba(255,255,255,0.75);text-align:center;margin-top:18px;position:relative}}
.icon-wrap{{position:relative;margin-top:32px}}
.bottom{{padding:44px 80px;display:flex;align-items:center;justify-content:space-between;flex-shrink:0}}
.b-left .bl-head{{font-family:'Poppins',sans-serif;font-size:30px;font-weight:800;letter-spacing:-0.5px;color:{LTEXT};margin-bottom:6px}}
.b-left .bl-sub{{font-size:18px;color:{LMUTED}}}
.stores{{display:flex;gap:12px}}
.store{{display:flex;align-items:center;gap:12px;background:{LSURF};border:1.5px solid {LBORDER};border-radius:14px;padding:13px 22px;box-shadow:0 2px 8px rgba(0,0,0,0.06)}}
.store-ico{{font-size:24px}}
.store-name{{font-family:'Poppins',sans-serif;font-weight:700;font-size:15px;color:{LTEXT}}}
.store-sub{{font-size:11px;color:{LMUTED}}}
"""
    body = f"""
<div class="top">
  <div class="t-circle"></div>
  <div class="t-headline">Baixe.<br>Conecte.<br>Toque.</div>
  <div class="t-sub">Grátis · iOS e Android · Brasil</div>
  <div class="icon-wrap">{mube_icon(88)}</div>
</div>
<div class="bottom">
  <div class="b-left">
    <div class="bl-head">Disponível agora.</div>
    <div class="bl-sub">Sua próxima parceria musical espera.</div>
  </div>
  <div class="stores">
    <div class="store"><div class="store-ico">📱</div><div><div class="store-sub">Baixe na</div><div class="store-name">App Store</div></div></div>
    <div class="store"><div class="store-ico">🤖</div><div><div class="store-sub">Baixe no</div><div class="store-name">Google Play</div></div></div>
  </div>
</div>
"""
    return wrap(style, body)


# ══════════════════════════════════════════════
# RENDER
# ══════════════════════════════════════════════

ARTS = [
    ("b01_algoritmo",      b01_algoritmo),
    ("b02_carlos",         b02_carlos),
    ("b03_antes_depois",   b03_antes_depois),
    ("b04_love_story",     b04_love_story),
    ("b05_ghosting",       b05_ghosting),
    ("b06_ratings",        b06_ratings),
    ("b07_pitch",          b07_pitch),
    ("b08_fomo",           b08_fomo),
    ("b09_mitos",          b09_mitos),
    ("b10_quiz_dark",      b10_quiz_dark),
    ("b11_manifesto2",     b11_manifesto2),
    # Light
    ("b12_dj_rafa",        b12_dj_rafa),
    ("b13_mari",           b13_mari),
    ("b14_tinder_parody",  b14_tinder_parody),
    ("b15_instrucoes",     b15_instrucoes),
    ("b16_testimonial",    b16_testimonial),
    ("b17_features_light", b17_features_light),
    ("b18_perda",          b18_perda),
    ("b19_qual_voce_light",b19_qual_voce_light),
    ("b20_banda_certa",    b20_banda_certa),
    ("b21_mensagem",       b21_mensagem),
    ("b22_cta_light",      b22_cta_light),
]


async def render_all():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page(viewport={"width": 1080, "height": 1080})
        for slug, fn in ARTS:
            print(f"🎨 Renderizando {slug}...")
            html = fn()
            tmp = OUT / f"_tmp_{slug}.html"
            tmp.write_text(html, encoding="utf-8")
            await page.goto(f"file:///{tmp.as_posix()}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)
            out_path = OUT / f"{slug}.png"
            await page.screenshot(path=str(out_path), clip={"x": 0, "y": 0, "width": 1080, "height": 1080})
            tmp.unlink()
            print(f"   ✓ {out_path.name}")
        await browser.close()
        print(f"\n✅ {len(ARTS)} artes geradas em: {OUT}")


if __name__ == "__main__":
    asyncio.run(render_all())
