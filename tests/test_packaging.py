"""Regression checks for independent installation and release validation."""

import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from install import install
from validate import validate


class PackagingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        (self.root / "LICENSE").write_text("MIT test notice\n")
        for name in ("first-skill", "second-skill"):
            folder = self.root / "skills" / name
            (folder / "references").mkdir(parents=True)
            (folder / "SKILL.md").write_text(
                f"---\nname: {name}\ndescription: Use for testing.\nlicense: MIT\n---\n"
                "[Guide](references/guide.md)\n")
            (folder / "LICENSE").write_text("MIT test notice\n")
            (folder / "references" / "guide.md").write_text("Example reference.\n")
        self.destination = self.root / "installed"

    def test_install_copies_complete_skill_and_license(self):
        install(self.root / "skills", self.destination, ["first-skill"])
        self.assertTrue((self.destination / "first-skill/references/guide.md").is_file())
        self.assertEqual((self.destination / "first-skill/LICENSE").read_text(), "MIT test notice\n")
        self.assertFalse((self.destination / "second-skill").exists())

    def test_collision_prevents_partial_install(self):
        (self.destination / "second-skill").mkdir(parents=True)
        with self.assertRaises(FileExistsError):
            install(self.root / "skills", self.destination, ["first-skill", "second-skill"])
        self.assertFalse((self.destination / "first-skill").exists())

    def test_copy_failure_rolls_back_owned_folders(self):
        with patch("install.shutil.copytree", side_effect=OSError("Disk full")):
            with self.assertRaises(OSError):
                install(self.root / "skills", self.destination, ["first-skill"])
        self.assertFalse((self.destination / "first-skill").exists())

    def test_dry_run_does_not_write(self):
        targets = install(self.root / "skills", self.destination, ["first-skill"], dry_run=True)
        self.assertEqual(targets, [self.destination / "first-skill"])
        self.assertFalse(self.destination.exists())

    def test_path_traversal_and_unknown_names_rejected(self):
        for name in ("../first-skill", "missing"):
            with self.assertRaises(ValueError):
                install(self.root / "skills", self.destination, [name])

    def test_symlinked_resources_rejected(self):
        (self.root / "skills/first-skill/references/external.md").symlink_to(self.root / "LICENSE")
        with self.assertRaises(ValueError):
            install(self.root / "skills", self.destination, ["first-skill"])
        self.assertTrue(any("symlinks" in e for e in validate(self.root)[0]))

    def test_valid_collection(self):
        self.assertEqual(validate(self.root), ([], 2))

    def test_missing_entrypoint_is_not_silently_skipped(self):
        (self.root / "skills/second-skill/SKILL.md").unlink()
        self.assertTrue(any("missing regular SKILL.md" in e for e in validate(self.root)[0]))

    def test_missing_reference_is_rejected(self):
        (self.root / "skills/first-skill/references/guide.md").unlink()
        self.assertTrue(any("missing reference" in e for e in validate(self.root)[0]))

    def test_sibling_skill_dependency_is_rejected(self):
        entry = self.root / "skills/first-skill/SKILL.md"
        entry.write_text(entry.read_text() + "[Other](../second-skill/SKILL.md)\n")
        self.assertTrue(any("leaves standalone skill" in e for e in validate(self.root)[0]))

    def test_license_notice_is_required(self):
        (self.root / "skills/first-skill/LICENSE").unlink()
        self.assertTrue(any("LICENSE" in e for e in validate(self.root)[0]))


if __name__ == "__main__":
    unittest.main()
