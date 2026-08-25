#!/usr/bin/env python3
"""Quick verification script: print milestones and open issue assignments."""
from __future__ import annotations

import json
import subprocess


def gh(method: str, path: str) -> object:
    p = subprocess.run(["gh", "api", "-X", method, path], capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError(p.stderr)
    return json.loads(p.stdout) if p.stdout.strip() else []


def main() -> None:
    milestones = gh("GET", "repos/1cetoprosto/cyber-cafe/milestones?state=open&per_page=100")
    print("MILESTONES:")
    for m in sorted(milestones, key=lambda x: x["number"]):
        print(f"  #{m['number']:>3} open={m['open_issues']:<2} {m['title']}")

    issues = gh("GET", "repos/1cetoprosto/cyber-cafe/issues?state=open&per_page=100")
    print("\nOPEN ISSUES:")
    for i in sorted(issues, key=lambda x: x["number"]):
        if "pull_request" in i:
            continue
        ms = (i.get("milestone") or {}).get("title", "NO MILESTONE")
        labels = ", ".join(l["name"] for l in i.get("labels", []))
        title = i["title"].replace("\n", " ")
        print(f"  #{i['number']:<5} [{ms:<18}] {title[:90]}")
        if labels:
            print(f"         labels: {labels}")


if __name__ == "__main__":
    main()
