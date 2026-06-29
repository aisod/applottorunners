#!/usr/bin/env python3
"""Copy and resize Play Store phone screenshots to 1080×1920 (9:16).

Finds PNGs from integration_test output or a source folder, writes to
store/google-play/screenshots/phone/.
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "store" / "google-play" / "screenshots" / "phone"
TARGET = (1080, 1920)  # 9:16 — Google Play phone screenshots

SEARCH_DIRS = [
    ROOT / "screenshots",
    ROOT / "build" / "integration_test_screenshots",
    ROOT / "integration_test_screenshots",
]

# Exact stems from integration_test/play_screenshots_test.dart takeScreenshot() names.
EXPECTED_STEMS = (
    "01-onboarding-welcome",
    "02-onboarding-errands",
    "03-sign-in",
    "04-home-dashboard",
    "05-my-orders",
    "06-my-history",
    "07-profile",
    "08-home-services",
)


def is_app_screenshot(path: Path) -> bool:
    stem = path.stem.lower()
    return stem in EXPECTED_STEMS or stem.startswith(
        tuple(f"{i:02d}-" for i in range(1, 9))
    ) and any(k in stem for k in ("onboarding", "sign-in", "dashboard", "orders", "history", "profile", "home-services"))


def find_pngs() -> list[Path]:
    found: list[Path] = []
    for base in SEARCH_DIRS:
        if not base.is_dir():
            continue
        found.extend(sorted(base.rglob("*.png")))
    # De-dupe and keep only app screenshots (not build resources/icons)
    unique: dict[str, Path] = {}
    for p in found:
        if "feature_graphic" in p.name or "app_icon" in p.name:
            continue
        if not is_app_screenshot(p):
            continue
        unique[str(p.resolve())] = p
    return sorted(unique.values(), key=lambda p: p.name)


def fit_9_16(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    """Center-crop to 9:16, then resize."""
    tw, th = size
    target_ratio = tw / th
    w, h = img.size
    src_ratio = w / h

    if src_ratio > target_ratio:
        new_w = int(h * target_ratio)
        left = (w - new_w) // 2
        img = img.crop((left, 0, left + new_w, h))
    elif src_ratio < target_ratio:
        new_h = int(w / target_ratio)
        top = (h - new_h) // 2
        img = img.crop((0, top, w, top + new_h))

    return img.resize(size, Image.Resampling.LANCZOS)


def main() -> None:
    pngs = find_pngs()
    if not pngs:
        sys.stderr.write(
            "No screenshots found under build/ or screenshots/. "
            "Run tools/capture_play_screenshots.ps1 first.\n"
        )
        sys.exit(1)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for old in OUT_DIR.glob("*.png"):
        old.unlink()

    for i, src in enumerate(pngs, start=1):
        img = Image.open(src).convert("RGB")
        out_img = fit_9_16(img, TARGET)
        dest = OUT_DIR / f"{i:02d}-{src.stem}.png"
        out_img.save(dest, format="PNG", optimize=True)
        print(f"Wrote {dest.relative_to(ROOT)} ({TARGET[0]}×{TARGET[1]}) from {src.relative_to(ROOT)}")

    print(f"\nUpload PNGs from: {OUT_DIR.relative_to(ROOT)}/")


if __name__ == "__main__":
    main()
