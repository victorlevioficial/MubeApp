from __future__ import annotations

import argparse
import os
import sys
import time
from datetime import datetime
from pathlib import Path

try:
    from google import genai
    from google.genai import types
except ImportError:
    print("Error: google-genai package not installed.")
    print("Install with: pip install google-genai pillow")
    sys.exit(1)


MODEL_PRO = "gemini-3-pro-image-preview"
ASPECT_RATIO = "1:1"
BASE_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = BASE_DIR / "outputs"
PROMPTS_FILE = BASE_DIR / "prompts_used.txt"


BASE_BRIEF = """
Create a professional mascot illustration for the Brazilian music networking app Mube.

Core character to preserve from the handmade sketch:
- a simple ghost character
- asymmetrical rounded body, slightly leaning, organic silhouette
- three rounded drips at the bottom
- two oversized black oval eyes with tiny white highlights
- no scary features, no teeth, no horror
- the character must feel friendly, memorable, soft, and emotionally warm

Brand direction:
- body color in raspberry pink #E8466C with refined tonal variation
- modern premium startup mascot
- vector-style illustration, clean silhouette, controlled soft shading
- single centered character only
- plain light neutral background
- no text, no props, no extra elements, no frame
- suitable for social media avatar, sticker, and brand mascot system

Avoid:
- photorealism
- 3D toy render
- anime style
- clip art
- generic halloween ghost
- multiple characters
- detailed background
- busy composition
""".strip()


FLAT_MOUTH_BRIEF = """
Create a professional mascot illustration for the Brazilian music networking app Mube.

Core character to preserve from the handmade sketch:
- a simple ghost character
- asymmetrical rounded body, slightly leaning, organic silhouette
- three rounded drips at the bottom
- two oversized black oval eyes with tiny white highlights
- add a mouth
- no scary features, no teeth, no horror
- the character must feel friendly, memorable, soft, and emotionally warm

Brand direction:
- body color in raspberry pink #E8466C
- flat vector illustration only
- solid fills only
- no gradient
- no gloss
- no soft shading
- no volume rendering
- no 3D effect
- no drop shadow
- no highlight blob on the body
- only simple clean shapes suitable for identity design
- single centered character only
- plain white or very light neutral background
- no text, no props, no extra elements, no frame
- suitable for social media avatar, sticker, and brand mascot system

Avoid:
- photorealism
- 3D toy render
- anime style
- clip art
- generic halloween ghost
- multiple characters
- detailed background
- busy composition
- gradients of any kind
- shiny surfaces
""".strip()


ROUND_1_STUDIES = [
    {
        "slug": "study_01_closest",
        "title": "Closest to sketch",
        "prompt": """
        Stay very close to the original naive sketch proportions, but refine the shape professionally.
        Keep the ghost slightly taller than wide, with a charming imperfect silhouette and a gentle handcrafted feel.
        Make the result look like a polished brand mascot, not a child drawing.
        """.strip(),
    },
    {
        "slug": "study_02_iconic",
        "title": "More iconic and balanced",
        "prompt": """
        Push the design toward a more iconic silhouette.
        Keep it extremely recognizable at small sizes, with cleaner curves, a stronger head shape,
        and better balance between cuteness and brand authority.
        """.strip(),
    },
    {
        "slug": "study_03_soft",
        "title": "Softer and more affectionate",
        "prompt": """
        Make the ghost feel warmer and more affectionate, with subtle softness in the body volume.
        Preserve simplicity and avoid adding a mouth unless it is nearly invisible and very delicate.
        The eyes should do most of the emotional work.
        """.strip(),
    },
    {
        "slug": "study_04_premium",
        "title": "Premium startup mascot",
        "prompt": """
        Refine the mascot as if it were designed by a top brand illustrator for a modern tech and music app.
        Keep the shape simple, but elevate the finish with taste, restraint, and visual confidence.
        The result should feel contemporary, scalable, and signature-worthy.
        """.strip(),
    },
]


ROUND_2_STUDIES = [
    {
        "slug": "study_05_refined_asymmetry",
        "title": "Refined asymmetry",
        "prompt": """
        Keep the best qualities of the original sketch:
        a slightly asymmetric silhouette, hand-drawn charm, and emotional simplicity.
        Refine the form so it feels professionally designed, with cleaner transitions and better weight distribution.
        Keep the body gently leaning and the bottom drips rounded and stable.
        """.strip(),
    },
    {
        "slug": "study_06_signature_shape",
        "title": "Signature shape",
        "prompt": """
        Design the ghost as a signature brand shape with a stronger top contour and a more memorable outline.
        Keep it simple enough to become an icon, sticker, or profile image.
        Preserve the innocence of the sketch and avoid making it too polished or generic.
        """.strip(),
    },
    {
        "slug": "study_07_closer_eyes",
        "title": "Closer eye language",
        "prompt": """
        Prioritize the emotional language of the eyes.
        Make them feel very close to the sketch: big black oval eyes with tiny highlights,
        slightly naive, slightly curious, and very lovable.
        Keep the body shape clean and minimal.
        """.strip(),
    },
    {
        "slug": "study_08_brand_ready",
        "title": "Brand-ready final direction",
        "prompt": """
        Create the version that feels most ready to become the official mascot of Mube.
        It should look ownable, contemporary, warm, and instantly recognizable.
        Use restraint and confidence rather than extra detail.
        """.strip(),
    },
]


ROUND_3_STUDIES = [
    {
        "slug": "study_09_final_balanced",
        "title": "Final balanced mascot",
        "prompt": """
        Use the strongest direction from the previous explorations:
        keep the elegant asymmetry, keep the body slightly leaning, and keep the three bottom drips stable and rounded.
        Make the silhouette feel polished and official, while still preserving the charm of the original sketch.
        """.strip(),
    },
    {
        "slug": "study_10_final_expressive",
        "title": "Final expressive eyes",
        "prompt": """
        Make the eyes the signature feature of the mascot.
        Keep them large, black, glossy, and emotionally rich, but still simple and graphic.
        The overall shape should stay minimal, ownable, and brand-ready.
        """.strip(),
    },
    {
        "slug": "study_11_final_iconic",
        "title": "Final iconic silhouette",
        "prompt": """
        Design the cleanest and most iconic official version of the character.
        Prioritize silhouette memorability, reduction of noise, and logo-like confidence,
        while keeping the feeling of the original pink ghost sketch.
        """.strip(),
    },
]


ROUND_4_STUDIES = [
    {
        "slug": "study_12_flat_smile",
        "title": "Flat smile",
        "brief": FLAT_MOUTH_BRIEF,
        "prompt": """
        Create a flat brand-mascot version with a very small curved smile.
        Keep the smile subtle, centered, and friendly.
        The shape should feel closest to the original sketch, with slightly imperfect charm.
        """.strip(),
    },
    {
        "slug": "study_13_flat_open_mouth",
        "title": "Flat open mouth",
        "brief": FLAT_MOUTH_BRIEF,
        "prompt": """
        Create a flat vector version with a tiny open mouth, very simple and graphic.
        The mouth should look cute and welcoming, not surprised or childish.
        Keep the body asymmetrical and memorable.
        """.strip(),
    },
    {
        "slug": "study_14_flat_confident_smile",
        "title": "Flat confident smile",
        "brief": FLAT_MOUTH_BRIEF,
        "prompt": """
        Create a flat vector version with a confident, gentle smile.
        The mouth should be minimal and elegant, giving the mascot a little more personality
        without making it look overly animated.
        """.strip(),
    },
    {
        "slug": "study_15_flat_soft_mouth",
        "title": "Flat soft mouth",
        "brief": FLAT_MOUTH_BRIEF,
        "prompt": """
        Create the softest and most lovable identity-ready version with a tiny mouth.
        Prioritize simplicity, flat color shapes, and a very ownable silhouette.
        It should feel like a mascot that can live in app identity for years.
        """.strip(),
    },
]


def get_api_key() -> str | None:
    return os.environ.get("GEMINI_API_KEY")


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


def generate_image(client: genai.Client, full_prompt: str, output_path: Path) -> Path:
    response = client.models.generate_content(
        model=MODEL_PRO,
        contents=full_prompt,
        config=types.GenerateContentConfig(
            response_modalities=["IMAGE", "TEXT"],
            image_config=types.ImageConfig(
                aspect_ratio=ASPECT_RATIO,
            ),
        ),
    )

    image_bytes = extract_image_bytes(response)
    if not image_bytes:
        raise RuntimeError("Model response did not contain an image.")

    output_path.write_bytes(image_bytes)
    return output_path


def build_prompt(study: dict[str, str]) -> str:
    brief = study.get("brief", BASE_BRIEF)
    return f"{brief}\n\nStudy direction:\n{study['prompt']}\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate mascot studies for Mube.")
    parser.add_argument(
        "--round",
        choices=["1", "2", "3", "4"],
        default="1",
        help="Study round to generate.",
    )
    args = parser.parse_args()

    api_key = get_api_key()
    if not api_key:
        print("Error: GEMINI_API_KEY not found in the current process.")
        print("In PowerShell, run:")
        print("$env:GEMINI_API_KEY = [Environment]::GetEnvironmentVariable('GEMINI_API_KEY','User')")
        return 1

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    client = genai.Client(api_key=api_key)
    if args.round == "1":
        studies = ROUND_1_STUDIES
    elif args.round == "2":
        studies = ROUND_2_STUDIES
    elif args.round == "3":
        studies = ROUND_3_STUDIES
    else:
        studies = ROUND_4_STUDIES

    prompt_dump: list[str] = []
    generated: list[Path] = []

    for index, study in enumerate(studies, start=1):
        output_path = OUTPUT_DIR / f"{timestamp}_{study['slug']}.png"
        full_prompt = build_prompt(study)
        prompt_dump.append(f"[{study['slug']}]\n{full_prompt}\n")
        print(f"[{index}/{len(studies)}] Generating {study['title']} -> {output_path.name}")
        try:
            generate_image(client, full_prompt, output_path)
            generated.append(output_path)
            print("  Saved")
        except Exception as exc:
            print(f"  Failed: {exc}")
        if index < len(studies):
            time.sleep(2)

    prompt_log = PROMPTS_FILE.with_name(f"prompts_round_{args.round}.txt")
    prompt_log.write_text("\n".join(prompt_dump), encoding="utf-8")
    print(f"Prompt log saved to: {prompt_log}")
    print(f"Generated {len(generated)} image(s)")
    return 0 if generated else 1


if __name__ == "__main__":
    raise SystemExit(main())
