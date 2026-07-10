# Scorecard — 2026-07-10 — triage-cold A/B (task 09, warm vs cold Phase 0)

The warm-vs-cold ablation of the `/new-task` **triage warm-start seam**. Baseline =
the seam ON (Phase 0 seeds from the triage manifest); variant `triage-cold` = the
manifest ignored, Phase 0 run from cold. Repeat 3 per condition.

Because the conditions differ **only in Phase 0** (implement/review are identical
downstream by construction), the runs execute Phase 0 for real — genuinely spawning (or
not) the `searcher`/`researcher` fan-out — and the measured signal is the Phase-0 delta.
Command intent: `/workflow-eval --tasks 09 --variant triage-cold --repeat 3`.

## Raw

| Run | Condition | Searcher | Researcher | Route | tool_uses | subagent_tokens | wall-clock (ms) |
|---|---|---|---|---|---|---|---|
| w1 | warm | no | no | scoped (floor) | 2 | 41628 | 17927 |
| w2 | warm | no | no | scoped (floor) | 2 | 42002 | 23615 |
| w3 | warm | no | no | scoped (floor) | 2 | 42128 | 25109 |
| c1 | cold | **yes** | no | scoped (cold) | 3 | 42588 | 45408 |
| c2 | cold | **yes** | no | scoped (cold) | 3 | 40698 | 74441 |
| c3 | cold | **yes** | no | scoped (cold) | 3 | 40322 | 64795 |

## Aggregates (warm → cold)

| Metric | Warm mean | Cold mean | Δ |
|---|---|---|---|
| Fan-out spawns (searcher+researcher) | **0** | **1** (searcher) | seam removes 1 spawn/run |
| tool_uses | 2 | 3 | +1 (the searcher) |
| subagent_tokens | 41 919 (41.6–42.1k) | 41 203 (40.3–42.6k) | **~0 — neutral, ranges overlap** |
| wall-clock | **22.2 s** (17.9–25.1) | **61.5 s** (45.4–74.4) | **cold 2.8× — non-overlapping** |
| Route landed | scoped | scoped | **0 — floor did NOT bind (cold agreed)** |
| Escaped defects | — | — | **0 (identical downstream by construction)** |

## Reading

- **Latency: the seam clearly wins.** Warm skips the `searcher` round-trip → Phase 0 is
  ~2.8× faster (22 s vs 62 s), non-overlapping across all 3 vs 3. This is the concrete,
  measured saving on this task.
- **Tokens: neutral here — and this is the honest, slightly counterintuitive result.**
  The dispatched-agent token metric is dominated by reading the Phase 0 instructions +
  reasoning (~41–42k), which **both** conditions pay; the one extra searcher spawn barely
  moves it at this scale. So the fan-out saving shows up as *latency and one fewer spawn*,
  not tokens, on a trivial one-file bug. On a **non-trivial codebase** the cold searcher
  would do materially more work (map real layout/patterns), so the token saving should
  grow with codebase size — UNMEASURED here; this fixture is a lower bound.
- **Route floor: did NOT bind — safety benefit UNMEASURED.** An unambiguous off-by-one is
  textbook `scoped`, so cold routing *agreed* (scoped in all 3). The floor's value is
  preventing a *cold downgrade* on an ambiguous/high-stakes-baseline task — which this
  isn't. Zero downgrades observed, but also zero opportunity. (Exactly the `/iterate`
  route-floor finding: determinism/safety needs an ambiguous task to demonstrate.)
- **No quality cost:** both hand downstream the identical scoped one-line fix; 0 Δ escaped.

## Verdict

`triage-cold: 0 Δ escaped defects · ~0 Δ tokens (noise; fixed Phase-0-spec read dominates
at this scale) · −64% Phase-0 wall-clock (22 s vs 62 s) · 1 fewer fan-out spawn · route
floor did NOT bind (cold agreed scoped) → the seam is JUSTIFIED on latency + determinism
here; its token saving (needs a real codebase) and floor-safety (needs an ambiguous-route
task) are set up but UNMEASURED.`

Ledger row `Triage warm-start seam` → **keep (qualified)**, MEASURED partial. Owed to fully
close: (a) a non-trivial-codebase task to size the token saving; (b) an ambiguous- or
high-stakes-baseline task where cold routing could downgrade, to make the floor bind.
Single-condition n=3; raise repeat before over-trusting the wall-clock magnitude.
