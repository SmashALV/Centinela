"""Genera el recorte de avatar del profesor tutor.

La ilustración de novela visual (`assets/vn/tutor_v2.png`) y la hoja de mapa en
cuatro vistas (`assets/characters/tutor_directions.png`) son arte entregado por el
equipo; este script ya no las modifica.

Uso: python scripts/generate_tutor_assets.py
"""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

AVATAR_TRES = """[gd_resource type="AtlasTexture" load_steps=2 format=3]

[ext_resource type="Texture2D" path="res://assets/vn/tutor_v2.png" id="1"]

[resource]
atlas = ExtResource("1")
region = Rect2(262, 40, 500, 500)
"""


def main() -> None:
    (ROOT / "assets" / "portraits" / "tutor_v2.tres").write_text(AVATAR_TRES, encoding="utf-8", newline="\n")
    print("PASS tutor_v2.tres")


if __name__ == "__main__":
    main()
