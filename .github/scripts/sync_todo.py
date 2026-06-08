#!/usr/bin/env python3
"""Mark TODO.md checkboxes done from PR body or commit messages.

Usage:
  python sync_todo.py --from-pr-body          # reads PR_BODY env var
  python sync_todo.py --from-commits HEAD~5..HEAD
  python sync_todo.py --done currency-panel-ui sfx-ui-tap

PR body / commit text — any of these mark a task done:
  ## TODO completed
  - currency-panel-ui
  - catnip-tea-order

  todo:done:currency-panel-ui
  todo:done: catnip-tea-order

Task ids are auto-derived from checkbox titles in TODO.md (slugified).
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TODO_PATH = ROOT / "TODO.md"

CHECKBOX_RE = re.compile(r"^(- \[)( |x)(\]) \*\*([^*]+)\*\*(.*)$")
TODO_DONE_RE = re.compile(r"todo:done:\s*([a-z0-9][a-z0-9-]*)", re.IGNORECASE)
BULLET_ID_RE = re.compile(r"^-\s+([a-z0-9][a-z0-9-]*)\s*$", re.IGNORECASE)


def slugify(title: str) -> str:
    s = title.strip().lower()
    s = s.replace("`", "")
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return s.strip("-")


def parse_todo_ids(lines: list[str]) -> dict[str, int]:
    """Map task id -> line index for unchecked/checked task lines."""
    ids: dict[str, int] = {}
    for i, line in enumerate(lines):
        m = CHECKBOX_RE.match(line)
        if not m:
            continue
        task_id = slugify(m.group(4))
        ids[task_id] = i
    return ids


def extract_done_ids(text: str) -> set[str]:
    done: set[str] = set()
    in_completed_section = False
    for raw in text.splitlines():
        line = raw.strip()
        if re.match(r"#{1,3}\s*todo completed", line, re.IGNORECASE):
            in_completed_section = True
            continue
        if in_completed_section and line.startswith("#"):
            in_completed_section = False
        if in_completed_section:
            m = BULLET_ID_RE.match(line)
            if m:
                done.add(m.group(1).lower())
        for m in TODO_DONE_RE.finditer(line):
            done.add(m.group(1).lower())
    return done


def mark_done(lines: list[str], done_ids: set[str]) -> tuple[list[str], list[str]]:
    id_to_line = parse_todo_ids(lines)
    applied: list[str] = []
    missing: list[str] = []
    out = lines[:]

    for task_id in sorted(done_ids):
        if task_id not in id_to_line:
            missing.append(task_id)
            continue
        idx = id_to_line[task_id]
        line = out[idx]
        m = CHECKBOX_RE.match(line)
        if not m or m.group(2) == "x":
            continue
        out[idx] = f"{m.group(1)}x{m.group(3)} **{m.group(4)}**{m.group(5)}"
        applied.append(task_id)

    return out, applied, missing


def read_commit_messages(rev_range: str) -> str:
    result = subprocess.run(
        ["git", "log", rev_range, "--pretty=format:%B%n---"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--from-pr-body", action="store_true")
    parser.add_argument("--from-commits", metavar="REV_RANGE")
    parser.add_argument("--done", nargs="*", default=[])
    args = parser.parse_args()

    done_ids: set[str] = set(args.done)

    if args.from_pr_body:
        done_ids |= extract_done_ids(os.environ.get("PR_BODY", ""))

    if args.from_commits:
        done_ids |= extract_done_ids(read_commit_messages(args.from_commits))

    if not done_ids:
        print("No todo ids to apply.")
        return 0

    if not TODO_PATH.exists():
        print(f"Missing {TODO_PATH}", file=sys.stderr)
        return 1

    lines = TODO_PATH.read_text(encoding="utf-8").splitlines(keepends=True)
    plain = [ln.rstrip("\n") for ln in lines]
    updated, applied, missing = mark_done(plain, done_ids)

    if missing:
        print("Unknown todo ids (no matching checkbox title):", ", ".join(missing))

    if not applied:
        print("No checkbox changes needed.")
        return 0

    TODO_PATH.write_text("\n".join(updated) + "\n", encoding="utf-8")
    print("Marked done:", ", ".join(applied))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
