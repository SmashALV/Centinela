"""Check that the playable D0 preview copies the supplied recovered text verbatim."""

import json
import re
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/historia/recovered/Guion_Literal_Recuperado_Ampliado_D0_D4_v0_2.md"
PREVIEW = ROOT / "data/narrative/day_0_RECOVERED_PREVIEW.json"


def section(text: str, heading: str) -> str:
    return text.split(heading, 1)[1].split("\n## ", 1)[0]


def literal_lines(block: str) -> list[tuple[str, str]]:
    return re.findall(r"^- (Sofi|Camila|Mateo|Bruno|Sebas): «([^»]+)»", block, re.MULTILINE)


def check() -> None:
    source = SOURCE.read_text(encoding="utf-8")
    data = json.loads(PREVIEW.read_text(encoding="utf-8"))
    nodes = data["nodes"]

    for heading, start, end in (
        ("## Día 0 — Despertar", 0, 3),
        ("## Día 0 — Patio del colegio (D0-03-A)", 3, 14),
        ("## Día 0 — Chat «Los chicos» (D0-05-A)", 14, 19),
    ):
        expected = literal_lines(section(source, heading))
        actual = [(node["speaker"], node["text"]) for node in nodes[start:end]]
        assert actual == expected, f"Texto alterado en {heading}"

    chat = section(source, "## Día 0 — Chat «Los chicos» (D0-05-A)")
    choices = re.findall(r"^- ([ABC]): «([^»]+)»", chat, re.MULTILINE)
    assert len(choices) == 3
    for index, (letter, text) in enumerate(choices):
        choice = nodes[19]["choices"][index]
        assert choice["choice_id"] == f"D0_05_A_OPT_{letter}"
        assert choice["text"] == text
        assert nodes[choice["next"]]["text"] == text

    assert data["provisional"] is True and data["ready_for_publication"] is False
    print("PASS: texto recuperado del Día 0 coincide con la fuente; vista previa no publicable")

    sys.path.insert(0, str(ROOT))
    from scripts import build_recovered_previews

    with tempfile.TemporaryDirectory() as temporary:
        build_recovered_previews.OUT = Path(temporary)
        build_recovered_previews.build()
        expected_files = (
            "day_1_RECOVERED_PREVIEW.json",
            "day_2_RECOVERED_PREVIEW.json",
            "day_3_RECOVERED_PREVIEW.json",
            "day_4_RECOVERED_PREVIEW.json",
            "endings_RECOVERED_PREVIEW.json",
        )
        for filename in expected_files:
            generated = (Path(temporary) / filename).read_bytes()
            stored = (ROOT / "data/narrative" / filename).read_bytes()
            assert generated == stored, f"El fragmento {filename} difiere de la fuente recuperada"
            payload = json.loads(stored)
            assert payload["provisional"] is True
            assert payload["ready_for_publication"] is False
            for scene in payload["scenes"]:
                assert not {"score", "points", "predicate", "next", "decision_id"}.intersection(scene)
                for option in scene.get("choices", []):
                    assert set(option) == {"key", "text"}
    print("PASS: D1–D4 y finales coinciden con la fuente; sin puntuación ni destinos inventados")


if __name__ == "__main__":
    check()
