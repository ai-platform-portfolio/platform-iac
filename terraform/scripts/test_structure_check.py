import unittest

from structure_check import classify


class StructureCheckTest(unittest.TestCase):
    def test_only_approval_findings_become_informational(self):
        policy = {"rule": "POLICY001", "file": "engineering.yaml"}
        structure = {"rule": "TF002", "file": "terraform/ci/main.tf"}
        report = {"status": "fail", "findings": [policy, structure]}
        self.assertEqual(classify(report, 1), 1)
        self.assertEqual(report["findings"], [structure])
        self.assertEqual(report["protected_changes"], [policy])
        report = {"status": "fail", "findings": [policy]}
        self.assertEqual(classify(report, 1), 0)
        self.assertEqual(report["status"], "pass")

    def test_checker_errors_still_fail(self):
        report = {"status": "error", "findings": [], "error": "Invalid policy"}
        self.assertEqual(classify(report, 2), 2)
        self.assertEqual(report["status"], "error")
