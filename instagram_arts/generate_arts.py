#!/usr/bin/env python3
"""
Mube Instagram Arts Generator
Gera 12 artes criativas 1080x1080 para Instagram usando Playwright
"""

import asyncio
import base64
import os
import tempfile
from pathlib import Path
from playwright.async_api import async_playwright

# ─────────────────────────────────────────
# Assets
# ─────────────────────────────────────────
BASE = Path(__file__).parent.parent
ASSETS = BASE / "assets" / "images"
OUT = Path(__file__).parent / "output"
OUT.mkdir(exist_ok=True)


def b64(path):
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def img_uri(path, mime="image/png"):
    return f"data:{mime};base64,{b64(path)}"


print("⏳ Carregando assets...")
SS = {i: img_uri(ASSETS / "screenshots" / f"ss{i}.png") for i in range(1, 8)
      if (ASSETS / "screenshots" / f"ss{i}.png").exists()}
print(f"   ✓ {len(SS)} screenshots carregados")

# ─────────────────────────────────────────
# SVGs inline
# ─────────────────────────────────────────
ICON_SVG = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 750"><circle cx="375" cy="375" r="375" fill="#e8466c"/><path d="M586.09,443.47c0,37.28-30.22,67.5-67.5,67.5-9.54,0-18.61-1.98-26.84-5.55-23.92-10.37-40.66-34.21-40.66-61.95v-241.87c0-4.81-1.97-9.19-5.14-12.36-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,.47-.01.94-.04,1.41v6.23c-.08,37.22-30.27,67.36-67.5,67.36-6.04,0-11.89-.79-17.45-2.28-28.09-7.49-48.96-32.65-50-62.85v-194.24c0-.43-.02-.86-.05-1.28-.31-4.3-2.2-8.19-5.09-11.08-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,13.75-11.25,25-25,25s-25-11.25-25-25v-284.37c.08-37.22,30.27-67.36,67.5-67.36,6.03,0,11.88.79,17.45,2.29,28.09,7.48,48.96,32.64,50,62.84v194.24c0,.43.02.86.05,1.28.31,4.3,2.2,8.19,5.09,11.08,3.17,3.17,7.55,5.14,12.36,5.14,9.62,0,17.5-7.87,17.5-17.5V209.24c0-.47,0-.94.04-1.41v-6.23c.08-37.22,30.27-67.36,67.5-67.36s67.42,30.14,67.5,67.36v176.66c5.58-1.49,11.45-2.29,17.5-2.29,37.28,0,67.5,30.22,67.5,67.5Z" fill="#fff"/></svg>"""

WORD_SVG = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1145.75 358.33"><path d="M564.74,253.29c0,14.87-2.79,28.11-8.37,39.73-5.57,11.62-13.55,20.68-23.93,27.19-10.38,6.5-22.7,9.76-36.95,9.76-13.01,0-24.71-2.78-35.09-8.37-10.38-5.57-18.59-13.54-24.63-23.93-6.04-10.38-9.07-22.85-9.07-37.42V105.03h-27.88v157.54c0,19.52,4.18,36.33,12.55,50.43,8.37,14.11,19.59,25.02,33.69,32.76,14.1,7.74,29.51,11.62,46.24,11.62,19.52,0,36.4-4.87,50.66-14.64,9.62-6.59,17.1-14.76,22.77-24.24v33.31h27.88V105.03h-27.88v148.25Z" fill="#fff"/><path d="M826.82,116.18c-18.28-11.15-39.04-16.72-62.27-16.72s-42.69,5.34-60.18,16.03c-14.88,9.08-26.61,20.96-35.55,35.31V0h-27.88v351.81h27.88v-47.62c8.52,15.08,20.08,27.43,35.09,36.7,17.81,10.99,38.03,16.49,60.65,16.49s43.99-5.65,62.27-16.96c18.27-11.3,32.68-26.72,43.22-46.24,10.53-19.51,15.8-41.51,15.8-65.99s-5.27-46.47-15.8-66c-10.54-19.51-24.95-34.85-43.22-46.01ZM844.01,280.01c-8.06,15.33-19.05,27.42-32.99,36.24-13.94,8.84-29.75,13.25-47.4,13.25s-33.62-4.41-47.87-13.25c-14.25-8.83-25.56-20.91-33.92-36.24-8.37-15.34-12.55-32.61-12.55-51.82s4.18-36.4,12.55-51.59c8.37-15.17,19.67-27.19,33.92-36.01,14.25-8.84,30.21-13.25,47.87-13.25s33.46,4.41,47.4,13.25c13.94,8.83,24.94,20.84,32.99,36.01,8.06,15.18,12.08,32.38,12.08,51.59s-4.03,36.48-12.08,51.82Z" fill="#fff"/><path d="M305.37,114.76c-13.79-7.75-28.89-11.62-45.31-11.62-1.32,0-2.57.23-3.88.28-1.44-.06-2.83-.28-4.29-.28-19.2,0-36.72,5.5-52.52,16.49-9.73,6.78-17.51,15.03-23.56,24.59-6.06-9.56-13.83-17.82-23.56-24.59-15.8-10.99-33.31-16.49-52.52-16.49-1.46,0-2.85.22-4.29.28-1.31-.05-2.55-.28-3.88-.28-16.42,0-31.52,3.87-45.31,11.62-13.78,7.75-24.94,18.51-33.46,32.29-8.52,13.79-12.78,29.51-12.78,47.17v161.26h27.88v-153.36c0-14.88,3.02-27.66,9.06-38.35,6.04-10.69,14.02-18.9,23.94-24.63,9.92-5.73,21.07-8.6,33.46-8.6,13.33,0,25.02,3.25,35.09,9.76,10.07,6.5,17.97,15.5,23.7,26.95,5.74,11.47,8.6,24.64,8.6,39.51v148.71h28.15v-148.71c0-14.87,2.86-28.04,8.6-39.51,5.73-11.45,13.63-20.44,23.7-26.95,10.07-6.5,21.76-9.76,35.09-9.76,12.39,0,23.54,2.87,33.46,8.6,9.91,5.73,17.89,13.94,23.94,24.63,6.04,10.69,9.06,23.47,9.06,38.35v153.36h27.88v-161.26c0-17.66-4.26-33.38-12.78-47.17-8.53-13.78-19.68-24.54-33.46-32.29Z" fill="#fff"/><path d="M1114.82,138.65c-9.93-10.84-21.69-19.31-35.28-25.43-13.59-6.11-28.79-9.16-45.58-9.16-21.99,0-41.85,5.5-59.56,16.49-17.72,11-31.77,26.04-42.15,45.13-10.39,19.09-15.58,40.7-15.58,64.83s5.34,45.89,16.04,65.28c10.69,19.4,25.2,34.67,43.52,45.81,18.32,11.15,38.94,16.72,61.85,16.72,15.58,0,30.01-2.6,43.29-7.79,13.29-5.19,24.97-12.29,35.05-21.3,10.08-9,17.87-19.16,23.36-30.46l-23.36-12.37c-8.25,14.05-18.94,25.28-32.07,33.67-13.13,8.4-28.56,12.6-46.27,12.6s-33.29-4.35-47.65-13.06c-14.36-8.71-25.66-20.69-33.9-35.96-7.02-13-10.82-27.66-11.42-43.98h198.8c.61-3.66,1.07-7.17,1.37-10.54.3-3.36.46-6.56.46-9.62,0-15.27-2.68-29.85-8.02-43.75-5.35-13.89-12.99-26.27-22.91-37.11ZM956.08,178.51c7.94-15.12,18.78-27.03,32.53-35.73,13.74-8.7,28.86-13.06,45.35-13.06s31.23,4.2,44.21,12.6c12.98,8.4,22.98,19.7,30.01,33.9,5.73,11.58,8.51,24.34,8.35,38.25h-170.9c1.31-13.19,4.79-25.18,10.46-35.96Z" fill="#fff"/></svg>"""

COMMON = """
@import url('https://fonts.googleapis.com/css2?family=Poppins:ital,wght@0,400;0,500;0,600;0,700;0,800;0,900;1,700;1,800;1,900&family=Inter:wght@400;500;600;700;800&display=swap');
*,*::before,*::after{margin:0;padding:0;box-sizing:border-box}
html,body{width:1080px;height:1080px;overflow:hidden;font-family:'Inter',sans-serif;color:#fff;-webkit-font-smoothing:antialiased;text-rendering:optimizeLegibility}
"""

def wrap(style, body, num):
    return f"""<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Arte {num}</title>
<style>{COMMON}{style}</style></head><body>{body}</body></html>"""


# ─────────────────────────────────────────
# ART 1 — MANIFESTO (tipografia editorial)
# ─────────────────────────────────────────
def art1():
    style = """
body{background:#0A0A0A;display:flex;flex-direction:column;justify-content:flex-end;padding:88px;position:relative}
.ghost{position:absolute;top:-120px;right:-80px;font-family:'Poppins',sans-serif;font-size:500px;font-weight:900;color:#fff;opacity:0.022;line-height:1;letter-spacing:-20px;pointer-events:none;user-select:none}
.tag{font-size:11px;font-weight:700;letter-spacing:6px;text-transform:uppercase;color:#E8466C;margin-bottom:36px}
.rule{width:64px;height:3px;background:#E8466C;margin-bottom:44px}
.h1{font-family:'Poppins',sans-serif;font-size:96px;font-weight:900;line-height:.9;letter-spacing:-5px;color:#fff;margin-bottom:28px}
.h1 em{font-style:normal;color:#E8466C}
.body{font-size:19px;color:#B3B3B3;line-height:1.65;max-width:520px;margin-bottom:72px}
.logo-row{display:flex;align-items:center;gap:14px}
.logo-icon{width:36px;height:36px}
.logo-word{height:16px;opacity:.85}
.ver{position:absolute;top:88px;right:88px;font-size:11px;letter-spacing:4px;color:#383838;text-transform:uppercase;writing-mode:vertical-rl}
"""
    body = f"""
<div class="ghost">M</div>
<div class="ver">2026 — BRASIL</div>
<div class="tag">MUBE · PLATAFORMA MUSICAL</div>
<div class="rule"></div>
<h1 class="h1">A música<br><em>conecta.</em><br>O Mube<br><em>aproxima.</em></h1>
<p class="body">Para músicos, bandas, estúdios e contratantes que levam a música a sério. Sem ruído.</p>
<div class="logo-row">
  <svg class="logo-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 750">{ICON_SVG.replace('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 750">','').replace('</svg>','')}</svg>
  <svg class="logo-word" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1145.75 358.33">{WORD_SVG.replace('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1145.75 358.33">','').replace('</svg>','')}</svg>
</div>
"""
    return wrap(style, body, 1)


# ─────────────────────────────────────────
# ART 2 — OS 4 PERFIS (grid colorido)
# ─────────────────────────────────────────
def art2():
    style = """
body{background:#0A0A0A;display:flex;flex-direction:column;padding:64px}
.header{margin-bottom:48px}
.tag{font-size:11px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:16px}
.title{font-family:'Poppins',sans-serif;font-size:44px;font-weight:800;letter-spacing:-2px;line-height:1}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:20px;flex:1}
.card{background:#141414;border-radius:20px;padding:36px 32px;display:flex;flex-direction:column;gap:20px;border:1px solid #1F1F1F;position:relative;overflow:hidden}
.card::before{content:'';position:absolute;top:0;left:0;right:0;height:3px}
.card.musico::before{background:linear-gradient(90deg,#E8466C,#D13F61)}
.card.banda::before{background:linear-gradient(90deg,#C026D3,#9333EA)}
.card.studio::before{background:linear-gradient(90deg,#DC2626,#B91C1C)}
.card.contratante::before{background:linear-gradient(90deg,#F59E0B,#D97706)}
.card-icon{width:56px;height:56px;border-radius:16px;display:flex;align-items:center;justify-content:center;font-size:28px}
.card.musico .card-icon{background:rgba(232,70,108,0.15)}
.card.banda .card-icon{background:rgba(192,38,211,0.15)}
.card.studio .card-icon{background:rgba(220,38,38,0.15)}
.card.contratante .card-icon{background:rgba(245,158,11,0.15)}
.card-name{font-family:'Poppins',sans-serif;font-size:22px;font-weight:700;margin-bottom:4px}
.card-desc{font-size:13px;color:#8A8A8A;line-height:1.5}
.badge{display:inline-flex;align-items:center;gap:6px;padding:5px 14px;border-radius:999px;font-size:11px;font-weight:700;letter-spacing:1px;text-transform:uppercase;align-self:flex-start}
.card.musico .badge{background:rgba(232,70,108,0.15);color:#E8466C}
.card.banda .badge{background:rgba(192,38,211,0.15);color:#C026D3}
.card.studio .badge{background:rgba(220,38,38,0.15);color:#DC2626}
.card.contratante .badge{background:rgba(245,158,11,0.15);color:#F59E0B}
"""
    body = """
<div class="header">
  <div class="tag">QUEM USA O MUBE</div>
  <h1 class="title">Qual é o seu<br>papel na música?</h1>
</div>
<div class="grid">
  <div class="card musico">
    <div class="card-icon">🎵</div>
    <div>
      <div class="card-name">Músico</div>
      <div class="card-desc">Cantor, instrumentista, DJ ou equipe técnica. Seu talento merece ser visto.</div>
    </div>
    <div class="badge">♪ Individual</div>
  </div>
  <div class="card banda">
    <div class="card-icon">🎸</div>
    <div>
      <div class="card-name">Banda</div>
      <div class="card-desc">Grupo musical ou orquestra. Mostre quem vocês são e atraiam as oportunidades certas.</div>
    </div>
    <div class="badge">♪ Grupo</div>
  </div>
  <div class="card studio">
    <div class="card-icon">🎙</div>
    <div>
      <div class="card-name">Estúdio</div>
      <div class="card-desc">Gravação, mixagem e masterização. Conecte com quem precisa de você.</div>
    </div>
    <div class="badge">♪ Serviço</div>
  </div>
  <div class="card contratante">
    <div class="card-icon">🎤</div>
    <div>
      <div class="card-name">Contratante</div>
      <div class="card-desc">Eventos, casas de show ou produtoras. Encontre os artistas certos para seu projeto.</div>
    </div>
    <div class="badge">♪ Produtor</div>
  </div>
</div>
"""
    return wrap(style, body, 2)


# ─────────────────────────────────────────
# ART 3 — MATCHPOINT (feature showcase)
# ─────────────────────────────────────────
def art3():
    ss3_data = SS.get(3, "")
    style = f"""
body{{background:#0A0A0A;display:flex;flex-direction:column;align-items:center;justify-content:space-between;padding:60px 80px}}
.top{{text-align:center}}
.tag{{font-size:11px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:16px}}
.title{{font-family:'Poppins',sans-serif;font-size:38px;font-weight:800;letter-spacing:-1.5px;line-height:1.1}}
.phone-wrap{{position:relative;flex:1;display:flex;align-items:center;justify-content:center;margin:40px 0}}
.glow{{position:absolute;width:300px;height:300px;background:radial-gradient(circle,rgba(232,70,108,0.35) 0%,transparent 70%);border-radius:50%;top:50%;left:50%;transform:translate(-50%,-50%)}}
.phone{{width:240px;height:480px;border-radius:36px;border:2px solid #292929;overflow:hidden;box-shadow:0 40px 80px rgba(0,0,0,0.7),0 0 0 1px #1F1F1F;position:relative;z-index:2}}
.phone img{{width:100%;height:100%;object-fit:cover;object-position:top}}
.swipe-left{{position:absolute;left:-80px;top:50%;transform:translateY(-50%);width:60px;height:60px;background:#1F1F1F;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:24px;z-index:3;box-shadow:0 8px 24px rgba(0,0,0,0.5)}}
.swipe-right{{position:absolute;right:-80px;top:50%;transform:translateY(-50%);width:60px;height:60px;background:rgba(232,70,108,0.2);border:2px solid #E8466C;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:24px;z-index:3;box-shadow:0 8px 24px rgba(232,70,108,0.3)}}
.bottom{{text-align:center}}
.sub{{font-size:17px;color:#B3B3B3;line-height:1.6;margin-bottom:32px;max-width:520px}}
.pill{{display:inline-flex;align-items:center;gap:10px;background:#141414;border:1px solid #292929;border-radius:999px;padding:12px 28px;font-family:'Poppins',sans-serif;font-size:15px;font-weight:600}}
.pill svg{{width:18px;height:18px}}
"""
    body = f"""
<div class="top">
  <div class="tag">MATCHPOINT · RECURSO EXCLUSIVO</div>
  <h1 class="title">Conecte-se com quem toca<br>na mesma frequência</h1>
</div>
<div class="phone-wrap">
  <div class="glow"></div>
  <div class="swipe-left">✕</div>
  <div class="phone">
    <img src="{ss3_data}" alt="Matchpoint screen"/>
  </div>
  <div class="swipe-right">♥</div>
</div>
<div class="bottom">
  <p class="sub">Explore perfis, dê match e inicie uma conversa. Simples assim.</p>
  <div class="pill">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 750" fill="none"><circle cx="375" cy="375" r="375" fill="#e8466c"/><path d="M586.09,443.47c0,37.28-30.22,67.5-67.5,67.5-9.54,0-18.61-1.98-26.84-5.55-23.92-10.37-40.66-34.21-40.66-61.95v-241.87c0-4.81-1.97-9.19-5.14-12.36-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,.47-.01.94-.04,1.41v6.23c-.08,37.22-30.27,67.36-67.5,67.36-6.04,0-11.89-.79-17.45-2.28-28.09-7.49-48.96-32.65-50-62.85v-194.24c0-.43-.02-.86-.05-1.28-.31-4.3-2.2-8.19-5.09-11.08-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,13.75-11.25,25-25,25s-25-11.25-25-25v-284.37c.08-37.22,30.27-67.36,67.5-67.36,6.03,0,11.88.79,17.45,2.29,28.09,7.48,48.96,32.64,50,62.84v194.24c0,.43.02.86.05,1.28.31,4.3,2.2,8.19,5.09,11.08,3.17,3.17,7.55,5.14,12.36,5.14,9.62,0,17.5-7.87,17.5-17.5V209.24c0-.47,0-.94.04-1.41v-6.23c.08-37.22,30.27-67.36,67.5-67.36s67.42,30.14,67.5,67.36v176.66c5.58-1.49,11.45-2.29,17.5-2.29,37.28,0,67.5,30.22,67.5,67.5Z" fill="#fff"/></svg>
    mube.app · disponível agora
  </div>
</div>
"""
    return wrap(style, body, 3)


# ─────────────────────────────────────────
# ART 4 — BUSCA INTELIGENTE (split layout)
# ─────────────────────────────────────────
def art4():
    ss5_data = SS.get(5, "")
    style = f"""
body{{background:#0A0A0A;display:grid;grid-template-columns:1fr 1fr;overflow:hidden}}
.left{{padding:88px 56px 88px 80px;display:flex;flex-direction:column;justify-content:center}}
.tag{{font-size:10px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:20px}}
.title{{font-family:'Poppins',sans-serif;font-size:56px;font-weight:900;line-height:.95;letter-spacing:-3px;margin-bottom:28px}}
.title em{{font-style:normal;color:#E8466C}}
.body{{font-size:15px;color:#B3B3B3;line-height:1.7;margin-bottom:48px}}
.cats{{display:flex;flex-direction:column;gap:10px}}
.cat{{display:flex;align-items:center;gap:12px;font-size:13px;font-weight:600;color:#fff}}
.cat-dot{{width:8px;height:8px;border-radius:50%;background:#E8466C;flex-shrink:0}}
.cat-dot.b{{background:#C026D3}}
.cat-dot.c{{background:#3B82F6}}
.cat-dot.d{{background:#22C55E}}
.right{{position:relative;overflow:hidden}}
.right::before{{content:'';position:absolute;top:0;left:0;bottom:0;width:60px;background:linear-gradient(90deg,#0A0A0A,transparent);z-index:2}}
.right img{{width:100%;height:100%;object-fit:cover;object-position:top center}}
.right::after{{content:'';position:absolute;inset:0;background:linear-gradient(180deg,rgba(10,10,10,0.3) 0%,transparent 30%)}}
"""
    body = f"""
<div class="left">
  <div class="tag">BUSCA · DESCUBRA</div>
  <h1 class="title">Encontre<br>o profissional<br><em>certo.</em></h1>
  <p class="body">Busque por instrumento, gênero musical ou função. Sem algoritmo escondido, sem ruído.</p>
  <div class="cats">
    <div class="cat"><div class="cat-dot"></div> Cantores & Instrumentistas</div>
    <div class="cat"><div class="cat-dot b"></div> Bandas & Grupos</div>
    <div class="cat"><div class="cat-dot c"></div> Estúdios de Gravação</div>
    <div class="cat"><div class="cat-dot d"></div> Beatmakers & DJs</div>
  </div>
</div>
<div class="right">
  <img src="{ss5_data}" alt="Tela de busca"/>
</div>
"""
    return wrap(style, body, 4)


# ─────────────────────────────────────────
# ART 5 — CHAT (conversa simulada)
# ─────────────────────────────────────────
def art5():
    style = """
body{background:#0A0A0A;display:flex;flex-direction:column;justify-content:space-between;padding:72px 80px}
.top{text-align:center}
.tag{font-size:11px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:16px}
.title{font-family:'Poppins',sans-serif;font-size:42px;font-weight:800;letter-spacing:-2px;line-height:1.1}
.chat{display:flex;flex-direction:column;gap:20px;flex:1;justify-content:center;padding:20px 0}
.msg{display:flex;flex-direction:column;max-width:68%}
.msg.recv{align-self:flex-start;align-items:flex-start}
.msg.sent{align-self:flex-end;align-items:flex-end}
.msg-name{font-size:11px;font-weight:600;color:#8A8A8A;letter-spacing:1px;margin-bottom:6px;text-transform:uppercase}
.bubble{padding:16px 22px;border-radius:20px;font-size:15px;line-height:1.55;font-weight:500}
.msg.recv .bubble{background:#1F1F1F;color:#fff;border-bottom-left-radius:6px}
.msg.sent .bubble{background:#E8466C;color:#fff;border-bottom-right-radius:6px}
.time{font-size:10px;color:#4A4A4A;margin-top:6px}
.bottom{display:flex;align-items:center;justify-content:space-between}
.cta{font-family:'Poppins',sans-serif;font-size:22px;font-weight:700;letter-spacing:-0.5px}
.cta em{font-style:normal;color:#E8466C}
.logo-wrap{display:flex;align-items:center;gap:10px}
.logo-icon{width:32px;height:32px}
"""
    body = f"""
<div class="top">
  <div class="tag">CHAT · COMUNICAÇÃO REAL</div>
  <h1 class="title">Do match à parceria,<br>em segundos.</h1>
</div>
<div class="chat">
  <div class="msg recv">
    <div class="msg-name">Hygor Tomaz</div>
    <div class="bubble">Oi! Vi seu perfil no Mube, você toca baixo né? Estamos precisando pra um show no fim do mês 🎶</div>
    <div class="time">14:32</div>
  </div>
  <div class="msg sent">
    <div class="msg-name">Você</div>
    <div class="bubble">Oi Hygor! Sim, toco baixo há 8 anos. Que tipo de show é?</div>
    <div class="time">14:34</div>
  </div>
  <div class="msg recv">
    <div class="msg-name">Hygor Tomaz</div>
    <div class="bubble">Show de rock autoral, 45 min de set. Podemos marcar um ensaio essa semana? 🤘</div>
    <div class="time">14:35</div>
  </div>
  <div class="msg sent">
    <div class="msg-name">Você</div>
    <div class="bubble">Perfeito! Quinta ou sexta funciona. Manda o repertório que já começo a estudar 🎸</div>
    <div class="time">14:36</div>
  </div>
</div>
<div class="bottom">
  <p class="cta">Sua próxima<br>parceria começa<br><em>aqui.</em></p>
  <div class="logo-wrap">
    <svg class="logo-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 750"><circle cx="375" cy="375" r="375" fill="#e8466c"/><path d="M586.09,443.47c0,37.28-30.22,67.5-67.5,67.5-9.54,0-18.61-1.98-26.84-5.55-23.92-10.37-40.66-34.21-40.66-61.95v-241.87c0-4.81-1.97-9.19-5.14-12.36-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,.47-.01.94-.04,1.41v6.23c-.08,37.22-30.27,67.36-67.5,67.36-6.04,0-11.89-.79-17.45-2.28-28.09-7.49-48.96-32.65-50-62.85v-194.24c0-.43-.02-.86-.05-1.28-.31-4.3-2.2-8.19-5.09-11.08-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,13.75-11.25,25-25,25s-25-11.25-25-25v-284.37c.08-37.22,30.27-67.36,67.5-67.36,6.03,0,11.88.79,17.45,2.29,28.09,7.48,48.96,32.64,50,62.84v194.24c0,.43.02.86.05,1.28.31,4.3,2.2,8.19,5.09,11.08,3.17,3.17,7.55,5.14,12.36,5.14,9.62,0,17.5-7.87,17.5-17.5V209.24c0-.47,0-.94.04-1.41v-6.23c.08-37.22,30.27-67.36,67.5-67.36s67.42,30.14,67.5,67.36v176.66c5.58-1.49,11.45-2.29,17.5-2.29,37.28,0,67.5,30.22,67.5,67.5Z" fill="#fff"/></svg>
    <span style="font-family:'Poppins',sans-serif;font-size:20px;font-weight:700">mube</span>
  </div>
</div>
"""
    return wrap(style, body, 5)


# ─────────────────────────────────────────
# ART 6 — GALERIA (colagem de fotos)
# ─────────────────────────────────────────
def art6():
    ss6_data = SS.get(6, "")
    style = f"""
body{{background:#0D0D0D;position:relative;overflow:hidden}}
.bg-img{{position:absolute;inset:-20px;background:url('{ss6_data}') center/cover no-repeat;filter:blur(12px) brightness(0.15);transform:scale(1.1)}}
.overlay{{position:absolute;inset:0;background:linear-gradient(180deg,rgba(10,10,10,0.6) 0%,rgba(10,10,10,0.95) 100%)}}
.content{{position:relative;z-index:2;height:100%;display:flex;flex-direction:column;padding:72px 80px}}
.tag{{font-size:11px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:16px}}
.title{{font-family:'Poppins',sans-serif;font-size:52px;font-weight:900;letter-spacing:-2.5px;line-height:1;margin-bottom:8px}}
.sub{{font-size:16px;color:#8A8A8A;margin-bottom:40px}}
.grid{{display:grid;grid-template-columns:repeat(3,1fr);grid-template-rows:repeat(2,1fr);gap:12px;flex:1}}
.photo{{border-radius:16px;overflow:hidden;background:#1F1F1F}}
.photo img{{width:100%;height:100%;object-fit:cover}}
.photo.big{{grid-column:span 2;grid-row:span 1}}
.bottom{{margin-top:40px;display:flex;align-items:center;justify-content:space-between}}
.stat{{text-align:center}}
.stat-num{{font-family:'Poppins',sans-serif;font-size:32px;font-weight:800;color:#E8466C}}
.stat-label{{font-size:12px;color:#8A8A8A;margin-top:2px}}
.logo-sm{{display:flex;align-items:center;gap:8px}}
.logo-sm svg{{width:28px;height:28px}}
"""
    body = f"""
<div class="bg-img"></div>
<div class="overlay"></div>
<div class="content">
  <div class="tag">GALERIA · PORTFÓLIO MUSICAL</div>
  <h1 class="title">Seu portfólio.<br>Sua história.</h1>
  <p class="sub">Fotos, vídeos e links integrados ao seu perfil.</p>
  <div class="grid">
    <div class="photo big">
      <img src="{ss6_data}" alt="galeria" style="object-position:center 20%"/>
    </div>
    <div class="photo" style="background:linear-gradient(135deg,#1a0810,#2d1220)">
      <div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;font-size:48px">🎸</div>
    </div>
    <div class="photo" style="background:linear-gradient(135deg,#0a1a2d,#0d2240)">
      <div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;font-size:48px">🎙️</div>
    </div>
    <div class="photo" style="background:linear-gradient(135deg,#0d1a0d,#1a2e1a)">
      <div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;font-size:48px">🥁</div>
    </div>
    <div class="photo" style="background:linear-gradient(135deg,#1a1a0d,#2e2e0d)">
      <div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;font-size:48px">🎹</div>
    </div>
  </div>
  <div class="bottom">
    <div class="stat"><div class="stat-num">Fotos</div><div class="stat-label">& Vídeos</div></div>
    <div class="stat"><div class="stat-num">Links</div><div class="stat-label">Instagram & Spotify</div></div>
    <div class="stat"><div class="stat-num">Livre</div><div class="stat-label">Para todos</div></div>
    <div class="logo-sm">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 750"><circle cx="375" cy="375" r="375" fill="#e8466c"/><path d="M586.09,443.47c0,37.28-30.22,67.5-67.5,67.5-9.54,0-18.61-1.98-26.84-5.55-23.92-10.37-40.66-34.21-40.66-61.95v-241.87c0-4.81-1.97-9.19-5.14-12.36-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,.47-.01.94-.04,1.41v6.23c-.08,37.22-30.27,67.36-67.5,67.36-6.04,0-11.89-.79-17.45-2.28-28.09-7.49-48.96-32.65-50-62.85v-194.24c0-.43-.02-.86-.05-1.28-.31-4.3-2.2-8.19-5.09-11.08-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,13.75-11.25,25-25,25s-25-11.25-25-25v-284.37c.08-37.22,30.27-67.36,67.5-67.36,6.03,0,11.88.79,17.45,2.29,28.09,7.48,48.96,32.64,50,62.84v194.24c0,.43.02.86.05,1.28.31,4.3,2.2,8.19,5.09,11.08,3.17,3.17,7.55,5.14,12.36,5.14,9.62,0,17.5-7.87,17.5-17.5V209.24c0-.47,0-.94.04-1.41v-6.23c.08-37.22,30.27-67.36,67.5-67.36s67.42,30.14,67.5,67.36v176.66c5.58-1.49,11.45-2.29,17.5-2.29,37.28,0,67.5,30.22,67.5,67.5Z" fill="#fff"/></svg>
      <span style="font-family:'Poppins',sans-serif;font-weight:700">mube</span>
    </div>
  </div>
</div>
"""
    return wrap(style, body, 6)


# ─────────────────────────────────────────
# ART 7 — PERFIL EM DESTAQUE (phone mockup)
# ─────────────────────────────────────────
def art7():
    ss4_data = SS.get(4, "")
    style = f"""
body{{background:#0A0A0A;display:flex;align-items:center;justify-content:center;position:relative;overflow:hidden}}
.bg-glow{{position:absolute;width:500px;height:500px;background:radial-gradient(circle,rgba(232,70,108,0.12) 0%,transparent 70%);border-radius:50%;top:50%;left:50%;transform:translate(-50%,-50%)}}
.content{{position:relative;display:flex;align-items:center;gap:60px}}
.left-labels{{display:flex;flex-direction:column;gap:24px;align-items:flex-end}}
.right-labels{{display:flex;flex-direction:column;gap:24px;align-items:flex-start}}
.label-pill{{background:#141414;border:1px solid #292929;border-radius:12px;padding:12px 18px;max-width:180px}}
.label-pill .lp-title{{font-size:11px;font-weight:700;color:#E8466C;letter-spacing:2px;text-transform:uppercase;margin-bottom:4px}}
.label-pill .lp-body{{font-size:12px;color:#B3B3B3;line-height:1.4}}
.label-arrow{{font-size:18px;color:#383838;margin-left:8px}}
.phone-frame{{width:220px;height:460px;border-radius:34px;border:2px solid #292929;overflow:hidden;box-shadow:0 60px 120px rgba(0,0,0,0.8),0 0 0 1px #1F1F1F;flex-shrink:0;background:#0A0A0A}}
.phone-frame img{{width:100%;height:100%;object-fit:cover;object-position:top center}}
.bottom-text{{position:absolute;bottom:72px;left:0;right:0;text-align:center}}
.bottom-text .title{{font-family:'Poppins',sans-serif;font-size:32px;font-weight:800;letter-spacing:-1px}}
.bottom-text .sub{{font-size:14px;color:#8A8A8A;margin-top:8px}}
"""
    body = f"""
<div class="bg-glow"></div>
<div style="display:flex;flex-direction:column;align-items:center;gap:40px">
  <div style="text-align:center">
    <div style="font-size:11px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:12px">PERFIL · IDENTIDADE PROFISSIONAL</div>
    <h1 style="font-family:'Poppins',sans-serif;font-size:38px;font-weight:800;letter-spacing:-1.5px">Um perfil que fala por você.</h1>
  </div>
  <div class="content">
    <div class="left-labels">
      <div class="label-pill">
        <div class="lp-title">Localização</div>
        <div class="lp-body">Conecta por proximidade geográfica</div>
      </div>
      <div class="label-pill">
        <div class="lp-title">Badge de tipo</div>
        <div class="lp-body">Músico, Banda, Estúdio ou Contratante</div>
      </div>
      <div class="label-pill">
        <div class="lp-title">Instrumentos</div>
        <div class="lp-body">Chips com suas especialidades</div>
      </div>
    </div>
    <div class="phone-frame">
      <img src="{ss4_data}" alt="perfil"/>
    </div>
    <div class="right-labels">
      <div class="label-pill">
        <div class="lp-title">Favoritos</div>
        <div class="lp-body">Quem curtiu seu perfil</div>
      </div>
      <div class="label-pill">
        <div class="lp-title">Funções técnicas</div>
        <div class="lp-body">Arranjador, beatmaker, compositor...</div>
      </div>
      <div class="label-pill">
        <div class="lp-title">Chat direto</div>
        <div class="lp-body">Inicie conversa com um toque</div>
      </div>
    </div>
  </div>
</div>
"""
    return wrap(style, body, 7)


# ─────────────────────────────────────────
# ART 8 — EM NÚMEROS (tipografia bold)
# ─────────────────────────────────────────
def art8():
    style = """
body{background:#0A0A0A;display:flex;flex-direction:column;justify-content:center;padding:80px;position:relative;overflow:hidden}
.rule-v{position:absolute;top:0;bottom:0;left:50%;width:1px;background:#141414}
.tag{font-size:11px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:60px}
.stat-row{display:flex;align-items:flex-end;gap:0;margin-bottom:16px;position:relative}
.stat-num{font-family:'Poppins',sans-serif;font-weight:900;line-height:.85;letter-spacing:-6px;color:#fff}
.stat-num.giant{font-size:180px}
.stat-num.large{font-size:140px}
.stat-num.medium{font-size:100px}
.stat-unit{font-family:'Poppins',sans-serif;font-size:32px;font-weight:700;color:#E8466C;align-self:flex-start;margin-top:24px;margin-left:8px}
.stat-label{position:absolute;right:0;bottom:8px;font-size:14px;color:#8A8A8A;max-width:220px;text-align:right;line-height:1.5}
.divider{width:100%;height:1px;background:#1F1F1F;margin:16px 0}
.footer{margin-top:40px;display:flex;align-items:center;justify-content:space-between}
.footer-text{font-family:'Poppins',sans-serif;font-size:22px;font-weight:700;letter-spacing:-0.5px}
.footer-text em{font-style:normal;color:#E8466C}
.logo-sm{display:flex;align-items:center;gap:10px}
.logo-sm svg{width:28px;height:28px}
"""
    body = f"""
<div class="rule-v"></div>
<div class="tag">MUBE · EM NÚMEROS</div>
<div class="stat-row">
  <div class="stat-num giant">4</div>
  <div class="stat-unit">tipos</div>
  <div class="stat-label">Músico, Banda,<br>Estúdio e Contratante</div>
</div>
<div class="divider"></div>
<div class="stat-row">
  <div class="stat-num large">1</div>
  <div class="stat-unit">app</div>
  <div class="stat-label">Tudo que você precisa<br>para se conectar</div>
</div>
<div class="divider"></div>
<div class="stat-row">
  <div class="stat-num medium">∞</div>
  <div class="stat-label">Conexões,<br>colaborações<br>e oportunidades</div>
</div>
<div class="footer">
  <p class="footer-text">Uma plataforma.<br><em>Infinitas possibilidades.</em></p>
  <div class="logo-sm">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 750"><circle cx="375" cy="375" r="375" fill="#e8466c"/><path d="M586.09,443.47c0,37.28-30.22,67.5-67.5,67.5-9.54,0-18.61-1.98-26.84-5.55-23.92-10.37-40.66-34.21-40.66-61.95v-241.87c0-4.81-1.97-9.19-5.14-12.36-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,.47-.01.94-.04,1.41v6.23c-.08,37.22-30.27,67.36-67.5,67.36-6.04,0-11.89-.79-17.45-2.28-28.09-7.49-48.96-32.65-50-62.85v-194.24c0-.43-.02-.86-.05-1.28-.31-4.3-2.2-8.19-5.09-11.08-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,13.75-11.25,25-25,25s-25-11.25-25-25v-284.37c.08-37.22,30.27-67.36,67.5-67.36,6.03,0,11.88.79,17.45,2.29,28.09,7.48,48.96,32.64,50,62.84v194.24c0,.43.02.86.05,1.28.31,4.3,2.2,8.19,5.09,11.08,3.17,3.17,7.55,5.14,12.36,5.14,9.62,0,17.5-7.87,17.5-17.5V209.24c0-.47,0-.94.04-1.41v-6.23c.08-37.22,30.27-67.36,67.5-67.36s67.42,30.14,67.5,67.36v176.66c5.58-1.49,11.45-2.29,17.5-2.29,37.28,0,67.5,30.22,67.5,67.5Z" fill="#fff"/></svg>
    <span style="font-family:'Poppins',sans-serif;font-weight:700;font-size:18px">mube</span>
  </div>
</div>
"""
    return wrap(style, body, 8)


# ─────────────────────────────────────────
# ART 9 — DOWNLOAD CTA (gradiente + ícone)
# ─────────────────────────────────────────
def art9():
    style = """
body{background:#0A0A0A;display:flex;flex-direction:column;align-items:center;justify-content:center;position:relative;overflow:hidden}
.bg-grad{position:absolute;inset:0;background:radial-gradient(ellipse 80% 60% at 50% 40%,rgba(232,70,108,0.18) 0%,transparent 70%)}
.rings{position:absolute;top:50%;left:50%;transform:translate(-50%,-55%)}
.ring{position:absolute;border-radius:50%;border:1px solid rgba(232,70,108,0.08);transform:translate(-50%,-50%)}
.r1{width:300px;height:300px;top:0;left:0}
.r2{width:500px;height:500px;top:0;left:0;border-color:rgba(232,70,108,0.05)}
.r3{width:700px;height:700px;top:0;left:0;border-color:rgba(232,70,108,0.03)}
.content{position:relative;display:flex;flex-direction:column;align-items:center;gap:0}
.app-icon{width:120px;height:120px;border-radius:28px;overflow:hidden;box-shadow:0 24px 64px rgba(232,70,108,0.4);margin-bottom:36px}
.app-icon svg{width:100%;height:100%}
.eyebrow{font-size:11px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:20px}
.h1{font-family:'Poppins',sans-serif;font-size:68px;font-weight:900;letter-spacing:-3px;line-height:.95;text-align:center;margin-bottom:16px}
.h1 em{font-style:normal;color:#E8466C}
.sub{font-size:18px;color:#B3B3B3;text-align:center;margin-bottom:56px}
.stores{display:flex;gap:16px}
.store-btn{display:flex;align-items:center;gap:12px;background:#141414;border:1px solid #292929;border-radius:16px;padding:14px 28px;font-size:15px;font-weight:600;color:#fff}
.store-btn .store-icon{font-size:24px}
.store-btn .store-sub{font-size:10px;color:#8A8A8A;font-weight:400}
.store-btn .store-name{font-family:'Poppins',sans-serif;font-weight:700;font-size:14px}
"""
    body = f"""
<div class="bg-grad"></div>
<div class="rings">
  <div class="ring r1"></div>
  <div class="ring r2"></div>
  <div class="ring r3"></div>
</div>
<div class="content">
  <div class="app-icon">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 750"><circle cx="375" cy="375" r="375" fill="#e8466c"/><path d="M586.09,443.47c0,37.28-30.22,67.5-67.5,67.5-9.54,0-18.61-1.98-26.84-5.55-23.92-10.37-40.66-34.21-40.66-61.95v-241.87c0-4.81-1.97-9.19-5.14-12.36-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,.47-.01.94-.04,1.41v6.23c-.08,37.22-30.27,67.36-67.5,67.36-6.04,0-11.89-.79-17.45-2.28-28.09-7.49-48.96-32.65-50-62.85v-194.24c0-.43-.02-.86-.05-1.28-.31-4.3-2.2-8.19-5.09-11.08-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,13.75-11.25,25-25,25s-25-11.25-25-25v-284.37c.08-37.22,30.27-67.36,67.5-67.36,6.03,0,11.88.79,17.45,2.29,28.09,7.48,48.96,32.64,50,62.84v194.24c0,.43.02.86.05,1.28.31,4.3,2.2,8.19,5.09,11.08,3.17,3.17,7.55,5.14,12.36,5.14,9.62,0,17.5-7.87,17.5-17.5V209.24c0-.47,0-.94.04-1.41v-6.23c.08-37.22,30.27-67.36,67.5-67.36s67.42,30.14,67.5,67.36v176.66c5.58-1.49,11.45-2.29,17.5-2.29,37.28,0,67.5,30.22,67.5,67.5Z" fill="#fff"/></svg>
  </div>
  <div class="eyebrow">DISPONÍVEL AGORA</div>
  <h1 class="h1">Baixe o <em>Mube.</em><br>É grátis.</h1>
  <p class="sub">Android e iOS · Brasil</p>
  <div class="stores">
    <div class="store-btn">
      <div class="store-icon">📱</div>
      <div>
        <div class="store-sub">Disponível na</div>
        <div class="store-name">App Store</div>
      </div>
    </div>
    <div class="store-btn">
      <div class="store-icon">🤖</div>
      <div>
        <div class="store-sub">Disponível no</div>
        <div class="store-name">Google Play</div>
      </div>
    </div>
  </div>
</div>
"""
    return wrap(style, body, 9)


# ─────────────────────────────────────────
# ART 10 — PARA MÚSICOS (poster direto)
# ─────────────────────────────────────────
def art10():
    style = """
body{background:#0A0A0A;display:flex;flex-direction:column;justify-content:center;padding:88px;position:relative;overflow:hidden}
.stripe{position:absolute;top:0;left:0;bottom:0;width:6px;background:#E8466C}
.deco{position:absolute;right:-100px;top:-100px;width:600px;height:600px;border-radius:50%;border:1px solid rgba(232,70,108,0.06)}
.deco2{position:absolute;right:-200px;top:-200px;width:800px;height:800px;border-radius:50%;border:1px solid rgba(232,70,108,0.04)}
.deco3{position:absolute;right:100px;bottom:-300px;width:600px;height:600px;border-radius:50%;border:1px solid rgba(255,255,255,0.03)}
.eyebrow{font-size:11px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:40px}
.big-q{font-family:'Poppins',sans-serif;font-size:80px;font-weight:900;line-height:.9;letter-spacing:-4px;margin-bottom:40px}
.big-q em{font-style:italic;color:#E8466C}
.answer{font-family:'Poppins',sans-serif;font-size:28px;font-weight:700;color:#fff;line-height:1.3;margin-bottom:48px;border-left:3px solid #E8466C;padding-left:24px}
.desc{font-size:17px;color:#8A8A8A;line-height:1.7;max-width:540px;margin-bottom:56px}
.cta-pill{display:inline-flex;align-items:center;gap:12px;background:#E8466C;border-radius:999px;padding:16px 36px;font-family:'Poppins',sans-serif;font-size:16px;font-weight:700;color:#fff;align-self:flex-start}
"""
    body = f"""
<div class="stripe"></div>
<div class="deco"></div>
<div class="deco2"></div>
<div class="deco3"></div>
<div class="eyebrow">PARA MÚSICOS · PROFISSIONAIS</div>
<h1 class="big-q">Você toca,<br>canta ou<br><em>produz?</em></h1>
<p class="answer">Então você já deveria<br>estar no Mube.</p>
<p class="desc">Crie seu perfil profissional, mostre seus instrumentos, géneros e funções técnicas. Deixe as oportunidades chegarem até você.</p>
<div class="cta-pill">
  <svg width="20" height="20" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 750"><circle cx="375" cy="375" r="375" fill="rgba(255,255,255,0.2)"/><path d="M586.09,443.47c0,37.28-30.22,67.5-67.5,67.5-9.54,0-18.61-1.98-26.84-5.55-23.92-10.37-40.66-34.21-40.66-61.95v-241.87c0-4.81-1.97-9.19-5.14-12.36-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,.47-.01.94-.04,1.41v6.23c-.08,37.22-30.27,67.36-67.5,67.36-6.04,0-11.89-.79-17.45-2.28-28.09-7.49-48.96-32.65-50-62.85v-194.24c0-.43-.02-.86-.05-1.28-.31-4.3-2.2-8.19-5.09-11.08-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,13.75-11.25,25-25,25s-25-11.25-25-25v-284.37c.08-37.22,30.27-67.36,67.5-67.36,6.03,0,11.88.79,17.45,2.29,28.09,7.48,48.96,32.64,50,62.84v194.24c0,.43.02.86.05,1.28.31,4.3,2.2,8.19,5.09,11.08,3.17,3.17,7.55,5.14,12.36,5.14,9.62,0,17.5-7.87,17.5-17.5V209.24c0-.47,0-.94.04-1.41v-6.23c.08-37.22,30.27-67.36,67.5-67.36s67.42,30.14,67.5,67.36v176.66c5.58-1.49,11.45-2.29,17.5-2.29,37.28,0,67.5,30.22,67.5,67.5Z" fill="#fff"/></svg>
  Criar meu perfil agora
</div>
"""
    return wrap(style, body, 10)


# ─────────────────────────────────────────
# ART 11 — LOCALIZAÇÃO (radar visual)
# ─────────────────────────────────────────
def art11():
    style = """
body{background:#0A0A0A;display:flex;flex-direction:column;align-items:center;justify-content:center;position:relative;overflow:hidden}
.radar{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%)}
.radar-circle{position:absolute;border-radius:50%;border:1px solid rgba(232,70,108,0.12);top:50%;left:50%;transform:translate(-50%,-50%)}
.rc1{width:200px;height:200px;border-color:rgba(232,70,108,0.3)}
.rc2{width:360px;height:360px;border-color:rgba(232,70,108,0.18)}
.rc3{width:520px;height:520px;border-color:rgba(232,70,108,0.1)}
.rc4{width:700px;height:700px;border-color:rgba(232,70,108,0.06)}
.rc5{width:900px;height:900px;border-color:rgba(232,70,108,0.04)}
.radar-line{position:absolute;top:50%;left:50%;width:1px;height:260px;background:linear-gradient(180deg,rgba(232,70,108,0.5),transparent);transform-origin:top;transform:rotate(-30deg);opacity:0.6}
.center-dot{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);width:16px;height:16px;background:#E8466C;border-radius:50%;box-shadow:0 0 24px rgba(232,70,108,0.8)}
.pin{position:absolute;display:flex;flex-direction:column;align-items:center;gap:4px}
.pin-dot{width:48px;height:48px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:20px;box-shadow:0 8px 24px rgba(0,0,0,0.5)}
.pin-label{font-size:10px;font-weight:700;color:#B3B3B3;white-space:nowrap;background:#141414;padding:3px 8px;border-radius:6px;border:1px solid #292929}
.p1{top:calc(50% - 160px);left:calc(50% + 80px)}
.p2{top:calc(50% - 60px);left:calc(50% - 200px)}
.p3{top:calc(50% + 100px);left:calc(50% + 140px)}
.p4{top:calc(50% + 60px);left:calc(50% - 140px)}
.p5{top:calc(50% - 260px);left:calc(50% - 80px)}
.content{position:relative;text-align:center;top:300px}
.tag{font-size:11px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:16px}
.title{font-family:'Poppins',sans-serif;font-size:40px;font-weight:800;letter-spacing:-2px;line-height:1.1;margin-bottom:12px}
.title em{font-style:normal;color:#E8466C}
.sub{font-size:15px;color:#8A8A8A}
"""
    body = f"""
<div class="radar">
  <div class="radar-circle rc1"></div>
  <div class="radar-circle rc2"></div>
  <div class="radar-circle rc3"></div>
  <div class="radar-circle rc4"></div>
  <div class="radar-circle rc5"></div>
  <div class="radar-line"></div>
  <div class="center-dot"></div>
  <div class="pin p1">
    <div class="pin-dot" style="background:#1a0d14;border:2px solid #E8466C">🎸</div>
    <div class="pin-label">Guitarrista · &lt;1km</div>
  </div>
  <div class="pin p2">
    <div class="pin-dot" style="background:#0d0d1a;border:2px solid #C026D3">🥁</div>
    <div class="pin-label">Baterista · &lt;2km</div>
  </div>
  <div class="pin p3">
    <div class="pin-dot" style="background:#0a1a0d;border:2px solid #22C55E">🎹</div>
    <div class="pin-label">Tecladista · &lt;3km</div>
  </div>
  <div class="pin p4">
    <div class="pin-dot" style="background:#1a1a0d;border:2px solid #F59E0B">🎙️</div>
    <div class="pin-label">Cantor · &lt;2km</div>
  </div>
  <div class="pin p5">
    <div class="pin-dot" style="background:#0d1a1a;border:2px solid #3B82F6">🎵</div>
    <div class="pin-label">Banda · &lt;4km</div>
  </div>
</div>
<div class="content">
  <div class="tag">LOCALIZAÇÃO · BUSCA PRÓXIMA</div>
  <h1 class="title">Músicos a <em>&lt;1km</em><br>de você.</h1>
  <p class="sub">Descubra talentos na sua cidade.</p>
</div>
"""
    return wrap(style, body, 11)


# ─────────────────────────────────────────
# ART 12 — COMUNIDADE (avatar constellation)
# ─────────────────────────────────────────
def art12():
    style = """
body{background:#0A0A0A;display:flex;flex-direction:column;align-items:center;justify-content:center;position:relative;overflow:hidden}
.constellation{position:absolute;top:50%;left:50%;transform:translate(-50%,-52%);width:700px;height:700px}
svg.lines{position:absolute;inset:0;width:100%;height:100%}
.avatar{position:absolute;display:flex;flex-direction:column;align-items:center;gap:6px;transform:translate(-50%,-50%)}
.av-circle{border-radius:50%;display:flex;align-items:center;justify-content:center;font-family:'Poppins',sans-serif;font-weight:800;color:#fff;border:2px solid rgba(255,255,255,0.1);box-shadow:0 8px 32px rgba(0,0,0,0.5)}
.av-big{width:72px;height:72px;font-size:20px}
.av-med{width:56px;height:56px;font-size:14px}
.av-sm{width:44px;height:44px;font-size:11px}
.av-label{font-size:10px;font-weight:600;color:#8A8A8A;white-space:nowrap;padding:2px 8px;background:#141414;border-radius:6px;border:1px solid #1F1F1F}
.center-logo{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);width:80px;height:80px;background:#E8466C;border-radius:50%;display:flex;align-items:center;justify-content:center;box-shadow:0 0 40px rgba(232,70,108,0.5),0 16px 32px rgba(0,0,0,0.5)}
.center-logo svg{width:50px;height:50px}
.content{position:relative;text-align:center;bottom:-310px}
.tag{font-size:11px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:14px}
.title{font-family:'Poppins',sans-serif;font-size:36px;font-weight:800;letter-spacing:-1.5px;line-height:1.1;margin-bottom:10px}
.title em{font-style:normal;color:#E8466C}
.sub{font-size:14px;color:#8A8A8A}
"""
    # Avatar positions (x%, y%) relative to 700x700 box
    avatars = [
        # (x, y, initials, color, size, label)
        (350, 100, "HT", "#F472B6", "big", "Músico"),
        (580, 200, "VL", "#A78BFA", "med", "Prod."),
        (620, 420, "KC", "#60A5FA", "big", "Guitarrista"),
        (520, 600, "MN", "#34D399", "med", "Cantor"),
        (280, 650, "RB", "#FBBF24", "big", "Baterista"),
        (100, 520, "AS", "#F87171", "med", "Estúdio"),
        (80, 300, "GM", "#E8466C", "big", "DJ"),
        (180, 140, "PT", "#C026D3", "med", "Banda"),
        (450, 310, "LF", "#22C55E", "sm", "Baixista"),
        (200, 380, "CW", "#3B82F6", "sm", "Técnico"),
    ]
    avs_html = ""
    lines_html = ""
    center = (350, 350)
    for x, y, init, color, size, label in avatars:
        cls = f"av-{size}"
        avs_html += f"""
<div class="avatar" style="left:{x}px;top:{y}px">
  <div class="av-circle {cls}" style="background:{color}22;border-color:{color}44;color:{color}">{init}</div>
  <div class="av-label">{label}</div>
</div>"""
        lines_html += f'<line x1="{center[0]}" y1="{center[1]}" x2="{x}" y2="{y}" stroke="{color}" stroke-width="1" stroke-opacity="0.2"/>'

    body = f"""
<div class="constellation">
  <svg class="lines" xmlns="http://www.w3.org/2000/svg">{lines_html}</svg>
  {avs_html}
  <div class="center-logo">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 750"><path d="M586.09,443.47c0,37.28-30.22,67.5-67.5,67.5-9.54,0-18.61-1.98-26.84-5.55-23.92-10.37-40.66-34.21-40.66-61.95v-241.87c0-4.81-1.97-9.19-5.14-12.36-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,.47-.01.94-.04,1.41v6.23c-.08,37.22-30.27,67.36-67.5,67.36-6.04,0-11.89-.79-17.45-2.28-28.09-7.49-48.96-32.65-50-62.85v-194.24c0-.43-.02-.86-.05-1.28-.31-4.3-2.2-8.19-5.09-11.08-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,13.75-11.25,25-25,25s-25-11.25-25-25v-284.37c.08-37.22,30.27-67.36,67.5-67.36,6.03,0,11.88.79,17.45,2.29,28.09,7.48,48.96,32.64,50,62.84v194.24c0,.43.02.86.05,1.28.31,4.3,2.2,8.19,5.09,11.08,3.17,3.17,7.55,5.14,12.36,5.14,9.62,0,17.5-7.87,17.5-17.5V209.24c0-.47,0-.94.04-1.41v-6.23c.08-37.22,30.27-67.36,67.5-67.36s67.42,30.14,67.5,67.36v176.66c5.58-1.49,11.45-2.29,17.5-2.29,37.28,0,67.5,30.22,67.5,67.5Z" fill="#fff"/></svg>
  </div>
</div>
<div class="content">
  <div class="tag">COMUNIDADE · REDE MUSICAL</div>
  <h1 class="title">Faça parte da maior<br>rede musical do <em>Brasil.</em></h1>
  <p class="sub">Artistas, bandas, estúdios e contratantes conectados.</p>
</div>
"""
    return wrap(style, body, 12)


# ─────────────────────────────────────────
# RENDER
# ─────────────────────────────────────────
ARTS = [
    ("01_manifesto",          art1),
    ("02_quatro_perfis",      art2),
    ("03_matchpoint",         art3),
    ("04_busca_inteligente",  art4),
    ("05_chat",               art5),
    ("06_galeria",            art6),
    ("07_perfil_destaque",    art7),
    ("08_em_numeros",         art8),
    ("09_download_cta",       art9),
    ("10_para_musicos",       art10),
    ("11_localizacao",        art11),
    ("12_comunidade",         art12),
]


async def render_all():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page(viewport={"width": 1080, "height": 1080})

        for slug, fn in ARTS:
            print(f"🎨 Renderizando {slug}...")
            html = fn()
            # Write to temp file for file:// access (allows external fonts)
            tmp = OUT / f"_tmp_{slug}.html"
            tmp.write_text(html, encoding="utf-8")
            await page.goto(f"file:///{tmp.as_posix()}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)  # wait for fonts
            out_path = OUT / f"{slug}.png"
            await page.screenshot(path=str(out_path), clip={"x": 0, "y": 0, "width": 1080, "height": 1080})
            tmp.unlink()
            print(f"   ✓ Salvo: {out_path.name}")

        await browser.close()
        print(f"\n✅ {len(ARTS)} artes geradas em: {OUT}")


if __name__ == "__main__":
    asyncio.run(render_all())
