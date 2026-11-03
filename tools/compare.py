#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""compare.py —— 把同一素材的候选图拼成对比图，方便一眼挑最好的。

用法：
    & $py tools\\compare.py                 # 全部素材
    & $py tools\\compare.py --only art_prop_bed
    & $py tools\\compare.py --cell 512      # 单格更大

产出：tools/_preview/<art_id>.png（每行 4 张，带 seed 标签）
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

REPO = Path(__file__).resolve().parents[1]
RAW = REPO / "assets" / "raw"
OUT = Path(__file__).resolve().parent / "_preview"

FONT_PATHS = [r"C:\Windows\Fonts\msyh.ttc", r"C:\Windows\Fonts\arial.ttf"]


def load_font(size: int):
    for p in FONT_PATHS:
        if Path(p).exists():
            try:
                return ImageFont.truetype(p, size)
            except Exception:                          # noqa: BLE001
                pass
    return ImageFont.load_default()


def metrics(img: Image.Image) -> tuple[float, float]:
    """返回 (边缘强度, 主体占比)。边缘强度越高通常越锐利。"""
    g = img.convert("L").resize((256, 256))
    edges = g.filter(ImageFilter.FIND_EDGES)
    sharp = float(np.asarray(edges, dtype=np.float32).std())
    a = np.asarray(img.convert("RGB").resize((256, 256)), dtype=np.float32) / 255.0
    bg = np.median(np.concatenate([a[:16, :16].reshape(-1, 3), a[:16, -16:].reshape(-1, 3),
                                   a[-16:, :16].reshape(-1, 3), a[-16:, -16:].reshape(-1, 3)]), axis=0)
    dist = np.linalg.norm(a - bg, axis=2)
    cover = float((dist > 0.12).mean())
    return sharp, cover


def build(art_id: str, paths: list[Path], cell: int) -> Path | None:
    if not paths:
        return None
    font = load_font(20)
    pad, bar = 8, 28
    cols = min(4, len(paths))
    rows = (len(paths) + cols - 1) // cols
    W = cols * (cell + pad) + pad
    H = rows * (cell + bar + pad) + pad
    sheet = Image.new("RGB", (W, H), (26, 23, 20))
    draw = ImageDraw.Draw(sheet)
    for i, p in enumerate(paths):
        im = Image.open(p).convert("RGB")
        im = im.resize((cell, int(cell * im.height / im.width)), Image.LANCZOS)
        x = pad + (i % cols) * (cell + pad)
        y = pad + (i // cols) * (cell + bar + pad)
        sheet.paste(im, (x, y))
        seed = p.stem.split("__s")[-1]
        draw.text((x + 4, y + cell + 4), f"s{seed}", fill=(220, 214, 200), font=font)
    OUT.mkdir(parents=True, exist_ok=True)
    dst = OUT / f"{art_id}.png"
    sheet.save(dst)
    return dst


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", help="逗号分隔的 art_id")
    ap.add_argument("--cell", type=int, default=384)
    args = ap.parse_args()

    groups: dict[str, list[Path]] = {}
    for p in sorted(RAW.glob("*/*__s*.png")):
        groups.setdefault(p.stem.split("__s")[0], []).append(p)
    if args.only:
        wanted = {s.strip() for s in args.only.split(",") if s.strip()}
        groups = {k: v for k, v in groups.items() if k in wanted}
    if not groups:
        print("没有候选图")
        return 1

    print(f"{'art_id':30} {'张数':4} {'边缘强度':>8} {'主体占比':>8}  文件")
    for art_id, paths in sorted(groups.items()):
        for p in paths:
            sharp, cover = metrics(Image.open(p))
            seed = p.stem.split("__s")[-1]
            print(f"{art_id:30} {len(paths):>4} {sharp:>8.2f} {cover*100:>7.1f}%  {seed}")
        dst = build(art_id, paths, args.cell)
        if dst:
            print(f"    → {dst.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    raise SystemExit(main())
