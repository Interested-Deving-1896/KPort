import importlib.util
import unittest
from pathlib import Path

_VALIDATOR = Path(__file__).resolve().parents[1] / "scripts" / "validate-debian-family-profile.py"
_SPEC = importlib.util.spec_from_file_location("debian_family_profile_validator", _VALIDATOR)
_MODULE = importlib.util.module_from_spec(_SPEC)
assert _SPEC and _SPEC.loader
_SPEC.loader.exec_module(_MODULE)
validate_profile = _MODULE.validate_profile


def valid_profile():
    return {
        "schema_version": 1,
        "profile_id": "debian-trixie-amd64",
        "distribution": {"family": "debian-family", "id": "debian"},
        "release": {"id": "trixie", "status": "stable"},
        "architecture": {"id": "amd64", "aliases": ["x86_64"]},
        "backend": {
            "kind": "apt",
            "repositories": [{
                "id": "debian-main", "uri": "https://deb.debian.org/debian",
                "suite": "trixie", "components": ["main"],
                "architectures": ["amd64"], "keyring": "debian-archive-keyring",
                "metadata_policy": "signed-inrelease-or-release-gpg-sha256"
            }]
        },
        "source": {"revision": "a" * 40, "uri": "https://github.com/example/profiles"},
        "support": {"state": "source-available", "evidence": []}
    }


class DebianFamilyProfileTests(unittest.TestCase):
    def test_accepts_pinned_debian_apt_profile(self):
        self.assertEqual(validate_profile(valid_profile())["profile_id"], "debian-trixie-amd64")

    def test_rejects_unknown_schema(self):
        p = valid_profile(); p["schema_version"] = 2
        with self.assertRaisesRegex(ValueError, "unsupported schema_version"):
            validate_profile(p)

    def test_rejects_unpinned_source(self):
        p = valid_profile(); p["source"]["revision"] = "main"
        with self.assertRaisesRegex(ValueError, "pinned"):
            validate_profile(p)

    def test_rejects_weak_apt_metadata(self):
        p = valid_profile(); p["backend"]["repositories"][0]["metadata_policy"] = "allow-unauthenticated"
        with self.assertRaisesRegex(ValueError, "weak"):
            validate_profile(p)

    def test_rejects_http_repository(self):
        p = valid_profile(); p["backend"]["repositories"][0]["uri"] = "http://mirror.invalid/debian"
        with self.assertRaisesRegex(ValueError, "HTTPS"):
            validate_profile(p)

    def test_keeps_i386_and_i686_distinct(self):
        p = valid_profile(); p["architecture"] = {"id": "i386", "aliases": ["i686"]}
        with self.assertRaisesRegex(ValueError, "distinct"):
            validate_profile(p)

    def test_rejects_pacstall_apt_repository_conflation(self):
        p = valid_profile(); p["backend"] = {"kind": "pacstall", "repositories": []}
        with self.assertRaisesRegex(ValueError, "must not declare APT"):
            validate_profile(p)

    def test_requires_neon_base_and_overlay(self):
        p = valid_profile(); p["distribution"]["id"] = "kde-neon"
        with self.assertRaisesRegex(ValueError, "explicit Ubuntu base"):
            validate_profile(p)

    def test_accepts_explicit_neon_base_and_overlay(self):
        p = valid_profile(); p["distribution"]["id"] = "kde-neon"
        p["neon"] = {"ubuntu_base_release": "noble", "overlay": "neon-user"}
        self.assertEqual(validate_profile(p)["neon"]["ubuntu_base_release"], "noble")

    def test_rejects_unknown_fields(self):
        p = valid_profile(); p["host_mutation"] = True
        with self.assertRaisesRegex(ValueError, "unknown fields"):
            validate_profile(p)


if __name__ == "__main__":
    unittest.main()
