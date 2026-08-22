#!/usr/bin/env python3
"""Rename v1.2.0/1.3.0/1.4.0 milestones to v1.1.2/v1.1.3/v1.1.4 and update descriptions/docs-issue."""
from __future__ import annotations

import json
import subprocess
from typing import Any, Dict, List

REPO = "1cetoprosto/cyber-cafe"


def gh_api(method: str, path: str, fields: Dict[str, Any] | None = None, input_json: Dict[str, Any] | None = None) -> Any:
    args: List[str] = ["gh", "api", "-X", method, path]
    if fields:
        for k, v in fields.items():
            args.extend(["-f", f"{k}={'' if v is None else v}"])
    if input_json is not None:
        import os
        import tempfile
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".json", delete=False) as f:
            json.dump(input_json, f, ensure_ascii=False)
            temp_path = f.name
        try:
            args.extend(["--input", temp_path])
            p = subprocess.run(args, capture_output=True, text=True)
        finally:
            try:
                os.remove(temp_path)
            except OSError:
                pass
    else:
        p = subprocess.run(args, capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError(f"gh api {method} {path} failed rc={p.returncode}\nOUT:{p.stdout}\nERR:{p.stderr}")
    return json.loads(p.stdout) if p.stdout.strip() else None


def main() -> None:
    milestones = gh_api("GET", f"repos/{REPO}/milestones?state=open&per_page=100")
    by_title: Dict[str, Dict[str, Any]] = {m["title"]: m for m in milestones}

    renames = [
        {
            "from": "Release v1.2.0",
            "to": "Release v1.1.2",
            "description": (
                "Inventory Audit & Bulk Count\n"
                "- InventoryAdjustment journal with audit context.\n"
                "- Bulk inventory workflow for multi-ingredient count sessions.\n"
                "- Per-ingredient low stock thresholds.\n"
            ),
        },
        {
            "from": "Release v1.3.0",
            "to": "Release v1.1.3",
            "description": (
                "Architecture Cleanup (Storage + Concurrency)\n"
                "- Remove remaining Realm from production code paths and align on Firestore-centric storage.\n"
                "- Migrate domain and FIR services to async/await consistently.\n"
                "- Refine domain models (Purchase/Opex/Sale/InventoryAdjustment) toward target architecture.\n"
            ),
        },
        {
            "from": "Release v1.4.0",
            "to": "Release v1.1.4",
            "description": (
                "UI Polish & Consistency\n"
                "- Use secondaryText across auxiliary content.\n"
                "- Replace input UIAlertController usage with PopupFactory + InputPopupView.\n"
                "- Rewrite remaining alerts to use PopupFactory.\n"
                "- Optionally migrate R.swift from CocoaPods to SPM.\n"
            ),
        },
    ]

    for r in renames:
        src = by_title.get(r["from"])
        dst = by_title.get(r["to"])
        if dst and src is None:
            print(f"SKIP target {r['to']} already present; update description")
            if dst.get("description") != r["description"]:
                gh_api("PATCH", f"repos/{REPO}/milestones/{dst['number']}", input_json={"description": r["description"]})
                print(f"UPDATED desc milestone {dst['number']} {r['to']}")
            continue
        if src is None:
            raise RuntimeError(f"Source milestone {r['from']} not found")
        target_num = dst["number"] if dst else src["number"]
        payload: Dict[str, Any] = {"title": r["to"], "description": r["description"]}
        if dst is None:
            gh_api("PATCH", f"repos/{REPO}/milestones/{target_num}", input_json=payload)
            print(f"RENAMED milestone {src['number']} {src['title']} -> {r['to']}")
        else:
            if dst.get("description") != r["description"]:
                gh_api("PATCH", f"repos/{REPO}/milestones/{target_num}", input_json={"description": r["description"]})
                print(f"UPDATED desc milestone {target_num} {dst['title']}")
            gh_api("PATCH", f"repos/{REPO}/milestones/{src['number']}", input_json={"state": "closed", "description": (src.get("description") or "") + "\n\nClosed: consolidated into " + r["to"]})
            print(f"CLOSED duplicate source milestone {src['number']} {src['title']}")

    # Update v1.1.1 description to explicitly mention patch sequence
    v111 = by_title.get("Release v1.1.1")
    if v111:
        new_desc = (
            "UI/UX Stability & Accessibility (Dynamic Type)\n"
            "- Migrate UILabel to AppLabel across key screens for consistent Dynamic Type and Accessibility.\n"
            "- Sync docs to reflect current shipped state (Reports Hub, aggregation layer, balances).\n"
            "- This starts the 1.1.x stabilization/feature-patch sequence before v1.2.\n"
        )
        if v111.get("description") != new_desc:
            gh_api("PATCH", f"repos/{REPO}/milestones/{v111['number']}", input_json={"description": new_desc})
            print(f"UPDATED desc milestone {v111['number']} Release v1.1.1")

    # Update docs issue #240 body to mention v1.1.x sequence
    issue_body = (
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
        "- Milestone order in plan files aligns with the current patch sequence: v1.1.1 -> v1.1.2 -> v1.1.3 -> v1.1.4.\n"
        "- No misleading statements that shipped features are still planned.\n\n"
        "## Validation\n"
        "- Spot-check every claim in docs vs shipped code paths.\n"
        "- Update roadmap to reflect the newly defined 1.1.x release sequence.\n"
    )
    gh_api("PATCH", f"repos/{REPO}/issues/240", input_json={"body": issue_body})
    print("UPDATED docs issue #240 body")


if __name__ == "__main__":
    main()
