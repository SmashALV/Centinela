"""Validate the review candidate without treating it as an approved rubric."""

import json
import re
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "narrative"
MAIN = ("D1_02_A", "D1_03_A", "D2_03_A", "D2_04_A", "D3_01_A", "D4_01_A", "D4_02_A", "D4_03_A")
ENDINGS = ("F01_A", "F01_B", "F02", "F03")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def run() -> None:
    candidate = json.loads((DATA / "playable_draft_v0_3.json").read_text(encoding="utf-8"))
    rubric = json.loads((ROOT / "docs" / "historia" / "rubric_candidate_v2.json").read_text(encoding="utf-8"))
    require(candidate["draft_version"] == "PLAYABLE_DRAFT_v0.3" and candidate["provisional"] is True
            and candidate["ready_for_publication"] is False, "Guion candidato marcado como aprobado")
    require(rubric["rubric_version"] == "RUBRIC_CANDIDATE_v2"
            and rubric["narrative_version"] == candidate["draft_version"]
            and rubric["approval_status"] == "pending_expert_and_institutional_review"
            and rubric["ready_for_publication"] is False, "Rúbrica candidata marcada como aprobada")
    require(rubric["scoring_authority"] == "server_only_after_approval"
            and rubric["student_visible_scores"] is False, "Autoridad o visibilidad de puntos inválida")
    scenes = {}
    for path in DATA.glob("*_RECOVERED_PREVIEW.json"):
        for scene in json.loads(path.read_text(encoding="utf-8")).get("scenes", []):
            scenes[scene["scene_id"]] = scene
    authored = candidate["authored_scene"]
    require(authored["scene_id"] == "D2_04_A" and authored["source_status"] == "new_text_pending_editorial_approval",
            "La escena nueva D2-04 carece de procedencia")
    scenes["D2_04_A"] = authored
    private_scene = candidate["d1_private_scene"]
    require(private_scene["scene_id"] == "D1_03_A" and private_scene["day"] == 1 and
            private_scene["source_status"] == "new_text_pending_editorial_approval" and
            len(private_scene["lines"]) >= 6 and not private_scene.get("choices"),
            "La conversación privada D1-03 está incompleta")
    scenes["D1_03_A"] = private_scene
    require(all(scene_id in scenes for scene_id in MAIN + ENDINGS), "Faltan escenas del recorrido")
    require(all(scene_id in candidate["connectors"] for scene_id in MAIN + ENDINGS), "Faltan conectores")
    require(set(candidate["day_introductions"]) == {"D1_02_A", "D2_03_A", "D3_01_A", "D4_01_A"} and
            all(len(lines) == 2 and all(lines) for lines in candidate["day_introductions"].values()),
            "Presentaciones diarias incompletas")
    for scene_id in MAIN:
        if scene_id == "D1_03_A":
            continue
        require(len(scenes[scene_id]["choices"]) == 3 and
                [choice["key"] for choice in scenes[scene_id]["choices"]] == ["A", "B", "C"],
                "Opciones incompletas en " + scene_id)
        require(all(candidate["choice_reactions"][scene_id][key] for key in "ABC"),
                "Reacciones incompletas en " + scene_id)
    recovered_d3 = scenes["D3_01_A"]["unplaced_lines"]
    require({item["text"] for item in candidate["d3_opening_by_d2_choice"].values()} ==
            {item["text"] for item in recovered_d3}, "Una variante recuperada de D3 fue modificada")
    require(all(candidate["ending_tail"][scene_id] for scene_id in ENDINGS), "Cierre sin texto")
    require(set(rubric["non_evaluable_scenes"]) == {"D0_05_A", "D1_02_A", "D1_03_A"}, "Escenas sociales evaluadas")

    expected_evaluable = set(MAIN) - {"D1_02_A", "D1_03_A"}
    require({item["scene_id"] for item in rubric["decisions"]} == expected_evaluable,
            "Cobertura de decisiones incompleta")
    dimensions = {"D1", "D2", "D3", "D4"}
    require(set(rubric["dimensions"]) == dimensions, "Dimensiones inválidas")
    decision_ids = set()
    choice_ids = set()
    dimension_counts = Counter()
    for item in rubric["decisions"]:
        scene_id = item["scene_id"]
        decision_id = item["decision_id"]
        client_ids = candidate["educational_ids"].get(scene_id, {})
        require(client_ids.get("decision_id") == decision_id and
                client_ids.get("choices") == {choice["key"]: choice["choice_id"] for choice in item["choices"]},
                "IDs de cliente y rúbrica divergen: " + scene_id)
        require(re.fullmatch(r"[A-Za-z0-9_.-]{1,80}", decision_id) and decision_id not in decision_ids,
                "ID de decisión inválido o repetido: " + decision_id)
        decision_ids.add(decision_id)
        require(item["day"] == scenes[scene_id]["day"] and item["dimension"] in dimensions,
                "Día o dimensión incorrecta: " + scene_id)
        dimension_counts[item["dimension"]] += 1
        source_choices = {choice["key"]: choice["text"] for choice in scenes[scene_id]["choices"]}
        require([choice["key"] for choice in item["choices"]] == ["A", "B", "C"],
                "Matriz A/B/C incompleta: " + scene_id)
        for choice in item["choices"]:
            choice_id = choice["choice_id"]
            require(re.fullmatch(r"[A-Za-z0-9_.-]{1,80}", choice_id) and
                    choice_id == decision_id + "." + choice["key"] and choice_id not in choice_ids,
                    "ID de opción inválido o repetido: " + choice_id)
            choice_ids.add(choice_id)
            require(choice["text"] == source_choices[choice["key"]], "Texto de opción alterado: " + choice_id)
            require(choice["points"] in (0, 1, 2) and choice["reason"], "Puntaje sin razón: " + choice_id)
    require(dict(dimension_counts) == rubric["required_items_by_dimension"],
            "Cobertura de dimensiones y requisitos divergen")
    require(len(decision_ids) == 6 and len(choice_ids) == 18, "Cantidad de IDs inesperada")
    require(set(candidate["educational_ids"]) == expected_evaluable, "El cliente expone IDs incompletos")
    require(set(rubric["score_exclusions"]) >= {"ending", "moba_result", "moba_class", "duration"},
            "Un dato no educativo podría afectar el puntaje")

    triggers = candidate["flag_triggers"]
    require(set(triggers) == {"CONFIANZA_MATEO_SOFI", "RECONOCE_MANIPULACION"}, "Banderas narrativas inválidas")
    for entries in triggers.values():
        for entry in entries:
            scene_id, key = entry.split(":")
            require(scene_id in MAIN and key in "ABC", "Activador inválido: " + entry)
    rules = candidate["ending_rules"]
    require(len(rules) == 5 and {(r["choice"], r["requires_both_flags"], r["scene"]) for r in rules} == {
        ("A", False, "F01_A"), ("B", True, "F01_A"), ("B", False, "F02"),
        ("C", True, "F01_A"), ("C", False, "F03")}, "Tabla de finales incompleta")
    print("PASS guion candidato: 8 escenas principales, 4 extractos finales, 5 condiciones")
    print("PASS rúbrica candidata: 6 decisiones, 18 opciones, 4 dimensiones; publicación bloqueada")


if __name__ == "__main__":
    run()
