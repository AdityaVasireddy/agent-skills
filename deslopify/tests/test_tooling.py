import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile


ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / "scripts" / "validate.py"
BUILDER = ROOT / "scripts" / "bundle.py"


class ToolingTests(unittest.TestCase):
    def run_validator(self, root):
        return subprocess.run(
            [sys.executable, str(VALIDATOR), str(root)],
            capture_output=True,
            text=True,
            check=False,
        )

    def test_validator_rejects_missing_required_reference(self):
        with tempfile.TemporaryDirectory() as directory:
            copy = Path(directory) / "deslopify"
            shutil.copytree(ROOT, copy, ignore=shutil.ignore_patterns("reviewer-bundle*"))
            (copy / "references" / "words.md").unlink()
            result = self.run_validator(copy)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("missing required files", result.stdout)

    def test_validator_rejects_dangling_and_orphaned_contracts(self):
        with tempfile.TemporaryDirectory() as directory:
            copy = Path(directory) / "deslopify"
            shutil.copytree(ROOT, copy, ignore=shutil.ignore_patterns("reviewer-bundle*"))
            gate = copy / "eval.md"
            gate.write_text(gate.read_text(encoding="utf-8") + "\n**MISSING-CONTRACT:**\n", encoding="utf-8")
            result = self.run_validator(copy)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("dangling contract", result.stdout)

    def test_validator_rejects_duplicate_definitions_and_ordinal_aliases(self):
        with tempfile.TemporaryDirectory() as directory:
            copy = Path(directory) / "deslopify"
            shutil.copytree(ROOT, copy, ignore=shutil.ignore_patterns("reviewer-bundle*"))
            skill = copy / "SKILL.md"
            text = skill.read_text(encoding="utf-8")
            skill.write_text(text + "\n**Contract `VOICE-PROTECTION`** duplicate\n", encoding="utf-8")
            result = self.run_validator(copy)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("duplicate contract", result.stdout)

        with tempfile.TemporaryDirectory() as directory:
            copy = Path(directory) / "deslopify"
            shutil.copytree(ROOT, copy, ignore=shutil.ignore_patterns("reviewer-bundle*"))
            reference = copy / "references" / "formats.md"
            reference.write_text(reference.read_text(encoding="utf-8") + "\nUse tier 3 when facts are missing.\n", encoding="utf-8")
            result = self.run_validator(copy)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("ordinal tier alias", result.stdout)

    def test_reviewer_package_is_verified_and_reproducible(self):
        with tempfile.TemporaryDirectory() as directory:
            first = Path(directory) / "nested" / "reviewer-one.zip"
            second = Path(directory) / "reviewer-two.zip"
            for output in (first, second):
                result = subprocess.run(
                    [sys.executable, str(BUILDER), "--kind", "reviewer", "--output", str(output)],
                    capture_output=True,
                    text=True,
                    check=False,
                )
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(hashlib.sha256(first.read_bytes()).digest(), hashlib.sha256(second.read_bytes()).digest())
            with zipfile.ZipFile(first) as archive:
                names = set(archive.namelist())
                self.assertNotIn("deslopify/evaluation/scoring-sheet.md", names)
                self.assertIn("BUILD_MANIFEST.json", names)
                manifest = json.loads(archive.read("BUILD_MANIFEST.json"))
                self.assertEqual(manifest["kind"], "reviewer")
                self.assertEqual(set(manifest["files"]), names - {"BUILD_MANIFEST.json"})
                self.assertNotIn("{{RUNTIME_SIZE}}", archive.read("evaluation/review-prompt.md").decode())

    def test_builder_refuses_overwrite(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "reviewer.zip"
            output.write_bytes(b"sentinel")
            result = subprocess.run(
                [sys.executable, str(BUILDER), "--kind", "reviewer", "--output", str(output)],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(output.read_bytes(), b"sentinel")


if __name__ == "__main__":
    unittest.main()
