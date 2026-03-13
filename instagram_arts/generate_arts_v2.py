#!/usr/bin/env python3
"""
Mube Instagram Arts v2 — 34 artes recriadas
Melhorias: texturas, gradientes, glow, iluminação, elementos gráficos,
textos maiores, fundos variados, tom informal/cômico.
"""

import asyncio
import base64
from pathlib import Path
from playwright.async_api import async_playwright

BASE = Path(__file__).parent.parent
ASSETS = BASE / "assets" / "images"
OUT = Path(__file__).parent / "output_v2"
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

# ─── SVG Assets ───
ICON_PATH = "M586.09,443.47c0,37.28-30.22,67.5-67.5,67.5-9.54,0-18.61-1.98-26.84-5.55-23.92-10.37-40.66-34.21-40.66-61.95v-241.87c0-4.81-1.97-9.19-5.14-12.36-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,.47-.01.94-.04,1.41v6.23c-.08,37.22-30.27,67.36-67.5,67.36-6.04,0-11.89-.79-17.45-2.28-28.09-7.49-48.96-32.65-50-62.85v-194.24c0-.43-.02-.86-.05-1.28-.31-4.3-2.2-8.19-5.09-11.08-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,13.75-11.25,25-25,25s-25-11.25-25-25v-284.37c.08-37.22,30.27-67.36,67.5-67.36,6.03,0,11.88.79,17.45,2.29,28.09,7.48,48.96,32.64,50,62.84v194.24c0,.43.02.86.05,1.28.31,4.3,2.2,8.19,5.09,11.08,3.17,3.17,7.55,5.14,12.36,5.14,9.62,0,17.5-7.87,17.5-17.5V209.24c0-.47,0-.94.04-1.41v-6.23c.08-37.22,30.27-67.36,67.5-67.36s67.42,30.14,67.5,67.36v176.66c5.58-1.49,11.45-2.29,17.5-2.29,37.28,0,67.5,30.22,67.5,67.5Z"

def mube_icon(size=36, bg="#e8466c", icon_color="#fff"):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 750" width="{size}" height="{size}"><circle cx="375" cy="375" r="375" fill="{bg}"/><path d="{ICON_PATH}" fill="{icon_color}"/></svg>'

def mube_logo(size=36):
    return f'<span style="display:inline-flex;align-items:center;gap:10px">{mube_icon(size)}<span style="font-family:Poppins,sans-serif;font-weight:800;font-size:{int(size*0.6)}px">mube</span></span>'

# ─── Fonts & Reset ───
FONTS = "@import url('https://fonts.googleapis.com/css2?family=Poppins:ital,wght@0,400;0,500;0,600;0,700;0,800;0,900;1,400;1,700;1,800;1,900&family=Inter:wght@400;500;600;700;800&display=swap');"
RESET = """*,*::before,*::after{margin:0;padding:0;box-sizing:border-box}
html,body{width:1080px;height:1080px;overflow:hidden;-webkit-font-smoothing:antialiased;font-family:'Inter',sans-serif;text-rendering:optimizeLegibility}"""

# ─── Background Styles (CSS) ───
# Noise overlay via SVG filter (subtle grain texture)
NOISE_OVERLAY = """
.noise::after{content:'';position:absolute;inset:0;opacity:0.06;pointer-events:none;
background-image:url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
background-size:128px 128px}
"""

# Floating orbs helper
def orb(x, y, size, color, blur=120):
    return f'<div style="position:absolute;left:{x}%;top:{y}%;width:{size}px;height:{size}px;border-radius:50%;background:{color};filter:blur({blur}px);opacity:0.5;pointer-events:none;z-index:0"></div>'

# Diagonal decorative lines
def deco_lines(color="rgba(232,70,108,0.08)", count=8):
    lines = ""
    for i in range(count):
        offset = i * 140 - 200
        lines += f'<div style="position:absolute;top:0;left:{offset}px;width:2px;height:1530px;background:{color};transform:rotate(35deg);transform-origin:top left;pointer-events:none;z-index:0"></div>'
    return lines

# Grid dots pattern
def dot_grid(color="rgba(255,255,255,0.04)", spacing=60, size=3):
    return f"""<div style="position:absolute;inset:0;background-image:radial-gradient(circle,{color} {size}px,transparent {size}px);background-size:{spacing}px {spacing}px;pointer-events:none;z-index:0"></div>"""

# Corner accent shapes
def corner_accent(pos="top-right", color="#E8466C", opacity=0.12):
    positions = {
        "top-right": "top:-80px;right:-80px",
        "top-left": "top:-80px;left:-80px",
        "bottom-right": "bottom:-80px;right:-80px",
        "bottom-left": "bottom:-80px;left:-80px",
    }
    return f'<div style="position:absolute;{positions[pos]};width:350px;height:350px;border-radius:50%;background:{color};opacity:{opacity};filter:blur(60px);pointer-events:none;z-index:0"></div>'

PRIMARY = "#E8466C"
ACCENT_PURPLE = "#9B59B6"
ACCENT_BLUE = "#4A90D9"
ACCENT_GOLD = "#D4A843"

def wrap(style, body):
    return f"""<!DOCTYPE html><html><head><meta charset="UTF-8">
<style>{FONTS}{RESET}{NOISE_OVERLAY}{style}</style></head><body>{body}</body></html>"""


# ═══════════════════════════════════════════
# ARTE 01 — MANIFESTO
# ═══════════════════════════════════════════
def art_01_manifesto():
    s = f"""
body{{background:linear-gradient(160deg,#0A0A0A 0%,#1a0a14 40%,#0f0a1a 100%);color:#fff;display:flex;flex-direction:column;justify-content:center;padding:90px;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};margin-bottom:28px;position:relative;z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:110px;font-weight:900;line-height:.88;letter-spacing:-5px;color:#fff;margin-bottom:32px;position:relative;z-index:2}}
.h1 em{{font-style:normal;color:{PRIMARY};text-shadow:0 0 60px rgba(232,70,108,0.4)}}
.body{{font-size:22px;color:#aaa;line-height:1.55;max-width:600px;margin-bottom:50px;position:relative;z-index:2}}
.footer{{display:flex;align-items:center;gap:14px;position:relative;z-index:2}}
"""
    b = f"""
{orb(70, -10, 500, 'rgba(232,70,108,0.15)', 150)}
{orb(-5, 80, 400, 'rgba(155,89,182,0.1)', 130)}
{dot_grid()}
{corner_accent("top-right", PRIMARY, 0.2)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="tag">MUBE · PLATAFORMA MUSICAL</div>
<h1 class="h1">A música<br><em>conecta.</em><br>O Mube<br><em>aproxima.</em></h1>
<p class="body">Para músicos, bandas, estúdios e contratantes que levam a música a sério. Sem ruído.</p>
<div class="footer">{mube_logo(40)}</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE 02 — QUATRO PERFIS
# ═══════════════════════════════════════════
def art_02_quatro_perfis():
    colors = {"musico": PRIMARY, "banda": ACCENT_PURPLE, "estudio": ACCENT_BLUE, "contratante": ACCENT_GOLD}
    def card(emoji, title, desc, badge, color):
        return f"""<div style="background:linear-gradient(145deg,rgba({int(color[1:3],16)},{int(color[3:5],16)},{int(color[5:7],16)},0.12),rgba(30,30,30,0.9));border:1px solid rgba({int(color[1:3],16)},{int(color[3:5],16)},{int(color[5:7],16)},0.25);border-radius:24px;padding:40px;position:relative;overflow:hidden">
<div style="font-size:48px;margin-bottom:16px">{emoji}</div>
<div style="font-family:Poppins,sans-serif;font-size:32px;font-weight:800;margin-bottom:10px">{title}</div>
<div style="font-size:18px;color:#aaa;line-height:1.5;margin-bottom:18px">{desc}</div>
<div style="display:inline-block;padding:8px 20px;background:{color};border-radius:50px;font-size:14px;font-weight:700;letter-spacing:1px">{badge}</div>
<div style="position:absolute;top:-30px;right:-30px;width:120px;height:120px;border-radius:50%;background:{color};opacity:0.08;filter:blur(40px)"></div>
</div>"""
    s = f"""
body{{background:linear-gradient(170deg,#0c0c12 0%,#120c18 50%,#0a0c14 100%);color:#fff;padding:80px;display:flex;flex-direction:column;gap:32px;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY}}}
.h1{{font-family:'Poppins',sans-serif;font-size:64px;font-weight:900;line-height:.95;letter-spacing:-3px}}
.grid{{display:grid;grid-template-columns:1fr 1fr;gap:24px;flex:1}}
"""
    b = f"""
{dot_grid("rgba(255,255,255,0.025)", 50, 2)}
{orb(80, 10, 300, 'rgba(155,89,182,0.12)', 120)}
{orb(10, 85, 250, 'rgba(74,144,217,0.1)', 100)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="tag">QUEM USA O MUBE</div>
<div class="h1">Qual é o seu<br>papel na música?</div>
<div class="grid">
{card("🎸", "Músico", "Cantor, instrumentista, DJ. Seu talento merece ser visto.", "♪ INDIVIDUAL", PRIMARY)}
{card("🎶", "Banda", "Grupo musical. Mostre quem vocês são e atraiam oportunidades.", "♪ GRUPO", ACCENT_PURPLE)}
{card("🎙️", "Estúdio", "Gravação, mixagem e masterização. Conecte com quem precisa.", "♪ SERVIÇO", ACCENT_BLUE)}
{card("🎤", "Contratante", "Eventos e casas de show. Encontre os artistas certos.", "♪ PRODUTOR", ACCENT_GOLD)}
</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE 03 — MATCHPOINT
# ═══════════════════════════════════════════
def art_03_matchpoint():
    ss = SS.get(3, SS.get(1, ""))
    s = f"""
body{{background:linear-gradient(180deg,#0c0510 0%,#150a1e 40%,#0a0a12 100%);color:#fff;display:flex;flex-direction:column;align-items:center;padding:70px;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};margin-bottom:20px;z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:62px;font-weight:900;line-height:.95;text-align:center;letter-spacing:-3px;margin-bottom:40px;z-index:2}}
.h1 em{{font-style:italic;color:{PRIMARY};text-shadow:0 0 40px rgba(232,70,108,0.3)}}
.phone{{width:320px;border-radius:32px;overflow:hidden;box-shadow:0 30px 80px rgba(232,70,108,0.2),0 0 120px rgba(232,70,108,0.08);position:relative;z-index:2;border:2px solid rgba(255,255,255,0.08)}}
.phone img{{width:100%;display:block}}
.sub{{font-size:22px;color:#bbb;text-align:center;margin-top:36px;z-index:2}}
.cta{{display:inline-flex;align-items:center;gap:10px;padding:14px 36px;background:rgba(232,70,108,0.15);border:1px solid rgba(232,70,108,0.3);border-radius:50px;font-size:16px;font-weight:700;color:#fff;margin-top:24px;z-index:2}}
"""
    b = f"""
{orb(50, 40, 600, 'rgba(232,70,108,0.1)', 200)}
{orb(20, 20, 300, 'rgba(155,89,182,0.08)', 150)}
{deco_lines("rgba(232,70,108,0.04)", 6)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="tag">MATCHPOINT · RECURSO EXCLUSIVO</div>
<h1 class="h1">Conecte-se com quem toca<br>na mesma <em>frequência</em></h1>
<div class="phone">{"<img src='" + ss + "'/>" if ss else '<div style="height:500px;background:#1a1a2e"></div>'}</div>
<p class="sub">Explore perfis, dê match e inicie uma conversa.</p>
<div class="cta">{mube_icon(24)} mube.app · disponível agora</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE 04 — BUSCA INTELIGENTE
# ═══════════════════════════════════════════
def art_04_busca():
    ss = SS.get(2, SS.get(1, ""))
    s = f"""
body{{background:linear-gradient(135deg,#0a0c14 0%,#0f1020 50%,#140a18 100%);color:#fff;display:grid;grid-template-columns:1fr 1fr;gap:50px;align-items:center;padding:80px;position:relative;overflow:hidden}}
.left{{position:relative;z-index:2}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};margin-bottom:24px}}
.h1{{font-family:'Poppins',sans-serif;font-size:72px;font-weight:900;line-height:.9;letter-spacing:-3px;margin-bottom:24px}}
.h1 em{{font-style:normal;color:{PRIMARY};text-shadow:0 0 50px rgba(232,70,108,0.3)}}
.body{{font-size:20px;color:#999;line-height:1.55;margin-bottom:30px}}
.pills{{display:flex;flex-direction:column;gap:12px}}
.pill{{display:flex;align-items:center;gap:10px;font-size:18px;font-weight:600}}
.pill .dot{{width:10px;height:10px;border-radius:50%}}
.right{{position:relative;z-index:2}}
.phone{{width:100%;border-radius:28px;overflow:hidden;box-shadow:0 20px 60px rgba(0,0,0,0.5),0 0 80px rgba(232,70,108,0.08);border:1px solid rgba(255,255,255,0.06)}}
.phone img{{width:100%;display:block}}
"""
    b = f"""
{orb(85, 50, 400, 'rgba(74,144,217,0.1)', 140)}
{orb(0, 0, 350, 'rgba(232,70,108,0.08)', 120)}
{dot_grid("rgba(255,255,255,0.02)", 55, 2)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="left">
<div class="tag">BUSCA · DESCUBRA</div>
<h1 class="h1">Encontre<br>o profissional<br><em>certo.</em></h1>
<p class="body">Busque por instrumento, gênero musical ou função. Sem algoritmo escondido.</p>
<div class="pills">
<div class="pill"><span class="dot" style="background:{PRIMARY}"></span>Cantores & Instrumentistas</div>
<div class="pill"><span class="dot" style="background:{ACCENT_PURPLE}"></span>Bandas & Grupos</div>
<div class="pill"><span class="dot" style="background:{ACCENT_BLUE}"></span>Estúdios de Gravação</div>
<div class="pill"><span class="dot" style="background:#2ecc71"></span>Beatmakers & DJs</div>
</div>
</div>
<div class="right">
<div class="phone">{"<img src='" + ss + "'/>" if ss else '<div style="height:600px;background:#1a1a2e"></div>'}</div>
</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE 05 — CHAT
# ═══════════════════════════════════════════
def art_05_chat():
    s = f"""
body{{background:linear-gradient(170deg,#080810 0%,#10081a 50%,#0a1014 100%);color:#fff;display:flex;flex-direction:column;padding:80px;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};text-align:center;margin-bottom:16px;z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:64px;font-weight:900;line-height:.92;text-align:center;letter-spacing:-3px;margin-bottom:50px;z-index:2}}
.h1 em{{font-style:italic;color:{PRIMARY};text-shadow:0 0 40px rgba(232,70,108,0.3)}}
.chat{{flex:1;display:flex;flex-direction:column;gap:20px;padding:0 30px;z-index:2}}
.msg-row{{display:flex;flex-direction:column}}
.msg-row.right{{align-items:flex-end}}
.sender{{font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;color:#666;margin-bottom:6px}}
.bubble{{padding:22px 28px;border-radius:22px;font-size:21px;line-height:1.4;max-width:700px;position:relative}}
.bubble.other{{background:rgba(255,255,255,0.07);border:1px solid rgba(255,255,255,0.08)}}
.bubble.me{{background:linear-gradient(135deg,{PRIMARY},#d63a5e);color:#fff;box-shadow:0 8px 30px rgba(232,70,108,0.3)}}
.time{{font-size:13px;color:#555;margin-top:6px}}
.footer{{display:flex;justify-content:space-between;align-items:flex-end;margin-top:auto;padding-top:30px;z-index:2}}
.footer-text{{font-family:'Poppins',sans-serif;font-size:38px;font-weight:900;line-height:1.05}}
.footer-text em{{font-style:normal;color:{PRIMARY}}}
"""
    b = f"""
{orb(50, 50, 500, 'rgba(232,70,108,0.06)', 180)}
{orb(80, 20, 300, 'rgba(155,89,182,0.06)', 130)}
{deco_lines("rgba(255,255,255,0.015)", 10)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="tag">CHAT · COMUNICAÇÃO REAL</div>
<h1 class="h1">Do match à parceria,<br><em>em segundos.</em></h1>
<div class="chat">
<div class="msg-row">
<div class="sender">HYGOR TOMAZ</div>
<div class="bubble other">Oi! Vi seu perfil no Mube, você toca baixo né? Estamos precisando pra um show no fim do mês 🎶</div>
<div class="time">14:32</div>
</div>
<div class="msg-row right">
<div class="sender">VOCÊ</div>
<div class="bubble me">Oi Hygor! Sim, toco baixo há 8 anos. Que tipo de show é?</div>
<div class="time">14:34</div>
</div>
<div class="msg-row">
<div class="sender">HYGOR TOMAZ</div>
<div class="bubble other">Show de rock autoral, 45 min de set. Podemos marcar um ensaio essa semana? 🤘</div>
<div class="time">14:35</div>
</div>
<div class="msg-row right">
<div class="bubble me">Perfeito! Quinta ou sexta funciona. Manda o repertório que já começo a estudar 🎵</div>
<div class="time">14:36</div>
</div>
</div>
<div class="footer">
<div class="footer-text">Sua próxima<br>parceria começa<br><em>aqui.</em></div>
{mube_logo(44)}
</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE 06 — GALERIA / PORTFÓLIO
# ═══════════════════════════════════════════
def art_06_galeria():
    ss1 = SS.get(5, SS.get(1, ""))
    ss2 = SS.get(6, SS.get(1, ""))
    s = f"""
body{{background:linear-gradient(150deg,#0a0810 0%,#180a14 50%,#0c1018 100%);color:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:80px;gap:40px;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:80px;font-weight:900;line-height:.9;text-align:center;letter-spacing:-4px;z-index:2}}
.h1 em{{font-style:italic;color:{PRIMARY};text-shadow:0 0 50px rgba(232,70,108,0.3)}}
.phones{{display:flex;gap:30px;z-index:2}}
.phone{{width:260px;border-radius:26px;overflow:hidden;box-shadow:0 25px 60px rgba(0,0,0,0.4),0 0 50px rgba(232,70,108,0.08);border:1px solid rgba(255,255,255,0.06)}}
.phone img{{width:100%;display:block}}
.body{{font-size:22px;color:#999;text-align:center;line-height:1.5;max-width:600px;z-index:2}}
.pills{{display:flex;gap:18px;z-index:2}}
.pill{{padding:8px 22px;border-radius:50px;font-size:15px;font-weight:700;color:#fff;border:1px solid rgba(232,70,108,0.3);background:rgba(232,70,108,0.1)}}
"""
    b = f"""
{orb(20, 30, 400, 'rgba(232,70,108,0.1)', 150)}
{orb(80, 70, 350, 'rgba(155,89,182,0.08)', 130)}
{corner_accent("bottom-left", ACCENT_PURPLE, 0.1)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="tag">GALERIA · PORTFÓLIO MUSICAL</div>
<h1 class="h1">Seu portfólio.<br>Sua <em>história.</em></h1>
<div class="phones">
<div class="phone" style="transform:rotate(-4deg)">{"<img src='" + ss1 + "'/>" if ss1 else '<div style="height:450px;background:#1a1a2e"></div>'}</div>
<div class="phone" style="transform:rotate(3deg)">{"<img src='" + ss2 + "'/>" if ss2 else '<div style="height:450px;background:#1a1a2e"></div>'}</div>
</div>
<p class="body">Fotos, vídeos e links integrados ao seu perfil.</p>
<div class="pills"><span class="pill">📸 Fotos & Vídeos</span><span class="pill">🔗 Links externos</span><span class="pill">💰 Grátis</span></div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE 07 — PERFIL DESTAQUE
# ═══════════════════════════════════════════
def art_07_perfil():
    ss = SS.get(4, SS.get(1, ""))
    s = f"""
body{{background:linear-gradient(160deg,#08080e 0%,#12081a 50%,#0a0e16 100%);color:#fff;display:flex;flex-direction:column;align-items:center;padding:70px;gap:30px;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:60px;font-weight:900;text-align:center;letter-spacing:-3px;z-index:2}}
.center{{display:flex;align-items:flex-start;gap:40px;z-index:2;flex:1}}
.phone{{width:300px;border-radius:28px;overflow:hidden;box-shadow:0 20px 80px rgba(232,70,108,0.2),0 0 100px rgba(232,70,108,0.06);border:1px solid rgba(255,255,255,0.06);flex-shrink:0}}
.phone img{{width:100%;display:block}}
.features{{display:flex;flex-direction:column;gap:16px;padding-top:20px}}
.feat{{background:rgba(255,255,255,0.04);border:1px solid rgba(255,255,255,0.06);border-radius:18px;padding:24px 28px}}
.feat-title{{font-size:15px;font-weight:700;letter-spacing:3px;text-transform:uppercase;color:{PRIMARY};margin-bottom:6px}}
.feat-desc{{font-size:18px;color:#bbb}}
"""
    b = f"""
{orb(50, 50, 500, 'rgba(232,70,108,0.08)', 180)}
{corner_accent("top-right", ACCENT_PURPLE, 0.12)}
{dot_grid("rgba(255,255,255,0.02)", 50, 2)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="tag">PERFIL · IDENTIDADE PROFISSIONAL</div>
<h1 class="h1">Um perfil que fala por você.</h1>
<div class="center">
<div style="display:flex;flex-direction:column;gap:14px">
<div class="feat"><div class="feat-title">LOCALIZAÇÃO</div><div class="feat-desc">Conecta por proximidade geográfica</div></div>
<div class="feat"><div class="feat-title">BADGE DE TIPO</div><div class="feat-desc">Músico, Banda, Estúdio ou Contratante</div></div>
<div class="feat"><div class="feat-title">INSTRUMENTOS</div><div class="feat-desc">Chips com suas especialidades</div></div>
</div>
<div class="phone">{"<img src='" + ss + "'/>" if ss else '<div style="height:550px;background:#1a1a2e"></div>'}</div>
<div style="display:flex;flex-direction:column;gap:14px">
<div class="feat"><div class="feat-title">FAVORITOS</div><div class="feat-desc">Quem curtiu seu perfil</div></div>
<div class="feat"><div class="feat-title">FUNÇÕES TÉCNICAS</div><div class="feat-desc">Arranjador, beatmaker, compositor...</div></div>
<div class="feat"><div class="feat-title">CHAT DIRETO</div><div class="feat-desc">Inicie conversa com um toque</div></div>
</div>
</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE 08 — EM NÚMEROS
# ═══════════════════════════════════════════
def art_08_numeros():
    s = f"""
body{{background:linear-gradient(145deg,#08060e 0%,#160a1a 50%,#0c0814 100%);color:#fff;display:flex;flex-direction:column;justify-content:center;padding:90px;gap:40px;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};z-index:2}}
.row{{display:flex;align-items:baseline;gap:24px;z-index:2}}
.big{{font-family:'Poppins',sans-serif;font-size:160px;font-weight:900;line-height:1;background:linear-gradient(135deg,#fff,#E8466C);-webkit-background-clip:text;-webkit-text-fill-color:transparent}}
.label{{font-family:'Poppins',sans-serif;font-size:50px;font-weight:800;color:{PRIMARY}}}
.detail{{font-size:20px;color:#888;margin-top:-10px;z-index:2}}
.divider{{width:100%;height:1px;background:linear-gradient(90deg,transparent,rgba(232,70,108,0.2),transparent);z-index:2}}
.footer{{display:flex;justify-content:space-between;align-items:flex-end;z-index:2;margin-top:20px}}
.footer-text{{font-family:'Poppins',sans-serif;font-size:38px;font-weight:900;line-height:1.05}}
.footer-text em{{font-style:normal;color:{PRIMARY}}}
"""
    b = f"""
{orb(80, 30, 400, 'rgba(232,70,108,0.12)', 160)}
{orb(10, 70, 350, 'rgba(155,89,182,0.08)', 130)}
{deco_lines("rgba(232,70,108,0.03)", 12)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="tag">MUBE · EM NÚMEROS</div>
<div class="row"><div class="big">4</div><div class="label">tipos de perfil</div></div>
<div class="detail" style="padding-left:10px">Músico · Banda · Estúdio · Contratante</div>
<div class="divider"></div>
<div class="row"><div class="big">1</div><div class="label">plataforma</div></div>
<div class="detail" style="padding-left:10px">Tudo em um só lugar · Grátis · iOS & Android</div>
<div class="divider"></div>
<div class="row"><div class="big">∞</div><div class="label">conexões</div></div>
<div class="detail" style="padding-left:10px">possibilidades · colaborações</div>
<div class="footer">
<div class="footer-text">Uma plataforma.<br><em>Infinitas possibilidades.</em></div>
{mube_logo(44)}
</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE 09 — DOWNLOAD CTA
# ═══════════════════════════════════════════
def art_09_download():
    s = f"""
body{{background:linear-gradient(180deg,#12081a 0%,#1a0a14 40%,#0a0a12 100%);color:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:24px;position:relative;overflow:hidden}}
.icon-wrap{{width:120px;height:120px;border-radius:30px;display:flex;align-items:center;justify-content:center;background:linear-gradient(135deg,{PRIMARY},#c0365a);box-shadow:0 20px 60px rgba(232,70,108,0.4),0 0 120px rgba(232,70,108,0.15);z-index:2}}
.tag{{font-size:15px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};z-index:2;margin-top:20px}}
.h1{{font-family:'Poppins',sans-serif;font-size:90px;font-weight:900;text-align:center;line-height:.9;letter-spacing:-4px;z-index:2}}
.h1 em{{font-style:normal;color:{PRIMARY};text-shadow:0 0 60px rgba(232,70,108,0.4)}}
.sub{{font-size:22px;color:#888;z-index:2}}
.stores{{display:flex;gap:20px;margin-top:20px;z-index:2}}
.store{{padding:16px 36px;background:rgba(255,255,255,0.06);border:1px solid rgba(255,255,255,0.1);border-radius:16px;display:flex;align-items:center;gap:12px;font-weight:700;font-size:18px}}
.store small{{font-size:12px;font-weight:500;color:#888;display:block}}
"""
    b = f"""
{orb(50, 30, 500, 'rgba(232,70,108,0.12)', 180)}
{orb(30, 60, 300, 'rgba(155,89,182,0.08)', 140)}
{corner_accent("bottom-right", PRIMARY, 0.15)}
{corner_accent("top-left", ACCENT_PURPLE, 0.08)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="icon-wrap">{mube_icon(70)}</div>
<div class="tag">DISPONÍVEL AGORA</div>
<h1 class="h1">Baixe o <em>Mube.</em><br>É grátis.</h1>
<div class="sub">Android e iOS · Brasil</div>
<div class="stores">
<div class="store"><div><small>Disponível na</small>App Store</div></div>
<div class="store"><div><small>Disponível no</small>Google Play</div></div>
</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE 10 — PARA MÚSICOS
# ═══════════════════════════════════════════
def art_10_musicos():
    s = f"""
body{{background:linear-gradient(155deg,#0a0a12 0%,#14081e 45%,#0e1018 100%);color:#fff;display:flex;flex-direction:column;justify-content:center;padding:90px;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};margin-bottom:24px;z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:100px;font-weight:900;line-height:.88;letter-spacing:-5px;margin-bottom:30px;z-index:2}}
.h1 em{{font-style:italic;color:{PRIMARY};text-shadow:0 0 50px rgba(232,70,108,0.3)}}
.quote{{font-family:'Poppins',sans-serif;font-size:36px;font-weight:800;border-left:4px solid {PRIMARY};padding-left:28px;margin-bottom:30px;z-index:2;line-height:1.2}}
.body{{font-size:22px;color:#999;line-height:1.55;max-width:600px;margin-bottom:40px;z-index:2}}
.cta{{display:inline-flex;align-items:center;gap:12px;padding:18px 40px;background:linear-gradient(135deg,{PRIMARY},#c0365a);border-radius:50px;font-size:20px;font-weight:800;color:#fff;box-shadow:0 12px 40px rgba(232,70,108,0.35);z-index:2}}
"""
    b = f"""
{orb(75, 20, 450, 'rgba(232,70,108,0.1)', 160)}
{orb(90, 80, 300, 'rgba(155,89,182,0.08)', 120)}
{deco_lines("rgba(155,89,182,0.025)", 8)}
{dot_grid("rgba(255,255,255,0.02)", 60, 2)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="tag">PARA MÚSICOS · PROFISSIONAIS</div>
<h1 class="h1">Você toca,<br>canta ou<br><em>produz?</em></h1>
<div class="quote">Então você já deveria<br>estar no Mube.</div>
<p class="body">Crie seu perfil profissional, mostre seus instrumentos, gêneros e funções técnicas. Deixe as oportunidades chegarem até você.</p>
<div class="cta">🎵 Criar meu perfil agora</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE 11 — LOCALIZAÇÃO
# ═══════════════════════════════════════════
def art_11_localizacao():
    s = f"""
body{{background:linear-gradient(160deg,#060610 0%,#100a18 50%,#080c14 100%);color:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:80px;position:relative;overflow:hidden}}
.radar{{position:relative;width:550px;height:550px;z-index:2;margin-bottom:40px}}
.ring{{position:absolute;border-radius:50%;border:1px solid rgba(232,70,108,0.12)}}
.ring1{{width:550px;height:550px;top:0;left:0}}
.ring2{{width:370px;height:370px;top:90px;left:90px}}
.ring3{{width:190px;height:190px;top:180px;left:180px}}
.center-dot{{position:absolute;width:20px;height:20px;border-radius:50%;background:{PRIMARY};top:265px;left:265px;box-shadow:0 0 30px rgba(232,70,108,0.6),0 0 60px rgba(232,70,108,0.3)}}
.pin{{position:absolute;display:flex;flex-direction:column;align-items:center;gap:6px}}
.pin-icon{{width:50px;height:50px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:24px;border:2px solid;box-shadow:0 0 20px rgba(0,0,0,0.3)}}
.pin-label{{font-size:14px;font-weight:600;color:#ccc;background:rgba(0,0,0,0.5);padding:4px 12px;border-radius:8px;white-space:nowrap}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:68px;font-weight:900;text-align:center;letter-spacing:-3px;z-index:2;line-height:.92}}
.h1 em{{font-style:normal;color:{PRIMARY};text-shadow:0 0 40px rgba(232,70,108,0.3)}}
.sub{{font-size:22px;color:#888;text-align:center;z-index:2;margin-top:12px}}
"""
    b = f"""
{orb(50, 40, 400, 'rgba(232,70,108,0.06)', 180)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="radar">
<div class="ring ring1"></div><div class="ring ring2"></div><div class="ring ring3"></div>
<div class="center-dot"></div>
<div class="pin" style="top:20px;left:230px"><div class="pin-icon" style="background:rgba(232,70,108,0.15);border-color:{PRIMARY}">🎸</div><div class="pin-label">Guitarrista · &lt;1km</div></div>
<div class="pin" style="top:120px;left:420px"><div class="pin-icon" style="background:rgba(155,89,182,0.15);border-color:{ACCENT_PURPLE}">🥁</div><div class="pin-label">Baterista · &lt;2km</div></div>
<div class="pin" style="top:350px;left:400px"><div class="pin-icon" style="background:rgba(46,204,113,0.15);border-color:#2ecc71">🎹</div><div class="pin-label">Tecladista · &lt;3km</div></div>
<div class="pin" style="top:370px;left:60px"><div class="pin-icon" style="background:rgba(212,168,67,0.15);border-color:{ACCENT_GOLD}">🎤</div><div class="pin-label">Cantor · &lt;2km</div></div>
<div class="pin" style="top:100px;left:30px"><div class="pin-icon" style="background:rgba(74,144,217,0.15);border-color:{ACCENT_BLUE}">🎵</div><div class="pin-label">Banda · &lt;4km</div></div>
</div>
<div class="tag">LOCALIZAÇÃO · BUSCA PRÓXIMA</div>
<h1 class="h1">Músicos a <em>&lt;1km</em><br>de você.</h1>
<p class="sub">Descubra talentos na sua cidade e bairro.</p>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE 12 — COMUNIDADE
# ═══════════════════════════════════════════
def art_12_comunidade():
    nodes = [
        ("HT", "Músico", "#E8466C", 80, 60),
        ("PT", "Banda", ACCENT_PURPLE, 30, 100),
        ("GM", "DJ", PRIMARY, 10, 220),
        ("VL", "Produtor", ACCENT_BLUE, 85, 180),
        ("LF", "Baixista", "#2ecc71", 65, 200),
        ("KC", "Guitarrista", ACCENT_BLUE, 90, 330),
        ("AS", "Estúdio", ACCENT_PURPLE, 8, 370),
        ("CW", "Técnico", ACCENT_BLUE, 40, 340),
        ("RB", "Baterista", ACCENT_GOLD, 28, 460),
        ("MN", "Cantor", "#2ecc71", 72, 440),
    ]
    nodes_html = ""
    for initials, role, color, x_pct, y_px in nodes:
        nodes_html += f"""<div style="position:absolute;left:{x_pct}%;top:{y_px}px;display:flex;flex-direction:column;align-items:center;gap:6px">
<div style="width:60px;height:60px;border-radius:50%;border:2px solid {color};display:flex;align-items:center;justify-content:center;font-weight:800;font-size:20px;color:{color};background:rgba(0,0,0,0.4)">{initials}</div>
<div style="font-size:14px;color:#888">{role}</div></div>"""

    s = f"""
body{{background:linear-gradient(150deg,#060610 0%,#120818 50%,#0a0c16 100%);color:#fff;display:flex;flex-direction:column;padding:80px;position:relative;overflow:hidden}}
.network{{position:relative;flex:1;z-index:2}}
.center-node{{position:absolute;left:50%;top:250px;transform:translate(-50%,-50%);width:90px;height:90px;border-radius:50%;background:linear-gradient(135deg,{PRIMARY},#c0365a);display:flex;align-items:center;justify-content:center;box-shadow:0 0 60px rgba(232,70,108,0.3),0 0 120px rgba(232,70,108,0.15)}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};text-align:center;z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:62px;font-weight:900;text-align:center;line-height:.92;letter-spacing:-3px;z-index:2;margin:12px 0}}
.h1 em{{font-style:normal;color:{PRIMARY};text-shadow:0 0 40px rgba(232,70,108,0.3)}}
.sub{{font-size:20px;color:#888;text-align:center;z-index:2}}
"""
    b = f"""
{orb(50, 30, 500, 'rgba(232,70,108,0.06)', 200)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="network">
<div class="center-node">{mube_icon(50)}</div>
{nodes_html}
</div>
<div class="tag">COMUNIDADE · REDE MUSICAL</div>
<h1 class="h1">Faça parte da maior<br>rede musical do <em>Brasil.</em></h1>
<p class="sub">Músicos, bandas, estúdios e contratantes conectados.</p>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE B01 — ALGORITMO (VS)
# ═══════════════════════════════════════════
def art_b01_algoritmo():
    def row_left(emoji, text, sub):
        return f"""<div style="display:flex;align-items:center;gap:16px;padding:22px 26px;background:rgba(255,255,255,0.04);border-radius:18px;border:1px solid rgba(255,255,255,0.06)">
<span style="font-size:36px">{emoji}</span>
<div><div style="font-size:19px;font-weight:600">{text}</div><div style="font-size:14px;color:#666">{sub}</div></div></div>"""
    def row_right(emoji, text, sub):
        return f"""<div style="display:flex;align-items:center;gap:16px;padding:22px 26px;background:linear-gradient(135deg,rgba(232,70,108,0.12),rgba(155,89,182,0.08));border-radius:18px;border:1px solid rgba(232,70,108,0.2)">
<span style="font-size:36px">{emoji}</span>
<div><div style="font-size:19px;font-weight:700">{text}</div><div style="font-size:14px;color:#aaa">{sub}</div></div></div>"""

    s = f"""
body{{background:linear-gradient(160deg,#08080e 0%,#10081a 50%,#0c0a14 100%);color:#fff;display:flex;flex-direction:column;padding:80px;gap:40px;position:relative;overflow:hidden}}
.top{{display:grid;grid-template-columns:1fr auto 1fr;gap:30px;align-items:center;z-index:2}}
.col{{display:flex;flex-direction:column;gap:16px}}
.col-title{{font-size:14px;font-weight:700;letter-spacing:4px;text-transform:uppercase;display:flex;align-items:center;gap:8px;margin-bottom:8px}}
.vs{{font-family:'Poppins',sans-serif;font-size:36px;font-weight:900;color:{PRIMARY};background:linear-gradient(135deg,{PRIMARY},#c0365a);-webkit-background-clip:text;-webkit-text-fill-color:transparent}}
.bottom{{z-index:2;text-align:center;margin-top:auto}}
.h1{{font-family:'Poppins',sans-serif;font-size:60px;font-weight:900;line-height:.92;letter-spacing:-3px}}
.h1 em{{font-style:italic;color:{PRIMARY};text-shadow:0 0 40px rgba(232,70,108,0.3)}}
"""
    b = f"""
{orb(50, 50, 500, 'rgba(232,70,108,0.06)', 180)}
{orb(80, 20, 300, 'rgba(155,89,182,0.06)', 130)}
{dot_grid("rgba(255,255,255,0.015)", 50, 2)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="top">
<div class="col">
<div class="col-title" style="color:#666">📱 INSTAGRAM / TIKTOK</div>
{row_left("🍕", "Receita de bolo de cenoura", "que vai mudar sua vida")}
{row_left("🐱", "Gatinho fofo dormindo", "4.2 milhões de views")}
{row_left("💪", "Motivação das 6h da manhã", '"você consegue, guerreiro!"')}
</div>
<div class="vs">VS</div>
<div class="col">
<div class="col-title" style="color:{PRIMARY}">🎵 MUBE</div>
{row_right("🥁", "Rafael Drummond · Baterista", "800m de você · disponível")}
{row_right("🎹", "Estúdio Onda Livre", "Gravação + mix disponível agora")}
{row_right("🎸", "Banda Os Estranhos", "Procurando vocalista em SP")}
</div>
</div>
<div class="bottom">
<h1 class="h1">Às vezes o algoritmo acerta.<br><em>Aqui sempre.</em></h1>
<div style="margin-top:20px">{mube_logo(40)}</div>
</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE B02 — CARLOS MENDES (personagem)
# ═══════════════════════════════════════════
def art_b02_carlos():
    s = f"""
body{{background:linear-gradient(165deg,#0a0810 0%,#180a14 50%,#0c0a18 100%);color:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:80px;position:relative;overflow:hidden}}
.card{{background:linear-gradient(145deg,rgba(255,255,255,0.04),rgba(255,255,255,0.02));border:1px solid rgba(255,255,255,0.08);border-radius:28px;padding:50px;max-width:820px;width:100%;position:relative;z-index:2}}
.top-label{{font-size:12px;letter-spacing:4px;text-transform:uppercase;color:#555;position:absolute;top:30px;right:30px}}
.profile{{display:flex;align-items:center;gap:24px;margin-bottom:30px}}
.avatar{{width:80px;height:80px;border-radius:50%;border:3px solid {PRIMARY};display:flex;align-items:center;justify-content:center;font-size:40px;background:rgba(232,70,108,0.1)}}
.name{{font-family:'Poppins',sans-serif;font-size:42px;font-weight:900;letter-spacing:-2px}}
.role{{font-size:18px;color:#888}}
.quote{{border-left:4px solid {PRIMARY};padding:24px 28px;margin:24px 0;font-size:24px;font-style:italic;line-height:1.5;background:rgba(232,70,108,0.04);border-radius:0 16px 16px 0}}
.quote strong{{color:{PRIMARY};font-style:normal}}
.stats{{display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px;margin-top:24px}}
.stat{{text-align:center;padding:24px;background:rgba(255,255,255,0.03);border:1px solid rgba(255,255,255,0.06);border-radius:18px}}
.stat-num{{font-family:'Poppins',sans-serif;font-size:48px;font-weight:900;color:{PRIMARY}}}
.stat-label{{font-size:15px;color:#888;margin-top:4px}}
.resolve{{display:flex;align-items:center;gap:10px;justify-content:flex-end;margin-top:20px;font-size:18px;font-weight:700;color:{PRIMARY}}}
"""
    b = f"""
{orb(80, 20, 350, 'rgba(232,70,108,0.1)', 140)}
{orb(10, 70, 300, 'rgba(155,89,182,0.06)', 120)}
{corner_accent("top-left", ACCENT_PURPLE, 0.08)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="card">
<div class="top-label">PERSONAGEM REAL (FICTÍCIO)</div>
<div class="profile">
<div class="avatar">🎸</div>
<div><div class="name">Carlos Mendes</div><div class="role">Guitarrista · 34 anos · Rio de Janeiro</div></div>
</div>
<div class="quote">"Criei <strong>7 grupos no WhatsApp</strong> procurando baterista.<br>Mandei mensagem pra 43 pessoas.<br>Achei um. <strong>Ele sumiu antes do show.</strong>"</div>
<div class="stats">
<div class="stat"><div class="stat-num">7</div><div class="stat-label">grupos criados</div></div>
<div class="stat"><div class="stat-num">43</div><div class="stat-label">mensagens enviadas</div></div>
<div class="stat"><div class="stat-num">0</div><div class="stat-label">shows que aconteceram</div></div>
</div>
<div class="resolve">{mube_icon(24)} mube resolve</div>
</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE B03 — ANTES / DEPOIS
# ═══════════════════════════════════════════
def art_b03_antes_depois():
    def item_bad(emoji, text):
        return f'<div style="display:flex;align-items:flex-start;gap:14px;font-size:22px;line-height:1.4"><span style="font-size:28px">{emoji}</span><span>{text}</span></div>'
    def item_good(emoji, text):
        return f'<div style="display:flex;align-items:flex-start;gap:14px;font-size:22px;line-height:1.4;font-weight:600"><span style="font-size:28px">{emoji}</span><span>{text}</span></div>'

    s = f"""
body{{background:linear-gradient(180deg,#0a080e 0%,#0e0a14 100%);color:#fff;display:grid;grid-template-columns:1fr 1fr;position:relative;overflow:hidden}}
.side{{padding:70px 60px;display:flex;flex-direction:column;gap:28px;position:relative;z-index:2}}
.side-bad{{border-right:1px solid rgba(255,255,255,0.06)}}
.side-good{{background:linear-gradient(180deg,rgba(232,70,108,0.04),rgba(46,204,113,0.02))}}
.label{{font-size:14px;font-weight:700;letter-spacing:4px;text-transform:uppercase;display:flex;align-items:center;gap:8px}}
.title{{font-family:'Poppins',sans-serif;font-size:58px;font-weight:900;line-height:.92;letter-spacing:-3px}}
.title em{{font-style:normal;color:{PRIMARY}}}
.bar{{position:absolute;bottom:0;left:0;right:0;padding:30px 60px;background:linear-gradient(135deg,{PRIMARY},#d63a5e);display:flex;justify-content:space-between;align-items:center;z-index:3}}
.bar-text{{font-family:'Poppins',sans-serif;font-size:32px;font-weight:900}}
"""
    b = f"""
{orb(0, 50, 400, 'rgba(255,50,50,0.05)', 150)}
{orb(100, 50, 400, 'rgba(46,204,113,0.05)', 150)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="side side-bad">
<div class="label" style="color:#ff6b6b">😤 ANTES DO MUBE</div>
<div class="title">O caos do<br>WhatsApp</div>
{item_bad("💬", '"Alguém conhece baterista?" — sem resposta por 3 dias')}
{item_bad("📲", "Encaminhado pro grupo errado de novo")}
{item_bad("👻", "Músico sumiu na véspera do show")}
{item_bad("😭", "Show cancelado. De novo.")}
</div>
<div class="side side-good">
<div class="label" style="color:#2ecc71">✅ COM O MUBE</div>
<div class="title"><em>Paz.<br>Música.</em></div>
{item_good("🔍", "Busca por instrumento, gênero e cidade")}
{item_good("👤", "Perfil completo com portfólio real")}
{item_good("💬", "Chat direto, sem intermediário")}
{item_good("🎵", "Show aconteceu. Todo mundo feliz.")}
</div>
<div class="bar" style="grid-column:1/-1">
<div class="bar-text">A diferença é enorme.</div>
{mube_logo(40)}
</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE B04 — LOVE STORY (match)
# ═══════════════════════════════════════════
def art_b04_love_story():
    s = f"""
body{{background:linear-gradient(170deg,#08060e 0%,#14081a 45%,#0a0c14 100%);color:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:24px;padding:80px;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:72px;font-weight:900;text-align:center;letter-spacing:-3px;z-index:2;line-height:.92}}
.h1 em{{font-style:italic;color:{PRIMARY};text-shadow:0 0 50px rgba(232,70,108,0.4)}}
.match-row{{display:flex;align-items:center;gap:50px;z-index:2;margin:20px 0}}
.person{{display:flex;flex-direction:column;align-items:center;gap:12px}}
.person-avatar{{width:100px;height:100px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:48px;border:3px solid}}
.person-name{{font-family:'Poppins',sans-serif;font-size:28px;font-weight:800}}
.person-role{{font-size:16px;color:#888}}
.person-need{{font-size:16px;color:#aaa;text-align:center;max-width:220px;padding:12px 20px;background:rgba(255,255,255,0.04);border-radius:14px;border:1px solid rgba(255,255,255,0.06);margin-top:8px}}
.heart{{font-size:70px;filter:drop-shadow(0 0 20px rgba(232,70,108,0.5))}}
.heart-label{{font-family:'Poppins',sans-serif;font-size:18px;font-weight:800;color:{PRIMARY}}}
.result{{background:linear-gradient(135deg,rgba(232,70,108,0.1),rgba(155,89,182,0.05));border:1px solid rgba(232,70,108,0.2);border-radius:22px;padding:28px 40px;display:flex;align-items:center;gap:18px;z-index:2;margin-top:10px}}
.result-text{{font-size:22px;font-weight:700}}
.result-text strong{{color:{PRIMARY}}}
.result-sub{{font-size:16px;color:#888}}
"""
    b = f"""
{orb(50, 40, 500, 'rgba(232,70,108,0.1)', 180)}
{orb(20, 70, 300, 'rgba(155,89,182,0.06)', 140)}
{corner_accent("top-right", PRIMARY, 0.12)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="tag">HISTÓRIA REAL (FICTÍCIA) · MUBE</div>
<h1 class="h1">O match<br>que <em>mudou tudo.</em></h1>
<div class="match-row">
<div class="person">
<div class="person-avatar" style="background:rgba(232,70,108,0.1);border-color:{PRIMARY}">🎸</div>
<div class="person-name">Fernanda Luz</div>
<div class="person-role">Violonista · São Paulo</div>
<div class="person-need">Precisava de produtor pro seu primeiro EP</div>
</div>
<div style="display:flex;flex-direction:column;align-items:center;gap:6px">
<div class="heart">❤️</div>
<div class="heart-label">MATCH</div>
</div>
<div class="person">
<div class="person-avatar" style="background:rgba(74,144,217,0.1);border-color:{ACCENT_BLUE}">🎧</div>
<div class="person-name">Paulo Silva</div>
<div class="person-role">Produtor · São Paulo</div>
<div class="person-need">Procurava artista com voz autoral</div>
</div>
</div>
<div class="result">
<span style="font-size:36px">🎵</span>
<div><div class="result-text"><strong>EP lançado. 40k streams.</strong></div><div class="result-sub">Tudo começou num match no Mube.</div></div>
</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE B05 — GHOSTING
# ═══════════════════════════════════════════
def art_b05_ghosting():
    s = f"""
body{{background:linear-gradient(155deg,#080810 0%,#12081a 50%,#0e0c14 100%);color:#fff;padding:80px;display:flex;flex-direction:column;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:4px;text-transform:uppercase;color:#888;margin-bottom:20px;z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:90px;font-weight:900;line-height:.88;letter-spacing:-4px;margin-bottom:40px;z-index:2}}
.h1 em{{font-style:normal;color:{PRIMARY};text-shadow:0 0 40px rgba(232,70,108,0.3)}}
.ghost-emoji{{position:absolute;right:60px;top:120px;font-size:240px;opacity:0.08;z-index:1;filter:blur(2px)}}
.timeline{{display:flex;flex-direction:column;gap:28px;z-index:2;flex:1}}
.step{{display:flex;align-items:flex-start;gap:18px}}
.step-dot{{width:48px;height:48px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:22px;flex-shrink:0;border:2px solid}}
.step-label{{font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;margin-bottom:4px}}
.step-text{{font-size:22px;line-height:1.4}}
.tip{{background:linear-gradient(135deg,rgba(232,70,108,0.08),rgba(155,89,182,0.04));border:1px solid rgba(232,70,108,0.15);border-radius:20px;padding:28px 32px;display:flex;align-items:flex-start;gap:16px;z-index:2;margin-top:auto;font-size:20px;line-height:1.5}}
.tip strong{{color:{PRIMARY}}}
"""
    b = f"""
{orb(70, 60, 400, 'rgba(155,89,182,0.06)', 150)}
{dot_grid("rgba(255,255,255,0.015)", 50, 2)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="ghost-emoji">👻</div>
<div class="tag">O MÚSICO FANTASMA · UMA HISTÓRIA FAMILIAR</div>
<h1 class="h1">Sumiu<br>antes do<br><em>show.</em></h1>
<div class="timeline">
<div class="step"><div class="step-dot" style="background:rgba(46,204,113,0.1);border-color:#2ecc71">😊</div><div><div class="step-label" style="color:#2ecc71">SEMANA 1</div><div class="step-text">Fechou tudo. "Pode contar comigo, irmão!"</div></div></div>
<div class="step"><div class="step-dot" style="background:rgba(212,168,67,0.1);border-color:{ACCENT_GOLD}">😐</div><div><div class="step-label" style="color:{ACCENT_GOLD}">SEMANA 2</div><div class="step-text">Viu a mensagem. Entrou online. Não respondeu.</div></div></div>
<div class="step"><div class="step-dot" style="background:rgba(232,70,108,0.1);border-color:{PRIMARY}">👻</div><div><div class="step-label" style="color:{PRIMARY}">VÉSPERA DO SHOW</div><div class="step-text">Desapareceu. Saiu do grupo. Bloqueou.</div></div></div>
</div>
<div class="tip">💡 No Mube você vê <strong>portfólio real</strong> e histórico de cada músico antes de fechar. Menos susto, mais show.</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE B06 — RATINGS / AVALIAÇÕES
# ═══════════════════════════════════════════
def art_b06_ratings():
    def review(stars, text, name, role, loc):
        star_html = "⭐" * stars
        return f"""<div style="background:rgba(255,255,255,0.03);border:1px solid rgba(255,255,255,0.06);border-radius:22px;padding:32px 36px">
<div style="font-size:28px;margin-bottom:14px">{star_html}</div>
<div style="font-size:22px;line-height:1.45;margin-bottom:18px">{text}</div>
<div style="display:flex;align-items:center;gap:12px">
<div style="width:40px;height:40px;border-radius:50%;background:rgba(232,70,108,0.15);display:flex;align-items:center;justify-content:center">🎵</div>
<div><div style="font-weight:700;font-size:17px">{name}</div><div style="font-size:14px;color:#888">{role} · {loc}</div></div>
</div></div>"""

    s = f"""
body{{background:linear-gradient(160deg,#0a080e 0%,#140a18 50%,#0c0a14 100%);color:#fff;padding:80px;display:flex;flex-direction:column;gap:30px;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:72px;font-weight:900;line-height:.9;letter-spacing:-3px;z-index:2}}
.h1 em{{font-style:normal;color:{PRIMARY};text-shadow:0 0 40px rgba(232,70,108,0.3)}}
.reviews{{display:flex;flex-direction:column;gap:20px;z-index:2;flex:1}}
.footer{{display:flex;justify-content:space-between;align-items:flex-end;z-index:2}}
.score{{font-family:'Poppins',sans-serif;font-size:80px;font-weight:900;background:linear-gradient(135deg,#fff,{PRIMARY});-webkit-background-clip:text;-webkit-text-fill-color:transparent}}
.score-label{{font-size:16px;color:#888;display:flex;align-items:center;gap:6px}}
"""
    b = f"""
{orb(80, 30, 350, 'rgba(232,70,108,0.08)', 140)}
{orb(10, 70, 300, 'rgba(212,168,67,0.06)', 120)}
{deco_lines("rgba(232,70,108,0.02)", 8)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="tag">AVALIAÇÕES · O QUE ESTÃO DIZENDO</div>
<h1 class="h1">O público<br><em>amou.</em></h1>
<div class="reviews">
{review(5, '"Achei guitarrista, tecladista e ainda conheci minha <em style="color:#E8466C;font-style:italic">banda dos sonhos</em>. Nunca mais uso grupo de zap."', "Marina Costa", "Cantora", "Belo Horizonte")}
{review(5, '"Postei meu perfil na segunda. Na quarta já tinha <em style="color:#E8466C;font-style:italic">3 propostas de show</em>. Fiquei desconfiado."', "Rodrigo Batista", "Baterista", "São Paulo")}
</div>
<div class="footer">
<div><div class="score">5.0</div><div class="score-label">⭐ média dos usuários fictícios</div></div>
{mube_logo(44)}
</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE B07 — PITCH
# ═══════════════════════════════════════════
def art_b07_pitch():
    s = f"""
body{{background:linear-gradient(160deg,#080810 0%,#10081a 50%,#0c0a14 100%);color:#fff;padding:80px;display:flex;flex-direction:column;gap:28px;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};z-index:2}}
.slide-num{{position:absolute;top:80px;right:80px;font-size:12px;letter-spacing:3px;color:#444;z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:78px;font-weight:900;line-height:.88;letter-spacing:-4px;z-index:2}}
.h1 em{{font-style:normal;color:{PRIMARY};text-shadow:0 0 40px rgba(232,70,108,0.3)}}
.block{{padding:28px 32px;border-radius:18px;font-size:22px;line-height:1.45;z-index:2;border-left:4px solid}}
.block-red{{background:linear-gradient(135deg,rgba(232,70,108,0.08),rgba(180,30,50,0.04));border-color:{PRIMARY}}}
.block-green{{background:linear-gradient(135deg,rgba(46,204,113,0.08),rgba(20,120,60,0.04));border-color:#2ecc71}}
.block-label{{font-size:14px;font-weight:700;letter-spacing:3px;text-transform:uppercase;margin-bottom:8px;display:flex;align-items:center;gap:6px}}
.stats-row{{display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px;z-index:2}}
.stat{{text-align:center;padding:28px;background:rgba(255,255,255,0.03);border:1px solid rgba(255,255,255,0.06);border-radius:18px}}
.stat-num{{font-family:'Poppins',sans-serif;font-size:44px;font-weight:900;color:{PRIMARY}}}
.stat-label{{font-size:15px;color:#888;margin-top:6px}}
.footer-brand{{display:flex;align-items:center;gap:10px;font-size:18px;color:#888;z-index:2;margin-top:auto}}
"""
    b = f"""
{orb(80, 30, 400, 'rgba(232,70,108,0.08)', 150)}
{orb(15, 65, 300, 'rgba(46,204,113,0.05)', 130)}
{deco_lines("rgba(255,255,255,0.015)", 8)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="slide-num">SLIDE 1 DE 1</div>
<div class="tag">SE O MUBE FOSSE UM PITCH</div>
<h1 class="h1">O problema<br>era <em>óbvio.</em></h1>
<div class="block block-red"><div class="block-label" style="color:{PRIMARY}">🔴 PROBLEMA</div>Músicos talentosos invisíveis enquanto grupos de WhatsApp explodem sem resultado.</div>
<div class="block block-green"><div class="block-label" style="color:#2ecc71">✅ SOLUÇÃO</div>Plataforma dedicada ao mercado musical brasileiro. Perfis, busca, match e chat — num só app.</div>
<div class="stats-row">
<div class="stat"><div class="stat-num">+1M</div><div class="stat-label">músicos no Brasil sem plataforma dedicada</div></div>
<div class="stat"><div class="stat-num">R$ 0</div><div class="stat-label">para criar seu perfil completo</div></div>
<div class="stat"><div class="stat-num">∞</div><div class="stat-label">conexões possíveis</div></div>
</div>
<div class="footer-brand">{mube_icon(28)} mube · a solução óbvia</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE B08 — FOMO
# ═══════════════════════════════════════════
def art_b08_fomo():
    s = f"""
body{{background:linear-gradient(170deg,#06060e 0%,#100a18 50%,#0a0c14 100%);color:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:80px;gap:28px;position:relative;overflow:hidden}}
.big-num{{font-family:'Poppins',sans-serif;font-size:200px;font-weight:900;line-height:1;background:linear-gradient(135deg,{PRIMARY},#c0365a);-webkit-background-clip:text;-webkit-text-fill-color:transparent;z-index:2;filter:drop-shadow(0 0 30px rgba(232,70,108,0.3))}}
.sub{{font-size:24px;color:#999;text-align:center;z-index:2}}
.feed{{display:flex;flex-direction:column;gap:14px;width:100%;max-width:700px;z-index:2}}
.feed-item{{display:flex;align-items:center;justify-content:space-between;padding:20px 28px;background:rgba(255,255,255,0.04);border-radius:16px;border:1px solid rgba(255,255,255,0.06);font-size:20px;font-weight:600}}
.feed-dot{{width:10px;height:10px;border-radius:50%;background:#2ecc71;box-shadow:0 0 10px rgba(46,204,113,0.5)}}
.feed-time{{font-size:14px;color:#555}}
.h2{{font-family:'Poppins',sans-serif;font-size:52px;font-weight:900;text-align:center;letter-spacing:-2px;z-index:2;line-height:1}}
.h2 em{{font-style:italic;color:{PRIMARY};text-shadow:0 0 30px rgba(232,70,108,0.3)}}
.disclaimer{{font-size:14px;color:#444;z-index:2}}
"""
    b = f"""
{orb(50, 20, 500, 'rgba(232,70,108,0.08)', 180)}
{corner_accent("bottom-right", ACCENT_PURPLE, 0.08)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="big-num">73</div>
<div class="sub">conexões no Mube enquanto você dormia*</div>
<div class="feed">
<div class="feed-item"><span style="display:flex;align-items:center;gap:12px"><span class="feed-dot"></span>Beatriz encontrou banda em SP</span><span class="feed-time">agora mesmo</span></div>
<div class="feed-item"><span style="display:flex;align-items:center;gap:12px"><span class="feed-dot"></span>Estúdio Focal fechou 2 gravações</span><span class="feed-time">3 min atrás</span></div>
<div class="feed-item"><span style="display:flex;align-items:center;gap:12px"><span class="feed-dot"></span>DJ Rafa fez match com contratante</span><span class="feed-time">8 min atrás</span></div>
</div>
<h2 class="h2">E você ainda não<br>tem <em>perfil?</em></h2>
<div class="disclaimer">*número fictício. o sentimento é real.</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE B09 — MITOS & VERDADES
# ═══════════════════════════════════════════
def art_b09_mitos():
    def myth(text):
        return f"""<div style="background:rgba(255,255,255,0.03);border:1px solid rgba(232,70,108,0.15);border-radius:18px;padding:26px 28px">
<div style="font-size:14px;font-weight:700;letter-spacing:3px;color:{PRIMARY};margin-bottom:8px;display:flex;align-items:center;gap:6px">❌ MITO</div>
<div style="font-size:20px;color:#888;text-decoration:line-through">{text}</div></div>"""
    def truth(text):
        return f"""<div style="background:linear-gradient(135deg,rgba(46,204,113,0.06),rgba(46,204,113,0.02));border:1px solid rgba(46,204,113,0.15);border-radius:18px;padding:26px 28px">
<div style="font-size:14px;font-weight:700;letter-spacing:3px;color:#2ecc71;margin-bottom:8px;display:flex;align-items:center;gap:6px">✅ VERDADE</div>
<div style="font-size:20px;font-weight:600">{text}</div></div>"""

    s = f"""
body{{background:linear-gradient(155deg,#08080e 0%,#12081a 50%,#0a0c14 100%);color:#fff;padding:80px;display:flex;flex-direction:column;gap:28px;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:80px;font-weight:900;line-height:.88;letter-spacing:-4px;z-index:2}}
.h1 em{{font-style:italic;color:{PRIMARY}}}
.grid{{display:grid;grid-template-columns:1fr 1fr;gap:16px;z-index:2;flex:1}}
.footer{{display:flex;justify-content:flex-end;z-index:2;margin-top:auto}}
"""
    b = f"""
{orb(80, 30, 350, 'rgba(232,70,108,0.06)', 140)}
{orb(15, 70, 300, 'rgba(46,204,113,0.04)', 120)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="tag">MITOS & VERDADES</div>
<h1 class="h1">Deixa eu<br><em>te contar.</em></h1>
<div class="grid">
{myth('"É só pra músico famoso"')}
{truth("Qualquer músico, do iniciante ao profissional.")}
{myth('"Tem que pagar caro"')}
{truth("Criar perfil e buscar músicos é completamente grátis.")}
{myth('"Não tem ninguém da minha cidade"')}
{truth("Busca por localização. Filtra pela sua cidade agora.")}
</div>
<div class="footer">{mube_logo(40)}</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE B10 — QUIZ DARK
# ═══════════════════════════════════════════
def art_b10_quiz():
    def option(emoji, title, desc, color):
        return f"""<div style="background:linear-gradient(145deg,rgba({int(color[1:3],16)},{int(color[3:5],16)},{int(color[5:7],16)},0.08),rgba(20,20,30,0.8));border:2px solid rgba({int(color[1:3],16)},{int(color[3:5],16)},{int(color[5:7],16)},0.25);border-radius:24px;padding:36px;text-align:center;display:flex;flex-direction:column;align-items:center;gap:10px">
<div style="font-size:50px">{emoji}</div>
<div style="font-family:Poppins,sans-serif;font-size:28px;font-weight:800;color:{color}">{title}</div>
<div style="font-size:17px;color:#999;line-height:1.4">{desc}</div></div>"""

    s = f"""
body{{background:linear-gradient(160deg,#0a0810 0%,#14081e 45%,#0c1018 100%);color:#fff;display:flex;flex-direction:column;align-items:center;padding:80px;gap:28px;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:70px;font-weight:900;text-align:center;letter-spacing:-3px;line-height:.92;z-index:2}}
.h1 em{{font-style:normal;color:{PRIMARY};text-shadow:0 0 40px rgba(232,70,108,0.3)}}
.grid{{display:grid;grid-template-columns:1fr 1fr;gap:20px;z-index:2;width:100%}}
.bottom{{font-size:22px;text-align:center;z-index:2;margin-top:auto}}
.bottom strong{{color:#fff}}
"""
    b = f"""
{orb(50, 50, 500, 'rgba(232,70,108,0.06)', 180)}
{orb(80, 20, 300, 'rgba(155,89,182,0.05)', 140)}
{deco_lines("rgba(155,89,182,0.02)", 10)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="tag">QUIZ · DESCUBRA SEU PERFIL</div>
<h1 class="h1">Qual é o<br>seu <em>papel?</em></h1>
<div class="grid">
{option("🎸", "Músico", "Toca, canta ou produz. É individual e talentoso.", PRIMARY)}
{option("🎵", "Banda", "Grupo unido por um som. Busca oportunidade juntos.", ACCENT_PURPLE)}
{option("🎙️", "Estúdio", "Oferece gravação, mix ou masterização.", ACCENT_BLUE)}
{option("🎤", "Contratante", "Organiza eventos. Precisa dos artistas certos.", ACCENT_GOLD)}
</div>
<div class="bottom"><strong>Todos têm espaço no Mube.</strong> Qual é o seu?</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTE B11 — MANIFESTO 2
# ═══════════════════════════════════════════
def art_b11_manifesto2():
    s = f"""
body{{background:linear-gradient(155deg,#0a0a10 0%,#160a14 50%,#0c0a18 100%);color:#fff;padding:90px;display:flex;flex-direction:column;justify-content:center;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};margin-bottom:24px;z-index:2}}
.strikethrough{{font-family:'Poppins',sans-serif;font-size:56px;font-weight:900;color:#333;text-decoration:line-through;text-decoration-thickness:4px;margin-bottom:8px;z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:90px;font-weight:900;line-height:.88;letter-spacing:-4px;z-index:2}}
.h1 em{{font-style:normal;color:{PRIMARY};text-shadow:0 0 50px rgba(232,70,108,0.3)}}
.body{{font-size:22px;color:#888;line-height:1.55;max-width:550px;margin-top:50px;z-index:2}}
.footer{{position:absolute;bottom:80px;right:80px;z-index:2}}
.ghost-m{{position:absolute;bottom:-50px;right:-30px;font-family:'Poppins',sans-serif;font-size:500px;font-weight:900;color:#fff;opacity:0.015;line-height:1;pointer-events:none;z-index:0}}
"""
    b = f"""
{orb(80, 50, 400, 'rgba(232,70,108,0.1)', 160)}
{orb(10, 20, 300, 'rgba(155,89,182,0.06)', 130)}
{dot_grid("rgba(255,255,255,0.015)", 55, 2)}
<div class="noise" style="position:absolute;inset:0"></div>
<div class="ghost-m">M</div>
<div class="tag">MUBE · DECLARAÇÃO PÚBLICA</div>
<div class="strikethrough">grupo do whatsapp</div>
<h1 class="h1">Mube.<br>É diferente.<br><em>É melhor.</em></h1>
<p class="body">Pare de procurar músico em lugar de comida. A gente tem um lugar certo pra isso.</p>
<div class="footer">{mube_logo(44)}</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# ARTES LIGHT MODE (B12–B22)
# ═══════════════════════════════════════════
LBG = "#F5F3EE"
LSURF = "#FFFFFF"
LTEXT = "#0D0D0D"
LMUTED = "#6B6B6B"

# B12 — DJ Rafa Santos
def art_b12_dj_rafa():
    s = f"""
body{{background:{LBG};color:{LTEXT};padding:80px;display:flex;flex-direction:column;justify-content:center;position:relative;overflow:hidden}}
.accent-blob{{position:absolute;top:-100px;right:-100px;width:500px;height:500px;border-radius:50%;background:linear-gradient(135deg,rgba(232,70,108,0.12),rgba(232,70,108,0.04));filter:blur(80px);pointer-events:none}}
.accent-blob2{{position:absolute;bottom:-150px;left:-100px;width:400px;height:400px;border-radius:50%;background:rgba(232,70,108,0.06);filter:blur(80px);pointer-events:none}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};margin-bottom:20px;z-index:2}}
.profile{{display:flex;align-items:center;gap:24px;margin-bottom:28px;z-index:2}}
.avatar{{width:90px;height:90px;border-radius:50%;background:linear-gradient(135deg,{ACCENT_PURPLE},{PRIMARY});display:flex;align-items:center;justify-content:center;font-size:42px;box-shadow:0 10px 30px rgba(232,70,108,0.2)}}
.name{{font-family:'Poppins',sans-serif;font-size:48px;font-weight:900;letter-spacing:-2px}}
.role{{font-size:18px;color:{LMUTED}}}
.loc{{font-size:16px;color:{PRIMARY};display:flex;align-items:center;gap:4px}}
.quote{{border-left:4px solid {PRIMARY};padding:24px 28px;font-size:24px;font-style:italic;line-height:1.45;color:{LTEXT};background:rgba(232,70,108,0.04);border-radius:0 16px 16px 0;margin-bottom:28px;z-index:2}}
.quote strong{{color:{PRIMARY};font-style:normal}}
.tags-row{{display:flex;gap:12px;flex-wrap:wrap;margin-bottom:28px;z-index:2}}
.tag-pill{{padding:10px 22px;border-radius:50px;font-size:16px;font-weight:600}}
.tag-pill.brand{{background:rgba(232,70,108,0.1);color:{PRIMARY};border:1px solid rgba(232,70,108,0.2)}}
.tag-pill.neutral{{background:{LSURF};color:{LTEXT};border:1px solid #ddd}}
.footer{{display:flex;justify-content:space-between;align-items:center;z-index:2;margin-top:20px}}
.cta{{display:inline-flex;align-items:center;gap:10px;padding:16px 36px;background:linear-gradient(135deg,{PRIMARY},#d63a5e);border-radius:50px;font-size:18px;font-weight:800;color:#fff;box-shadow:0 10px 30px rgba(232,70,108,0.25)}}
"""
    b = f"""
<div class="accent-blob"></div><div class="accent-blob2"></div>
<div class="tag">CONHEÇA · USUÁRIO MUBE</div>
<div class="profile">
<div class="avatar">🎧</div>
<div>
<div class="name">DJ Rafa Santos</div>
<div class="role">DJ · Produtor Musical</div>
<div class="loc">📍 Belo Horizonte, MG</div>
</div>
</div>
<div class="quote">"Entrei no Mube sem expectativa. Em 2 semanas já tinha <strong>4 propostas de evento</strong>. Meu calendário tá cheio."</div>
<div class="tags-row">
<span class="tag-pill brand">House</span><span class="tag-pill brand">Techno</span><span class="tag-pill brand">DJ Set</span><span class="tag-pill neutral">Produção</span><span class="tag-pill neutral">Eventos</span>
</div>
<div class="footer">
<div class="cta">Ver perfil completo →</div>
{mube_logo(40)}
</div>
"""
    return wrap(s, b)


# B13 — Mari Costa
def art_b13_mari():
    ss = SS.get(4, SS.get(1, ""))
    s = f"""
body{{background:{LBG};color:{LTEXT};display:grid;grid-template-columns:1fr 1fr;align-items:center;padding:80px;gap:50px;position:relative;overflow:hidden}}
.accent-bar{{position:absolute;top:0;left:0;right:0;height:8px;background:linear-gradient(90deg,{PRIMARY},{ACCENT_PURPLE},{ACCENT_BLUE});z-index:3}}
.left{{z-index:2}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};margin-bottom:20px}}
.name{{font-family:'Poppins',sans-serif;font-size:72px;font-weight:900;line-height:.88;letter-spacing:-3px;margin-bottom:10px}}
.role{{font-size:20px;color:{LMUTED};margin-bottom:24px}}
.body{{font-size:22px;color:{LTEXT};line-height:1.5;margin-bottom:28px}}
.body strong{{color:{PRIMARY}}}
.tags-row{{display:flex;gap:10px;flex-wrap:wrap;margin-bottom:24px}}
.tag-pill{{padding:10px 22px;border-radius:50px;font-size:15px;font-weight:600;background:{LSURF};border:1px solid #ddd;color:{LTEXT}}}
.right{{z-index:2}}
.phone{{width:100%;max-width:340px;border-radius:28px;overflow:hidden;box-shadow:0 20px 60px rgba(0,0,0,0.15);border:1px solid #e0e0e0}}
.phone img{{width:100%;display:block}}
"""
    b = f"""
<div class="accent-bar"></div>
{corner_accent("top-right", PRIMARY, 0.08)}
{corner_accent("bottom-left", ACCENT_PURPLE, 0.06)}
<div class="left">
<div class="tag">PERSONAGEM · MUBE</div>
<div class="name">Mari<br>Costa</div>
<div class="role">Cantora de MPB · Recife, PE</div>
<div class="body">Ficou <strong>6 meses</strong> tentando achar produtora pelo Instagram. Criou perfil no Mube. Em <strong>3 semanas</strong> fechou álbum.</div>
<div class="tags-row">
<span class="tag-pill">Voz</span><span class="tag-pill">MPB</span><span class="tag-pill">Bossa Nova</span><span class="tag-pill">Compositora</span>
</div>
{mube_logo(40)}
</div>
<div class="right">
<div class="phone">{"<img src='" + ss + "'/>" if ss else '<div style="height:550px;background:#f0f0f0"></div>'}</div>
</div>
"""
    return wrap(s, b)


# B14 — Tinder Parody
def art_b14_tinder():
    s = f"""
body{{background:{LBG};color:{LTEXT};display:flex;flex-direction:column;align-items:center;justify-content:center;padding:80px;gap:24px;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:68px;font-weight:900;text-align:center;letter-spacing:-3px;z-index:2;line-height:.92}}
.h1 em{{font-style:italic;color:{PRIMARY}}}
.card-stack{{position:relative;width:360px;height:380px;z-index:2;margin:10px 0}}
.card{{position:absolute;width:340px;background:#fff;border-radius:24px;padding:50px 40px;text-align:center;box-shadow:0 15px 40px rgba(0,0,0,0.1);border:1px solid #eee}}
.card:nth-child(1){{top:0;left:10px;z-index:3;transform:rotate(-2deg)}}
.card:nth-child(2){{top:10px;left:20px;z-index:2;transform:rotate(2deg);opacity:0.7}}
.card:nth-child(3){{top:20px;left:30px;z-index:1;opacity:0.4}}
.card-emoji{{font-size:70px;margin-bottom:16px}}
.card-name{{font-family:'Poppins',sans-serif;font-size:32px;font-weight:800}}
.card-detail{{font-size:17px;color:{LMUTED};margin-top:8px;line-height:1.4}}
.actions{{display:flex;gap:20px;z-index:2}}
.action{{width:60px;height:60px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:26px;box-shadow:0 8px 20px rgba(0,0,0,0.08)}}
.action-no{{background:#fff;border:2px solid #ddd}}
.action-yes{{background:{PRIMARY};color:#fff;box-shadow:0 8px 25px rgba(232,70,108,0.3)}}
.body{{font-size:20px;color:{LMUTED};text-align:center;max-width:550px;z-index:2;margin-top:10px}}
.body strong{{color:{LTEXT}}}
"""
    b = f"""
{corner_accent("top-right", PRIMARY, 0.06)}
{corner_accent("bottom-left", ACCENT_PURPLE, 0.04)}
<div class="tag">MATCHPOINT · FUNCIONA IGUAL, MAS PRO QUE IMPORTA</div>
<h1 class="h1">Deu match<br>com o <em>som certo.</em></h1>
<div class="card-stack">
<div class="card"><div class="card-emoji">🎸</div><div class="card-name">João Guitarrista</div><div class="card-detail">26 anos · São Paulo<br>Rock Alternativo · Blues</div></div>
<div class="card"></div>
<div class="card"></div>
</div>
<div class="actions">
<div class="action action-no">✕</div>
<div class="action action-yes">♥</div>
</div>
<p class="body"><strong>Não é app de namoro.</strong> É melhor: aqui você acha o músico com quem vai criar algo incrível.</p>
<div style="margin-top:10px">{mube_logo(36)}</div>
"""
    return wrap(s, b)


# B15 — Instruções (3 passos)
def art_b15_instrucoes():
    def step(num, title, desc):
        return f"""<div style="display:flex;align-items:flex-start;gap:24px;margin-bottom:16px">
<div style="width:64px;height:64px;border-radius:50%;background:linear-gradient(135deg,{PRIMARY},#d63a5e);display:flex;align-items:center;justify-content:center;font-family:Poppins,sans-serif;font-size:32px;font-weight:900;color:#fff;flex-shrink:0;box-shadow:0 8px 24px rgba(232,70,108,0.2)">{num}</div>
<div><div style="font-family:Poppins,sans-serif;font-size:30px;font-weight:800">{title}</div><div style="font-size:20px;color:{LMUTED};margin-top:6px;line-height:1.4">{desc}</div></div></div>"""

    s = f"""
body{{background:{LBG};color:{LTEXT};padding:80px;display:flex;flex-direction:column;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};margin-bottom:20px;z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:86px;font-weight:900;line-height:.88;letter-spacing:-4px;margin-bottom:50px;z-index:2}}
.h1 em{{font-style:italic;color:{PRIMARY}}}
.steps{{z-index:2;flex:1;display:flex;flex-direction:column;justify-content:center;gap:30px}}
.divider{{width:100%;height:1px;background:linear-gradient(90deg,transparent,#ddd,transparent);z-index:2}}
.footer{{display:flex;justify-content:space-between;align-items:center;z-index:2;margin-top:auto;padding-top:24px}}
.footer-text{{font-size:18px;color:{LMUTED}}}
.footer-text strong{{color:{LTEXT}}}
"""
    b = f"""
{corner_accent("top-right", PRIMARY, 0.06)}
{corner_accent("bottom-left", ACCENT_BLUE, 0.04)}
<div class="tag">TUTORIAL · SEM COMPLICAÇÃO</div>
<h1 class="h1">3 passos.<br><em>Isso.</em></h1>
<div class="steps">
{step(1, "Crie seu perfil", 'Instrumento, gênero, cidade. <strong style="color:#E8466C">5 minutos</strong>. Sério.')}
{step(2, "Busque ou seja encontrado", 'Procure quem você precisa <strong style="color:#E8466C">ou</strong> deixe as oportunidades chegarem.')}
{step(3, "Conecte e faça música", 'Chat direto. <strong style="color:#E8466C">Vá fazer música de verdade.</strong> A gente cuida do resto.')}
</div>
<div class="divider"></div>
<div class="footer">
<div class="footer-text"><strong>Tempo médio pra criar conta:</strong> menos de 5 minutos</div>
{mube_logo(40)}
</div>
"""
    return wrap(s, b)


# B16 — Testimonial
def art_b16_testimonial():
    s = f"""
body{{background:{LBG};color:{LTEXT};display:flex;flex-direction:column;align-items:center;justify-content:center;padding:80px;position:relative;overflow:hidden}}
.quote-marks{{position:absolute;top:50px;left:60px;font-size:200px;font-family:Georgia,serif;color:rgba(232,70,108,0.08);line-height:1;pointer-events:none}}
.stars{{font-size:36px;margin-bottom:24px;z-index:2}}
.quote{{font-family:'Poppins',sans-serif;font-size:44px;font-weight:800;text-align:center;line-height:1.2;letter-spacing:-2px;max-width:800px;z-index:2}}
.quote strong{{color:{PRIMARY}}}
.quote em{{font-style:italic;color:{PRIMARY}}}
.person{{display:flex;align-items:center;gap:16px;margin-top:40px;z-index:2}}
.person-avatar{{width:60px;height:60px;border-radius:50%;background:linear-gradient(135deg,{ACCENT_PURPLE},{PRIMARY});display:flex;align-items:center;justify-content:center;font-size:28px}}
.person-name{{font-size:20px;font-weight:700}}
.person-role{{font-size:16px;color:{LMUTED}}}
.footer{{margin-top:32px;z-index:2}}
"""
    b = f"""
<div class="quote-marks">❝</div>
{corner_accent("top-right", PRIMARY, 0.06)}
{corner_accent("bottom-left", ACCENT_PURPLE, 0.04)}
<div class="stars">⭐⭐⭐⭐⭐</div>
<div class="quote">"Tentei achar produtor pelo Instagram por <strong>4 meses</strong>. Entrei no Mube, <em>uma semana depois</em> tava gravando."</div>
<div class="person">
<div class="person-avatar">🎵</div>
<div><div class="person-name">Beatriz Almeida</div><div class="person-role">Cantora Independente · Curitiba, PR</div></div>
</div>
<div class="footer">{mube_logo(40)}</div>
"""
    return wrap(s, b)


# B17 — Features Light
def art_b17_features():
    def feat(emoji, title, desc):
        return f"""<div style="background:{LSURF};border-radius:22px;padding:36px;box-shadow:0 4px 20px rgba(0,0,0,0.04);border:1px solid #eee">
<div style="font-size:42px;margin-bottom:14px">{emoji}</div>
<div style="font-family:Poppins,sans-serif;font-size:26px;font-weight:800;color:{PRIMARY};margin-bottom:8px">{title}</div>
<div style="font-size:18px;color:{LMUTED};line-height:1.4">{desc}</div></div>"""

    s = f"""
body{{background:{LBG};color:{LTEXT};padding:80px;display:flex;flex-direction:column;gap:28px;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:76px;font-weight:900;line-height:.88;letter-spacing:-4px;z-index:2}}
.h1 em{{font-style:italic;color:{PRIMARY}}}
.grid{{display:grid;grid-template-columns:1fr 1fr;gap:20px;z-index:2;flex:1}}
.footer{{display:flex;justify-content:space-between;align-items:center;z-index:2;margin-top:auto}}
.footer-text{{font-size:18px;color:{LMUTED}}}
.footer-text strong{{color:{PRIMARY}}}
"""
    b = f"""
{corner_accent("top-right", PRIMARY, 0.06)}
<div class="tag">FUNCIONALIDADES</div>
<h1 class="h1">Simples.<br>Completo.<br><em>Musical.</em></h1>
<div class="grid">
{feat("🎯", "Matchpoint", 'Explore perfis e dê match com quem <strong>toca na mesma frequência</strong>.')}
{feat("🔍", "Busca avançada", 'Filtre por instrumento, gênero ou cidade. <strong>Sem algoritmo escondido.</strong>')}
{feat("💬", "Chat direto", 'Do match à parceria em <strong>poucos minutos</strong>. Sem intermediário.')}
{feat("🖼️", "Portfólio", 'Fotos, vídeos e links do seu trabalho. <strong>Tudo no perfil.</strong>')}
</div>
<div class="footer">
<div class="footer-text"><strong>100% gratuito</strong> para criar seu perfil</div>
{mube_logo(40)}
</div>
"""
    return wrap(s, b)


# B18 — Perda (FOMO light)
def art_b18_perda():
    def loss(emoji, title, desc):
        return f"""<div style="background:{LSURF};border-radius:20px;padding:28px 32px;box-shadow:0 4px 20px rgba(0,0,0,0.04);border:1px solid #eee;display:flex;align-items:center;gap:18px">
<span style="font-size:38px">{emoji}</span>
<div><div style="font-size:22px;font-weight:700">{title}</div><div style="font-size:16px;color:{LMUTED};margin-top:4px">{desc}</div></div></div>"""

    s = f"""
body{{background:{LBG};color:{LTEXT};padding:80px;display:flex;flex-direction:column;gap:28px;position:relative;overflow:hidden}}
.h1{{font-family:'Poppins',sans-serif;font-size:76px;font-weight:900;line-height:.88;letter-spacing:-4px;z-index:2;margin-top:40px}}
.h1 em{{font-style:italic;color:{PRIMARY}}}
.losses{{display:flex;flex-direction:column;gap:18px;z-index:2;flex:1}}
.footer{{display:flex;justify-content:space-between;align-items:center;z-index:2;margin-top:auto}}
.cta{{display:inline-flex;align-items:center;gap:10px;padding:16px 36px;background:linear-gradient(135deg,{PRIMARY},#d63a5e);border-radius:50px;font-size:18px;font-weight:800;color:#fff;box-shadow:0 10px 30px rgba(232,70,108,0.25)}}
"""
    b = f"""
{corner_accent("top-right", PRIMARY, 0.06)}
<h1 class="h1">Sem o Mube,<br>você <em>perde...</em></h1>
<div class="losses">
{loss("🥁", "O baterista perfeito da sua cidade", "que você nunca vai descobrir no grupo de zap")}
{loss("🎧", "O produtor que ia mudar seu som", "estava a 3km de você. Não se conheceram.")}
{loss("🎤", "O show que não vai acontecer", "porque faltava só um músico. Que estava aqui.")}
</div>
<div class="footer">
<div class="cta">Entrar no Mube agora</div>
{mube_logo(40)}
</div>
"""
    return wrap(s, b)


# B19 — Qual você (quiz light)
def art_b19_quiz_light():
    def opt(emoji, title, desc, color):
        return f"""<div style="background:{LSURF};border:2px solid {color}22;border-radius:22px;padding:36px;text-align:center;display:flex;flex-direction:column;align-items:center;gap:10px;box-shadow:0 4px 16px rgba(0,0,0,0.04)">
<div style="font-size:50px">{emoji}</div>
<div style="font-family:Poppins,sans-serif;font-size:28px;font-weight:800;color:{color}">{title}</div>
<div style="font-size:17px;color:{LMUTED};line-height:1.4">{desc}</div></div>"""

    s = f"""
body{{background:{LBG};color:{LTEXT};display:flex;flex-direction:column;align-items:center;padding:80px;gap:28px;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:68px;font-weight:900;text-align:center;letter-spacing:-3px;z-index:2;line-height:.92}}
.h1 em{{font-style:italic;color:{PRIMARY}}}
.grid{{display:grid;grid-template-columns:1fr 1fr;gap:20px;width:100%;z-index:2}}
.bottom{{font-size:22px;text-align:center;z-index:2;margin-top:auto}}
.bottom strong{{color:{PRIMARY}}}
"""
    b = f"""
{corner_accent("top-right", ACCENT_PURPLE, 0.05)}
<div class="tag">QUIZ · QUAL É O SEU PERFIL?</div>
<h1 class="h1">Com qual você<br>se <em>identifica?</em></h1>
<div class="grid">
{opt("🎸", "Músico", "Individual. Toca, canta ou produz seu som.", PRIMARY)}
{opt("🎵", "Banda", "Grupo unido. Busca oportunidade junto.", ACCENT_PURPLE)}
{opt("🎙️", "Estúdio", "Oferece gravação, mix ou masterização.", ACCENT_BLUE)}
{opt("🎤", "Contratante", "Organiza eventos. Precisa dos artistas certos.", ACCENT_GOLD)}
</div>
<div class="bottom"><strong>Todos têm espaço</strong> no Mube.</div>
"""
    return wrap(s, b)


# B20 — Banda certa
def art_b20_banda_certa():
    s = f"""
body{{background:{LBG};color:{LTEXT};padding:90px;display:flex;flex-direction:column;justify-content:center;position:relative;overflow:hidden}}
.accent-circle{{position:absolute;top:-80px;right:-80px;width:450px;height:450px;border-radius:50%;border:2px solid rgba(232,70,108,0.08);pointer-events:none}}
.accent-circle2{{position:absolute;top:-30px;right:-30px;width:350px;height:350px;border-radius:50%;border:1px solid rgba(232,70,108,0.05);pointer-events:none}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};margin-bottom:24px;z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:100px;font-weight:900;line-height:.86;letter-spacing:-5px;z-index:2}}
.h1 em{{font-style:italic;color:{PRIMARY}}}
.body{{font-size:22px;color:{LMUTED};line-height:1.55;max-width:550px;margin-top:28px;margin-bottom:40px;z-index:2}}
.body strong{{color:{LTEXT}}}
.footer{{display:flex;justify-content:space-between;align-items:center;z-index:2;margin-top:auto}}
.cta{{display:inline-flex;align-items:center;gap:10px;padding:16px 36px;background:linear-gradient(135deg,{PRIMARY},#d63a5e);border-radius:50px;font-size:18px;font-weight:800;color:#fff;box-shadow:0 10px 30px rgba(232,70,108,0.25)}}
"""
    b = f"""
<div class="accent-circle"></div><div class="accent-circle2"></div>
<div class="tag">MUBE · PARA QUEM LEVA A SÉRIO</div>
<h1 class="h1">A banda<br><em>certa</em><br>existe.</h1>
<p class="body">Ela ainda não te achou porque você não está no lugar certo. <strong>O Mube é esse lugar.</strong></p>
<div class="footer">
<div class="cta">Criar meu perfil</div>
{mube_logo(40)}
</div>
"""
    return wrap(s, b)


# B21 — Mensagem (chat light)
def art_b21_mensagem():
    s = f"""
body{{background:{LBG};color:{LTEXT};display:flex;flex-direction:column;align-items:center;padding:70px;gap:20px;position:relative;overflow:hidden}}
.tag{{font-size:14px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:{PRIMARY};z-index:2}}
.h1{{font-family:'Poppins',sans-serif;font-size:60px;font-weight:900;text-align:center;letter-spacing:-3px;z-index:2;line-height:.92}}
.h1 em{{font-style:italic;color:{PRIMARY}}}
.chat-card{{background:{LSURF};border-radius:24px;padding:36px;box-shadow:0 10px 40px rgba(0,0,0,0.06);border:1px solid #eee;width:100%;max-width:750px;z-index:2;display:flex;flex-direction:column;gap:16px}}
.header{{display:flex;align-items:center;gap:14px;margin-bottom:8px}}
.avatar{{width:50px;height:50px;border-radius:50%;background:linear-gradient(135deg,{ACCENT_PURPLE},{ACCENT_BLUE});display:flex;align-items:center;justify-content:center;font-size:24px}}
.name{{font-weight:700;font-size:18px}}
.online{{font-size:14px;color:#2ecc71;display:flex;align-items:center;gap:4px}}
.bubble{{padding:18px 24px;border-radius:20px;font-size:20px;line-height:1.4;max-width:85%}}
.bubble-them{{background:#f0f0f0;align-self:flex-start;border:1px solid #e8e8e8}}
.bubble-me{{background:linear-gradient(135deg,{PRIMARY},#d63a5e);color:#fff;align-self:flex-end;box-shadow:0 6px 20px rgba(232,70,108,0.2)}}
.bottom{{font-family:'Poppins',sans-serif;font-size:36px;font-weight:900;text-align:center;z-index:2;margin-top:auto}}
.bottom em{{font-style:italic;color:{PRIMARY}}}
"""
    b = f"""
{corner_accent("top-left", PRIMARY, 0.05)}
<div class="tag">CHAT · COMEÇA COM UMA MENSAGEM</div>
<h1 class="h1">A mensagem<br>que <em>mudou tudo.</em></h1>
<div class="chat-card">
<div class="header">
<div class="avatar">🎧</div>
<div><div class="name">Lucas Produtor</div><div class="online">● online agora</div></div>
</div>
<div class="bubble bubble-them">Oi! Vi seu perfil no Mube. Amei sua voz no portfólio! 🎵</div>
<div class="bubble bubble-me">Oi Lucas! Obrigada! Tô procurando produtor pro meu EP 👀</div>
<div class="bubble bubble-them">Perfeito. Tenho estúdio livre essa semana. Bora? 🎙️</div>
<div class="bubble bubble-me">Manda o endereço! Vou adorar 🎶</div>
</div>
<div class="bottom">Sua <em>próxima parceria</em> começa assim.</div>
<div style="z-index:2">{mube_logo(36)}</div>
"""
    return wrap(s, b)


# B22 — CTA Light
def art_b22_cta():
    s = f"""
body{{display:flex;flex-direction:column;overflow:hidden;position:relative}}
.top{{flex:1;background:linear-gradient(160deg,{PRIMARY},#d63a5e,#c0365a);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px;padding:80px;position:relative}}
.top::after{{content:'';position:absolute;bottom:-60px;left:50%;transform:translateX(-50%);width:250px;height:250px;border-radius:50%;background:rgba(255,255,255,0.08);filter:blur(60px)}}
.h1{{font-family:'Poppins',sans-serif;font-size:90px;font-weight:900;text-align:center;line-height:.88;letter-spacing:-4px;color:#fff;z-index:2}}
.sub{{font-size:22px;color:rgba(255,255,255,0.8);z-index:2}}
.mube-mark{{font-size:60px;z-index:2;margin-top:10px}}
.bottom{{background:{LBG};padding:50px 80px;display:flex;justify-content:space-between;align-items:center}}
.bottom-text{{font-family:'Poppins',sans-serif;font-size:28px;font-weight:800;color:{LTEXT}}}
.bottom-sub{{font-size:18px;color:{LMUTED};margin-top:6px}}
.stores{{display:flex;gap:16px}}
.store{{padding:14px 28px;background:{LSURF};border:1px solid #ddd;border-radius:14px;display:flex;align-items:center;gap:10px;font-weight:700;font-size:16px;color:{LTEXT}}}
.store small{{font-size:11px;font-weight:500;color:{LMUTED};display:block}}
"""
    b = f"""
<div class="top">
<h1 class="h1">Baixe.<br>Conecte.<br>Toque.</h1>
<div class="sub">Grátis · iOS e Android · Brasil</div>
<div class="mube-mark">{mube_icon(60, "#fff", PRIMARY)}</div>
</div>
<div class="bottom">
<div><div class="bottom-text">Disponível agora.</div><div class="bottom-sub">Sua próxima parceria musical espera.</div></div>
<div class="stores">
<div class="store"><div><small>Baixe na</small>App Store</div></div>
<div class="store"><div><small>Baixe no</small>Google Play</div></div>
</div>
</div>
"""
    return wrap(s, b)


# ═══════════════════════════════════════════
# RENDERIZAÇÃO
# ═══════════════════════════════════════════
ALL_ARTS = [
    ("01_manifesto", art_01_manifesto),
    ("02_quatro_perfis", art_02_quatro_perfis),
    ("03_matchpoint", art_03_matchpoint),
    ("04_busca_inteligente", art_04_busca),
    ("05_chat", art_05_chat),
    ("06_galeria", art_06_galeria),
    ("07_perfil_destaque", art_07_perfil),
    ("08_em_numeros", art_08_numeros),
    ("09_download_cta", art_09_download),
    ("10_para_musicos", art_10_musicos),
    ("11_localizacao", art_11_localizacao),
    ("12_comunidade", art_12_comunidade),
    ("b01_algoritmo", art_b01_algoritmo),
    ("b02_carlos", art_b02_carlos),
    ("b03_antes_depois", art_b03_antes_depois),
    ("b04_love_story", art_b04_love_story),
    ("b05_ghosting", art_b05_ghosting),
    ("b06_ratings", art_b06_ratings),
    ("b07_pitch", art_b07_pitch),
    ("b08_fomo", art_b08_fomo),
    ("b09_mitos", art_b09_mitos),
    ("b10_quiz_dark", art_b10_quiz),
    ("b11_manifesto2", art_b11_manifesto2),
    ("b12_dj_rafa", art_b12_dj_rafa),
    ("b13_mari", art_b13_mari),
    ("b14_tinder_parody", art_b14_tinder),
    ("b15_instrucoes", art_b15_instrucoes),
    ("b16_testimonial", art_b16_testimonial),
    ("b17_features_light", art_b17_features),
    ("b18_perda", art_b18_perda),
    ("b19_qual_voce_light", art_b19_quiz_light),
    ("b20_banda_certa", art_b20_banda_certa),
    ("b21_mensagem", art_b21_mensagem),
    ("b22_cta_light", art_b22_cta),
]


async def render_all():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page(viewport={"width": 1080, "height": 1080})

        for name, fn in ALL_ARTS:
            html = fn()
            await page.set_content(html, wait_until="networkidle")
            await page.wait_for_timeout(800)  # fonts
            path = OUT / f"{name}.png"
            await page.screenshot(path=str(path), type="png")
            print(f"   ✅ {name}.png")

        await browser.close()
        print(f"\n🎉 {len(ALL_ARTS)} artes geradas em {OUT}")


if __name__ == "__main__":
    asyncio.run(render_all())
