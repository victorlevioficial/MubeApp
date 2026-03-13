#!/usr/bin/env python3
"""Fix arts 06, 08, 11, 12"""
import asyncio, base64
from pathlib import Path
from playwright.async_api import async_playwright

BASE = Path(__file__).parent.parent
ASSETS = BASE / "assets" / "images"
OUT = Path(__file__).parent / "output"

def b64(path):
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")

def img_uri(path):
    return f"data:image/png;base64,{b64(path)}"

SS = {i: img_uri(ASSETS / "screenshots" / f"ss{i}.png") for i in range(1, 8)
      if (ASSETS / "screenshots" / f"ss{i}.png").exists()}

ICON_PATH = """M586.09,443.47c0,37.28-30.22,67.5-67.5,67.5-9.54,0-18.61-1.98-26.84-5.55-23.92-10.37-40.66-34.21-40.66-61.95v-241.87c0-4.81-1.97-9.19-5.14-12.36-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,.47-.01.94-.04,1.41v6.23c-.08,37.22-30.27,67.36-67.5,67.36-6.04,0-11.89-.79-17.45-2.28-28.09-7.49-48.96-32.65-50-62.85v-194.24c0-.43-.02-.86-.05-1.28-.31-4.3-2.2-8.19-5.09-11.08-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,13.75-11.25,25-25,25s-25-11.25-25-25v-284.37c.08-37.22,30.27-67.36,67.5-67.36,6.03,0,11.88.79,17.45,2.29,28.09,7.48,48.96,32.64,50,62.84v194.24c0,.43.02.86.05,1.28.31,4.3,2.2,8.19,5.09,11.08,3.17,3.17,7.55,5.14,12.36,5.14,9.62,0,17.5-7.87,17.5-17.5V209.24c0-.47,0-.94.04-1.41v-6.23c.08-37.22,30.27-67.36,67.5-67.36s67.42,30.14,67.5,67.36v176.66c5.58-1.49,11.45-2.29,17.5-2.29,37.28,0,67.5,30.22,67.5,67.5Z"""

ICON_SVG = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 750"><circle cx="375" cy="375" r="375" fill="#e8466c"/><path d="{ICON_PATH}" fill="#fff"/></svg>'

COMMON = """
@import url('https://fonts.googleapis.com/css2?family=Poppins:ital,wght@0,400;0,500;0,600;0,700;0,800;0,900;1,700;1,800;1,900&family=Inter:wght@400;500;600;700;800&display=swap');
*,*::before,*::after{margin:0;padding:0;box-sizing:border-box}
html,body{width:1080px;height:1080px;overflow:hidden;font-family:'Inter',sans-serif;color:#fff;-webkit-font-smoothing:antialiased}
"""

def wrap(style, body, num):
    return f"""<!DOCTYPE html><html><head><meta charset="UTF-8">
<style>{COMMON}{style}</style></head><body>{body}</body></html>"""


# ─────────────────────────────────────────
# ART 06 FIXED — GALERIA (layout reformulado)
# Full-bleed collage with strong typography overlay
# ─────────────────────────────────────────
def art6_fixed():
    ss6 = SS.get(6, "")
    ss4 = SS.get(4, "")
    style = f"""
body{{background:#0A0A0A;position:relative;overflow:hidden}}
.grid{{display:grid;grid-template-columns:55% 1fr 1fr;grid-template-rows:60% 1fr;gap:8px;width:100%;height:100%;position:absolute;inset:0}}
.cell{{overflow:hidden;position:relative}}
.cell img{{width:100%;height:100%;object-fit:cover}}
.cell.c1{{grid-column:1;grid-row:1/3}}
.cell.c2{{grid-column:2;grid-row:1}}
.cell.c3{{grid-column:3;grid-row:1}}
.cell.c4{{grid-column:2;grid-row:2;background:linear-gradient(135deg,#1a0810 0%,#2d1220 100%);display:flex;align-items:center;justify-content:center;font-size:52px}}
.cell.c5{{grid-column:3;grid-row:2;background:linear-gradient(135deg,#0a0d1a 0%,#141a30 100%);display:flex;align-items:center;justify-content:center;font-size:52px}}
.overlay{{position:absolute;inset:0;background:linear-gradient(135deg,rgba(10,10,10,0.92) 0%,rgba(10,10,10,0.6) 60%,rgba(10,10,10,0.3) 100%);z-index:2}}
.content{{position:absolute;inset:0;z-index:3;display:flex;flex-direction:column;justify-content:flex-end;padding:72px 80px}}
.tag{{font-size:11px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:20px}}
.title{{font-family:'Poppins',sans-serif;font-size:72px;font-weight:900;line-height:.9;letter-spacing:-3px;margin-bottom:24px}}
.title span{{display:block}}
.title em{{font-style:italic;color:#E8466C}}
.desc{{font-size:16px;color:rgba(255,255,255,0.7);line-height:1.6;max-width:480px;margin-bottom:40px}}
.bottom-row{{display:flex;align-items:center;justify-content:space-between}}
.features{{display:flex;gap:24px}}
.feat{{display:flex;align-items:center;gap:8px;font-size:13px;color:rgba(255,255,255,0.5)}}
.feat-dot{{width:6px;height:6px;border-radius:50%;background:#E8466C}}
.logo-sm{{display:flex;align-items:center;gap:10px}}
.logo-sm svg{{width:32px;height:32px}}
.logo-sm span{{font-family:'Poppins',sans-serif;font-weight:700;font-size:18px}}
"""
    body = f"""
<div class="grid">
  <div class="cell c1"><img src="{ss6}" alt="" style="object-position:left 25%"/></div>
  <div class="cell c2"><img src="{ss4}" alt="" style="object-position:center 10%"/></div>
  <div class="cell c3"><img src="{ss6}" alt="" style="object-position:right 60%"/></div>
  <div class="cell c4">🎸</div>
  <div class="cell c5">🎙️</div>
</div>
<div class="overlay"></div>
<div class="content">
  <div class="tag">GALERIA · PORTFÓLIO MUSICAL</div>
  <h1 class="title">
    <span>Seu portfólio.</span>
    <span>Sua <em>história.</em></span>
  </h1>
  <p class="desc">Fotos, vídeos e links integrados ao seu perfil.<br>Mostre seu trabalho para quem importa.</p>
  <div class="bottom-row">
    <div class="features">
      <div class="feat"><div class="feat-dot"></div> Fotos & Vídeos</div>
      <div class="feat"><div class="feat-dot"></div> Links externos</div>
      <div class="feat"><div class="feat-dot"></div> Grátis</div>
    </div>
    <div class="logo-sm">
      {ICON_SVG}
      <span>mube</span>
    </div>
  </div>
</div>
"""
    return wrap(style, body, 6)


# ─────────────────────────────────────────
# ART 08 FIXED — EM NÚMEROS (layout bold melhorado)
# ─────────────────────────────────────────
def art8_fixed():
    style = """
body{background:#0A0A0A;display:flex;flex-direction:column;justify-content:center;padding:80px;position:relative;overflow:hidden}
.bg-accent{position:absolute;bottom:-200px;right:-200px;width:600px;height:600px;background:radial-gradient(circle,rgba(232,70,108,0.08) 0%,transparent 70%);border-radius:50%}
.tag{font-size:11px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:56px}
.stat{display:flex;align-items:flex-start;margin-bottom:8px;position:relative}
.num{font-family:'Poppins',sans-serif;font-weight:900;color:#fff;line-height:.85;letter-spacing:-4px}
.num.n4{font-size:220px}
.num.n1{font-size:220px}
.num.ninf{font-size:160px}
.unit{font-family:'Poppins',sans-serif;font-size:40px;font-weight:700;color:#E8466C;margin-top:32px;margin-left:16px}
.label-block{position:absolute;right:0;bottom:0;text-align:right}
.label-title{font-family:'Poppins',sans-serif;font-size:18px;font-weight:700;color:#fff;margin-bottom:4px}
.label-sub{font-size:13px;color:#8A8A8A;line-height:1.4}
.divider{width:100%;height:1px;background:#1F1F1F;margin:8px 0 16px}
.footer{display:flex;align-items:center;justify-content:space-between;margin-top:32px}
.footer-left p{font-family:'Poppins',sans-serif;font-size:26px;font-weight:800;letter-spacing:-0.5px;line-height:1.2}
.footer-left em{font-style:normal;color:#E8466C}
.logo-sm{display:flex;align-items:center;gap:10px}
.logo-sm svg{width:36px;height:36px}
.logo-sm span{font-family:'Poppins',sans-serif;font-weight:700;font-size:20px}
"""
    body = f"""
<div class="bg-accent"></div>
<div class="tag">MUBE · EM NÚMEROS</div>

<div class="stat">
  <div class="num n4">4</div>
  <div class="unit">tipos de perfil</div>
  <div class="label-block">
    <div class="label-title">Músico · Banda</div>
    <div class="label-sub">Estúdio · Contratante</div>
  </div>
</div>
<div class="divider"></div>

<div class="stat">
  <div class="num n1">1</div>
  <div class="unit">plataforma</div>
  <div class="label-block">
    <div class="label-title">Tudo em um só lugar</div>
    <div class="label-sub">Grátis · iOS & Android</div>
  </div>
</div>
<div class="divider"></div>

<div class="stat">
  <div class="num ninf">∞</div>
  <div style="margin-top:16px;margin-left:16px">
    <div class="unit" style="font-size:32px">conexões</div>
    <div style="font-size:13px;color:#8A8A8A;margin-top:8px">possibilidades · colaborações</div>
  </div>
</div>

<div class="footer">
  <div class="footer-left">
    <p>Uma plataforma.<br><em>Infinitas possibilidades.</em></p>
  </div>
  <div class="logo-sm">
    {ICON_SVG}
    <span>mube</span>
  </div>
</div>
"""
    return wrap(style, body, 8)


# ─────────────────────────────────────────
# ART 11 FIXED — LOCALIZAÇÃO (radar mais central e visível)
# ─────────────────────────────────────────
def art11_fixed():
    style = """
body{background:#0A0A0A;display:flex;flex-direction:column;overflow:hidden;position:relative}
.radar-area{flex:1;position:relative;display:flex;align-items:center;justify-content:center}
.rc{position:absolute;border-radius:50%;top:50%;left:50%;transform:translate(-50%,-50%)}
.rc1{width:180px;height:180px;border:1.5px solid rgba(232,70,108,0.5)}
.rc2{width:320px;height:320px;border:1px solid rgba(232,70,108,0.25)}
.rc3{width:460px;height:460px;border:1px solid rgba(232,70,108,0.14)}
.rc4{width:620px;height:620px;border:1px solid rgba(232,70,108,0.07)}
.sweep{position:absolute;top:50%;left:50%;width:310px;height:1px;background:linear-gradient(90deg,rgba(232,70,108,0.7),transparent);transform-origin:left center;transform:rotate(-40deg);opacity:0.8}
.center{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);width:20px;height:20px;background:#E8466C;border-radius:50%;box-shadow:0 0 20px rgba(232,70,108,1),0 0 40px rgba(232,70,108,0.5)}
.pin{position:absolute;display:flex;flex-direction:column;align-items:center;gap:5px;transform:translate(-50%,-50%)}
.pin-dot{width:52px;height:52px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:22px;border:2px solid transparent}
.pin-lbl{font-size:10px;font-weight:700;color:#B3B3B3;white-space:nowrap;background:#141414;border:1px solid #292929;padding:3px 10px;border-radius:8px}
.text-area{padding:56px 80px;text-align:center;flex-shrink:0}
.tag{font-size:11px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:16px}
.title{font-family:'Poppins',sans-serif;font-size:52px;font-weight:900;letter-spacing:-2.5px;line-height:.95;margin-bottom:12px}
.title em{font-style:normal;color:#E8466C}
.sub{font-size:15px;color:#8A8A8A}
"""
    # Pin positions relative to radar center (at 540, ~370)
    pins = [
        # (offset_x, offset_y, emoji, color, label)
        (0,   -240, "🎸", "#E8466C", "Guitarrista · <1km"),
        (210, -120, "🥁", "#C026D3", "Baterista · <2km"),
        (230,  120, "🎹", "#22C55E", "Tecladista · <3km"),
        (-210, 120, "🎙️", "#F59E0B", "Cantor · <2km"),
        (-220, -110, "🎵", "#3B82F6", "Banda · <4km"),
    ]
    pins_html = ""
    lines_html = ""
    CX, CY = 540, 370
    for dx, dy, emoji, color, label in pins:
        x, y = CX + dx, CY + dy
        pins_html += f"""<div class="pin" style="left:{x}px;top:{y}px">
  <div class="pin-dot" style="background:{color}18;border-color:{color}60">{emoji}</div>
  <div class="pin-lbl">{label}</div>
</div>"""
        lines_html += f'<line x1="{CX}" y1="{CY}" x2="{x}" y2="{y}" stroke="{color}" stroke-width="1" stroke-opacity="0.25"/>'

    body = f"""
<div class="radar-area">
  <svg style="position:absolute;inset:0;width:100%;height:100%" xmlns="http://www.w3.org/2000/svg">{lines_html}</svg>
  <div class="rc rc1"></div>
  <div class="rc rc2"></div>
  <div class="rc rc3"></div>
  <div class="rc rc4"></div>
  <div class="sweep"></div>
  <div class="center"></div>
  {pins_html}
</div>
<div class="text-area">
  <div class="tag">LOCALIZAÇÃO · BUSCA PRÓXIMA</div>
  <h1 class="title">Músicos a <em>&lt;1km</em><br>de você.</h1>
  <p class="sub">Descubra talentos na sua cidade e bairro.</p>
</div>
"""
    return wrap(style, body, 11)


# ─────────────────────────────────────────
# ART 12 FIXED — COMUNIDADE (avatares bem espaçados)
# ─────────────────────────────────────────
def art12_fixed():
    style = """
body{background:#0A0A0A;display:flex;flex-direction:column;align-items:center;overflow:hidden;position:relative}
.star-area{flex:1;width:100%;position:relative}
.star-area svg.lines{position:absolute;inset:0;width:100%;height:100%}
.av{position:absolute;display:flex;flex-direction:column;align-items:center;gap:6px;transform:translate(-50%,-50%)}
.av-c{border-radius:50%;display:flex;align-items:center;justify-content:center;font-family:'Poppins',sans-serif;font-weight:800;color:#fff;box-shadow:0 8px 32px rgba(0,0,0,0.6)}
.lbl{font-size:10px;font-weight:600;color:#8A8A8A;background:#141414;border:1px solid #1F1F1F;padding:3px 8px;border-radius:6px;white-space:nowrap}
.center-logo{position:absolute;width:72px;height:72px;background:#E8466C;border-radius:50%;display:flex;align-items:center;justify-content:center;box-shadow:0 0 48px rgba(232,70,108,0.5);transform:translate(-50%,-50%)}
.text-area{padding:0 80px 64px;text-align:center;flex-shrink:0;width:100%}
.tag{font-size:11px;font-weight:700;letter-spacing:5px;text-transform:uppercase;color:#E8466C;margin-bottom:16px}
.title{font-family:'Poppins',sans-serif;font-size:46px;font-weight:900;letter-spacing:-2px;line-height:1;margin-bottom:12px}
.title em{font-style:normal;color:#E8466C}
.sub{font-size:15px;color:#8A8A8A}
"""
    # Avatars centered around (540, 390) within 780px tall area
    CX, CY = 540, 390
    avatars = [
        # (offset_x, offset_y, initials, color, size, label)
        (0,    -290, "HT", "#F472B6", 68, "Músico"),
        (240,  -180, "VL", "#A78BFA", 52, "Produtor"),
        (290,   50,  "KC", "#60A5FA", 68, "Guitarrista"),
        (160,  230,  "MN", "#34D399", 52, "Cantor"),
        (-160, 240,  "RB", "#FBBF24", 68, "Baterista"),
        (-290,  60,  "AS", "#F87171", 52, "Estúdio"),
        (-290, -160, "GM", "#E8466C", 68, "DJ"),
        (-140, -280, "PT", "#C026D3", 52, "Banda"),
        (100,  -120, "LF", "#22C55E", 44, "Baixista"),
        (-80,   80,  "CW", "#3B82F6", 44, "Técnico"),
    ]
    avs_html = ""
    lines_html = ""
    for dx, dy, init, color, sz, label in avatars:
        x, y = CX + dx, CY + dy
        font_sz = int(sz * 0.28)
        avs_html += f"""<div class="av" style="left:{x}px;top:{y}px">
  <div class="av-c" style="width:{sz}px;height:{sz}px;font-size:{font_sz}px;background:{color}20;border:2px solid {color}50;color:{color}">{init}</div>
  <div class="lbl">{label}</div>
</div>"""
        lines_html += f'<line x1="{CX}" y1="{CY}" x2="{x}" y2="{y}" stroke="{color}" stroke-width="1" stroke-opacity="0.2"/>'

    icon_path = "M586.09,443.47c0,37.28-30.22,67.5-67.5,67.5-9.54,0-18.61-1.98-26.84-5.55-23.92-10.37-40.66-34.21-40.66-61.95v-241.87c0-4.81-1.97-9.19-5.14-12.36-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,.47-.01.94-.04,1.41v6.23c-.08,37.22-30.27,67.36-67.5,67.36-6.04,0-11.89-.79-17.45-2.28-28.09-7.49-48.96-32.65-50-62.85v-194.24c0-.43-.02-.86-.05-1.28-.31-4.3-2.2-8.19-5.09-11.08-3.17-3.17-7.55-5.14-12.36-5.14-9.62,0-17.5,7.87-17.5,17.5v284.37c0,13.75-11.25,25-25,25s-25-11.25-25-25v-284.37c.08-37.22,30.27-67.36,67.5-67.36,6.03,0,11.88.79,17.45,2.29,28.09,7.48,48.96,32.64,50,62.84v194.24c0,.43.02.86.05,1.28.31,4.3,2.2,8.19,5.09,11.08,3.17,3.17,7.55,5.14,12.36,5.14,9.62,0,17.5-7.87,17.5-17.5V209.24c0-.47,0-.94.04-1.41v-6.23c.08-37.22,30.27-67.36,67.5-67.36s67.42,30.14,67.5,67.36v176.66c5.58-1.49,11.45-2.29,17.5-2.29,37.28,0,67.5,30.22,67.5,67.5Z"

    body = f"""
<div class="star-area">
  <svg class="lines" xmlns="http://www.w3.org/2000/svg">{lines_html}</svg>
  {avs_html}
  <div class="center-logo" style="left:{CX}px;top:{CY}px">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 750" style="width:44px;height:44px"><path d="{icon_path}" fill="#fff"/></svg>
  </div>
</div>
<div class="text-area">
  <div class="tag">COMUNIDADE · REDE MUSICAL</div>
  <h1 class="title">Faça parte da maior<br>rede musical do <em>Brasil.</em></h1>
  <p class="sub">Músicos, bandas, estúdios e contratantes conectados.</p>
</div>
"""
    return wrap(style, body, 12)


FIXES = [
    ("06_galeria",     art6_fixed),
    ("08_em_numeros",  art8_fixed),
    ("11_localizacao", art11_fixed),
    ("12_comunidade",  art12_fixed),
]

async def render():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page(viewport={"width": 1080, "height": 1080})
        for slug, fn in FIXES:
            print(f"🔧 Corrigindo {slug}...")
            html = fn()
            tmp = OUT / f"_tmp_{slug}.html"
            tmp.write_text(html, encoding="utf-8")
            await page.goto(f"file:///{tmp.as_posix()}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)
            out_path = OUT / f"{slug}.png"
            await page.screenshot(path=str(out_path), clip={"x":0,"y":0,"width":1080,"height":1080})
            tmp.unlink()
            print(f"   ✓ {out_path.name}")
        await browser.close()
        print(f"\n✅ Correções aplicadas!")

if __name__ == "__main__":
    asyncio.run(render())
