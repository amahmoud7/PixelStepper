"""Compose App Store screenshots (1206x2622, RGB, no alpha) from raw captures.

Usage: python scripts/appstore_screenshots.py <raw_dir> <out_dir>
Raw captures come from the CI "screenshots (appstore)" artifact (UI test test_3_appStore, demo data).
Raw files are matched by name prefix to the caption list below.
"""
import os
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1206, 2622
TOP, BOTTOM = (13, 5, 38), (32, 12, 72)          # brand gradient (Theme.bgDeep → deeper purple)
GLOW = (125, 92, 252)                            # Theme.purple
# Bold sans for captions; override with APPSTORE_FONT=/path/to/font.ttf on macOS/Linux.
FONT = Path(os.environ.get("APPSTORE_FONT", r"C:\Windows\Fonts\segoeuib.ttf"))

SHOTS = [  # (raw file stem prefix, caption, crop as (top, bottom) fractions of the capture, or None)
    ("A1-home", "Meet your walking companion", None),
    ("A3-missions", "Complete daily missions", None),
    ("A4-stats", "Track your streak & stats", None),
    ("A5-premium", "Evolve through 4 phases", None),
    ("A6-hook", "Choose your pixel companion", None),
]

def background():
    img = Image.new("RGB", (W, H))
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        row = tuple(round(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3))
        for x in range(W):
            px[x, y] = row
    glow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(glow).ellipse((W * 0.05, H * 0.30, W * 0.95, H * 0.80), fill=90)
    glow = glow.filter(ImageFilter.GaussianBlur(220))
    img.paste(Image.new("RGB", (W, H), GLOW), (0, 0), glow)
    return img

def wrap(draw, text, font, max_width):
    words, lines, line = text.split(), [], ""
    for word in words:
        trial = f"{line} {word}".strip()
        if draw.textlength(trial, font=font) <= max_width:
            line = trial
        else:
            lines.append(line)
            line = word
    lines.append(line)
    return lines

def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *img.size), radius=radius, fill=255)
    return mask

def compose(raw_path, caption, out_path, keep=None):
    canvas = background()
    draw = ImageDraw.Draw(canvas)

    # Caption: up to two lines, centered, shrinking if needed.
    size = 104
    while True:
        font = ImageFont.truetype(str(FONT), size)
        lines = wrap(draw, caption, font, W - 160)
        if len(lines) <= 2 or size <= 72:
            break
        size -= 4
    line_h = int(size * 1.18)
    y = 170
    for line in lines:
        w = draw.textlength(line, font=font)
        draw.text(((W - w) / 2, y), line, font=font, fill=(255, 255, 255))
        y += line_h
    caption_bottom = y

    # Screenshot: fit below the caption with a margin, rounded and shadowed.
    shot = Image.open(raw_path).convert("RGB")
    if keep:
        top_f, bottom_f = keep
        shot = shot.crop((0, round(shot.height * top_f), shot.width, round(shot.height * bottom_f)))
    top = caption_bottom + 70
    max_h = H - top - 90
    scale = min(max_h / shot.height, (W - 150) / shot.width)
    shot = shot.resize((round(shot.width * scale), round(shot.height * scale)), Image.LANCZOS)
    x = (W - shot.width) // 2
    top += max(0, (max_h - shot.height) // 2)   # center shorter (cropped) captures
    radius = round(shot.width * 0.075)

    shadow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shadow).rounded_rectangle((x, top + 24, x + shot.width, top + 24 + shot.height), radius=radius, fill=150)
    shadow = shadow.filter(ImageFilter.GaussianBlur(40))
    canvas.paste(Image.new("RGB", (W, H), (0, 0, 0)), (0, 0), shadow)
    canvas.paste(shot, (x, top), rounded(shot, radius))
    ImageDraw.Draw(canvas).rounded_rectangle((x, top, x + shot.width, top + shot.height), radius=radius,
                                             outline=(70, 52, 140), width=3)

    canvas.save(out_path, "PNG", optimize=True)
    return canvas.size

def main(raw_dir, out_dir):
    raw_dir, out_dir = Path(raw_dir), Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    for i, (prefix, caption, keep) in enumerate(SHOTS, 1):
        matches = sorted(raw_dir.rglob(f"{prefix}*.png"))
        if not matches:
            print(f"skip {prefix}: no capture")
            continue
        out = out_dir / f"{i:02d}-{prefix.split('-', 1)[1]}.png"
        size = compose(matches[0], caption, out, keep)
        print(f"{out.name}: {size[0]}x{size[1]} RGB  <- {matches[0].name}")

if __name__ == "__main__":
    main(*sys.argv[1:3])
