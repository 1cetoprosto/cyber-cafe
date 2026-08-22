#!/usr/bin/env python3
"""Create milestones and seed missing issues for TrackMyCafe plan."""
from __future__ import annotations

import json
import subprocess
from typing import Any, Dict, List

REPO = "1cetoprosto/cyber-cafe"


def gh_api(method: str, path: str, **kwargs: Any) -> Any:
    input_json = kwargs.pop("input_json", None)
    if input_json is None:
        args = ["gh", "api", "-X", method, path]
        p = subprocess.run(args, capture_output=True, text=True)
    else:
        args = ["gh", "api", "-X", method, path]
        if isinstance(input_json, dict):
            fields: List[str] = []
            has_complex = False
            for key, value in input_json.items():
                if isinstance(value, (dict, list)):
                    has_complex = True
                    break
                fields.append(f"-f")
                fields.append(f"{key}={'' if value is None else value}")
            if not has_complex:
                args.extend(fields)
                p = subprocess.run(args, capture_output=True, text=True)
            else:
                import tempfile
                with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".json", delete=False) as f:
                    json.dump(input_json, f, ensure_ascii=False)
                    temp_path = f.name
                try:
                    args.extend(["--input", temp_path])
                    p = subprocess.run(args, capture_output=True, text=True)
                finally:
                    import os
                    try:
                        os.remove(temp_path)
                    except OSError:
                        pass
        else:
            raise TypeError("input_json must be dict")
    if p.returncode != 0:
        raise RuntimeError(f"gh api {method} {path} failed rc={p.returncode}\nSTDOUT:{p.stdout}\nSTDERR:{p.stderr}")
    if p.stdout.strip():
        return json.loads(p.stdout)
    return None


def get_milestones() -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    page = 1
    while True:
        batch = gh_api("GET", f"repos/{REPO}/milestones?state=all&per_page=100&page={page}")
        if not batch:
            break
        out.extend(batch)
        if len(batch) < 100:
            break
        page += 1
    return out


def get_open_issues() -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    page = 1
    while True:
        batch = gh_api("GET", f"repos/{REPO}/issues?state=open&per_page=100&page={page}")
        if not batch:
            break
        for item in batch:
            if "pull_request" in item:
                continue
            out.append(item)
        if len(batch) < 100:
            break
        page += 1
    return out


def ensure_milestones(targets: List[Dict[str, Any]], existing: List[Dict[str, Any]]) -> Dict[str, int]:
    by_title = {m["title"]: m["number"] for m in existing}
    result: Dict[str, int] = {}
    for t in targets:
        title = t["title"]
        if title in by_title:
            num = by_title[title]
            current_desc = next(m for m in existing if m["title"] == title).get("description") or ""
            want_desc = t["description"]
            if current_desc != want_desc:
                gh_api("PATCH", f"repos/{REPO}/milestones/{num}", input_json={"description": want_desc})
                print(f"UPDATED milestone {num} {title}")
            result[title] = num
        else:
            created = gh_api("POST", f"repos/{REPO}/milestones", input_json={
                "title": title, "state": "open", "description": t["description"]
            })
            num = created["number"]
            print(f"CREATED milestone {num} {title}")
            result[title] = num
    return result


def update_issue_milestone(issue_number: int, milestone_number: int | None) -> None:
    body: Dict[str, Any] = {"milestone": milestone_number}
    gh_api("PATCH", f"repos/{REPO}/issues/{issue_number}", input_json=body)
    print(f"PATCH issue {issue_number} -> milestone {milestone_number}")


def create_issue(title: str, body: str, labels: List[str] | None, milestone_number: int | None) -> int:
    payload: Dict[str, Any] = {"title": title, "body": body}
    if labels:
        payload["labels"] = labels
    if milestone_number is not None:
        payload["milestone"] = milestone_number
    created = gh_api("POST", f"repos/{REPO}/issues", input_json=payload)
    num = created["number"]
    print(f"CREATED issue {num} {title}")
    return num


TARGET_MILESTONES = [
    {
        "title": "Release v1.1.1",
        "description": (
            "UI/UX Stability & Accessibility (Dynamic Type)\n"
            "- Migrate UILabel to AppLabel across key screens for consistent Dynamic Type and Accessibility.\n"
            "- Sync docs to reflect current shipped state (Reports Hub, aggregation layer, balances).\n"
        ),
    },
    {
        "title": "Release v1.2.0",
        "description": (
            "Inventory Audit & Bulk Count\n"
            "- InventoryAdjustment journal with audit context.\n"
            "- Bulk inventory workflow for multi-ingredient count sessions.\n"
            "- Per-ingredient low stock thresholds.\n"
        ),
    },
    {
        "title": "Release v1.3.0",
        "description": (
            "Architecture Cleanup (Storage + Concurrency)\n"
            "- Remove remaining Realm from production code paths and align on Firestore-centric storage.\n"
            "- Migrate domain and FIR services to async/await consistently.\n"
            "- Refine domain models (Purchase/Opex/Sale/InventoryAdjustment) toward target architecture.\n"
        ),
    },
    {
        "title": "Release v1.4.0",
        "description": (
            "UI Polish & Consistency\n"
            "- Use secondaryText across auxiliary content.\n"
            "- Replace input UIAlertController usage with PopupFactory + InputPopupView.\n"
            "- Rewrite remaining alerts to use PopupFactory.\n"
            "- Optionally migrate R.swift from CocoaPods to SPM.\n"
        ),
    },
]

ISSUE_MILESTONE_MAP = {
    "Release v1.1.1": [190],
    "Release v1.2.0": [144, 152],
    "Release v1.3.0": [141, 140, 142, 178],
    "Release v1.4.0": [173, 127, 100, 164],
}

NEW_ISSUES = [
    {
        "milestone": "Release v1.1.1",
        "title": "chore(docs): sync product docs with current shipped state",
        "body": (
            "## Context\n"
            "Several product docs still describe Reports Hub and financial layers as \"future\", but code ships:\n"
            "- Reports Hub as tab 4 (MainTabBarController)\n"
            "- P&L / ABC / Trends report screens\n"
            "- Finance / aggregation services\n"
            "- journal + daily balances\n\n"
            "## Goal\n"
            "Update the docs so the current state description matches what is actually implemented.\n\n"
            "## Files to sync\n"
            "- docs/README.md\n"
            "- TrackMyCafe/Documentations/ROADMAP.md\n"
            "- TrackMyCafe/Documentations/DEV_IMPLEMENTATION_GUIDE.md\n"
            "- TrackMyCafe/Documentations/ARCHITECTURE_AND_LOGIC.md\n"
            "- TrackMyCafe/Documentations/REPORTS.md\n\n"
            "## Expected outcome\n"
            "- \"Current state\" sections reflect v1.1.0 reality (Reports shipped, aggregation layer shipped, balances shipped).\n"
            "- Milestone order in plan files aligns with the current plan: v1.1.1 -> v1.2.0 -> v1.3.0 -> v1.4.0.\n"
            "- No misleading statements that shipped features are still planned.\n\n"
            "## Validation\n"
            "- Spot-check every claim in docs vs shipped code paths.\n"
            "- Update roadmap to reflect the newly defined release sequence.\n"
        ),
        "labels": ["type: 5 chore", "priority: 2 medium", "docs"],
    }
]


def main() -> None:
    existing_milestones = get_milestones()
    milestone_numbers = ensure_milestones(TARGET_MILESTONES, existing_milestones)

    open_issues = {i["number"]: i for i in get_open_issues()}
    scheduled_nums: set[int] = set()

    for ms_title, issue_nums in ISSUE_MILESTONE_MAP.items():
        ms_num = milestone_numbers[ms_title]
        for num in issue_nums:
            if num not in open_issues:
                print(f"WARN issue {num} not found in open issues, skipping")
                continue
            current_ms = open_issues[num].get("milestone")
            current_num = current_ms["number"] if current_ms else None
            if current_num != ms_num:
                update_issue_milestone(num, ms_num)
            else:
                print(f"NO CHANGE issue {num} already on milestone {ms_num}")
            scheduled_nums.add(num)

    for issue_def in NEW_ISSUES:
        ms_num = milestone_numbers.get(issue_def["milestone"])
        create_issue(
            title=issue_def["title"],
            body=issue_def["body"],
            labels=issue_def.get("labels"),
            milestone_number=ms_num,
        )

    keep_in_future = sorted(set(open_issues.keys()) - scheduled_nums)
    future_num = next((m["number"] for m in existing_milestones if m["title"] == "Future Release"), None)
    if future_num:
        for num in keep_in_future:
            current = open_issues[num].get("milestone")
            current_num = current["number"] if current else None
            if current_num != future_num:
                update_issue_milestone(num, future_num)
            else:
                print(f"KEEP issue {num} in Future Release")

    print("\nDONE")
    print("Milestones:", milestone_numbers)
    print("Scheduled issue count:", len(scheduled_nums))


if __name__ == "__main__":
    main()
