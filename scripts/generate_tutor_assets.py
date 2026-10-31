"""Genera los recursos provisionales del tutor: hoja de 4 vistas para el mapa,
ilustración de novela visual y avatar. Son reemplazables (ver docs/ASSETS.md).

Uso: python scripts/generate_tutor_assets.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]

OUTLINE = (43, 32, 51, 255)
HAIR = (74, 52, 38, 255)
HAIR_LIGHT = (104, 76, 56, 255)
SKIN = (217, 162, 122, 255)
SKIN_SHADOW = (185, 128, 88, 255)
CARDIGAN = (63, 143, 138, 255)
CARDIGAN_SHADOW = (47, 111, 107, 255)
SHIRT = (242, 239, 230, 255)
LANYARD = (226, 173, 54, 255)
CARD = (250, 250, 245, 255)
PANTS = (107, 90, 72, 255)
PANTS_SHADOW = (84, 70, 58, 255)
SHOES = (58, 43, 43, 255)
LENS = (196, 226, 236, 255)


# --- Hoja de mapa en pixel art (cuatro vistas, misma disposición que los compañeros) ---

def _rect(px: dict, x0: int, y0: int, x1: int, y1: int, color: tuple) -> None:
    for x in range(x0, x1 + 1):
        for y in range(y0, y1 + 1):
            px[(x, y)] = color


def _figure(facing: str) -> Image.Image:
    w, h = 32, 44
    px: dict = {}
    side = facing in ("left", "right")
    # Piernas y zapatos
    if side:
        _rect(px, 13, 32, 18, 40, PANTS)
        _rect(px, 13, 32, 14, 40, PANTS_SHADOW)
        _rect(px, 12, 41, 19, 42, SHOES)
    else:
        _rect(px, 10, 32, 14, 40, PANTS)
        _rect(px, 17, 32, 21, 40, PANTS)
        _rect(px, 15, 32, 16, 34, PANTS_SHADOW)
        _rect(px, 9, 41, 14, 42, SHOES)
        _rect(px, 17, 41, 22, 42, SHOES)
    # Torso con cárdigan
    if side:
        _rect(px, 11, 19, 20, 32, CARDIGAN)
        _rect(px, 11, 19, 12, 32, CARDIGAN_SHADOW)
        _rect(px, 14, 21, 17, 31, CARDIGAN_SHADOW)
        _rect(px, 13, 32, 16, 33, SKIN)  # mano
    else:
        _rect(px, 8, 19, 23, 32, CARDIGAN)
        _rect(px, 6, 20, 8, 31, CARDIGAN_SHADOW)
        _rect(px, 23, 20, 25, 31, CARDIGAN_SHADOW)
        _rect(px, 6, 32, 8, 33, SKIN)
        _rect(px, 23, 32, 25, 33, SKIN)
        if facing == "down":
            _rect(px, 13, 19, 18, 31, SHIRT)
            for y in range(20, 27):  # cordón de identificación
                px[(13 + (y - 20) // 3, y)] = LANYARD
                px[(18 - (y - 20) // 3, y)] = LANYARD
            _rect(px, 14, 27, 17, 30, CARD)
            _rect(px, 15, 28, 16, 28, CARDIGAN)
    # Cabeza
    _rect(px, 10, 6, 21, 18, SKIN)
    _rect(px, 13, 18, 18, 19, SKIN_SHADOW)
    if facing == "up":
        _rect(px, 9, 3, 22, 16, HAIR)
        _rect(px, 11, 4, 18, 6, HAIR_LIGHT)
    else:
        _rect(px, 9, 3, 22, 7, HAIR)
        _rect(px, 11, 3, 17, 4, HAIR_LIGHT)
        if facing == "down":
            _rect(px, 9, 7, 10, 12, HAIR)
            _rect(px, 21, 7, 22, 12, HAIR)
            # Gafas y ojos
            _rect(px, 11, 10, 14, 13, OUTLINE)
            _rect(px, 17, 10, 20, 13, OUTLINE)
            _rect(px, 12, 11, 13, 12, LENS)
            _rect(px, 18, 11, 19, 12, LENS)
            _rect(px, 15, 11, 16, 11, OUTLINE)
            px[(13, 12)] = OUTLINE
            px[(18, 12)] = OUTLINE
            _rect(px, 14, 16, 17, 16, SKIN_SHADOW)  # sonrisa
        else:
            back = 21 if facing == "left" else 10
            front = 10 if facing == "left" else 21
            step = -1 if facing == "left" else 1
            _rect(px, min(back, back - 3 * step), 7, max(back, back - 3 * step), 13, HAIR)
            _rect(px, min(front, front - 3 * step), 10, max(front, front - 3 * step), 13, OUTLINE)
            px[(front - step, 11)] = LENS
            px[(front - 2 * step, 11)] = LENS
            px[(front + step, 14)] = SKIN  # nariz
            px[(front - step, 16)] = SKIN_SHADOW
            px[(back - step, 11)] = SKIN_SHADOW  # oreja
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for (x, y), color in px.items():
        if 0 <= x < w and 0 <= y < h:
            img.putpixel((x, y), color)
    # Contorno de un píxel alrededor de la silueta
    outline = img.copy()
    for (x, y) in list(px):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in px:
                outline.putpixel((nx, ny), OUTLINE)
    return outline


def direction_sheet() -> Image.Image:
    cell = 320
    sheet = Image.new("RGBA", (cell * 2, cell * 2), (0, 0, 0, 0))
    for index, facing in enumerate(["down", "up", "left", "right"]):
        figure = _figure(facing).resize((32 * 6, 44 * 6), Image.NEAREST)
        cx, cy = (index % 2) * cell, (index // 2) * cell
        sheet.alpha_composite(figure, (cx + (cell - figure.width) // 2, cy + (cell - figure.height) // 2))
    return sheet


# --- Ilustración de novela visual (1024×1536, mismo encuadre que los compañeros) ---

def portrait() -> Image.Image:
    scale = 2
    W, H = 1024 * scale, 1536 * scale
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    S = lambda *v: [c * scale for c in v]
    lw = 7 * scale
    # Piernas
    d.rectangle(S(340, 1230, 500, 1536), fill=PANTS, outline=OUTLINE, width=lw)
    d.rectangle(S(524, 1230, 684, 1536), fill=PANTS, outline=OUTLINE, width=lw)
    # Torso y cárdigan
    d.polygon(S(250, 640, 774, 640, 820, 1260, 204, 1260), fill=CARDIGAN, outline=OUTLINE, width=lw)
    d.polygon(S(420, 640, 604, 640, 560, 1240, 464, 1240), fill=SHIRT, outline=OUTLINE, width=lw)
    d.polygon(S(420, 640, 512, 760, 604, 640), fill=SKIN_SHADOW, outline=OUTLINE, width=lw)
    # Mangas y manos que sostienen una carpeta
    d.polygon(S(250, 650, 160, 1000, 250, 1060, 330, 760), fill=CARDIGAN_SHADOW, outline=OUTLINE, width=lw)
    d.polygon(S(774, 650, 864, 1000, 774, 1060, 694, 760), fill=CARDIGAN_SHADOW, outline=OUTLINE, width=lw)
    d.rounded_rectangle(S(300, 930, 560, 1130), radius=18 * scale, fill=(116, 92, 156, 255), outline=OUTLINE, width=lw)
    d.rectangle(S(320, 960, 540, 975), fill=(222, 206, 240, 255))
    d.ellipse(S(220, 980, 330, 1080), fill=SKIN, outline=OUTLINE, width=lw)
    d.ellipse(S(520, 990, 620, 1080), fill=SKIN, outline=OUTLINE, width=lw)
    # Cordón y credencial
    d.line(S(440, 660, 500, 900), fill=LANYARD, width=12 * scale)
    d.line(S(584, 660, 524, 900), fill=LANYARD, width=12 * scale)
    d.rounded_rectangle(S(462, 880, 562, 1000), radius=10 * scale, fill=CARD, outline=OUTLINE, width=5 * scale)
    d.rectangle(S(480, 900, 544, 930), fill=CARDIGAN)
    d.line(S(480, 950, 544, 950), fill=OUTLINE, width=4 * scale)
    d.line(S(480, 970, 530, 970), fill=OUTLINE, width=4 * scale)
    # Cuello y cabeza
    d.rectangle(S(452, 560, 572, 680), fill=SKIN_SHADOW, outline=OUTLINE, width=lw)
    d.ellipse(S(330, 230, 694, 640), fill=SKIN, outline=OUTLINE, width=lw)
    d.ellipse(S(304, 400, 360, 500), fill=SKIN, outline=OUTLINE, width=lw)
    d.ellipse(S(664, 400, 720, 500), fill=SKIN, outline=OUTLINE, width=lw)
    # Cabello corto con raya al costado y algunas canas
    d.pieslice(S(316, 180, 708, 520), 180, 360, fill=HAIR, outline=OUTLINE, width=lw)
    d.polygon(S(330, 350, 360, 470, 380, 350), fill=HAIR, outline=OUTLINE, width=lw)
    d.polygon(S(694, 350, 664, 470, 644, 350), fill=HAIR, outline=OUTLINE, width=lw)
    d.arc(S(420, 210, 640, 360), 200, 300, fill=(160, 150, 145, 255), width=8 * scale)
    d.arc(S(380, 230, 560, 380), 210, 290, fill=HAIR_LIGHT, width=10 * scale)
    # Cejas, ojos tras gafas, nariz, sonrisa y mejillas
    d.line(S(400, 395, 470, 385), fill=OUTLINE, width=9 * scale)
    d.line(S(554, 385, 624, 395), fill=OUTLINE, width=9 * scale)
    for x in (390, 534):
        d.rounded_rectangle(S(x, 410, x + 100, 482), radius=22 * scale, fill=(220, 236, 240, 255), outline=OUTLINE, width=8 * scale)
        d.ellipse(S(x + 32, 425, x + 68, 468), fill=(70, 54, 44, 255))
        d.ellipse(S(x + 44, 432, x + 54, 444), fill=(255, 255, 255, 255))
    d.line(S(490, 440, 534, 440), fill=OUTLINE, width=7 * scale)
    d.line(S(512, 470, 500, 530), fill=SKIN_SHADOW, width=7 * scale)
    d.arc(S(450, 520, 574, 590), 20, 160, fill=OUTLINE, width=8 * scale)
    d.ellipse(S(380, 500, 440, 540), fill=(232, 150, 140, 110))
    d.ellipse(S(584, 500, 644, 540), fill=(232, 150, 140, 110))
    img = img.filter(ImageFilter.SMOOTH)
    return img.resize((1024, 1536), Image.LANCZOS)


AVATAR_TRES = """[gd_resource type="AtlasTexture" load_steps=2 format=3]

[ext_resource type="Texture2D" path="res://assets/vn/tutor_v1.png" id="1"]

[resource]
atlas = ExtResource("1")
region = Rect2(262, 170, 500, 500)
"""


def main() -> None:
    direction_sheet().save(ROOT / "assets" / "characters" / "tutor_directions.png")
    portrait().save(ROOT / "assets" / "vn" / "tutor_v1.png")
    (ROOT / "assets" / "portraits" / "tutor_v1.tres").write_text(AVATAR_TRES, encoding="utf-8")
    print("PASS tutor_directions.png, tutor_v1.png, tutor_v1.tres")


if __name__ == "__main__":
    main()
