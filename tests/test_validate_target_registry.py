"""Unit tests for the Windows/ReactOS target registry contract."""
import copy
import importlib.util
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "validate_target_registry", ROOT / "scripts/validate-target-registry.py"
)
validator = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(validator)


class TargetRegistryTests(unittest.TestCase):
    def setUp(self):
        self.data = json.loads(validator.REGISTRY.read_text(encoding="utf-8"))
        self.schema = json.loads(validator.SCHEMA.read_text(encoding="utf-8"))

    def test_checked_in_registry_is_valid(self):
        validator.validate_registry(self.data, self.schema)

    def test_duplicate_target_ids_are_rejected(self):
        data = copy.deepcopy(self.data)
        data["targets"].append(copy.deepcopy(data["targets"][0]))
        with self.assertRaisesRegex(ValueError, "target IDs must be unique"):
            validator.validate_registry(data, self.schema)

    def test_reactos_arm64_is_rejected(self):
        data = copy.deepcopy(self.data)
        data["targets"][0]["os"] = "reactos"
        data["targets"][0]["architecture"] = "arm64"
        with self.assertRaisesRegex(ValueError, "ReactOS ARM64"):
            validator.validate_registry(data, self.schema)

    def test_windows_success_cannot_enable_pr_publishing(self):
        data = copy.deepcopy(self.data)
        data["policy"]["publish_from_untrusted_pull_requests"] = True
        with self.assertRaisesRegex(ValueError, "publishing from untrusted pull requests"):
            validator.validate_registry(data, self.schema)

    def test_required_and_optional_package_formats_cannot_overlap(self):
        data = copy.deepcopy(self.data)
        data["targets"][0]["optional_package_formats"].append("portable-zip")
        with self.assertRaisesRegex(ValueError, "both required and optional"):
            validator.validate_registry(data, self.schema)

    def test_unknown_fields_are_rejected(self):
        data = copy.deepcopy(self.data)
        data["targets"][0]["surprise"] = "ignored"
        with self.assertRaisesRegex(ValueError, "unexpected keys"):
            validator.validate_registry(data, self.schema)


if __name__ == "__main__":
    unittest.main()
