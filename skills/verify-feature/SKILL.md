---
name: verify-feature
description: Prove a feature behaves as specified by driving it end-to-end before code review — execute the plan's Verification section, exercise the changed flow, report observed vs expected. Use for every non-bug-fix diff with a runtime surface.
---

# Verify a feature

Static review reads the diff; it cannot observe behavior. A green test suite is necessary, not sufficient — a feature is a hypothesis until the checks below run. Report which checks ran and their results; this report feeds the Phase 6 computed verdict.

## 1. Execute the plan's Verification section

The plan (Phase 3 contract) lists per-step verification. Actually RUN each item — build/run the binary, start the server, invoke the CLI, run the named test — don't just confirm the suite compiles-and-passes and infer the rest. An unexecuted verification item is a gap, not a pass.

## 2. Drive the changed flow

Exercise the new or changed path end-to-end with real inputs: the entry point a user (or caller) would hit, not just the unit under test. Capture observed output against expected per item. One happy path plus the edge the plan flagged as risky is the minimum; a flow that can't be driven (no runtime surface reachable) is reported as such, never silently skipped.

## 3. Exemptions

- **Doc-only / dead-code-removal diffs** — no runtime surface. Verification = build + vet + existing suite + reviewer accuracy pass (comments/claims vs code).
- **Bug fixes already proven per `verify-fix`** — that skill's CI-exact reproduction and revert-discriminate proof subsume this one; don't double-verify.

State the exemption and reason explicitly: `verification: exempt (<reason>)`.

## 4. Report format

Per verification item: the command/action run, expected, observed, PASS/FAIL. Then one line: overall pass / fail / exempt. Compact — ~300-word cap, no raw logs (delegate long runs to `test-runner` and cite its digest).
