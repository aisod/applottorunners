#!/usr/bin/env python3
"""Generate Google Play listing PNGs (512×512 icon, 1024×500 feature graphic).

Source icon (first found): web/icons/lotto runners icon 512.png (512×512),
web/icons/lotto runners icon 92.png, web/icons/logolotto.png, or Icon-512.png.

Output: store/google-play/app_icon_512x512.png  (required 512×512 for Play Console)
        store/google-play/feature_graphic_1024x500.png
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "store" / "google-play"

ICON_CANDIDATES = [
    ROOT / "web" / "icons" / "lotto runners icon 512.png",
    ROOT / "web" / "icons" / "lotto runners icon 92.png",
    ROOT / "web" / "icons" / "logolotto.png",
    ROOT / "web" / "icons" / "Icon-512.png",
    ROOT / "build" / "flutter_assets" / "web" / "icons" / "Icon-512.png",
]


def find_source_icon() -> Path:
    for p in ICON_CANDIDATES:
        if p.is_file():
            return p
    sys.stderr.write(
        "No icon source found. Add web/icons/logolotto.png or run "
        "`flutter build web` so build/flutter_assets/web/icons/Icon-512.png exists.\n"
    )
    sys.exit(1)


def horizontal_gradient(size: tuple[int, int], left_rgb: tuple[int, int, int], right_rgb: tuple[int, int, int]) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    r1, g1, b1 = left_rgb
    r2, g2, b2 = right_rgb
    for x in range(w):
        t = x / (w - 1) if w > 1 else 0.0
        r = int(r1 + (r2 - r1) * t)
        g = int(g1 + (g2 - g1) * t)
        b = int(b1 + (b2 - b1) * t)
        for y in range(h):
            px[x, y] = (r, g, b)
    return img


def prepare_banner_logo(icon: Image.Image) -> Image.Image:
    """Recolor logo for blue banner: white runner, light blue bag, white text/highlights."""
    src = icon.convert("RGBA")
    out = Image.new("RGBA", src.size, (0, 0, 0, 0))
    spx = src.load()
    opx = out.load()
    w, h = src.size
    white = (255, 255, 255)
    bag_blue = (191, 219, 254)  # light blue — visible on dark blue gradient
    for y in range(h):
        for x in range(w):
            r, g, b, a = spx[x, y]
            if a < 40:
                continue
            lum = (r + g + b) / 3
            # Blue-tinted pixels (shirt, bag) — bag is mid/strong blue; text on bag is bright
            is_blue = b > r + 15 and b > g + 5 and b > 60
            is_bright = lum > 185 or (r > 200 and g > 200 and b > 200)
            if is_blue and not is_bright:
                opx[x, y] = (*bag_blue, a)
            elif is_bright:
                opx[x, y] = (*white, a)
            else:
                opx[x, y] = (*white, a)
    return out


def load_font(size: int, *, bold: bool = True) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    windows = [
        Path(r"C:\Windows\Fonts\segoeuib.ttf") if bold else Path(r"C:\Windows\Fonts\segoeui.ttf"),
        Path(r"C:\Windows\Fonts\arialbd.ttf") if bold else Path(r"C:\Windows\Fonts\arial.ttf"),
        Path(r"C:\Windows\Fonts\arial.ttf"),
    ]
    for p in windows:
        if p.is_file():
            try:
                return ImageFont.truetype(str(p), size)
            except OSError:
                continue
    return ImageFont.load_default()


def text_size(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont) -> tuple[int, int]:
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0], bbox[3] - bbox[1]


def main() -> None:
    src = find_source_icon()
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    icon_src = Image.open(src).convert("RGBA")
    if icon_src.size == (512, 512):
        icon_512 = icon_src
    else:
        icon_512 = icon_src.resize((512, 512), Image.Resampling.LANCZOS)
    icon_path = OUT_DIR / "app_icon_512x512.png"
    icon_512.save(icon_path, format="PNG", optimize=True)
    print(f"Wrote {icon_path.relative_to(ROOT)} ({icon_512.size[0]}×{icon_512.size[1]}) from {src.relative_to(ROOT)}")

    # Feature graphic: white background, logo + centered text block as one unit
    fw, fh = 1024, 500
    banner = Image.new("RGB", (fw, fh), (255, 255, 255))

    logo_h = 340
    logo = icon_src.resize((logo_h, logo_h), Image.Resampling.LANCZOS)

    draw = ImageDraw.Draw(banner)
    title_font = load_font(58, bold=True)
    sub_font = load_font(26, bold=False)
    title = "Lotto Runners"
    subtitle = "Errands, transport & more on demand"
    title_blue = (0x02, 0x6E, 0xB8)  # matches bag blue (#026eb8)
    subtitle_gray = (0x47, 0x55, 0x69)

    title_w, title_h = text_size(draw, title, title_font)
    sub_w, sub_h = text_size(draw, subtitle, sub_font)
    text_col_w = max(title_w, sub_w)
    title_sub_gap = 28
    gap = 36
    text_block_h = title_h + title_sub_gap + sub_h
    group_w = logo_h + gap + text_col_w
    group_h = max(logo_h, text_block_h)

    group_x = (fw - group_w) // 2
    group_y = (fh - group_h) // 2

    lx = group_x
    ly = group_y + (group_h - logo_h) // 2
    banner.paste(logo, (lx, ly), logo.split()[3])

    text_col_x = group_x + logo_h + gap
    text_y = group_y + (group_h - text_block_h) // 2
    title_x = text_col_x + (text_col_w - title_w) // 2
    sub_x = text_col_x + (text_col_w - sub_w) // 2
    draw.text((title_x, text_y), title, fill=title_blue, font=title_font)
    draw.text((sub_x, text_y + title_h + title_sub_gap), subtitle, fill=subtitle_gray, font=sub_font)

    feat_path = OUT_DIR / "feature_graphic_1024x500.png"
    banner.save(feat_path, format="PNG", optimize=True)
    print(f"Wrote {feat_path.relative_to(ROOT)} ({fw}×{fh})")


if __name__ == "__main__":
    main()
