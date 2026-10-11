import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import validate


class ValidationDiscoveryTest(unittest.TestCase):
    def test_nested_provider_modules_are_checked_and_caches_are_skipped(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = (Path(temporary) / "terraform").resolve()
            expected = {
                "modules/azure/network", "modules/auth0/configuration",
                "modules/aws/bedrock", "modules/gcp/gemini", "examples/nested/network",
            }
            for relative in expected | {"modules/azure/network/.terraform/modules/cache"}:
                directory = root / relative
                directory.mkdir(parents=True, exist_ok=True)
                (directory / "main.tf").write_text("")
            (root / "modules/aws/empty").mkdir()
            script = root / "scripts/validate.py"
            with (
                patch.object(validate, "__file__", str(script)),
                patch("sys.argv", ["validate.py"]),
                patch.object(validate.subprocess, "run") as run,
            ):
                self.assertEqual(validate.main(), 0)
            initialized = {
                str(call.kwargs["cwd"].relative_to(root))
                for call in run.call_args_list
                if call.args[0][1] == "init"
            }
            self.assertEqual(initialized, expected | {"ci"})
