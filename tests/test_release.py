"""Release integrity and publication guards."""

import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scripts import release


class ReleaseTests(unittest.TestCase):
    def test_portraits_are_tracked_as_export_inputs(self):
        expected = {f"assets/portraits/{name}_neutral.png{suffix}" for name in
                    ("sofi", "mateo", "bruno", "camila", "sebas")
                    for suffix in ("", ".import")}
        self.assertTrue(expected.issubset(release.source_hashes()))
        inputs = {path.relative_to(release.ROOT).as_posix() for path in release.export_inputs()}
        self.assertTrue(expected.issubset(inputs))

    def test_generated_world_maps_are_tracked(self):
        names = ("day1_lobby_generated", "day2_school_exterior_generated",
                 "day3_corridor_generated", "day4_courtyard_generated")
        expected = {f"assets/world/{name}.png" for name in names}
        self.assertTrue(expected.issubset(release.source_hashes()))
        inputs = {path.relative_to(release.ROOT).as_posix() for path in release.export_inputs()}
        self.assertTrue(expected.issubset(inputs))

    def test_world_tiles_are_tracked(self):
        names = ("day1_lobby_floor", "day2_exterior_paving",
                 "day3_corridor_floor", "day4_courtyard_paving")
        expected = {f"assets/world/tiles/{name}.png{suffix}" for name in names
                    for suffix in ("", ".import")}
        self.assertTrue(expected.issubset(release.source_hashes()))
        inputs = {path.relative_to(release.ROOT).as_posix() for path in release.export_inputs()}
        self.assertTrue(expected.issubset(inputs))

    def test_stale_web_export_is_rejected(self):
        with tempfile.TemporaryDirectory(dir=release.ROOT / "build") as temporary:
            newer = Path(temporary) / "changed.gd"
            newer.write_text("change", encoding="utf-8")
            future = (release.GAME_EXPORT / "index.pck").stat().st_mtime_ns + 10_000_000_000
            os.utime(newer, ns=(future, future))
            with patch.object(release, "export_inputs", return_value=[newer]):
                with self.assertRaisesRegex(ValueError, "vuelve a exportar"):
                    release.assert_fresh_export()

    def test_provisional_build_cannot_enter_staging_or_production(self):
        self.assertEqual(release.release_guard("preview")["game_version"], release.metadata()["game_version"])
        for channel in ("staging", "production"):
            with self.subTest(channel=channel), self.assertRaisesRegex(ValueError, "Guardia de release"):
                release.release_guard(channel)

    def test_package_detects_tampering(self):
        with tempfile.TemporaryDirectory(dir=release.ROOT / "build") as temporary:
            output = Path(temporary) / "release"
            release.package("preview", output.resolve())
            manifest = release.verify(output)
            self.assertIn("game/index.wasm", manifest["files"])
            self.assertNotIn("game/smoke.png", manifest["files"])
            (output / "dashboard/styles.css").write_text("modified", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Hash o tamaño diferente"):
                release.verify(output)

    def test_rollback_requires_same_save_content_and_migrations(self):
        with tempfile.TemporaryDirectory() as temporary:
            current = Path(temporary) / "current"
            previous = Path(temporary) / "previous"
            for folder in (current, previous):
                folder.mkdir()
                (folder / "game.html").write_text("build", encoding="utf-8")
                manifest = {"format_version": 1, "save_schema_version": 1,
                            "narrative_version": "approved-v1", "rubric_version": "approved-v1",
                            "source_sha256": {"supabase/migrations/001.sql": "abc", "data/narrative/day_0.json": "def"},
                            "files": {"game.html": {"sha256": release.sha256(folder / "game.html"), "bytes": 5}}}
                (folder / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
            release.rollback_check(current, previous)
            changed = json.loads((previous / "manifest.json").read_text(encoding="utf-8"))
            changed["source_sha256"]["supabase/migrations/001.sql"] = "different"
            (previous / "manifest.json").write_text(json.dumps(changed), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "migraciones"):
                release.rollback_check(current, previous)
            changed["source_sha256"]["supabase/migrations/001.sql"] = "abc"
            changed["source_sha256"]["scripts/SaveManager.gd"] = "different"
            (previous / "manifest.json").write_text(json.dumps(changed), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "persistencia"):
                release.rollback_check(current, previous)


if __name__ == "__main__":
    unittest.main()
