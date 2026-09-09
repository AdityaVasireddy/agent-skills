import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile

import yaml

ROOT = Path(__file__).resolve().parents[1]


class ReleaseTests(unittest.TestCase):
    def copy(self, directory):
        target = Path(directory) / 'deslopify'
        shutil.copytree(ROOT, target, ignore=shutil.ignore_patterns('*.zip', '__pycache__', 'dist'))
        return target

    def run_script(self, root, script, *args):
        return subprocess.run([sys.executable, str(root / 'scripts' / script), *map(str, args)],
                              cwd=root, capture_output=True, text=True)

    def test_yaml_syntax_types_duplicate_keys_and_missing_contracts(self):
        for header in ('name: deslopify\ndescription: valid\nUnindented sentence',
                       'name: deslopify\ndescription: [wrong, type]',
                       'name: deslopify\ndescription: first\ndescription: second',
                       'name: deslopify\ndescription: ""'):
            with self.subTest(header=header), tempfile.TemporaryDirectory() as directory:
                root = self.copy(directory)
                skill = root / 'SKILL.md'
                body = skill.read_text(encoding='utf-8').split('---', 2)[2]
                skill.write_text('---\n' + header + '\n---' + body, encoding='utf-8')
                result = self.run_script(root, 'validate.py', root)
                self.assertNotEqual(result.returncode, 0, result.stdout)
        with tempfile.TemporaryDirectory() as directory:
            root = self.copy(directory)
            skill = root / 'SKILL.md'
            skill.write_text(skill.read_text(encoding='utf-8') + '\n**Contract `UNUSED-CONTRACT`**\n', encoding='utf-8')
            result = self.run_script(root, 'validate.py', root)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('orphaned', result.stdout)

    def test_all_packages_reproducible_and_source_excludes_generated_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.copy(directory)
            for kind, name in [('reviewer', 'reviewer.zip'), ('install', 'deslopify-install.zip'), ('source', 'deslopify-source.zip')]:
                first, second = root / name, root / 'dist' / name
                for path in (first, second):
                    result = self.run_script(root, 'bundle.py', '--kind', kind, '--output', path)
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    result = self.run_script(root, 'bundle.py', '--verify', path)
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(first.read_bytes(), second.read_bytes())
                with zipfile.ZipFile(first) as archive:
                    names = set(archive.namelist())
                    self.assertFalse(any(n.lower().endswith('.zip') or n.startswith('dist/') for n in names))
                    if kind == 'install':
                        self.assertNotIn('README.md', names)
                        self.assertIn('agents/openai.yaml', names)
                        self.assertFalse(any(n.startswith(('scripts/', 'evaluation/', 'tests/')) for n in names))
                        yaml.safe_load(archive.read('SKILL.md').decode().split('---', 2)[1])
                        metadata = yaml.safe_load(archive.read('agents/openai.yaml'))
                        self.assertIn('$deslopify', metadata['interface']['default_prompt'])
                    if kind == 'reviewer':
                        self.assertNotIn('evaluation/scoring-sheet.md', names)
                        self.assertNotIn('KNOWN-LIMITATIONS.md', names)

    def test_wrapper_custom_basename_and_default(self):
        bash = os.environ.get('DESLOPIFY_BASH') or shutil.which('bash')
        if sys.platform == 'win32' and Path('C:/Program Files/Git/bin/bash.exe').exists():
            bash = 'C:/Program Files/Git/bin/bash.exe'
        self.assertIsNotNone(bash, 'Bash is required for release validation')
        with tempfile.TemporaryDirectory() as directory:
            root = self.copy(directory)
            for args, name in [(['nested/custom name'], 'nested/custom name.zip'), ([], 'reviewer-bundle.zip')]:
                env = dict(os.environ, PYTHON=sys.executable)
                result = subprocess.run([bash, 'scripts/bundle.sh', *args], cwd=root, env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertTrue((root / name).is_file())

    def test_corpus_has_real_paragraphs_and_unique_ids(self):
        cases = json.loads((ROOT / 'evaluation/cases.json').read_text(encoding='utf-8'))
        self.assertEqual(len(cases), len({c['id'] for c in cases}))
        for case in cases:
            self.assertNotIn('expected', case)
            self.assertNotIn('\\n', case.get('text', ''))
        self.assertIn('\n\n', cases[0]['text'])
        prompt = (ROOT / 'evaluation/review-prompt.md').read_text(encoding='utf-8')
        self.assertNotIn(cases[0]['text'].split('\n')[0], prompt)

    def test_detect_grounding_case_is_in_reviewer_without_changing_existing_detect_cases(self):
        expected_existing = {
            'detect-human-technical': {
                'mode': 'detect',
                'request': 'Audit this for slop. Do not rewrite it.',
                'text': "I spent four days on a bug that turned out to be a trailing slash. Four days. The config loader was doing path joins with string concatenation instead of path.join, so /etc/app/ and /etc/app resolved to different cache keys and the second one silently created an empty config. No error. Just an app that booted fine and ignored every setting.\n\nI want to say I found it through disciplined bisection. I found it because I got annoyed and started printing every variable in the loader. Sometimes that is the method. The fix was one character. The test that would have caught it took forty minutes to write and I wrote it after, which is the wrong order and I know it.",
            },
            'detect-marketing': {
                'mode': 'detect',
                'request': 'Audit this for slop. Do not rewrite it.',
                'text': "In today's rapidly evolving digital landscape, businesses need robust solutions that can seamlessly scale with their needs. Our platform doesn't just streamline your workflow. It transforms it.\n\nHere's what most teams get wrong: they focus on tools instead of outcomes. The reality is that meaningful change requires more than software. It requires a paradigm shift.\n\nThat's why we built something different. A platform that empowers your team to delve into what actually matters, highlighting the insights that drive real results. Industry reports suggest that companies leveraging integrated workflows see significant improvements in productivity.\n\nThe future of work isn't coming. It's already here.",
            },
        }
        expected_new = {
            'id': 'detect-named-pattern-grounding',
            'mode': 'detect',
            'request': 'Audit this LinkedIn post for named slop patterns. Do not rewrite it.',
            'text': "In today's rapidly evolving AI landscape, we're not just building tools — we're redefining what's possible.",
        }
        cases = json.loads((ROOT / 'evaluation/cases.json').read_text(encoding='utf-8'))
        by_id = {case['id']: case for case in cases}
        self.assertEqual(sum(case['id'] == expected_new['id'] for case in cases), 1)
        self.assertEqual(by_id[expected_new['id']], expected_new)
        for case_id, expected in expected_existing.items():
            self.assertEqual(by_id[case_id], {'id': case_id, **expected})

        with tempfile.TemporaryDirectory() as directory:
            reviewer = Path(directory) / 'reviewer.zip'
            result = self.run_script(ROOT, 'bundle.py', '--kind', 'reviewer', '--output', reviewer)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            with zipfile.ZipFile(reviewer) as archive:
                names = set(archive.namelist())
                packaged = json.loads(archive.read('evaluation/cases.json'))
                self.assertEqual([case for case in packaged if case['id'] == expected_new['id']], [expected_new])
                self.assertNotIn('evaluation/scoring-sheet.md', names)

    def test_verify_rejects_tampered_manifest_and_unsafe_members(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.copy(directory)
            good = root / 'good.zip'
            result = self.run_script(root, 'bundle.py', '--kind', 'reviewer', '--output', good)
            self.assertEqual(result.returncode, 0, result.stderr)
            with zipfile.ZipFile(good) as archive:
                original = {n: archive.read(n) for n in archive.namelist()}
            for case in ('hash', 'schema', 'traversal', 'missing', 'extra', 'symlink', 'directory', 'duplicate-key'):
                with self.subTest(case=case):
                    members = dict(original)
                    if case == 'hash': members['SKILL.md'] += b'changed'
                    elif case == 'schema': members['BUILD_MANIFEST.json'] = b'[]'
                    elif case == 'traversal': members['../escape'] = b'bad'
                    elif case == 'missing': del members['eval.md']
                    elif case == 'extra': members['evaluation/scoring-sheet.md'] = b'oracle'
                    elif case == 'duplicate-key': members['BUILD_MANIFEST.json'] = members['BUILD_MANIFEST.json'].replace(b'"schema": 1', b'"schema": 1, "schema": 1')
                    bad = root / (case + '.zip')
                    with zipfile.ZipFile(bad, 'w') as archive:
                        for name, data in sorted(members.items()):
                            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
                            info.create_system = 3
                            info.external_attr = 0o100644 << 16
                            if name == 'SKILL.md' and case == 'symlink': info.external_attr = 0o120777 << 16
                            if name == 'SKILL.md' and case == 'directory': info.external_attr = 0o040755 << 16
                            archive.writestr(info, data)
                    result = self.run_script(root, 'bundle.py', '--verify', bad)
                    self.assertNotEqual(result.returncode, 0)

    def test_validator_accepts_documented_current_directory(self):
        result = self.run_script(ROOT, 'validate.py', '.')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_line_endings_do_not_change_archive(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.copy(directory)
            first, second = root / 'lf.zip', root / 'crlf.zip'
            result = self.run_script(root, 'bundle.py', '--kind', 'install', '--output', first)
            self.assertEqual(result.returncode, 0, result.stderr)
            for path in root.rglob('*'):
                if path.is_file() and path.suffix in ('.md', '.yaml'):
                    path.write_bytes(path.read_bytes().replace(b'\r\n', b'\n').replace(b'\n', b'\r\n'))
            result = self.run_script(root, 'bundle.py', '--kind', 'install', '--output', second)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(first.read_bytes(), second.read_bytes())


if __name__ == '__main__':
    unittest.main()
