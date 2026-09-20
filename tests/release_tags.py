#!/usr/bin/env python3
"""Check product release destinations without building or publishing images."""

import os
from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
ENV = {key: value for key, value in os.environ.items() if key not in (
    "RELEASE_VERSION", "IMAGE_REVISION", "STABILITY_TAG", "TAG", "MAKEFLAGS", "MFLAGS")}
ENV.update(DOCKER_USERNAME="test", DOCKER_PASSWORD="test", TAGS="latest")
WRAPPER = r'''
docker() {
    if [[ "$1" == login ]]; then cat >/dev/null; echo "docker login"; else return 1; fi
}
make() { command make --no-print-directory -n "$@"; }
. .github/actions/release.sh
'''


class ProductReleaseTests(unittest.TestCase):
    def publish(self, ref):
        """Render the real release commands with registry login stubbed out."""
        return subprocess.run(["bash", "-c", WRAPPER], cwd=ROOT,
                              env={**ENV, "GITHUB_REF": ref}, text=True, capture_output=True)

    def test_semantic_tag_publishes_exact_product_version(self):
        result = self.publish("refs/tags/2.3.3")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--push -t wodby/backup:2.3.3", result.stdout)
        self.assertNotIn("wodby/backup:latest", result.stdout)

    def test_default_branch_publishes_latest(self):
        result = self.publish("refs/heads/master")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--push -t wodby/backup:latest", result.stdout)

    def test_non_product_tags_are_rejected(self):
        for tag in ("r0", "r1", "r23", "2.3.3-rc1", "2.3.3.1", "02.3.3", "v2.3.3"):
            with self.subTest(tag=tag):
                result = self.publish("refs/tags/" + tag)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, "")
                self.assertIn("Refusing non-product release tag", result.stderr)

    def test_non_publishing_refs(self):
        for ref in ("refs/heads/feature/test", "refs/pull/123/merge"):
            with self.subTest(ref=ref):
                result = self.publish(ref)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, "")

    def test_local_build_inputs_remain_compatible(self):
        for args in (["RELEASE_VERSION=2.3.3"], ["IMAGE_REVISION=2.3.3"],
                     ["STABILITY_TAG=2.3.3"],
                     ["RELEASE_VERSION=2.3.3", "IMAGE_REVISION=r0", "STABILITY_TAG=2.3.2"]):
            with self.subTest(args=args):
                result = subprocess.run(
                    ["make", "--no-print-directory", "-n", "build", *args],
                    cwd=ROOT, env=ENV, text=True, capture_output=True, check=True)
                self.assertIn("-t wodby/backup:2.3.3", result.stdout)


if __name__ == "__main__":
    unittest.main()
