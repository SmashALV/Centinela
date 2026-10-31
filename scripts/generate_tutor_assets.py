"""Genera los recursos de mapa del profesor tutor a partir de su ilustración.

La ilustración de novela visual (`assets/vn/tutor_v2.png`) es arte entregado por
el equipo. Este script produce la hoja de cuatro vistas en pixel art para el mapa
y el recorte de avatar, con la paleta tomada de esa ilustración.

Uso: python scripts/generate_tutor_assets.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]

# Paleta muestreada de assets/vn/tutor_v2.png
OUTLINE = (34, 26, 30, 255)
HAIR = (92, 88, 90, 255)
HAIR_LIGHT = (150, 146, 148, 255)
HAIR_DARK = (60, 56, 60, 255)
SKIN = (198, 136, 88, 255)
SKIN_SHADOW = (160, 100, 62, 255)
EYE = (70, 40, 24, 255)
GLASSES = (52, 48, 52, 255)
LENS = (214, 226, 230, 255)
CARDIGAN = (34, 72, 48, 255)
CARDIGAN_LIGHT = (52, 98, 66, 255)
CARDIGAN_DARK = (22, 50, 34, 255)
BUTTON = (96, 62, 44, 255)
SHIRT = (250, 234, 206, 255)
SHIRT_SHADOW = (222, 200, 168, 255)
BELT = (70, 44, 36, 255)
PANTS = (166, 138, 100, 255)
PANTS_SHADOW = (128, 104, 74, 255)
SHOES = (58, 40, 37, 255)
FOLDER = (39, 66, 150, 255)
FOLDER_EDGE = (200, 204, 216, 255)

W, H = 32, 46


def _rect(px: dict, x0: int, y0: int, x1: int, y1: int, color: tuple) -> None:
    for x in range(x0, x1 + 1):
        for y in range(y0, y1 + 1):
            px[(x, y)] = color


def _mirror(px: dict) -> dict:
    return {(W - 1 - x, y): c for (x, y), c in px.items()}


def _legs(px: dict, side: bool) -> None:
    if side:
        _rect(px, 13, 32, 18, 41, PANTS)
        _rect(px, 13, 32, 14, 41, PANTS_SHADOW)
        _rect(px, 12, 42, 19, 43, SHOES)
        return
    _rect(px, 10, 32, 15, 41, PANTS)
    _rect(px, 17, 32, 22, 41, PANTS)
    _rect(px, 15, 33, 16, 41, PANTS_SHADOW)
    _rect(px, 10, 32, 11, 41, PANTS_SHADOW)
    _rect(px, 9, 42, 15, 43, SHOES)
    _rect(px, 17, 42, 23, 43, SHOES)


def _front() -> dict:
    px: dict = {}
    _legs(px, False)
    # Torso: cárdigan abierto en V, camisa con cuello, cinturón
    _rect(px, 8, 19, 24, 31, CARDIGAN)
    _rect(px, 8, 19, 9, 31, CARDIGAN_DARK)
    _rect(px, 23, 19, 24, 31, CARDIGAN_DARK)
    _rect(px, 8, 30, 24, 31, CARDIGAN_LIGHT)  # puño del cárdigan
    for y in range(19, 27):
        half = max(0, 3 - (y - 19) // 3)
        _rect(px, 16 - half - 1, y, 16 + half, y, SHIRT)
    _rect(px, 13, 19, 14, 20, SHIRT_SHADOW)  # cuello
    _rect(px, 17, 19, 18, 20, SHIRT_SHADOW)
    for y in (24, 27, 30):
        px[(16, y)] = BUTTON
    _rect(px, 10, 32, 22, 32, BELT)
    # Brazos: izquierdo gesticula, derecho sostiene la carpeta azul
    _rect(px, 5, 20, 7, 28, CARDIGAN)
    _rect(px, 5, 20, 5, 28, CARDIGAN_DARK)
    _rect(px, 4, 29, 7, 30, SKIN)
    _rect(px, 25, 20, 27, 27, CARDIGAN)
    _rect(px, 27, 20, 27, 27, CARDIGAN_DARK)
    _rect(px, 22, 22, 28, 31, FOLDER)
    _rect(px, 28, 22, 28, 31, FOLDER_EDGE)
    _rect(px, 23, 26, 25, 27, SKIN)
    # Cabeza
    _rect(px, 10, 7, 21, 18, SKIN)
    _rect(px, 14, 18, 18, 19, SKIN_SHADOW)
    _rect(px, 9, 11, 9, 14, SKIN_SHADOW)
    _rect(px, 22, 11, 22, 14, SKIN_SHADOW)
    # Cabello gris en mechones
    _rect(px, 9, 4, 22, 8, HAIR)
    _rect(px, 9, 8, 10, 11, HAIR)
    _rect(px, 21, 8, 22, 11, HAIR)
    for x, y in ((10, 3), (13, 2), (16, 3), (19, 2), (22, 3), (8, 5), (23, 6)):
        px[(x, y)] = HAIR
    _rect(px, 12, 4, 17, 5, HAIR_LIGHT)
    _rect(px, 19, 6, 21, 7, HAIR_DARK)
    # Gafas rectangulares y ojos
    _rect(px, 11, 11, 14, 13, GLASSES)
    _rect(px, 17, 11, 20, 13, GLASSES)
    _rect(px, 12, 12, 13, 12, LENS)
    _rect(px, 18, 12, 19, 12, LENS)
    _rect(px, 15, 11, 16, 11, GLASSES)
    px[(13, 12)] = EYE
    px[(18, 12)] = EYE
    _rect(px, 14, 16, 17, 16, SKIN_SHADOW)  # sonrisa
    return px


def _back() -> dict:
    px: dict = {}
    _legs(px, False)
    _rect(px, 8, 19, 24, 31, CARDIGAN)
    _rect(px, 8, 19, 9, 31, CARDIGAN_DARK)
    _rect(px, 23, 19, 24, 31, CARDIGAN_DARK)
    _rect(px, 8, 30, 24, 31, CARDIGAN_LIGHT)
    _rect(px, 14, 19, 18, 19, SHIRT)  # cuello de la camisa
    _rect(px, 5, 20, 7, 28, CARDIGAN_DARK)
    _rect(px, 25, 20, 27, 28, CARDIGAN_DARK)
    _rect(px, 4, 29, 7, 30, SKIN)
    _rect(px, 3, 22, 4, 31, FOLDER)
    _rect(px, 25, 29, 27, 30, SKIN)
    _rect(px, 10, 7, 21, 18, HAIR)
    _rect(px, 13, 17, 18, 18, SKIN_SHADOW)  # nuca
    _rect(px, 9, 4, 22, 14, HAIR)
    for x, y in ((10, 3), (13, 2), (16, 3), (19, 2), (22, 3)):
        px[(x, y)] = HAIR
    _rect(px, 12, 5, 18, 7, HAIR_LIGHT)
    # Brillos sueltos y borde inferior irregular en la nuca
    for x, y in ((11, 9), (13, 11), (16, 9), (18, 12), (20, 10), (14, 14), (19, 14)):
        px[(x, y)] = HAIR_LIGHT
    for x in range(10, 22, 2):
        px[(x, 15)] = HAIR
    for corner in ((9, 4), (22, 4), (9, 14), (22, 14), (9, 13), (22, 13)):  # contorno redondeado
        px.pop(corner, None)
    _rect(px, 12, 5, 18, 7, HAIR)
    for x, y in ((12, 5), (15, 6), (17, 5)):
        px[(x, y)] = HAIR_LIGHT
    return px


def _side_left() -> dict:
    px: dict = {}
    _legs(px, True)
    _rect(px, 11, 19, 20, 31, CARDIGAN)
    _rect(px, 19, 19, 20, 31, CARDIGAN_DARK)
    _rect(px, 11, 30, 20, 31, CARDIGAN_LIGHT)
    _rect(px, 11, 19, 12, 24, SHIRT)  # camisa visible al frente
    _rect(px, 11, 32, 20, 32, BELT)
    # Brazo con la carpeta pegada al cuerpo
    _rect(px, 14, 21, 17, 29, CARDIGAN_DARK)
    _rect(px, 12, 23, 15, 31, FOLDER)
    _rect(px, 12, 23, 12, 31, FOLDER_EDGE)
    _rect(px, 14, 28, 16, 29, SKIN)
    # Cabeza de perfil mirando a la izquierda
    _rect(px, 10, 7, 20, 18, SKIN)
    px[(9, 13)] = SKIN  # nariz
    px[(9, 14)] = SKIN_SHADOW
    _rect(px, 14, 18, 18, 19, SKIN_SHADOW)
    _rect(px, 11, 4, 22, 8, HAIR)
    _rect(px, 16, 8, 21, 14, HAIR)
    for x, y in ((12, 3), (15, 2), (18, 3), (21, 2), (23, 5), (22, 9)):
        px[(x, y)] = HAIR
    _rect(px, 13, 4, 17, 5, HAIR_LIGHT)
    for x in (18, 20):
        _rect(px, x, 9, x, 12, HAIR_DARK)
    _rect(px, 16, 11, 17, 13, SKIN_SHADOW)  # oreja
    _rect(px, 10, 11, 14, 11, GLASSES)  # patilla y lente
    _rect(px, 10, 12, 12, 13, GLASSES)
    px[(11, 12)] = LENS
    px[(12, 12)] = EYE
    _rect(px, 11, 16, 12, 16, SKIN_SHADOW)
    return px


def _render(px: dict) -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for (x, y), color in px.items():
        if 0 <= x < W and 0 <= y < H:
            img.putpixel((x, y), color)
    for (x, y) in list(px):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < W and 0 <= ny < H and (nx, ny) not in px:
                img.putpixel((nx, ny), OUTLINE)
    return img


def direction_sheet() -> Image.Image:
    # Cuadrícula 2×2 como los compañeros: frente, espalda, izquierda, derecha.
    cell = 320
    sheet = Image.new("RGBA", (cell * 2, cell * 2), (0, 0, 0, 0))
    views = [_front(), _back(), _side_left(), _mirror(_side_left())]
    for index, view in enumerate(views):
        figure = _render(view).resize((W * 6, H * 6), Image.NEAREST)
        cx, cy = (index % 2) * cell, (index // 2) * cell
        sheet.alpha_composite(figure, (cx + (cell - figure.width) // 2, cy + (cell - figure.height) // 2))
    return sheet


AVATAR_TRES = """[gd_resource type="AtlasTexture" load_steps=2 format=3]

[ext_resource type="Texture2D" path="res://assets/vn/tutor_v2.png" id="1"]

[resource]
atlas = ExtResource("1")
region = Rect2(262, 40, 500, 500)
"""


def main() -> None:
    direction_sheet().save(ROOT / "assets" / "characters" / "tutor_directions.png")
    (ROOT / "assets" / "portraits" / "tutor_v2.tres").write_text(AVATAR_TRES, encoding="utf-8", newline="\n")
    print("PASS tutor_directions.png, tutor_v2.tres")


if __name__ == "__main__":
    main()
