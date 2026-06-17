#!/usr/bin/env python3
"""Генерирует иконку приложения Coffein — «Бодрый глаз» на тёмно-синем градиенте.

Рисует мастер 1024×1024 (скруглённый квадрат + градиент + миндалевидный глаз),
затем масштабирует во все размеры iconset. На выходе:
  build/icon_1024.png        — мастер для предпросмотра
  build/AppIcon.iconset/...  — набор для `iconutil -c icns`
"""

import os
from PIL import Image, ImageDraw, ImageFilter, ImageChops

S = 1024  # размер мастера

# Палитра
BG_TOP = (0x0B, 0x1E, 0x3A)      # тёмно-синий
BG_BOT = (0x21, 0x40, 0x74)      # синий посветлее
SCLERA_TOP = (222, 230, 240)     # белок: лёгкая тень века сверху
SCLERA_BOT = (255, 255, 255)     # белок: чистый низ
IRIS_IN = (255, 232, 158)        # центр радужки (светлее)
IRIS_OUT = (236, 168, 56)        # край радужки (тёплый янтарь)
IRIS_RING = (150, 92, 22)        # тёмный ободок радужки
PUPIL = (16, 18, 28)             # зрачок
OUTLINE = (18, 36, 68)           # контур глаза (тёмно-синий)
GLOW = (130, 205, 255)           # голубое свечение «бодрости»


def lerp(a, b, t):
    return int(round(a + (b - a) * t))


def vertical_gradient(top, bottom, w, h):
    img = Image.new("RGB", (w, h))
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / (h - 1)
        draw.line([(0, y), (w, y)], fill=(
            lerp(top[0], bottom[0], t),
            lerp(top[1], bottom[1], t),
            lerp(top[2], bottom[2], t)))
    return img


def radial_iris(cx, cy, r, inner, outer):
    """Радужка с радиальным градиентом (светлее в центре)."""
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    steps = 60
    for i in range(steps, 0, -1):
        t = i / steps
        rr = int(r * t)
        draw.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=(
            lerp(inner[0], outer[0], t),
            lerp(inner[1], outer[1], t),
            lerp(inner[2], outer[2], t), 255))
    return layer


def almond_mask(cx, cy, ew, eh):
    """Маска миндалевидного глаза = пересечение двух больших окружностей."""
    a, s = ew / 2.0, eh / 2.0
    d = (a * a - s * s) / (2 * s)
    r = (a * a + s * s) / (2 * s)
    disk_a = Image.new("L", (S, S), 0)
    ImageDraw.Draw(disk_a).ellipse([cx - r, (cy + d) - r, cx + r, (cy + d) + r], fill=255)
    disk_b = Image.new("L", (S, S), 0)
    ImageDraw.Draw(disk_b).ellipse([cx - r, (cy - d) - r, cx + r, (cy - d) + r], fill=255)
    return ImageChops.multiply(disk_a, disk_b)


def build_master():
    transparent = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    canvas = transparent.copy()

    # 1) Скруглённый квадрат с вертикальным градиентом и полем по краям.
    margin = 96
    radius = int((S - 2 * margin) * 0.2237)
    bg_mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(bg_mask).rounded_rectangle(
        [margin, margin, S - margin, S - margin], radius=radius, fill=255)
    canvas = Image.composite(vertical_gradient(BG_TOP, BG_BOT, S, S).convert("RGBA"),
                             canvas, bg_mask)

    # 2) Мягкий блик сверху (объём).
    sheen = transparent.copy()
    ImageDraw.Draw(sheen).ellipse(
        [int(S * 0.16), int(S * 0.04), int(S * 0.84), int(S * 0.56)], fill=(90, 150, 230, 75))
    sheen = Image.composite(sheen.filter(ImageFilter.GaussianBlur(130)), transparent, bg_mask)
    canvas = Image.alpha_composite(canvas, sheen)

    cx, cy = S // 2, int(S * 0.52)
    ew, eh = int(S * 0.70), int(S * 0.46)
    almond = almond_mask(cx, cy, ew, eh)

    # 3) Аккуратное голубое свечение строго вокруг глаза (не размывает белок).
    glow_alpha = almond.filter(ImageFilter.GaussianBlur(34)).point(lambda v: int(v * 0.55))
    glow = Image.new("RGBA", (S, S), GLOW + (255,))
    glow.putalpha(glow_alpha)
    glow = Image.composite(glow, transparent, bg_mask)
    canvas = Image.alpha_composite(canvas, glow)

    # 4) Белок — чистый, с лёгкой тенью века сверху.
    sclera = Image.composite(
        vertical_gradient(SCLERA_TOP, SCLERA_BOT, S, S).convert("RGBA"), transparent, almond)
    canvas = Image.alpha_composite(canvas, sclera)

    # 5) Радужка + ободок (обрезаны по форме глаза).
    iris_r = int(S * 0.150)
    iris = Image.composite(radial_iris(cx, cy, iris_r, IRIS_IN, IRIS_OUT), transparent, almond)
    canvas = Image.alpha_composite(canvas, iris)
    draw = ImageDraw.Draw(canvas)
    draw.ellipse([cx - iris_r, cy - iris_r, cx + iris_r, cy + iris_r],
                 outline=IRIS_RING + (255,), width=int(S * 0.012))

    # 6) Зрачок + блик.
    pr = int(S * 0.067)
    draw.ellipse([cx - pr, cy - pr, cx + pr, cy + pr], fill=PUPIL + (255,))
    hr = int(S * 0.031)
    hx, hy = cx - int(iris_r * 0.34), cy - int(iris_r * 0.40)
    draw.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=(255, 255, 255, 240))
    # маленький вторичный блик
    hr2 = int(S * 0.013)
    draw.ellipse([cx + int(iris_r * 0.18) - hr2, cy + int(iris_r * 0.22) - hr2,
                  cx + int(iris_r * 0.18) + hr2, cy + int(iris_r * 0.22) + hr2],
                 fill=(255, 255, 255, 150))

    # 7) Тонкий контур глаза для чёткости.
    inner = almond.filter(ImageFilter.MinFilter(9))  # эрозия ~4px
    ring_alpha = ImageChops.subtract(almond, inner)
    ring = Image.new("RGBA", (S, S), OUTLINE + (255,))
    ring.putalpha(ring_alpha)
    canvas = Image.alpha_composite(canvas, ring)

    return canvas


def main():
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    build_dir = os.path.join(root, "build")
    iconset = os.path.join(build_dir, "AppIcon.iconset")
    os.makedirs(iconset, exist_ok=True)

    master = build_master()
    master.save(os.path.join(build_dir, "icon_1024.png"))

    specs = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1),
             (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)]
    for base, scale in specs:
        px = base * scale
        suffix = "@2x" if scale == 2 else ""
        master.resize((px, px), Image.LANCZOS).save(
            os.path.join(iconset, f"icon_{base}x{base}{suffix}.png"))

    print(f"Иконка готова: {iconset}")


if __name__ == "__main__":
    main()
