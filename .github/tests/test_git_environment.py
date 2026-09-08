"""Verify ordinary pushes stay routed to the owning Gerrit review project."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[2] / 'xWalk-git-env.sh'


class GitEnvironmentTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='xwalk-git-env-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.env = dict(os.environ, GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL='/dev/null',
                        GIT_AUTHOR_NAME='Test', GIT_AUTHOR_EMAIL='test@example.invalid',
                        GIT_COMMITTER_NAME='Test', GIT_COMMITTER_EMAIL='test@example.invalid',
                        XWALK_GERRIT_SERVER_ENV_FILE='/dev/null', XWALK_GIT_ENV_LOCAL_FILE='/dev/null',
                        XWALK_GIT_ENV_QUIET='true', GERRIT_SERVER_HOST='gerrit.example',
                        GERRIT_USER='reviewer', GERRIT_SSH_PORT='29419', GERRIT_BRANCH='master',
                        GERRIT_PROJECT='xWalkPiCarAI', XWALK_GIT_AUTO_START='false')
        self.git(self.root, 'init', '-b', 'master')
        shutil.copyfile(SOURCE, self.root / SOURCE.name)
        self.git(self.root, 'remote', 'add', 'origin', 'ssh://reviewer@gerrit.example/integration')
        self.component = self.root / 'xWalk-rpi5-iw'
        self.component.mkdir()
        self.git(self.component, 'init', '-b', 'master')
        self.git(self.component, 'commit', '--allow-empty', '-m', 'Fixture')
        self.git(self.component, 'remote', 'add', 'origin', 'ssh://reviewer@gerrit.example/iw')
        revision = self.git(self.component, 'rev-parse', 'HEAD')
        for name in ('xWalk-rpi5-iw', 'uninitialized'):
            self.git(self.root, 'update-index', '--add', '--cacheinfo', f'160000,{revision},{name}')
        (self.root / 'uninitialized').mkdir()
        (self.root / '.gitmodules').write_text('')

    def git(self, directory, *args):
        return subprocess.run(['git', '-C', str(directory), *args], check=True,
                              env=self.env, text=True, capture_output=True).stdout.strip()

    def source(self):
        result = subprocess.run(['bash', '-c', 'source ./xWalk-git-env.sh'], cwd=self.root,
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        for directory in (self.root, self.component):
            self.assertEqual(self.git(directory, 'config', 'remote.origin.push'), 'HEAD:refs/for/master')
            self.assertEqual(self.git(directory, 'config', 'remote.pushDefault'), 'origin')

    def test_missing_connector_routes_each_real_repository_directly(self):
        self.source()
        for directory, project in ((self.root, 'xWalkPiCarAI'), (self.component, 'xWalk-rpi5-iw')):
            self.assertEqual(self.git(directory, 'remote', 'get-url', '--push', 'origin'),
                             f'ssh://reviewer@gerrit.example:29419/{project}')

    def test_available_connector_preserves_startup_transport(self):
        connector = self.root / 'xWalk-rpi5-tool/py-agent/gerrit-tool/bin/xwalk-gerrit-git-connect'
        connector.parent.mkdir(parents=True)
        connector.write_text('#!/bin/sh\nexit 99\n')
        connector.chmod(0o700)
        self.source()
        for directory, project in ((self.root, 'xWalkPiCarAI'), (self.component, 'xWalk-rpi5-iw')):
            self.assertEqual(self.git(directory, 'remote', 'get-url', '--push', 'origin'),
                             f'ext::{connector} reviewer@gerrit.example 29419 {project} false %S')


if __name__ == '__main__':
    unittest.main()
