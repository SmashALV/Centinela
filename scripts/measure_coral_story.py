"""Count words presented on each D1–D4 story path; no play-time claim."""

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NARRATIVE = ROOT / "data" / "narrative"
CORAL = json.loads((NARRATIVE / "coral_story_v0_1.json").read_text(encoding="utf-8"))
DRAFT = json.loads((NARRATIVE / "playable_draft_v0_3.json").read_text(encoding="utf-8"))
RECOVERED = {}
for day in (1, 2, 3, 4):
    data = json.loads((NARRATIVE / f"day_{day}_RECOVERED_PREVIEW.json").read_text(encoding="utf-8"))
    RECOVERED.update({scene["scene_id"]: scene for scene in data["scenes"]})


def words(text):
    return len(re.findall(r"\b\w+\b", text, flags=re.UNICODE))


def line_words(lines):
    return sum(words(str(line.get("text", ""))) for line in lines)


def scene_words(scene_id, choice=""):
    scene = CORAL["scenes"][scene_id]
    lines = list(scene.get("lines", []))
    for source in scene.get("source_scenes", []):
        original = DRAFT["authored_scene"] if source == "D2_04_A" else DRAFT["d1_private_scene"] if source == "D1_03_A" else RECOVERED[source]
        lines += original["lines"]
    total = line_words(lines)
    total += sum(words(option["text"]) for option in scene.get("choices", []))
    if choice:
        total += line_words([CORAL["reactions"][scene_id][choice]])
    return total


def path_words(route, d2_choice, ending, d4_choice="A"):
    branch = route + ("1" if d2_choice == "A" else "2")
    total = sum(sum(words(line) for line in intro) for intro in CORAL["day_intros"].values())
    for actor in ("D1_CAMILA", "D1_MATEO"):
        total += sum(words(line) for line in CORAL["interactions"][actor]["lines"])
    for scene_id, choice in (("D1_GATE", route), (f"D1_{route}_FOLLOW", ""),
                             (f"D2_{route}", d2_choice), (f"D3_{branch}", ""),
                             (f"D4_{branch}", d4_choice)):
        total += scene_words(scene_id, choice)
    total += words(CORAL["narrator_after_d2"][route])
    total += line_words(CORAL["ending_lines"][ending])
    total += line_words(CORAL["epilogue_by_route"][route])
    total += line_words([CORAL["epilogue_by_branch"][branch]])
    if branch.endswith("2"):
        total += line_words([CORAL["repair_epilogue"]])
    if ending == "F01":
        total += sum(words(line) for line in CORAL["interactions"]["TUTOR"]["lines"])
    elif ending == "F02":
        total += sum(words(line) for line in CORAL["interactions"]["LIMIT"]["lines"])
    return total


if __name__ == "__main__":
    for route in "ABC":
        for choice in "AB":
            for d4_choice in "AB":
                for ending in ("F01", "F02", "F03"):
                    print(f"{route}{choice} D4:{d4_choice} {ending}: {path_words(route, choice, ending, d4_choice)} palabras D1–D4")
