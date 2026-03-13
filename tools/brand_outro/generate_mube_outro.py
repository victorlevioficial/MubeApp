from __future__ import annotations

import argparse
import math
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


REPO_ROOT = Path(__file__).resolve().parents[2]
BRAND_PNG_DIR = REPO_ROOT / "assets" / "images" / "logos_png"
OUTPUT_DIR = REPO_ROOT / "build" / "brand_outro"
FRAMES_DIR = OUTPUT_DIR / "frames"
FFMPEG_CANDIDATES = [
    shutil.which("ffmpeg"),
    Path(
        r"C:\Users\Victor\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.0.1-full_build\bin\ffmpeg.exe"
    ),
]

WIDTH = 1080
HEIGHT = 1920
FPS = 30
DURATION_SECONDS = 4.2
FRAME_COUNT = int(FPS * DURATION_SECONDS)

BG_COLOR = (10, 10, 10, 255)
BG_SOFT = (20, 20, 20, 255)
PRIMARY = (232, 70, 108, 255)
PRIMARY_DEEP = (209, 63, 97, 255)
WHITE = (255, 255, 255, 255)


@dataclass(frozen=True)
class RenderTargets:
    video: Path
    poster: Path


def clamp(value: float, minimum: float = 0.0, maximum: float = 1.0) -> float:
    return max(minimum, min(maximum, value))


def lerp(start: float, end: float, progress: float) -> float:
    return start + (end - start) * progress


def ease_out_cubic(value: float) -> float:
    return 1 - (1 - value) ** 3


def ease_in_out_cubic(value: float) -> float:
    if value < 0.5:
        return 4 * value * value * value
    return 1 - ((-2 * value + 2) ** 3) / 2


def ease_out_back(value: float) -> float:
    c1 = 1.70158
    c3 = c1 + 1
    return 1 + c3 * (value - 1) ** 3 + c1 * (value - 1) ** 2


def segment_progress(
    t: float,
    start: float,
    end: float,
    easing=ease_in_out_cubic,
) -> float:
    if end <= start:
        raise ValueError("end must be greater than start")
    raw = clamp((t - start) / (end - start))
    return easing(raw)


def load_png_asset(asset_path: Path) -> Image.Image:
    return Image.open(asset_path).convert("RGBA")


def extract_wordmark(horizontal_logo: Image.Image) -> Image.Image:
    # The horizontal PNG includes the icon on the left. Crop the transparent
    # padding and keep only the wordmark area.
    candidate = horizontal_logo.crop((800, 0, horizontal_logo.width, horizontal_logo.height))
    bbox = candidate.getbbox()
    if bbox is None:
        raise ValueError("Unable to extract wordmark from horizontal logo asset")
    return candidate.crop(bbox)


def pad_image(image: Image.Image, padding: int) -> Image.Image:
    padded = Image.new(
        "RGBA",
        (image.width + padding * 2, image.height + padding * 2),
        (0, 0, 0, 0),
    )
    padded.alpha_composite(image, (padding, padding))
    return padded


def alpha_scale(image: Image.Image, factor: float) -> Image.Image:
    scaled = image.copy()
    alpha = scaled.getchannel("A").point(lambda value: int(value * clamp(factor)))
    scaled.putalpha(alpha)
    return scaled


def place_center(image: Image.Image, item: Image.Image, center_x: float, top_y: float) -> None:
    x = int(round(center_x - item.width / 2))
    y = int(round(top_y))
    image.alpha_composite(item, (x, y))


def draw_glow_blob(
    base: Image.Image,
    center_x: float,
    center_y: float,
    radius_x: float,
    radius_y: float,
    color: tuple[int, int, int, int],
    blur_radius: int,
) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    box = (
        int(center_x - radius_x),
        int(center_y - radius_y),
        int(center_x + radius_x),
        int(center_y + radius_y),
    )
    draw.ellipse(box, fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(blur_radius))
    base.alpha_composite(layer)


def build_background(t: float) -> Image.Image:
    base = Image.new("RGBA", (WIDTH, HEIGHT), BG_COLOR)

    draw_glow_blob(
        base,
        center_x=lerp(250, 340, (math.sin(t * 0.8) + 1) / 2),
        center_y=lerp(360, 520, (math.cos(t * 0.5 + 0.6) + 1) / 2),
        radius_x=320,
        radius_y=300,
        color=(232, 70, 108, 52),
        blur_radius=150,
    )
    draw_glow_blob(
        base,
        center_x=lerp(780, 880, (math.sin(t * 0.65 + 1.1) + 1) / 2),
        center_y=lerp(1180, 1480, (math.cos(t * 0.75 + 0.1) + 1) / 2),
        radius_x=420,
        radius_y=340,
        color=(232, 70, 108, 34),
        blur_radius=180,
    )
    draw_glow_blob(
        base,
        center_x=WIDTH / 2,
        center_y=900 + math.sin(t * 1.2) * 32,
        radius_x=280,
        radius_y=280,
        color=(255, 255, 255, 22),
        blur_radius=220,
    )

    vignette_mask = Image.new("L", (WIDTH, HEIGHT), 160)
    vignette_draw = ImageDraw.Draw(vignette_mask)
    vignette_draw.ellipse((90, 180, WIDTH - 90, HEIGHT - 160), fill=0)
    vignette_mask = vignette_mask.filter(ImageFilter.GaussianBlur(120))
    vignette = Image.new("RGBA", (WIDTH, HEIGHT), BG_SOFT)
    vignette.putalpha(vignette_mask)
    base.alpha_composite(vignette)

    line_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    line_draw = ImageDraw.Draw(line_layer)
    for x in (170, WIDTH - 170):
        line_draw.rounded_rectangle(
            (x, 220, x + 2, HEIGHT - 220),
            radius=1,
            fill=(255, 255, 255, 18),
        )
    line_layer = line_layer.filter(ImageFilter.GaussianBlur(2))
    base.alpha_composite(line_layer)

    return base


def make_shadow_mask(alpha: Image.Image, blur: int, intensity: float) -> Image.Image:
    mask = alpha.filter(ImageFilter.GaussianBlur(blur))
    return mask.point(lambda value: int(value * clamp(intensity)))


def add_sheen(frame: Image.Image, mask: Image.Image, progress: float) -> None:
    if progress <= 0 or progress >= 1:
        return

    band = Image.new("L", (WIDTH, HEIGHT), 0)
    draw = ImageDraw.Draw(band)
    center_x = lerp(-320, WIDTH + 320, progress)
    polygon = [
        (center_x - 220, 0),
        (center_x - 30, 0),
        (center_x + 220, HEIGHT),
        (center_x + 30, HEIGHT),
    ]
    draw.polygon(polygon, fill=255)
    band = band.filter(ImageFilter.GaussianBlur(48))
    band = ImageChops.multiply(band, mask)

    strength = 0.45 * math.sin(math.pi * progress)
    band = band.point(lambda value: int(value * strength))

    sheen = Image.new("RGBA", (WIDTH, HEIGHT), WHITE)
    sheen.putalpha(band)
    frame.alpha_composite(sheen)


def render_frame(
    t: float,
    icon_asset: Image.Image,
    wordmark_asset: Image.Image,
) -> Image.Image:
    frame = build_background(t)

    center_x = WIDTH / 2
    icon_center_y = 830 + math.sin(t * 1.3) * 6
    icon_entry = segment_progress(t, 0.08, 0.95, easing=ease_out_back)
    icon_fade = segment_progress(t, 0.0, 0.42, easing=ease_out_cubic)
    icon_scale = lerp(0.58, 1.0, icon_entry)
    icon_y = lerp(icon_center_y + 80, icon_center_y, ease_out_cubic(clamp(t / 0.9)))

    icon_width = int(round(332 * icon_scale))
    icon = icon_asset.resize((icon_width, icon_width), Image.Resampling.LANCZOS)
    icon = alpha_scale(icon, icon_fade)
    icon_x = int(round(center_x - icon.width / 2))
    icon_top = int(round(icon_y))

    wordmark_entry = segment_progress(t, 0.95, 1.65)
    wordmark_fade = segment_progress(t, 0.95, 1.55)
    wordmark_scale = lerp(0.92, 1.0, wordmark_entry)
    wordmark_width = int(round(520 * wordmark_scale))
    wordmark_height = int(round(wordmark_width * wordmark_asset.height / wordmark_asset.width))
    wordmark = wordmark_asset.resize((wordmark_width, wordmark_height), Image.Resampling.LANCZOS)
    wordmark = alpha_scale(wordmark, wordmark_fade)
    wordmark_y = lerp(1075, 1038, wordmark_entry) + math.sin(t * 1.4 + 0.8) * 4
    wordmark_x = int(round(center_x - wordmark.width / 2))

    logo_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))

    draw_glow_blob(
        frame,
        center_x=center_x,
        center_y=icon_center_y + 8,
        radius_x=150 * icon_scale,
        radius_y=150 * icon_scale,
        color=(232, 70, 108, int(80 * icon_fade)),
        blur_radius=80,
    )

    ring_progress = segment_progress(t, 0.05, 0.95, easing=ease_out_cubic)
    ring_alpha = int(round(150 * (1 - ring_progress)))
    if ring_alpha > 0:
        ring_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
        ring_draw = ImageDraw.Draw(ring_layer)
        ring_radius = lerp(180, 265, ring_progress)
        ring_box = (
            center_x - ring_radius,
            icon_center_y - ring_radius,
            center_x + ring_radius,
            icon_center_y + ring_radius,
        )
        ring_draw.ellipse(ring_box, outline=(232, 70, 108, ring_alpha), width=6)
        ring_layer = ring_layer.filter(ImageFilter.GaussianBlur(8))
        frame.alpha_composite(ring_layer)

    logo_layer.alpha_composite(icon, (icon_x, icon_top))

    wordmark_shadow_mask = make_shadow_mask(wordmark.getchannel("A"), blur=24, intensity=0.18)
    wordmark_shadow = Image.new("RGBA", (wordmark.width, wordmark.height), PRIMARY_DEEP)
    wordmark_shadow.putalpha(wordmark_shadow_mask)
    place_center(logo_layer, wordmark_shadow, center_x, wordmark_y + 8)
    logo_layer.alpha_composite(wordmark, (wordmark_x, int(round(wordmark_y))))

    logo_alpha = logo_layer.getchannel("A")
    frame.alpha_composite(logo_layer)
    add_sheen(frame, logo_alpha, segment_progress(t, 1.55, 2.35))

    bottom_fade = clamp((t - 3.82) / 0.38)
    if bottom_fade > 0:
        fade_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, int(round(255 * bottom_fade))))
        frame.alpha_composite(fade_layer)

    return frame


def ensure_directories() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    if FRAMES_DIR.exists():
        shutil.rmtree(FRAMES_DIR)
    FRAMES_DIR.mkdir(parents=True, exist_ok=True)


def encode_video(targets: RenderTargets) -> None:
    ffmpeg_path = None
    for candidate in FFMPEG_CANDIDATES:
        if candidate and Path(candidate).exists():
            ffmpeg_path = str(candidate)
            break

    if ffmpeg_path is None:
        raise FileNotFoundError("Unable to locate ffmpeg.exe")

    subprocess.run(
        [
            ffmpeg_path,
            "-y",
            "-framerate",
            str(FPS),
            "-i",
            str(FRAMES_DIR / "frame_%04d.png"),
            "-c:v",
            "libx264",
            "-pix_fmt",
            "yuv420p",
            "-profile:v",
            "high",
            "-crf",
            "16",
            str(targets.video),
        ],
        check=True,
    )


def render_video(keep_frames: bool) -> RenderTargets:
    ensure_directories()

    icon_asset = pad_image(load_png_asset(BRAND_PNG_DIR / "Mube_logo_logo_icone-11.png"), padding=120)
    wordmark_asset = extract_wordmark(load_png_asset(BRAND_PNG_DIR / "logo_horizontal.png"))

    poster_frame = None
    for frame_index in range(FRAME_COUNT):
        t = frame_index / FPS
        frame = render_frame(t, icon_asset, wordmark_asset)
        frame.save(FRAMES_DIR / f"frame_{frame_index:04d}.png", optimize=True)

        if frame_index == int(FPS * 2.6):
            poster_frame = frame.copy()

        if frame_index % 15 == 0:
            print(f"Rendered frame {frame_index + 1}/{FRAME_COUNT}")

    if poster_frame is None:
        poster_frame = frame.copy()

    targets = RenderTargets(
        video=OUTPUT_DIR / "mube_brand_outro_vertical.mp4",
        poster=OUTPUT_DIR / "mube_brand_outro_poster.png",
    )
    poster_frame.save(targets.poster)
    encode_video(targets)

    if not keep_frames:
        shutil.rmtree(FRAMES_DIR)

    return targets


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate the Mube social video outro.")
    parser.add_argument(
        "--keep-frames",
        action="store_true",
        help="Keep the rendered PNG frames after encoding.",
    )
    args = parser.parse_args()

    targets = render_video(keep_frames=args.keep_frames)
    print(f"Video saved to: {targets.video}")
    print(f"Poster saved to: {targets.poster}")


if __name__ == "__main__":
    main()
