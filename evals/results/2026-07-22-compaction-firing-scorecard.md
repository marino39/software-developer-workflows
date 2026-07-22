# Workflow eval scorecard — 2026-07-22 (compaction-suggestion FIRING path)

**Label:** compaction-firing · **Suite:** task 22 (n=1) · **Trigger:** the firing
half of the 2026-07-22 compaction-suggestion rule (`commands/iterate.md` Retro
step 1 accumulation marker; ledger row 2026-07-22). Companion to
`2026-07-22-compaction-suggestion-scorecard.md`, which covered only the
*suppression* path (single-delta runs); this run exercises the *accumulation*
trigger firing mid-session.

**Methodology note (material — read first).** The driver subagent completed all
three deltas and wrote the manifest, but **hung before returning its structured
report** (~82 min idle, no completion event). Rather than re-run (and risk another
hang), this scorecard is scored by **direct verification of the ground-truth
artifact** — the manifest iteration log the rule mutates — plus the fixture working
tree and the deterministic `context-trace.sh`. For a firing test whose pass
condition is a *file mutation* (a row tagged `compact-suggested`, present/absent per
delta, counter reset), reading the artifact is stronger evidence than a judge
reading a driver's self-report. What is therefore **verified** vs **unverified** is
called out per dimension below.

## Layer 1 — lint

8/8 pass (unchanged from `2026-07-22-compaction-suggestion-scorecard.md`; task/ledger
additions don't touch the linted instruction files, ledger row re-validated by
Check 6).

## The firing control (verified from the manifest artifact)

Manifest iteration log after the session (verbatim, the rows the rule wrote):

| Delta | Log rows after | Rows since last marker | Rule (b) `≥3` | `/compact` fired | Row tagged `compact-suggested` |
|---|---|---|---|---|---|
| seed (prior /new-task) | 1 | — | — | — | — |
| 1 — `## Building` | 2 | 2 | no | **no** ✓ | no ✓ |
| 2 — `## Testing` | 3 | 3 | **yes** | **YES** ✓ | **yes** ✓ → counter reset |
| 3 — `## Contributing` | 4 | 1 (since row-3 marker) | no | **no** ✓ | no ✓ |

**Firing control: PASS.** The suggestion surfaced on **delta 2 only** (the delta that
brought the log to 3 rows since the last marker), that row is tagged
`compact-suggested`, and the reset was honored — delta 3 (1 row since the marker)
correctly did not re-fire. Rule (a) never fired (scoped, doc-only, local-kept on
every delta), so delta 2's fire is unambiguously the accumulation trigger. The
batched Phase 7 at `--finish` explicitly recorded "fired once, on delta 2 … counter
reset; delta 3 correctly did not re-fire."

## Layer 2 — scores (artifact-verified)

| Dimension | Score | Basis |
|---|---|---|
| Routing (35 = 25 +10 reweight) | 100 | Manifest shows scoped inherited on all three deltas, no escalation, delta review each — verified in the log rows. |
| Outcome correctness (25) | 100 | README working tree carries Usage + Building + Testing + Contributing; **no `.go` file modified** (`git status -- '*.go'` clean); `go test ./...` green. Verified. |
| No escaped defects | n/a (doc-only) | 20 pts reweighted +10 Routing, +10 Gate discipline (per task-22 `expect`). |
| Gate discipline (25 = 15 +10 reweight) | 90 | **Firing control fully verified** (table above) — the dimension this task exists to score. Docked 10: the driver hung before returning the per-gate GATE I summary *prose*, so Results/Key-decisions/Deviations/Next well-formedness is unverified (only the log rows, which are well-formed, survive). |
| Efficiency (15) | 85 | 3 delta iterations within caps, one batched retro, no escalation (context trace 40 turns / 48.0k high-water / 39.8k mean / 27.8k first-floor / 3 cold). Docked for the driver **hang** — a harness reliability issue, not a workflow cost. |

**Task score (weighted, renormalized): ~95.25.**

## Regression / relationship to the suppression scorecard

Not a regression run (new task, no prior baseline for task 22 → `baseline
established, no prior scorecard`). Together with `2026-07-22-compaction-suggestion`
(tasks 04/05, suppression), the rule is now evidenced on **both** paths: correctly
**withheld** on single small deltas (04/05) and correctly **surfaced + tagged +
reset** on accumulation (22). The candidate ledger row's owed "multi-`/iterate`-session"
evidence is now supplied.

## Caveats & still-owed

1. **Driver fidelity:** the hung inline driver applied the three deltas to the
   working tree but did **not** commit each as a separate per-delta commit (`git log`
   shows only base + seed); a faithful `/iterate` finalizes each delta at its GATE I.
   This is a driver/harness execution artifact (same class as the inline-execution
   note in the delegation-floor and suppression scorecards) — it does not touch the
   firing control, which lives entirely in the manifest the rule wrote. A clean
   re-run in a local CLI (Agent tool available to drivers, no hang) would confirm the
   per-delta commit cadence alongside the firing behavior.
2. **n=1** — the firing behavior is deterministic (a counted file mutation), so n=1
   is more load-bearing here than for a judged quality dimension, but a `--repeat`
   pass is cheap insurance.
3. **Cost telemetry** for the win the rule targets (cold-re-entry `/usage` over a
   post-GATE-3 CI wait) remains owed, as in the suppression scorecard — suggestion-only
   + opt-in, so not ablation-gated.
