#!/usr/bin/env python3
"""Check product release destinations without building or publishing images."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
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


class GitHubReleaseTests(unittest.TestCase):
    def setUp(self):
        """Use a local Git repo and a recording gh command for release metadata."""
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.repo = Path(self.directory.name)
        self.git("init", "-q")
        self.git("config", "user.name", "Release tests")
        self.git("config", "user.email", "tests@example.invalid")
        self.git("config", "commit.gpgsign", "false")
        self.git("config", "tag.gpgsign", "false")
        self.git("commit", "--allow-empty", "-qm", "Product change")
        self.notes = "Refresh Backup base image\n\nwodby/alpine:latest now uses the updated digest."
        self.git("tag", "-am", self.notes, "2.3.3")
        self.log = self.repo / "gh.jsonl"
        gh = self.repo / "gh"
        gh.write_text("""#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
record = {"args": args}
if "--notes-file" in args:
    record["notes"] = pathlib.Path(args[args.index("--notes-file") + 1]).read_text()
with open(os.environ["GH_LOG"], "a") as log:
    log.write(json.dumps(record) + "\\n")
if args[:2] == ["release", "view"]:
    sys.exit(0 if os.environ.get("EXISTING_RELEASE") == "1" else 1)
if args[:2] != ["release", "create"]:
    sys.exit(2)
""")
        gh.chmod(0o755)

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.repo, text=True,
                              capture_output=True, check=True)

    def release(self, tag="2.3.3", existing=False):
        env = {**ENV, "PATH": str(self.repo) + os.pathsep + ENV["PATH"],
               "GITHUB_REF": "refs/tags/" + tag, "GITHUB_REF_NAME": tag,
               "GH_LOG": str(self.log), "EXISTING_RELEASE": "1" if existing else "0"}
        return subprocess.run(["bash", str(ROOT / ".github/actions/github-release.sh")],
                              cwd=self.repo, env=env, text=True, capture_output=True)

    def test_title_and_notes_match_annotated_tag(self):
        result = self.release()
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = [json.loads(line) for line in self.log.read_text().splitlines()]
        self.assertEqual(len(calls), 2)
        created = calls[1]
        self.assertEqual(created["args"][:6],
                         ["release", "create", "2.3.3", "--verify-tag", "--title", "2.3.3"])
        self.assertEqual(created["notes"].strip(), self.notes)

    def test_existing_release_is_preserved(self):
        result = self.release(existing=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = [json.loads(line) for line in self.log.read_text().splitlines()]
        self.assertEqual([c["args"] for c in calls], [["release", "view", "2.3.3"]])

    def test_rejects_revision_and_lightweight_tags(self):
        self.git("tag", "-am", "Retained image revision", "r0")
        self.git("tag", "2.3.4")
        for tag in ("r0", "2.3.4"):
            with self.subTest(tag=tag):
                self.assertNotEqual(self.release(tag).returncode, 0)
                self.assertFalse(self.log.exists())

    def test_rejects_empty_release_description(self):
        self.git("tag", "-a", "-m", "", "2.3.4")
        self.assertNotEqual(self.release("2.3.4").returncode, 0)
        self.assertFalse(self.log.exists())


if __name__ == "__main__":
    unittest.main()
