---
description: Recurring workflow maintenance — capture live self-improvements, curate learnings, check trunk health. Idempotent; safe to schedule headless (cron or routine).
---

# Workflow Maintenance: $ARGUMENTS

Run the four checks below in order. Each check reports; only check 1 may commit. `$ARGUMENTS` is an optional space-separated list of repo paths for check 3. End with the summary. Nothing here asks the human a question — this command must complete unattended.

## 1. Capture sync

1. Locate the workflow repo (the directory containing this repo's `capture.sh`; default `~/Prywatne/software-developer-workflows`). Missing → report `capture: repo not found` and skip to check 2.
2. Run `capture.sh`, then inspect `git status --short` and `git diff` in the repo.
3. Commit ONLY a faithful mirror of live state: modified learnings files (`new-task/LEARNINGS.md`, `new-task/learnings/*.md`), or agent/command/skill files that match a live self-improvement. Message: one line describing what drifted (e.g. `capture: 2 new learnings from <repo-key> runs`). Do NOT push.
4. Anything surprising — deleted files, drift in files no `/new-task` run should touch, conflict markers → report it, revert the working tree for those paths, commit nothing for them.

## 2. Learnings curation

For `~/.claude/new-task/LEARNINGS.md` and each `~/.claude/new-task/learnings/*.md`:

1. Count bullets. Over 25 → propose merges/prunes to get comfortably under the 30 cap.
2. Flag bullets that duplicate a skill (`~/.claude/skills/verify-fix`, `verify-feature`, `convention-scan`, `ci-triage`) or a rule already in `new-task.md` — these are promoted and should be deleted per the curation rules.
3. Flag contradicting bullet pairs (newest wins; propose deleting the older).
4. Flag any dated bullet missing a trigger tag `[tag]` or a `src:` ref (v2 format) — propose the tag/src to add. This is the curable side of lint Check 7.
5. Output the proposal as a unified diff **in the report only** — NEVER apply it. Applying learnings edits is a human/GATE 4 action.

## 3. Trunk health

For each repo path in `$ARGUMENTS` (none → skip): `gh run list --branch <default-branch> --limit 3 --json conclusion,name,url`. Any failing conclusion → list the repo, workflow name, and URL. Red trunk here means the next `/new-task` run inherits it — flag it before it's misread as a regression.

## 4. Context metrics

1. Run the deterministic aggregator: `sh <workflow-repo>/hooks/context-report.sh --top 10` (samples are written per turn by the `context-metrics` Stop hook `install.sh` registers; the report needs no LLM). It prints `context: no metrics` when the hook has produced nothing yet — report that line and stop this check.
2. Surface the report table verbatim (top sessions by max context, mean, cold re-entries).
3. Flag two thresholds from the 2026-07-20 context-compaction proposal: any session with high-water **> 250k** (auto-compaction territory — the disposal-rule/run-ledger machinery is load-bearing there), and total cold re-entries **> 5** since the last maintenance run (cache TTL bleeding at gates/CI wakes — the signal that would justify the proposal's S6 tail hand-off). Report-only; this check writes nothing.

## Summary

Compact, four lines max per check: what was committed (check 1), proposed diff or `learnings: clean` (check 2), red trunks or `trunks: green` (check 3), context high-water + cold-re-entry line or `context: no metrics` (check 4). No transcripts, no raw logs.
