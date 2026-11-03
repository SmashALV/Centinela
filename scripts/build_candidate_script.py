"""Render the review script from literal recovered JSON and authored v0.3 data."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "narrative"
OUTPUT = ROOT / "docs" / "historia" / "GUION_EDITORIAL_CANDIDATO_v2.md"
MAIN_ORDER = ("D1_02_A", "D1_03_A", "D2_03_A", "D2_04_A", "D3_01_A", "D4_01_A", "D4_02_A", "D4_03_A")
ENDING_ORDER = ("F01_A", "F01_B", "F02", "F03")


def loaded(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def gd_constant(name: str, following: str) -> object:
    source = (ROOT / "scripts" / "Main.gd").read_text(encoding="utf-8")
    match = re.search(rf"const {name} := (.*?)\nconst {following}", source, re.S)
    if not match:
        raise ValueError(f"No se encontró {name}")
    return json.loads(match.group(1))


def lines(items: list[dict], provenance: str) -> list[str]:
    return [f"- **{item['speaker']}**: «{item['text']}» [{provenance}]" for item in items]


def render() -> str:
    draft = loaded(DATA / "playable_draft_v0_3.json")
    rubric = loaded(ROOT / "docs" / "historia" / "rubric_candidate_v2.json")
    recovered = {}
    for path in DATA.glob("*_RECOVERED_PREVIEW.json"):
        for scene in loaded(path).get("scenes", []):
            recovered[scene["scene_id"]] = scene
    recovered["D2_04_A"] = draft["authored_scene"]
    recovered["D1_03_A"] = draft["d1_private_scene"]
    d0 = loaded(DATA / "day_0_RECOVERED_PREVIEW.json")["nodes"]
    prologue = gd_constant("PROLOGUE_LINES", "PORTRAITS")
    d0_reactions = gd_constant("D0_CHAT_REACTIONS", "UI_ICONS")
    rubric_by_scene = {item["scene_id"]: item for item in rubric["decisions"]}

    out = [
        "# Guion integral y rúbrica para revisión · candidato v2",
        "",
        "**Estado:** propuesta completa redactada a partir de los fragmentos recuperados y los conectores creados para el juego. Pendiente de aprobación editorial, académica e institucional. `ready_for_publication: false`.",
        "",
        "**Leyenda:** [R] texto literal recuperado; [N] texto nuevo redactado para cerrar la ruta. Las etiquetas son de procedencia y no aparecen en el juego. Los nombres de escena e IDs se proponen estables desde esta versión, pero todavía no son históricos ni aprobados externamente.",
        "",
        "## Día 0 · Sofi y el grupo",
        "",
        "### Prólogo del narrador",
        "",
        *[f"- **Narrador**: «{line}» [N]" for line in prologue],
        "",
        "### Despertar",
        "",
        *lines(d0[:3], "R"),
        "",
        "### Patio del colegio",
        "",
        *lines(d0[3:14], "R"),
        "",
        "### Chat Los chicos",
        "",
        *lines(d0[14:19], "R"),
        "",
        "**Respuestas de Sofi (sociales, no evaluables):**",
        "",
    ]
    for index, choice in enumerate(d0[19]["choices"]):
        key = "ABC"[index]
        reaction = d0_reactions[choice["choice_id"]]
        out.append(f"- **{key}. Sofi**: «{choice['text']}» [R] → **{reaction['speaker']}**: «{reaction['text']}» [N]")
    out += ["", "### Resultado del MOBA · reacción de Camila", ""]
    for result, roles in draft["camila_reactions"].items():
        for role, text in roles.items():
            out.append(f"- **{result.capitalize()} / {role} — Camila**: «{text}» [N]")
    out += ["", "### Interludio al Día 1", "", f"- **Narrador**: «{draft['connectors']['D1_02_A']}» [N]", ""]

    for scene_id in MAIN_ORDER:
        scene = recovered[scene_id]
        provenance = "N" if scene_id in ("D1_03_A", "D2_04_A") else "R"
        out += [f"## Día {scene['day']} · {scene['title']} ({scene_id})", ""]
        if scene_id in draft["day_introductions"]:
            out += ["**Presentación del día por el narrador (antes de explorar):**", ""]
            out += [f"- **Narrador**: «{line}» [N]" for line in draft["day_introductions"][scene_id]]
            out.append("")
        if scene_id != "D1_02_A":
            out += [f"- **Narrador**: «{draft['connectors'][scene_id]}» [N]", ""]
        if scene_id in ("D1_03_A", "D2_03_A"):
            out += ["*En el juego se presenta como mensaje directo entre Sofi y Mateo; el intercambio con Kairo de D2-03 aparece dentro de una captura compartida por Mateo.*", ""]
        if scene_id == "D3_01_A":
            out += lines(scene["lines"][:2], provenance) + [""]
            out += ["**Variante previa de Mateo según D2-04 (una sola):**", ""]
            for key, item in draft["d3_opening_by_d2_choice"].items():
                out.append(f"- Tras **{key}**: «{item['text']}» [R; posición reconstruida después de la segunda línea]")
            out.append("")
            out += lines(scene["lines"][2:], provenance)
        else:
            out += lines(scene["lines"], provenance)
        if scene.get("choices"):
            out += ["", "**Decisión de Sofi:**", ""]
            rubric_item = rubric_by_scene.get(scene_id)
            for choice in scene["choices"]:
                key = choice["key"]
                reaction = draft["choice_reactions"][scene_id][key]
                if rubric_item:
                    rated = next(item for item in rubric_item["choices"] if item["key"] == key)
                    identity = f"`{rated['choice_id']}` · {rubric_item['dimension']} · {rated['points']}/2 propuestos"
                else:
                    identity = "social, sin puntuación"
                out.append(f"- **{key}.** «{choice['text']}» [{provenance}; {identity}] → **Mateo**: «{reaction}» [N]")
        if scene_id == "D1_02_A":
            out += ["", "**Despedida (posición reconstruida):**", "", *lines(draft["d1_after_choice"], "R")]
        elif scene.get("after_choice"):
            out += ["", "**Continuación:**", "", *lines(scene["after_choice"], provenance)]
        out.append("")

    out += [
        "## Condiciones de los finales",
        "",
        "Las banderas comienzan en `false` y, una vez activadas, permanecen en `true`. Se derivan de las elecciones guardadas, sin sumar puntos educativos.",
        "",
    ]
    for flag, triggers in draft["flag_triggers"].items():
        out.append(f"- `{flag}` se activa con: {', '.join('`' + item + '`' for item in triggers)}.")
    out += [
        "",
        "| D4-03 | Condición previa | Final |",
        "|---|---|---|",
        "| A | Cualquier estado | F01 |",
        "| B | Ambas banderas activas | F01, por iniciativa de Mateo |",
        "| B | Falta alguna bandera | F02 |",
        "| C | Ambas banderas activas | F01, por iniciativa de Mateo |",
        "| C | Falta alguna bandera | F03 |",
        "",
        "El final es descriptivo; no modifica el puntaje. Ninguna ruta representa un encuentro físico con Kairo.",
        "",
        "## Finales",
        "",
    ]
    for scene_id in ENDING_ORDER:
        scene = recovered[scene_id]
        out += [f"### {scene['title']} ({scene_id})", ""]
        if scene_id == "F01_A":
            out += [f"- **Narrador, entrada A**: «{draft['f01_context']['direct']}» [N]",
                    f"- **Narrador, entrada B/C con ambas banderas**: «{draft['f01_context']['mateo_initiative']}» [N]", ""]
        else:
            out += [f"- **Narrador**: «{draft['connectors'][scene_id]}» [N]", ""]
        out += lines(scene["lines"], "R")
        if scene.get("later_chat"):
            out += ["", "**Chat posterior y pensamiento (orden recuperado):**", "", *lines(scene["later_chat"], "R")]
        out += ["", "**Cierre redactado para esta versión:**", "", *lines(draft["ending_tail"][scene_id], "N"), ""]

    out += [
        "## Matriz educativa propuesta",
        "",
        "D0-05 y D1-02 son decisiones sociales no evaluables; D1-03 tampoco puntúa. Las seis decisiones restantes suman 18 alternativas. El archivo [rubric_candidate_v2.json](rubric_candidate_v2.json) conserva texto, `decision_id`, `choice_id`, dimensión, puntaje y razón por opción. D1: reconocimiento de señales; D2: manipulación emocional; D3: privacidad y límites; D4: apoyo adulto. Cobertura requerida: D1=1, D2=1, D3=2, D4=2.",
        "",
        "Los puntos describen respuestas de Sofi en la ficción, no a la persona que juega ni a una víctima. La puntuación solo podrá calcularla el servidor después de validar y desplegar una rúbrica aprobada; el final, MOBA, tiempo y pistas quedan fuera.",
        "",
        "## Procedencia y revisión pendiente",
        "",
        "El texto [R] procede de `data/narrative/*_RECOVERED_PREVIEW.json` y se coteja con la transcripción entregada mediante `tests/verify_recovered_script.py`. El texto [N] reside en `scripts/Main.gd` o `data/narrative/playable_draft_v0_3.json`. Las condiciones de final y los dos nombres de bandera siguen la recuperación secundaria del ZIP; los puntos y los IDs estables son propuestas nuevas. Requieren cotejo editorial y juicio experto antes de publicación o uso en investigación.",
        "",
        "Referencias de seguridad para la redacción (no validan la puntuación): [Ministerio Público del Perú](https://www.gob.pe/35878-el-online-grooming), [PCM del Perú](https://www.gob.pe/12799-recomendaciones-de-uso-seguro-de-internet-para-menores-de-edad) y [eSafety Commissioner](https://www.esafety.gov.au/parents/issues-and-advice/grooming-or-unwanted-contact).",
        "",
    ]
    return "\n".join(out)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    document = render()
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_text(encoding="utf-8") != document:
            raise SystemExit("El guion editorial no coincide con los datos ejecutables; regenera el archivo")
        print("PASS guion editorial sincronizado")
    else:
        OUTPUT.write_text(document, encoding="utf-8")
        print(OUTPUT)


if __name__ == "__main__":
    main()
