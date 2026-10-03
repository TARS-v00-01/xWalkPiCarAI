"""Exercise Gerrit checkout with real Git repositories and a local SSH stand-in."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ACTION = Path(__file__).with_name('checkout.sh').resolve()
MAPPINGS = {
    'devloper-note': 'devloper-note',
    'xWalkDriver': 'xWalk-rpi5-hw/xWalkDriver',
    'xWalkAudioResources': 'xWalk-rpi5-hw/xWalkAudioResources',
    'xWalkController': 'xWalk-rpi5-hw/xWalkController',
    'xWalkHal': 'xWalk-rpi5-hw/xWalkHal',
    'xWalkLibrary': 'xWalk-rpi5-hw/xWalkLibrary',
    'xWalk-rpi5-trace': 'xWalk-rpi5-trace',
    'xWalk-rpi5-iw': 'xWalk-rpi5-iw',
    'xWalk-rpi5-node': 'xWalk-rpi5-node',
    'xWalk-rpi5-tool': 'xWalk-rpi5-tool',
}
# Shared tooling is pinned exactly like every other component.
TOOL = 'xWalk-rpi5-tool'


class GerritCheckoutTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='xwalk-checkout-test-')
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.root = self.directory / 'integration'
        self.root.mkdir()
        self.env = dict(os.environ, GIT_CONFIG_NOSYSTEM='1',
                        GIT_CONFIG_GLOBAL='/dev/null', GIT_AUTHOR_NAME='Checkout Test',
                        GIT_AUTHOR_EMAIL='test@example.invalid', GIT_COMMITTER_NAME='Checkout Test',
                        GIT_COMMITTER_EMAIL='test@example.invalid')
        self.env.update(GITHUB_ACTIONS='true', GITHUB_WORKSPACE=str(self.root),
                        GITHUB_RUN_ID='123', GITHUB_RUN_ATTEMPT='2')
        self.git(self.root, 'init', '-b', 'master')
        seed = self.directory / 'seed'
        seed.mkdir()
        self.git(seed, 'init', '-b', 'master')
        (seed / 'source.txt').write_text('submitted component\n')
        self.git(seed, 'add', '.')
        self.git(seed, 'commit', '-m', 'Submitted source')
        self.submitted = self.git(seed, 'rev-parse', 'HEAD')
        self.server = self.directory / 'gerrit'
        self.server.mkdir()
        for name, path in MAPPINGS.items():
            self.git(self.directory, 'clone', '--bare', str(seed), str(self.server / name))
            self.git(self.root, 'config', '-f', '.gitmodules', f'submodule.{name}.path', path)
            self.git(self.root, 'config', '-f', '.gitmodules', f'submodule.{name}.url', f'../{name}.git')
            self.git(self.root, 'config', '-f', '.gitmodules', f'submodule.{name}.branch', 'master')
            self.git(self.root, 'update-index', '--add', '--cacheinfo', f'160000,{self.submitted},{path}')
        self.git(self.root, 'add', '.gitmodules')
        self.git(self.root, 'commit', '-m', 'Pin submitted components')
        key = self.directory / 'key'
        key.write_text('fixture key; no credentials\n')
        key.chmod(0o600)
        known_hosts = self.directory / 'known_hosts'
        known_hosts.write_text('fixture pinned host key\n')
        executable = self.directory / 'bin'
        executable.mkdir()
        ssh = executable / 'ssh'
        ssh.write_text('''#!/usr/bin/env python3
import os
from pathlib import Path
import shlex
import sys
if '-G' in sys.argv:
    sys.exit(0)
assert 'ci@gerrit.example' in sys.argv, sys.argv
command, repository = shlex.split(sys.argv[-1])
assert command == 'git-upload-pack', command
name = repository.removeprefix('/')
assert '/' not in name and name not in ('.', '..'), repository
with open(os.environ['FIXTURE_SSH_LOG'], 'a') as log:
    log.write(name + '\\n')
os.execv('/usr/bin/git', ['git', 'upload-pack', str(Path(os.environ['FIXTURE_GERRIT']) / name)])
''')
        ssh.chmod(0o700)
        self.env.update(PATH=f'{executable}:{os.environ["PATH"]}',
                        GERRIT_SUBMODULE_SSH_KEY_FILE=str(key),
                        GERRIT_SSH_KNOWN_HOSTS_FILE=str(known_hosts),
                        GERRIT_SUBMODULE_USERNAME='ci', GERRIT_SERVER_HOST='gerrit.example',
                        GERRIT_SSH_PORT='29419', FIXTURE_GERRIT=str(self.server),
                        FIXTURE_SSH_LOG=str(self.directory / 'ssh.log'))

    def git(self, directory, *arguments):
        return subprocess.run(['git', '-C', str(directory), *arguments], env=self.env,
                              check=True, capture_output=True, text=True).stdout.strip()

    def checkout(self, success=True):
        result = subprocess.run(['bash', str(ACTION)], cwd=self.root, env=self.env,
                                capture_output=True, text=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def add_nested_hardware(self):
        hardware = self.directory / 'hardware'
        hardware.mkdir()
        self.git(hardware, 'init', '-b', 'master')
        for name, path in MAPPINGS.items():
            if not path.startswith('xWalk-rpi5-hw/'):
                continue
            self.git(hardware, 'config', '-f', '.gitmodules', f'submodule.{name}.path', name)
            self.git(hardware, 'config', '-f', '.gitmodules', f'submodule.{name}.url',
                     f'https://github.com/TARS-v00-01/{name}.git')
            self.git(hardware, 'config', '-f', '.gitmodules', f'submodule.{name}.branch', 'master')
            self.git(hardware, 'update-index', '--add', '--cacheinfo', f'160000,{self.submitted},{name}')
            self.git(self.root, 'update-index', '--force-remove', path)
            self.git(self.root, 'config', '-f', '.gitmodules', '--remove-section', f'submodule.{name}')
        self.git(hardware, 'add', '.gitmodules')
        self.git(hardware, 'commit', '-m', 'Hardware integration')
        revision = self.git(hardware, 'rev-parse', 'HEAD')
        self.git(self.directory, 'clone', '--bare', str(hardware), str(self.server / 'xWalk-rpi5-hw'))
        for key, value in [('path', 'xWalk-rpi5-hw'), ('branch', 'master'),
                           ('url', 'https://github.com/TARS-v00-01/xWalk-rpi5-hw.git')]:
            self.git(self.root, 'config', '-f', '.gitmodules', f'submodule.xWalk-rpi5-hw.{key}', value)
        self.git(self.root, 'update-index', '--add', '--cacheinfo', f'160000,{revision},xWalk-rpi5-hw')
        self.git(self.root, 'add', '.gitmodules')
        self.git(self.root, 'commit', '-m', 'Pin nested hardware integration')
        return revision

    def test_nested_hardware_fetches_exact_submitted_children_and_preserves_changes(self):
        revision = self.add_nested_hardware()
        self.checkout()
        hardware = self.root / 'xWalk-rpi5-hw'
        self.assertEqual(self.git(hardware, 'rev-parse', 'HEAD'), revision)
        component = hardware / 'xWalkHal'
        self.assertEqual(self.git(component, 'rev-parse', 'HEAD'), self.submitted)
        (component / 'source.txt').write_text('saved nested runner edit\n')
        self.checkout()
        self.assertEqual(self.git(component, 'status', '--porcelain'), '')
        self.assertEqual(self.git(component, 'show', 'refs/stash:source.txt'), 'saved nested runner edit')
        self.assertIn('xWalk-rpi5-hw', (self.directory / 'ssh.log').read_text())

    def test_flat_runner_migration_preserves_component_edits_and_local_configuration(self):
        self.checkout()
        component = self.root / MAPPINGS['xWalkHal']
        (component / 'source.txt').write_text('saved pre-migration edit\n')
        hardware = self.root / 'xWalk-rpi5-hw'
        (hardware / 'local.cfg').write_text('saved local configuration\n')
        revision = self.add_nested_hardware()
        self.env['GITHUB_ACTIONS'] = 'false'
        self.assertIn('Refusing hardware migration', self.checkout(False).stderr)
        self.assertFalse((hardware / '.git').exists())
        self.env['GITHUB_ACTIONS'] = 'true'
        self.checkout()
        self.assertEqual(self.git(hardware, 'rev-parse', 'HEAD'), revision)
        self.assertEqual(self.git(component, 'show', 'refs/stash:source.txt'), 'saved pre-migration edit')
        self.assertEqual(self.git(hardware, 'show', 'refs/stash^3:local.cfg'), 'saved local configuration')
        self.assertEqual(self.git(hardware, 'status', '--porcelain'), '')
        self.checkout()
        self.assertEqual(self.git(component, 'show', 'refs/stash:source.txt'), 'saved pre-migration edit')

    def test_exact_submitted_checkout_and_reused_remote(self):
        self.checkout()
        for name, path in {**MAPPINGS, TOOL: TOOL}.items():
            self.assertEqual(self.git(self.root / path, 'rev-parse', 'HEAD'), self.submitted)
            self.git(self.root / path, 'remote', 'set-url', 'origin', f'git@github.invalid:{name}')
        self.checkout()
        for name, path in {**MAPPINGS, TOOL: TOOL}.items():
            self.assertEqual(self.git(self.root / path, 'remote', 'get-url', 'origin'),
                             f'ssh://ci@gerrit.example:29419/{name}')

    def test_tool_keeps_exact_pin_when_submitted_master_advances(self):
        self.checkout()
        tool = self.root / TOOL
        seed = self.directory / 'seed'
        (seed / 'source.txt').write_text('new submitted tool\n')
        self.git(seed, 'commit', '-am', 'Update submitted tool')
        self.git(seed, 'push', str(self.server / TOOL), 'HEAD:master')
        self.checkout()
        self.assertEqual(self.git(tool, 'rev-parse', 'HEAD'), self.submitted)
        self.assertNotEqual(self.git(tool, 'rev-parse', 'origin/master'), self.submitted)

    def test_review_only_revision_is_rejected(self):
        seed = self.directory / 'seed'
        (seed / 'source.txt').write_text('unsubmitted review\n')
        self.git(seed, 'commit', '-am', 'Pending review')
        pending = self.git(seed, 'rev-parse', 'HEAD')
        self.git(seed, 'push', str(self.server / 'xWalkDriver'), 'HEAD:refs/changes/01/1/1')
        self.git(self.root, 'update-index', '--cacheinfo',
                 f'160000,{pending},{MAPPINGS["xWalkDriver"]}')
        self.git(self.root, 'commit', '-m', 'Pin unsubmitted review')
        self.assertIn('has not been submitted', self.checkout(False).stderr)

    def test_dirty_reused_component_is_preserved_before_switching_revision(self):
        self.checkout()
        component = self.root / MAPPINGS['xWalk-rpi5-iw']
        (component / 'source.txt').write_text('staged runner change\n')
        self.git(component, 'add', 'source.txt')
        (component / 'source.txt').write_text('unstaged runner change\n')
        (component / 'generated.txt').write_text('generated runner file\n')
        seed = self.directory / 'seed'
        (seed / 'source.txt').write_text('new submitted source\n')
        self.git(seed, 'commit', '-am', 'Update submitted source')
        self.git(seed, 'push', str(self.server / 'xWalk-rpi5-iw'), 'HEAD:master')
        revision = self.git(seed, 'rev-parse', 'HEAD')
        self.git(self.root, 'update-index', '--cacheinfo',
                 f'160000,{revision},{MAPPINGS["xWalk-rpi5-iw"]}')
        self.git(self.root, 'commit', '-m', 'Update component pin')
        self.checkout()
        self.assertEqual(self.git(component, 'rev-parse', 'HEAD'), revision)
        self.assertEqual(self.git(component, 'status', '--porcelain'), '')
        self.assertEqual(self.git(component, 'show', 'refs/stash:source.txt'), 'unstaged runner change')
        self.assertEqual(self.git(component, 'show', 'refs/stash^2:source.txt'), 'staged runner change')
        self.assertEqual(self.git(component, 'show', 'refs/stash^3:generated.txt'), 'generated runner file')
        saved = self.git(component, 'rev-parse', 'refs/stash')
        self.checkout()
        self.assertEqual(self.git(component, 'rev-parse', 'refs/stash'), saved)

    def test_dirty_developer_checkout_is_not_modified(self):
        self.checkout()
        component = self.root / MAPPINGS['xWalk-rpi5-iw']
        (component / 'source.txt').write_text('developer change\n')
        for actions, workspace in (('false', str(self.root)), ('true', str(self.directory))):
            self.env.update(GITHUB_ACTIONS=actions, GITHUB_WORKSPACE=workspace)
            self.assertIn('Refusing to stash', self.checkout(False).stderr)
            self.assertEqual((component / 'source.txt').read_text(), 'developer change\n')
            self.assertEqual(self.git(component, 'stash', 'list'), '')

    def test_unsafe_key_permissions_fail_before_transport(self):
        Path(self.env['GERRIT_SUBMODULE_SSH_KEY_FILE']).chmod(0o644)
        self.assertIn('group or others', self.checkout(False).stderr)
        self.assertFalse((self.directory / 'ssh.log').exists())

    def test_unexpected_mapping_fails_before_transport(self):
        self.git(self.root, 'config', '-f', '.gitmodules', 'submodule.xWalkDriver.path', '../escape')
        self.assertIn('Unexpected path', self.checkout(False).stderr)
        self.assertFalse((self.directory / 'ssh.log').exists())


if __name__ == '__main__':
    unittest.main()
