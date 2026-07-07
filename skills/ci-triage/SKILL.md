---
name: ci-triage
description: Triage failing CI runs — digest without ingesting raw logs, classify infra vs real, respect trunk-red inheritance. Use whenever a PR check or workflow run fails.
---

# CI triage

## 1. Trunk first

Before treating any failure as yours: `gh run list --branch <default-branch> --limit 3`. Trunk already red → the PR inherits that red. Record it in the digest and do NOT chase it as a regression in the diff.

## 2. Digest, don't ingest

Raw CI logs never enter the orchestrator's context. Send failing run IDs to `test-runner` for `gh run view <run-id> --log-failed` digested to: failing check names, assertion/error per failure, file:line, 5–10 relevant log lines each, ~300 words total.

## 3. Classify: infra vs real

- **Infra-smelling** (runner setup, network timeouts, quota, artifact download): one free `gh run rerun <run-id> --failed` — it does not cost an iteration. One only; a second infra-looking failure is treated as real.
- **Real** (test assertion, build error, lint): costs an iteration; goes to a coder with the digest. The fix is then proven per the `verify-fix` skill — reproduce with CI's exact command first.

## 4. CI adjudicates

Local green is a hypothesis. The loop terminates on green checks, an exhausted iteration cap (halt + failure digest), or a diagnosis that the failure is real-but-out-of-scope (report, don't grind).
