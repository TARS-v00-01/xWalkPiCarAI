"""Regression checks for the public documentation boundary."""
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from verify import CHAPTERS, check_text, verify


class PrivacyTests(unittest.TestCase):
    def test_endpoint_and_secret_boundaries(self):
        for value in ('192.168.1.10', '10.20.30.40', '/home/operator/file', 'token="secret"'):
            with self.subTest(value=value), self.assertRaises(ValueError):
                check_text(Path('example.md'), value)
        check_text(Path('example.md'), '127.0.0.1 192.0.2.10 198.51.100.2 203.0.113.4')

    def test_manifest_and_links(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / 'chapters'
            for name in ('index.md', *(f'{chapter}/index.md' for chapter in CHAPTERS)):
                path = source / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('# Public\n')
            def manifest():
                data = {p.relative_to(source).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                        for p in source.rglob('*') if p.is_file()}
                (root / 'manifest.json').write_text(json.dumps(data))
            manifest()
            verify(root)
            page = source / 'index.md'
            page.write_text('# Changed\n')
            with self.assertRaisesRegex(ValueError, 'manifest'):
                verify(root)
            manifest()
            extra = source / 'unreviewed.md'
            extra.write_text('# Extra\n')
            with self.assertRaisesRegex(ValueError, 'manifest'):
                verify(root)
            extra.unlink()
            extra.symlink_to(page)
            with self.assertRaisesRegex(ValueError, 'symbolic'):
                verify(root)
            extra.unlink()
            page.write_text('[Private](https://github.com/TARS-v00-01/private-component)\n')
            manifest()
            with self.assertRaisesRegex(ValueError, 'external link'):
                verify(root)


if __name__ == '__main__':
    unittest.main()
