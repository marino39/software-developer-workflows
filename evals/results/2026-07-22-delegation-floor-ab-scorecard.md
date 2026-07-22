# Workflow eval scorecard — 2026-07-22 (delegation-floor A/B)

**Label:** delegation-floor-ab · **Suite:** tasks 04 (n=1/condition), 05 (n=3/condition) · **Conditions:** pre = `commands/iterate.md` @ `f7eeefe` (parent of the floor commit) vs post = @ `f048e72` (delegation floor) · **Trigger:** behavior-affecting change under the modification protocol — the `/iterate` delegation floor (`commands/iterate.md`; ledger row 2026-07-22), prompted by a user report of `/iterate` under-delegating in live sessions.

**Methodology.** 8 isolated, git-initialized fixture copies seeded per the task files; 8 driver subagents dispatched in parallel, each given its condition's *literal* command text as the authoritative `iterate.md` (the pre condition is the real pre-change file, not a variant delta — `evals/variants/delegation-floor-off.md` now exists for harness-idiom reproduction). Same preamble, same telemetry return spec both sides. Primary read: deterministic traces (`evals/delegation-trace.sh`, `evals/context-trace.sh`) over the driver transcripts; secondary: fresh `reviewer` judges per run (blind to the A/B), each independently re-running build/test in its fixture.

**Environment characterization (material):** the remote harness did not expose the Agent tool to the driver subagents (nested dispatch unavailable; confirmed by every driver's probe). This makes the harness *dispatch-hostile*: delegation was only possible through initiative (e.g. headless `claude -p --agent` subprocess dispatch). That turns this A/B into a measure of **delegation intent under adversity**, not of the normal Agent-tool path — the local-CLI A/B (where prior scorecards measured warm runs at 4 real subagents) remains owed; see Verdict.

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS on the floor commit (pre-commit hook run) and on every subsequent commit on this branch.

## Layer 2 — deterministic delegation trace (the headline)

`evals/delegation-trace.sh` over each driver's own chain (spawns include rejected attempts and `claude -p` cli-fallback dispatches; self-edit excludes `docs/superpowers/` artifacts):

| Run | Spawns | Self-edit | Self-test | Delegation outcome |
|---|---|---|---|---|
| pre-04-r1 | 1 (rejected Agent attempt) | 1 | 2 | inlined everything after one failed probe |
| pre-05-r1 | 0 | 2 | 4 | inlined everything |
| pre-05-r2 | 0 | 2 | 4 | inlined everything |
| pre-05-r3 | 0 | 2 | 4 | inlined everything |
| **pre total** | **1 (0 effective)** | **7** | **14** | **0/4 delegated** |
| post-04-r1 | 0 | 2 | 1 | inlined; generic harness deviation recorded |
| post-05-r1 | 8 (cli-fallback) | **0** | **0** | **full floor: architect/coder/verify-coder/test-runner/reviewer via `claude -p --agent`; verification by coder before review spend (I2.2)** |
| post-05-r2 | 6 (cli-fallback) | **0** | **0** | **full floor: same 5-agent roster via cli-fallback; "delegation floor preserved" cited** |
| post-05-r3 | 0 | 2 | 3 | inlined; deviation explicitly states "delegation floor could not be honored" |
| **post total** | **14** | **4** | **4** | **2/4 fully delegated; 3/4 named or honored the floor** |

Under identical adversity, the floor moved orchestrator behavior from **0/4 runs delegating (7 self-edits, 14 self-run test commands)** to **2/4 fully delegating (0 self-edits, 0 self-tests on those runs)**, with a third run explicitly surfacing the floor as an unhonorable deviation. The pre condition's only dispatch attempt was abandoned after one rejection.

## Layer 2 — judge scores + cost

| Run | Routing | Outcome | No-escaped | Gate | Efficiency | Task score | Escaped | Driver cost (tok / tools / s) | ctx hiwater / cold |
|---|---|---|---|---|---|---|---|---|---|
| pre-04-r1 | 100 | 100 | n/a¹ | 97 | 75 | 95.5 | none | 77.0k / 24 / 345 | 76.5k / 2 |
| pre-05-r1 | 95 | 100 | 100 | 90 | 65 | 92.0 | none | 81.0k / 29 / 361 | 80.4k / 0 |
| pre-05-r2 | 100 | 100 | 100 | 100 | 70 | 95.5 | none | 87.8k / 29 / 343 | 87.2k / 0 |
| pre-05-r3 | 100 | 100 | 100 | 90 | 75 | 94.75 | none | 84.6k / 29 / 364 | 84.1k / 0 |
| **pre mean** | **98.75** | **100** | **100** | **94.25** | **71.25** | **94.44** | **0** | **82.6k / 345s** | |
| post-04-r1 | 100 | 100 | n/a¹ | 100 | 68 | 95.2 | none | 79.2k / 26 / 360 | 78.7k / 0 |
| post-05-r1 | 100 | 100 | 100 | 90 | 45 | 90.25 | none | 170.8k² / 36 / 562 | 89.1k / 0 |
| post-05-r2 | 100 | 100 | 100 | 92 | 65 | 93.55 | none | 87.1k² / 25 / 598 | 86.8k / 0 |
| post-05-r3 | 100 | 100 | 100 | 95 | 70 | 94.75 | none | 89.6k / 28 / 356 | 89.1k / 0 |
| **post mean** | **100** | **100** | **100** | **94.25** | **62** | **93.44** | **0** | | |

¹ Task 04 `expect`: *No escaped defects* n/a, reweight +10 Routing +10 Gate discipline.
² The two delegating runs' `claude -p` children are **unmetered** — their driver-context figures understate true total tokens; post-05-r1's figure spans two segments (it ended its turn awaiting background verification lanes — event-driven, not idle — then resumed).

**Regression check (post vs pre, per rubric):** no dimension dropped > 10 points (task-05 Efficiency mean 70 → 60 = −10, at but not over the threshold), zero new escaped defects → **no formal regression**. Prose flag the rubric requires: the Efficiency drop is real and is entirely the two delegating runs paying serial-subprocess dispatch overhead (562–598s vs ~350s inline) — see Verdict for why this does not price the real path.

## Verdict

`delegation-floor-off→on: Δ escaped defects = 0; Δ delegation = 0/4 → 2/4 full-floor runs (self-edit 7→4, self-test 14→4, effective spawns 0→14); Δ cost = driver-tokens ~flat (children unmetered), wall-clock +60–70% on the delegating runs (cli-fallback serial dispatch, this harness only) → the floor is justified on behavioral evidence at equal quality; its live cost/latency claim remains open.`

- **The floor changes behavior in the intended direction.** Same tasks, same adversarial harness: pre-text orchestrators absorbed all substantive work inline every time; post-text orchestrators fought to delegate — two achieved the full floor (0 self-edit / 0 self-test, verification executed by a dedicated coder *before* review spend, exactly I2.2), and a third made the floor's violation explicit at the gate instead of silent. This is the precise failure mode of the triggering user report, reproduced under pre and visibly countered under post.
- **Quality is unchanged.** 8/8 runs correct (judges independently re-ran build/vet/test), routes inherited with no escalation, all gates well-formed and honestly deviated, 0 escaped defects both sides. The floor buys delegation without paying quality.
- **This environment cannot price the real dispatch path.** Here delegation required serial `claude -p` subprocesses (slower, children unmetered); in the intended environment the Agent tool runs lanes in parallel on cheaper models (prior local measurements: warm `/iterate` = 4 subagents, ~68k, 320–360s). The judges' Efficiency dings (45–65 on delegating runs) are honest about *this harness* and say nothing about the local CLI.

**Owed to close:** the same A/B in a local CLI where the Agent tool is available to drivers — `/workflow-eval --tasks 04,05 --variant delegation-floor-off --repeat 3` — reading `delegation-trace.sh` (spawns should be real Agent dispatches; self columns 0) and comparing wall-clock/tokens with parallel lanes. That run supplies the cost/latency half of the floor's justification; this scorecard supplies the behavioral half.

## Notes

- Drivers auto-approved gates per the eval preamble; GATE 4 propose-only honored in all 8 runs (nothing written outside fixtures, no capture.sh).
- Both conditions saw identical harness limits (no Agent tool, `superpowers:*` unregistered); all 8 disclosed them as deviations — the *content* of the disclosure (generic vs floor-aware) is itself a condition effect, noted above.
- Two incidental findings surfaced by the runs (not scored): (a) three separate GATE 4 tables independently proposed the same I0-step-2 "untrack already-tracked `docs/superpowers/` artifacts at warm setup" instruction edit — a strong convergent candidate for a follow-up change; (b) task 05's frozen seed commits its manifest (predates the 2026-07-21 artifact-hygiene reversal), which every run then had to repair — consider refreshing the fixture seed when next editing the task.
- pre-04-r1's 2 cold re-entries are the only cache-bleed events; context high-water 77–89k across all runs, comparable both conditions.
