---
name: verify-fix
description: Prove a bug fix is real before reporting done — CI-exact reproduction, revert-discriminate proof for new repro tests, race matrix for concurrency. Use for every bug-fix diff and every CI-failure fix.
---

# Verify a fix

A fix is a hypothesis until each applicable check below passes. Report which checks ran and their results.

## 1. Reproduce and verify with CI's EXACT command

Run the failing check exactly as CI does — same flags, same `-count`, and an explicit `-timeout`. A gate that stresses harder than CI in a way that changes the failure mode produces false alarms (e.g. `-count=5` without `-timeout` hits go test's 10-min ceiling and fakes a deadlock). Find the command in the workflow YAML or CI logs; never approximate it.

## 2. Revert-discriminate proof (every NEW repro test)

A new test only counts as a repro if it discriminates:

1. Revert ONLY the production hunk (keep the test).
2. Re-run — the test MUST fail. If it passes, it doesn't guard the bug; fix the test.
3. Restore the production hunk; the test passes again.

For lost-wakeup/interleaving tests, additionally confirm the interleaving hook fires in the condition-read→wait gap and stays textually stable across old and new code.

## 3. Wrong test or wrong fix?

When a new test fails, ask "wrong test or wrong fix?" FIRST: grep existing semantics tests for the behavior under assertion. An established test may prove the new expectation itself is wrong — don't bend production code to a mistaken assertion.

## 4. Race matrix (concurrency/storage code)

"Passes locally, fails on CI" in concurrency code is a real-race signal, not a flake. Reproduce with `GOMAXPROCS=2`, `-race`, and a `-count` high enough to surface the interleaving (equivalent stress flags in other languages) before any masking change. Grep every user of the shared primitive — sibling call sites often carry the identical defect; fixing only the reported site ships a half-fix.

## 5. CI adjudicates

Local green — even with an injected repro — is a hypothesis. Push and let CI confirm before declaring the fix verified.
