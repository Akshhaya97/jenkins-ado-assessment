#!/usr/bin/env python3
from __future__ import annotations

import csv
from collections import Counter
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
EXPORT_DIR = REPO_ROOT / "jira-export"
OUTPUT_FILE = REPO_ROOT / "reports" / "jira_readiness_report.md"


def read_csv(name: str) -> list[dict[str, str]]:
    path = EXPORT_DIR / name
    if not path.exists():
        return []
    with path.open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def build_report() -> str:
    projects = read_csv("projects.csv")
    users = read_csv("users.csv")
    apps = read_csv("apps.csv")
    issues = read_csv("issues.csv")

    inactive_users = [user for user in users if user.get("status", "").lower() != "active"]
    app_status = Counter(app.get("cloud_compatibility", "unknown") for app in apps)
    issues_by_project = Counter(issue.get("project", "UNKNOWN") for issue in issues)

    high_wave = [project for project in projects if project.get("complexity", "").lower() == "high"]
    medium_wave = [project for project in projects if project.get("complexity", "").lower() == "medium"]
    low_wave = [project for project in projects if project.get("complexity", "").lower() == "low"]

    return "\n".join(
        [
            "# Jira Cloud Migration Readiness Report",
            "",
            "## Summary",
            f"- Projects assessed: {len(projects)}",
            f"- Issues assessed: {len(issues)}",
            f"- Users assessed: {len(users)}",
            f"- Inactive users: {len(inactive_users)}",
            f"- Apps assessed: {len(apps)}",
            "",
            "## App Compatibility",
            f"- Compatible: {app_status.get('compatible', 0)}",
            f"- Requires review: {app_status.get('review', 0)}",
            f"- Not supported: {app_status.get('not-supported', 0)}",
            "",
            "## Project Volumes",
            *[f"- {project}: {count} issues" for project, count in issues_by_project.items()],
            "",
            "## Recommended Migration Waves",
            f"- Wave 1 (low complexity): {', '.join(project['project_key'] for project in low_wave) or 'none'}",
            f"- Wave 2 (medium complexity): {', '.join(project['project_key'] for project in medium_wave) or 'none'}",
            f"- Wave 3 (high complexity): {', '.join(project['project_key'] for project in high_wave) or 'none'}",
            "",
            "## Readiness Risks",
            "- Clean up inactive users before production migration.",
            "- Review apps marked as review or not-supported for replacement or redesign.",
            "- Validate workflow and integration parity during test migration.",
            "",
            "## Migration Approach",
            "1. Complete app and workflow assessment.",
            "2. Run a test migration for low-complexity projects.",
            "3. Execute UAT with project owners and integration owners.",
            "4. Perform production cutover in approved waves.",
            "5. Run hypercare and rollback only within agreed boundary conditions.",
        ]
    )


def main() -> None:
    report = build_report()
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_text(report, encoding="utf-8")
    print(f"Wrote {OUTPUT_FILE}")


if __name__ == "__main__":
    main()