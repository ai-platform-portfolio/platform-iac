import unittest

from discover_federation import discover


class DiscoveryTest(unittest.TestCase):
    def setUp(self):
        self.policy = {"enabled": True, "organization": "ai-platform-portfolio", "apply_environment": "central-apply"}
        self.repo = {"name": "new-repo", "id": 123, "owner": {"login": "ai-platform-portfolio", "id": 456},
                     "full_name": "ai-platform-portfolio/new-repo"}

    def test_disabled_by_default_and_scoped_to_the_org(self):
        self.assertEqual(discover({}, {}, lambda _: self.fail("Must not fetch")), {})
        with self.assertRaises(ValueError):
            discover(dict(self.policy, organization="downstream"), {}, lambda _: [])

    def test_new_repository_gets_only_apply_trust_without_workflow_detection(self):
        entry = discover(self.policy, {}, lambda _: [self.repo])["new-repo"]
        self.assertNotIn("plan_environment", entry)
        self.assertEqual(entry["repository_id"], "123")
        self.assertEqual(entry["apply_environment"], "central-apply")
        existing = {"new-repo": dict(entry, plan_environment="plan")}
        self.assertEqual(discover(self.policy, existing, lambda _: [self.repo]), existing)

    def test_failed_metadata_and_capacity_cannot_silently_drop_trust(self):
        with self.assertRaises(ValueError):
            discover(self.policy, {}, lambda _: {"error": "unavailable"})
        wrong = dict(self.repo, id=999)
        configured = discover(self.policy, {}, lambda _: [self.repo])
        with self.assertRaises(ValueError):
            discover(self.policy, configured, lambda _: [wrong])
        with self.assertRaises(ValueError):
            discover(self.policy, {str(i): {"apply_environment": "apply"} for i in range(21)}, lambda _: [])

    def test_planning_default_backfills_existing_apply_only_repositories(self):
        configured = discover(self.policy, {}, lambda _: [self.repo])
        policy = dict(self.policy, plan_environment="central-plan")
        resolved = discover(policy, configured, lambda _: [self.repo])
        self.assertEqual(resolved["new-repo"]["plan_environment"], "central-plan")
        self.assertNotIn("plan_environment", configured["new-repo"])
        self.assertEqual(resolved["new-repo"]["apply_environment"], "central-apply")
        self.assertEqual(discover(policy, {}, lambda _: [self.repo]), resolved)

    def test_explicit_planning_override_and_opt_out_are_preserved(self):
        policy = dict(self.policy, plan_environment="central-plan")
        entry = discover(self.policy, {}, lambda _: [self.repo])["new-repo"]
        for environment in ("custom-plan", None):
            configured = {"new-repo": dict(entry, plan_environment=environment)}
            self.assertEqual(discover(policy, configured, lambda _: [self.repo]), configured)

    def test_invalid_planning_default_fails_before_fetching(self):
        for environment in ("", " ", 123, "central-apply"):
            with self.subTest(environment=environment), self.assertRaises(ValueError):
                discover(dict(self.policy, plan_environment=environment), {},
                         lambda _: self.fail("Invalid policy must not fetch"))

    def test_capacity_counts_both_phases(self):
        policy = dict(self.policy, plan_environment="central-plan")
        repos = [dict(self.repo, id=i + 1, name=f"repo-{i}",
                      full_name=f"ai-platform-portfolio/repo-{i}") for i in range(11)]
        self.assertEqual(len(discover(policy, {}, lambda _: repos[:10])), 10)
        with self.assertRaises(ValueError):
            discover(policy, {}, lambda _: repos)
