"""Package and verify a traceable Centinela Web build without deployment credentials."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GAME_EXPORT = ROOT / "build" / "web"
GAME_REQUIRED = ("index.html", "index.js", "index.pck", "index.wasm")
DASHBOARD_FILES = ("index.html", "app.mjs", "export.mjs", "styles.css", "config.json")
CANONICAL_FILES = tuple(f"data/narrative/day_{day}.json" for day in range(5)) + (
    "data/narrative/endings.json",
)
SOURCE_FILES = (
    "project.godot", "export_presets.cfg", "package-lock.json", "scripts/release.py",
    "scripts/generate_audio.py", ".github/workflows/quality.yml",
    "web/backend_config.json", "dashboard/config.json",
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def gd_constant(source: str, name: str) -> str:
    match = re.search(rf'^const {re.escape(name)} := (?:"([^"]+)"|(\d+))', source, re.M)
    if not match:
        raise ValueError(f"No se encontró {name} en GameState.gd")
    return match.group(1) or match.group(2)


def metadata() -> dict:
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    version = re.search(r'^config/version="([^"]+)"', project, re.M)
    if not version:
        raise ValueError("project.godot no declara config/version")
    state = (ROOT / "scripts/GameState.gd").read_text(encoding="utf-8")
    game_config = json.loads((ROOT / "web/backend_config.json").read_text(encoding="utf-8"))
    return {
        "game_version": version.group(1),
        "save_schema_version": int(gd_constant(state, "SCHEMA_VERSION")),
        "narrative_version": gd_constant(state, "NARRATIVE_VERSION"),
        "preview_pack_version": gd_constant(state, "PREVIEW_PACK_VERSION"),
        "draft_content_version": gd_constant(state, "DRAFT_CONTENT_VERSION"),
        "rubric_version": game_config.get("rubric_version", ""),
    }


def release_guard(channel: str) -> dict:
    info = metadata()
    errors = []
    if channel in ("staging", "production"):
        if "preview" in info["game_version"].lower():
            errors.append("la versión del juego sigue marcada como preview")
        if info["narrative_version"].startswith(("provisional", "TEST_ONLY")):
            errors.append("la versión narrativa sigue siendo provisional")
        if info["rubric_version"].startswith("TEST_ONLY") or not info["rubric_version"]:
            errors.append("la rúbrica aprobada no está configurada")
        game_config = json.loads((ROOT / "web/backend_config.json").read_text(encoding="utf-8"))
        admin_config = json.loads((ROOT / "dashboard/config.json").read_text(encoding="utf-8"))
        for name, config in (("juego", game_config), ("dashboard", admin_config)):
            if config.get("enabled") is not True or not str(config.get("url", "")).startswith("https://"):
                errors.append(f"{name}: backend HTTPS no habilitado")
            if not str(config.get("public_key", "")).startswith("sb_publishable_"):
                errors.append(f"{name}: falta clave publicable")
        if game_config.get("url") != admin_config.get("url") or game_config.get("rubric_version") != admin_config.get("rubric_version"):
            errors.append("juego y dashboard declaran backend o rúbrica diferentes")
        if "foubkxlhlqxeaywzpebp.supabase.co" in str(game_config.get("url", "")):
            errors.append("staging/producción no puede reutilizar el proyecto Supabase de desarrollo")
        main = (ROOT / "scripts/Main.gd").read_text(encoding="utf-8")
        if "DAY_0_PREVIEW" in main or "RecoveredPreviewCatalog" in main:
            errors.append("el recorrido jugable aún usa la vista previa recuperada")
        if "PlayableDraftFlow" in main:
            errors.append("el recorrido jugable aún usa conectores y desenlaces de borrador")
        for relative in CANONICAL_FILES:
            path = ROOT / relative
            if not path.is_file():
                errors.append(f"falta {relative}")
                continue
            try:
                content = json.loads(path.read_text(encoding="utf-8"))
                if content.get("ready_for_publication") is not True or content.get("provisional") is not False:
                    errors.append(f"{relative} no está aprobado para publicación")
            except (OSError, ValueError):
                errors.append(f"{relative} no es JSON válido")
    if channel == "production":
        errors.append("producción requiere promoción manual desde staging y aprobación humana")
    if errors:
        raise ValueError("Guardia de release:\n- " + "\n- ".join(errors))
    return info


def source_hashes() -> dict[str, str]:
    paths = [ROOT / item for item in SOURCE_FILES]
    paths += sorted((ROOT / "scripts").rglob("*.gd"))
    paths += sorted((ROOT / "scenes").rglob("*.tscn"))
    paths += sorted((ROOT / "web").glob("*.js"))
    paths += sorted((ROOT / "supabase/migrations").glob("*.sql"))
    paths += sorted((ROOT / "supabase/functions").rglob("*.ts"))
    paths += sorted((ROOT / "data/narrative").glob("*.json"))
    paths += sorted((ROOT / "assets/audio").glob("*.wav*"))
    paths += sorted((ROOT / "assets").rglob("*.png*"))
    paths.append(ROOT / "icon.svg")
    return {path.relative_to(ROOT).as_posix(): sha256(path) for path in paths}


def export_inputs() -> list[Path]:
    paths = [ROOT / "project.godot", ROOT / "export_presets.cfg", ROOT / "icon.svg"]
    for folder, pattern in (("scripts", "*.gd"), ("scenes", "*.tscn"),
                            ("data/narrative", "*.json"), ("web", "*.js")):
        paths += list((ROOT / folder).rglob(pattern))
    paths.append(ROOT / "web/backend_config.json")
    paths += list((ROOT / "assets/audio").glob("*.wav*"))
    paths += list((ROOT / "assets").rglob("*.png*"))
    return paths


def assert_fresh_export() -> None:
    export = GAME_EXPORT / "index.pck"
    if not export.is_file():
        raise ValueError(f"Falta exportar Web: {export}")
    newest = max(export_inputs(), key=lambda path: path.stat().st_mtime_ns)
    if export.stat().st_mtime_ns < newest.stat().st_mtime_ns:
        raise ValueError(f"La exportación Web es anterior a {newest.relative_to(ROOT)}; vuelve a exportar")


def revision() -> str | None:
    try:
        result = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, capture_output=True, text=True, check=False)
    except FileNotFoundError:
        return None
    return result.stdout.strip() if result.returncode == 0 else None


def package(channel: str, output: Path) -> Path:
    info = release_guard(channel)
    build_root = (ROOT / "build").resolve()
    if ROOT.resolve() not in build_root.parents or output == build_root or build_root not in output.parents:
        raise ValueError("El paquete debe estar en un subdirectorio de build/")
    if output.exists():
        raise ValueError(f"El destino ya existe: {output}")
    for name in GAME_REQUIRED:
        if not (GAME_EXPORT / name).is_file():
            raise ValueError(f"Falta exportar Web: {GAME_EXPORT / name}")
    assert_fresh_export()
    output.mkdir(parents=True)
    try:
        game_files = sorted(path for path in GAME_EXPORT.glob("index.*") if path.is_file() and not path.name.endswith(".import"))
        (output / "game").mkdir()
        for source in game_files:
            shutil.copy2(source, output / "game" / source.name)
        for name in DASHBOARD_FILES:
            target = output / "dashboard" / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / "dashboard" / name, target)
        files = {}
        for path in sorted(output.rglob("*")):
            if path.is_file():
                files[path.relative_to(output).as_posix()] = {"sha256": sha256(path), "bytes": path.stat().st_size}
        manifest = {"format_version": 1, "channel": channel, **info,
                    "source_revision": revision(), "source_sha256": source_hashes(), "files": files}
        (output / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
        verify(output)
    except BaseException:
        shutil.rmtree(output)
        raise
    return output


def verify(folder: Path) -> dict:
    manifest = json.loads((folder / "manifest.json").read_text(encoding="utf-8"))
    if manifest.get("format_version") != 1:
        raise ValueError("Formato de manifiesto incompatible")
    actual = {path.relative_to(folder).as_posix() for path in folder.rglob("*") if path.is_file() and path.name != "manifest.json"}
    expected = set(manifest.get("files", {}))
    if actual != expected:
        raise ValueError(f"Archivos distintos al manifiesto: faltan {expected - actual}; sobran {actual - expected}")
    for relative, record in manifest["files"].items():
        if Path(relative).is_absolute() or ".." in Path(relative).parts:
            raise ValueError(f"Ruta inválida en manifiesto: {relative}")
        path = folder / relative
        if sha256(path) != record["sha256"] or path.stat().st_size != record["bytes"]:
            raise ValueError(f"Hash o tamaño diferente: {relative}")
    return manifest


def rollback_check(current: Path, previous: Path) -> None:
    current_manifest = verify(current)
    previous_manifest = verify(previous)
    for field in ("save_schema_version", "narrative_version", "rubric_version"):
        if current_manifest[field] != previous_manifest[field]:
            raise ValueError(f"Rollback bloqueado: {field} difiere")
    safety_files = {"scripts/GameState.gd", "scripts/SaveManager.gd",
                    "web/centinela_storage.js", "web/centinela_sync.js"}
    comparable = lambda data: {key: value for key, value in data["source_sha256"].items()
                               if key.startswith(("supabase/migrations/", "data/narrative/")) or key in safety_files}
    if comparable(current_manifest) != comparable(previous_manifest):
        raise ValueError("Rollback bloqueado: persistencia, migraciones o contenido narrativo difieren")
    print("Rollback de cliente elegible para ensayo en staging; comprobar guardados reales antes de promover.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    check = commands.add_parser("check")
    check.add_argument("--channel", choices=("preview", "staging", "production"), required=True)
    pack = commands.add_parser("package")
    pack.add_argument("--channel", choices=("preview", "staging", "production"), required=True)
    pack.add_argument("--output", type=Path, required=True)
    validation = commands.add_parser("verify")
    validation.add_argument("folder", type=Path)
    rollback = commands.add_parser("rollback-check")
    rollback.add_argument("--current", type=Path, required=True)
    rollback.add_argument("--previous", type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.command == "check":
            print(f"PASS {args.channel}: {release_guard(args.channel)}")
        elif args.command == "package":
            print(f"Paquete verificado: {package(args.channel, args.output.resolve())}")
        elif args.command == "verify":
            print(f"PASS manifiesto: {verify(args.folder.resolve())['game_version']}")
        else:
            rollback_check(args.current.resolve(), args.previous.resolve())
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as error:
        print(error, file=sys.stderr)
        raise SystemExit(1) from error


if __name__ == "__main__":
    main()
