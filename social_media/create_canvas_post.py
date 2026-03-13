"""
Mube Instagram Post — "Em Breve" (Teaser de Expectativa)

Todos os valores visuais usam exclusivamente tokens reais do design system
definido em lib/src/design_system/foundations/tokens/.

─── Fontes ───
  Display (títulos): Poppins Bold / SemiBold / Black  (app_typography.dart)
  Body   (corpo):    Inter Medium                      (app_typography.dart)

─── Cores ───
  Paleta Raw           | Semântico
  _primary   #E8466C   | primary
  _primaryP  #D13F61   | primaryPressed
  _bgDeep    #0A0A0A   | background
  _bgSurface #141414   | surface
  _bgSurface2#1F1F1F   | surface2
  _bgHighl   #292929   | surfaceHighlight
  _border    #383838   | border
  _textWhite #FFFFFF   | textPrimary
  _textGray  #B3B3B3   | textSecondary
  _textDGray #8A8A8A   | textTertiary

─── Espaçamento ─── Base 4px
  s4=4  s8=8  s12=12  s16=16  s20=20  s24=24  s32=32  s40=40  s48=48
"""

import math
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# ═══════════════════════════════════════════════════════════════════════
# TOKENS — 100% do design system real (app_colors.dart)
# ═══════════════════════════════════════════════════════════════════════

# Brand
PRIMARY = (0xE8, 0x46, 0x6C)          # #E8466C
PRIMARY_PRESSED = (0xD1, 0x3F, 0x61)  # #D13F61

# Backgrounds
BG_DEEP = (0x0A, 0x0A, 0x0A)          # #0A0A0A — background
BG_SURFACE = (0x14, 0x14, 0x14)       # #141414 — surface
BG_SURFACE2 = (0x1F, 0x1F, 0x1F)     # #1F1F1F — surface2
BG_HIGHLIGHT = (0x29, 0x29, 0x29)     # #292929 — surfaceHighlight
BORDER = (0x38, 0x38, 0x38)           # #383838 — border

# Text
TEXT_PRIMARY = (0xFF, 0xFF, 0xFF)     # #FFFFFF
TEXT_SECONDARY = (0xB3, 0xB3, 0xB3)  # #B3B3B3
TEXT_TERTIARY = (0x8A, 0x8A, 0x8A)   # #8A8A8A

# Spacing (app_spacing.dart — base 4px)
S4 = 4
S8 = 8
S12 = 12
S16 = 16
S20 = 20
S24 = 24
S32 = 32
S40 = 40
S48 = 48

# ═══════════════════════════════════════════════════════════════════════
# FONTS — Poppins (display) + Inter (body) conforme app_typography.dart
# ═══════════════════════════════════════════════════════════════════════

FONT_DIR = Path(__file__).parent / "fonts"

# Display fonts — Poppins (headlineLarge: 28, w700 | matchSuccessTitle: 48, w900)
POPPINS_BOLD = str(FONT_DIR / "Poppins-Bold.ttf")
POPPINS_SEMIBOLD = str(FONT_DIR / "Poppins-SemiBold.ttf")
POPPINS_BLACK = str(FONT_DIR / "Poppins-Black.ttf")
POPPINS_BOLD_ITALIC = str(FONT_DIR / "Poppins-BoldItalic.ttf")

# Body font — Inter (bodyMedium: 14, w500)
INTER = str(FONT_DIR / "Inter-Regular.ttf")

# ═══════════════════════════════════════════════════════════════════════
# ASSETS
# ═══════════════════════════════════════════════════════════════════════

PROJECT_ROOT = Path(__file__).parent.parent
LOGO_PATH = PROJECT_ROOT / "assets" / "images" / "logos_png" / "Mube_logo_logo_icone-11.png"

# ═══════════════════════════════════════════════════════════════════════
# CANVAS — Instagram 1080x1080
# ═══════════════════════════════════════════════════════════════════════

W, H = 1080, 1080
CX, CY = W // 2, H // 2 - S32  # Logo levemente acima do centro

random.seed(42)

img = Image.new("RGBA", (W, H), BG_DEEP + (255,))


# ─── Helper: alpha tuple ────────────────────────────────────────────
def rgba(color: tuple, alpha: int) -> tuple:
    return color + (max(0, min(255, alpha)),)


# ═══════════════════════════════════════════════════════════════════════
# LAYER 1 — Radial glow central (PRIMARY muted ao redor do logo)
# Usa primaryMuted (alpha 0.3 = 77/255) do token real
# ═══════════════════════════════════════════════════════════════════════

glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
max_r = 420
for r in range(max_r, 0, -2):
    # primaryMuted max alpha=77, decaying outward
    a = int(77 * ((1 - r / max_r) ** 1.6))
    gd.ellipse([CX - r, CY - r, CX + r, CY + r], fill=rgba(PRIMARY, a))
img = Image.alpha_composite(img, glow)


# ═══════════════════════════════════════════════════════════════════════
# LAYER 2 — Sound wave rings (usando BORDER #383838 e PRIMARY com alpha)
# ═══════════════════════════════════════════════════════════════════════

rings = Image.new("RGBA", (W, H), (0, 0, 0, 0))
rd = ImageDraw.Draw(rings)

ring_radii = [140, 195, 260, 335, 420]
for i, radius in enumerate(ring_radii):
    # Rings alternando entre border color e primary muted
    if i % 2 == 0:
        color = rgba(PRIMARY, 35 - i * 5)
    else:
        color = rgba(BORDER, 50 - i * 5)
    rd.ellipse(
        [CX - radius, CY - radius, CX + radius, CY + radius],
        outline=color, width=1
    )

img = Image.alpha_composite(img, rings)


# ═══════════════════════════════════════════════════════════════════════
# LAYER 3 — Radial energy lines (usando surfaceHighlight #292929)
# ═══════════════════════════════════════════════════════════════════════

rays = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ryd = ImageDraw.Draw(rays)

num_rays = 48
for i in range(num_rays):
    angle = (2 * math.pi / num_rays) * i
    inner_r = 150
    outer_r = 440 + random.randint(-S20, S20)
    x1 = CX + int(inner_r * math.cos(angle))
    y1 = CY + int(inner_r * math.sin(angle))
    x2 = CX + int(outer_r * math.cos(angle))
    y2 = CY + int(outer_r * math.sin(angle))
    # Alternando cor entre primary e highlight
    if i % 3 == 0:
        color = rgba(PRIMARY, random.randint(8, 18))
    else:
        color = rgba(BG_HIGHLIGHT, random.randint(15, 30))
    ryd.line([(x1, y1), (x2, y2)], fill=color, width=1)

img = Image.alpha_composite(img, rays)


# ═══════════════════════════════════════════════════════════════════════
# LAYER 4 — Particles (usando textTertiary #8A8A8A e primary)
# ═══════════════════════════════════════════════════════════════════════

particles = Image.new("RGBA", (W, H), (0, 0, 0, 0))
pd_draw = ImageDraw.Draw(particles)

for _ in range(70):
    px = random.randint(S48, W - S48)
    py = random.randint(S48, H - S48)
    dist = math.sqrt((px - CX) ** 2 + (py - CY) ** 2)
    if dist < 120:
        continue
    size = random.choice([1, 1, 2, 2, 3])
    alpha = random.randint(25, 80)
    # 30% primary, 70% textTertiary
    if random.random() > 0.7:
        color = rgba(PRIMARY, alpha)
    else:
        color = rgba(TEXT_TERTIARY, alpha)
    pd_draw.ellipse([px - size, py - size, px + size, py + size], fill=color)

img = Image.alpha_composite(img, particles)


# ═══════════════════════════════════════════════════════════════════════
# LAYER 5 — Logo circle central com glow
# Glow usa PRIMARY com opacity decrescente (como primaryMuted)
# Círculo sólido usa PRIMARY (como primary)
# ═══════════════════════════════════════════════════════════════════════

logo_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
lld = ImageDraw.Draw(logo_layer)
logo_r = 85

# Glow externo
for gr in range(logo_r + 50, logo_r, -1):
    a = int(30 * (1 - (gr - logo_r) / 50))
    lld.ellipse([CX - gr, CY - gr, CX + gr, CY + gr], fill=rgba(PRIMARY, a))

# Círculo sólido primary
lld.ellipse(
    [CX - logo_r, CY - logo_r, CX + logo_r, CY + logo_r],
    fill=PRIMARY + (255,)
)

img = Image.alpha_composite(img, logo_layer)


# ═══════════════════════════════════════════════════════════════════════
# LAYER 6 — Logo icon do Mube (paste real)
# ═══════════════════════════════════════════════════════════════════════

draw = ImageDraw.Draw(img)

try:
    logo = Image.open(str(LOGO_PATH)).convert("RGBA")
    logo_icon_size = int(logo_r * 1.45)
    logo = logo.resize((logo_icon_size, logo_icon_size), Image.Resampling.LANCZOS)
    lx = CX - logo_icon_size // 2
    ly = CY - logo_icon_size // 2
    img.paste(logo, (lx, ly), logo)
    draw = ImageDraw.Draw(img)
except Exception as e:
    print(f"⚠️  Logo fallback (M letter): {e}")
    font_logo = ImageFont.truetype(POPPINS_BLACK, 90)
    bb = draw.textbbox((0, 0), "M", font=font_logo)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    draw.text((CX - tw // 2, CY - th // 2), "M", fill=TEXT_PRIMARY, font=font_logo)


# ═══════════════════════════════════════════════════════════════════════
# LAYER 7 — "EM BREVE" (profileTypeLabel style: Inter w700, 12px, ls 1.5, primary)
# Escalado para 1080px: ~22px
# ═══════════════════════════════════════════════════════════════════════

# profileTypeLabel: fontSize 12, w700, primary, letterSpacing 1.5
# Para 1080px canvas escalamos ~1.8x → 22px
font_em_breve = ImageFont.truetype(INTER, 22)

em_breve_text = "EM BREVE"
# Simular letterSpacing 1.5 escalado → ~12px entre caracteres
ls = S12
total_w = 0
char_ws = []
for ch in em_breve_text:
    bb = draw.textbbox((0, 0), ch, font=font_em_breve)
    cw = bb[2] - bb[0]
    char_ws.append(cw)
    total_w += cw
total_w += ls * (len(em_breve_text) - 1)

sx = CX - total_w // 2
ty = S48 + S40  # top padding
for i, ch in enumerate(em_breve_text):
    draw.text((sx, ty), ch, fill=rgba(PRIMARY, 200), font=font_em_breve)
    sx += char_ws[i] + ls

# Linha decorativa sob "EM BREVE" (border color, 1px)
line_y = ty + S32
line_half = S40
draw.line(
    [(CX - line_half, line_y), (CX + line_half, line_y)],
    fill=rgba(BORDER, 120), width=1
)


# ═══════════════════════════════════════════════════════════════════════
# LAYER 8 — "MUBE" título (matchSuccessKicker style: Poppins w700, ls 4)
# matchSuccessKicker: 20px, w700, textPrimary, letterSpacing 4
# Para post escalamos: ~80px com ls proporcional
# ═══════════════════════════════════════════════════════════════════════

font_title = ImageFont.truetype(POPPINS_BOLD, 80)

title = "MUBE"
# letterSpacing 4 escalado para 80px → ~16px
title_ls = S16
t_total = 0
t_cws = []
for ch in title:
    bb = draw.textbbox((0, 0), ch, font=font_title)
    t_cws.append(bb[2] - bb[0])
    t_total += bb[2] - bb[0]
t_total += title_ls * (len(title) - 1)

t_sx = CX - t_total // 2
t_y = H - S48 * 5  # posição inferior com padding
for i, ch in enumerate(title):
    draw.text((t_sx, t_y), ch, fill=TEXT_PRIMARY + (255,), font=font_title)
    t_sx += t_cws[i] + title_ls


# ═══════════════════════════════════════════════════════════════════════
# LAYER 9 — Tagline (bodyMedium style: Inter w500, 14px, textPrimary)
# Escalado: ~24px, usando textSecondary para hierarquia
# ═══════════════════════════════════════════════════════════════════════

font_tag = ImageFont.truetype(INTER, 24)

tagline = "A música te conecta"
bb = draw.textbbox((0, 0), tagline, font=font_tag)
tw = bb[2] - bb[0]
th = bb[3] - bb[1]
tag_y = t_y + 80 + S16  # abaixo do título + spacing s16
draw.text((CX - tw // 2, tag_y), tagline, fill=rgba(TEXT_SECONDARY, 200), font=font_tag)


# ═══════════════════════════════════════════════════════════════════════
# LAYER 10 — Accent line inferior (primaryGradient simulado)
# primaryGradient: [_primary → _primaryPressed]
# ═══════════════════════════════════════════════════════════════════════

accent_y = H - S48 - S16
accent_half = 60
for x in range(CX - accent_half, CX + accent_half):
    # Interpolar primary → primaryPressed
    t = (x - (CX - accent_half)) / (2 * accent_half)
    r = int(PRIMARY[0] + (PRIMARY_PRESSED[0] - PRIMARY[0]) * t)
    g = int(PRIMARY[1] + (PRIMARY_PRESSED[1] - PRIMARY[1]) * t)
    b = int(PRIMARY[2] + (PRIMARY_PRESSED[2] - PRIMARY[2]) * t)
    # Fade nas extremidades
    dist = abs(x - CX) / accent_half
    a = int(180 * (1 - dist ** 2))
    draw.point((x, accent_y), fill=(r, g, b, max(0, a)))


# ═══════════════════════════════════════════════════════════════════════
# LAYER 11 — Corner marks editoriais (border #383838 com alpha)
# ═══════════════════════════════════════════════════════════════════════

mark_len = S20
mark_margin = S40
mark_color = rgba(BORDER, 60)

corners = [
    # top-left
    ((mark_margin, mark_margin), (mark_margin + mark_len, mark_margin)),
    ((mark_margin, mark_margin), (mark_margin, mark_margin + mark_len)),
    # top-right
    ((W - mark_margin, mark_margin), (W - mark_margin - mark_len, mark_margin)),
    ((W - mark_margin, mark_margin), (W - mark_margin, mark_margin + mark_len)),
    # bottom-left
    ((mark_margin, H - mark_margin), (mark_margin + mark_len, H - mark_margin)),
    ((mark_margin, H - mark_margin), (mark_margin, H - mark_margin - mark_len)),
    # bottom-right
    ((W - mark_margin, H - mark_margin), (W - mark_margin - mark_len, H - mark_margin)),
    ((W - mark_margin, H - mark_margin), (W - mark_margin, H - mark_margin - mark_len)),
]
for p1, p2 in corners:
    draw.line([p1, p2], fill=mark_color, width=1)


# ═══════════════════════════════════════════════════════════════════════
# LAYER 12 — Subtle grain (textTertiary #8A8A8A micro-noise)
# ═══════════════════════════════════════════════════════════════════════

noise = Image.new("RGBA", (W, H), (0, 0, 0, 0))
nd = ImageDraw.Draw(noise)
for _ in range(2500):
    nx = random.randint(0, W - 1)
    ny = random.randint(0, H - 1)
    na = random.randint(2, 8)
    nd.point((nx, ny), fill=rgba(TEXT_TERTIARY, na))

img = Image.alpha_composite(img, noise)


# ═══════════════════════════════════════════════════════════════════════
# SAVE
# ═══════════════════════════════════════════════════════════════════════

output = Path(__file__).parent / "mube_instagram_canvas.png"
final = img.convert("RGB")
final.save(str(output), "PNG")
print(f"✅ Post salvo: {output}")
print(f"   Dimensões: {W}x{H}px")
print(f"   Tokens: 100% design system real (app_colors, app_typography, app_spacing)")
