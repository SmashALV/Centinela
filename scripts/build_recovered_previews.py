"""Transcribe recovered D1-D4 and ending excerpts into non-canonical preview JSON."""

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/recovered/Guion_Literal_Recuperado_Ampliado_D0_D4_v0_2.md"
OUT = ROOT / "data/narrative"
VERSION = "RECOVERED_PREVIEW_D0_D4_v0.2"


def between(source: str, start: str, end: str) -> str:
    if start not in source or end not in source.split(start, 1)[1]:
        raise ValueError(f"Missing source boundary: {start} / {end}")
    return source.split(start, 1)[1].split(end, 1)[0]


def lines(text: str) -> list[dict[str, str]]:
    return [{"speaker": speaker.strip(), "text": dialogue}
            for speaker, dialogue in re.findall(r"^- ([^:\n]+): «([^»]+)»", text, re.MULTILINE)]


def options(text: str) -> list[dict[str, str]]:
    plain = re.findall(r"^- ([ABC]): «([^»]+)»", text, re.MULTILINE)
    bold = re.findall(r"^- \*\*([ABC]):\*\* «([^»]+)»", text, re.MULTILINE)
    found = plain or bold
    if [key for key, _ in found] != ["A", "B", "C"]:
        raise ValueError("Expected three literal options A/B/C")
    return [{"key": key, "text": dialogue} for key, dialogue in found]


def scene(scene_id: str, title: str, day: int | None, main: list[dict[str, str]],
          choices: list[dict[str, str]] | None = None,
          after_choice: list[dict[str, str]] | None = None,
          unplaced: list[dict[str, str]] | None = None,
          later_chat: list[dict[str, str]] | None = None) -> dict:
    if not main:
        raise ValueError(f"No literal lines: {scene_id}")
    result = {"scene_id": scene_id, "title": title, "day": day, "lines": main}
    if choices:
        result["choices"] = choices
    if after_choice:
        result["after_choice"] = after_choice
    if unplaced:
        result["unplaced_lines"] = unplaced
    if later_chat:
        result["later_chat"] = later_chat
    return result


def pack(scenes: list[dict], filename: str) -> None:
    payload = {"schema_version": 1, "preview_version": VERSION, "provisional": True,
               "ready_for_publication": False, "source_document": SOURCE.name,
               "scenes": scenes}
    (OUT / filename).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def build() -> None:
    source = SOURCE.read_text(encoding="utf-8")
    d1 = between(source, "## Día 1 — Presentación de Kairo en lobby (D1-02-A)", "## Día 2 —")
    d2 = between(source, "## Día 2 — Regalo de skin; Mateo muestra su celular (D2-03-A)", "## Día 3 —")
    d3 = between(source, "## Día 3 — Presión emocional y secreto (D3-01-A)", "## Día 4 —")
    d4a = between(source, "## Día 4 — Propuesta de encuentro, conversación en patio (D4-01-A)", "## Día 4 — D4-02-A")
    d4b = between(source, "## Día 4 — D4-02-A «Estoy contigo»", "## Día 4 — D4-03-A")
    d4c = between(source, "## Día 4 — D4-03-A «¿Qué hacemos ahora?»", "## Final F01")
    f01a = between(source, "### F01-A — Conversación con el tutor", "### F01-B")
    f01b = between(source, "### F01-B — Conversación con la madre de Mateo", "## Final F02")
    f02 = between(source, "## Final F02 — «Hasta aquí» (intermedio)", "## Final F03")
    f03 = between(source, "## Final F03 — «Esto todavía no termina» (no resuelto)", "## Identificadores")

    pack([scene("D1_02_A", "Presentación de Kairo en lobby", 1,
                lines(d1.split("**Opciones de Sofi:**", 1)[0]), options(d1),
                unplaced=lines(between(d1, "**Otras líneas recuperadas de despedida, sin reconstruir los conectores:**", "**Falta:**")))],
         "day_1_RECOVERED_PREVIEW.json")
    pack([scene("D2_03_A", "Regalo de skin", 2,
                lines(d2.split("**Opciones de Sofi:**", 1)[0]), options(d2),
                after_choice=lines(between(d2, "**Continuación recuperada:**", "**Falta:**")))],
         "day_2_RECOVERED_PREVIEW.json")
    pack([scene("D3_01_A", "Presión emocional y secreto", 3,
                lines(d3.split("**Opciones de Sofi:**", 1)[0]), options(d3),
                unplaced=lines(between(d3, "**Variantes textuales adicionales recuperadas (no se reconstruye aquí su predicado narrativo):**", "**Falta:**")))],
         "day_3_RECOVERED_PREVIEW.json")
    pack([
        scene("D4_01_A", "Propuesta de encuentro", 4,
              lines(d4a.split("**Orden cotejado", 1)[0]), options(d4a)),
        scene("D4_02_A", "Estoy contigo", 4,
              lines(between(d4b, "**Diálogo literal recuperado:**", "**Opciones literales recuperadas de Sofi:**")),
              options(d4b)),
        scene("D4_03_A", "¿Qué hacemos ahora?", 4,
              lines(between(d4c, "**Diálogo literal recuperado:**", "**Opciones literales recuperadas de Sofi:**")),
              options(d4c)),
    ], "day_4_RECOVERED_PREVIEW.json")
    pack([
        scene("F01_A", "F01 · tutor", None, lines(f01a)),
        scene("F01_B", "F01 · madre de Mateo", None,
              lines(f01b.split("**Recuperado como resumen", 1)[0])),
        scene("F02", "F02 · Hasta aquí", None,
              lines(f02.split("**Acciones confirmadas", 1)[0])),
        scene("F03", "F03 · Esto todavía no termina", None,
              lines(f03.split("**Traslado narrativo aprobado:**", 1)[0]),
              later_chat=lines(between(f03, "**Mensajes literales adicionales recuperados (no se conoce si había burbujas intercaladas):**", "**No recuperado:**"))),
    ], "endings_RECOVERED_PREVIEW.json")


if __name__ == "__main__":
    build()
