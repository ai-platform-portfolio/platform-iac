"""Validate candidate policy; report protected changes under native review rules."""

import json
import os
from pathlib import Path
import subprocess
import tempfile


def classify(report, code):
    if code not in (0, 1) or report.get("status") not in ("pass", "fail"):
        return code or 2
    report["protected_changes"] = [f for f in report["findings"] if f["rule"] == "POLICY001"]
    report["findings"] = [f for f in report["findings"] if f["rule"] != "POLICY001"]
    report["policy_source"] = "candidate"
    report["status"] = "fail" if report["findings"] else "pass"
    return int(bool(report["findings"]))


def main():
    path = Path("reports/quality.json")
    with tempfile.TemporaryDirectory() as directory:
        policy = Path(directory) / "engineering.yaml"
        policy.write_bytes(Path("engineering.yaml").read_bytes())
        run = subprocess.run([
            os.environ["CHECKER"], "--base", os.environ["BASE"],
            "--policy", str(policy), "--tools", os.environ["TOOLS"],
            "--report", str(path),
        ], check=False)
    if not path.exists():
        return run.returncode or 2
    report = json.loads(path.read_text())
    code = classify(report, run.returncode)
    path.write_text(json.dumps(report, indent=2) + "\n")
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with Path(os.environ["GITHUB_STEP_SUMMARY"]).open("a") as stream:
            stream.write("## Structure policy\n\nValidated against candidate engineering.yaml. "
                         "GitHub repository rules control required reviews.\n\n")
            for finding in report.get("protected_changes", []):
                stream.write(f"- Protected change: `{finding['file']}`\n")
    return code


if __name__ == "__main__":
    raise SystemExit(main())
