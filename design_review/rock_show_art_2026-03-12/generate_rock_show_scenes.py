from __future__ import annotations

import os
import sys
import time
from datetime import datetime
from pathlib import Path

from PIL import Image

try:
    from google import genai
    from google.genai import types
except ImportError:
    print("Error: google-genai package not installed.")
    sys.exit(1)


BASE_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = BASE_DIR / "generated"
PROMPTS_FILE = BASE_DIR / "prompts_used.txt"
MASCOT_REF = Path(
    r"C:\Users\Victor\Desktop\AppMube\design_review\mascot_studies_2026-03-12\outputs\20260312_002414_study_11_final_iconic.png"
)
MODEL = "gemini-2.5-flash-image"


PROMPTS = [
    {
        "slug": "option_a_stage_hero",
        "prompt": """
        Use the attached pink ghost mascot as the clear character reference.
        Create a beautiful, playful rock show scene for social media.
        The mascot is on stage as the lead act in a stylized rock concert,
        with dramatic spotlights, speaker stacks, subtle haze, crowd silhouettes with raised hands,
        and a lively but tasteful sense of performance.
        Keep the character cute, friendly, and recognizable.
        Art direction: premium poster illustration, bold composition, playful but not childish,
        dark stage environment with Mube pink as the hero color, energetic concert lighting,
        whimsical rock atmosphere, high visual impact.
        No text in the image.
        """.strip(),
    },
    {
        "slug": "option_b_stage_wide",
        "prompt": """
        Use the attached pink ghost mascot as the main character reference.
        Create a ludic, beautiful rock concert scene with more world-building:
        big stage, overhead lights, amplifiers, subtle confetti, crowd silhouettes, and a sense of live music.
        The mascot should feel like a charming rock star, but still soft and approachable.
        Style: polished editorial poster illustration, playful modern branding image, strong contrast,
        dark concert palette with pink highlights and warm white lights.
        No text in the image.
        """.strip(),
    },
]


def extract_image_bytes(response: object) -> bytes | None:
    candidates = getattr(response, "candidates", None) or []
    for candidate in candidates:
        content = getattr(candidate, "content", None)
        if not content:
            continue
        for part in getattr(content, "parts", []) or []:
            inline_data = getattr(part, "inline_data", None)
            if inline_data and getattr(inline_data, "mime_type", "").startswith("image/"):
                return inline_data.data
    return None


def main() -> int:
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("GEMINI_API_KEY not found in current session.")
        return 1

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    client = genai.Client(api_key=api_key)
    ref_img = Image.open(MASCOT_REF)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    prompt_dump: list[str] = []
    generated = 0

    for index, item in enumerate(PROMPTS, start=1):
        prompt_dump.append(f"[{item['slug']}]\n{item['prompt']}\n")
        out_file = OUTPUT_DIR / f"{timestamp}_{item['slug']}.png"
        print(f"[{index}/{len(PROMPTS)}] Generating {out_file.name}")
        try:
            response = client.models.generate_content(
                model=MODEL,
                contents=[item["prompt"], ref_img],
                config=types.GenerateContentConfig(
                    response_modalities=["IMAGE", "TEXT"],
                    image_config=types.ImageConfig(aspect_ratio="4:5"),
                ),
            )
            image_bytes = extract_image_bytes(response)
            if not image_bytes:
                raise RuntimeError("No image returned")
            out_file.write_bytes(image_bytes)
            generated += 1
            print("  Saved")
        except Exception as exc:
            print(f"  Failed: {exc}")
        if index < len(PROMPTS):
            time.sleep(2)

    PROMPTS_FILE.write_text("\n".join(prompt_dump), encoding="utf-8")
    print(f"Generated {generated} image(s)")
    return 0 if generated else 1


if __name__ == "__main__":
    raise SystemExit(main())
