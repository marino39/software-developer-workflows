# Scorecard — 2026-07-10 — /explain Flow + Compare (tasks 15–16), closing 7/7 coverage

Closes the two `/explain` cases the minimal `base` fixture couldn't exercise —
**Flow/trace (3)** and **Compare (6)** — using a new richer fixture, `evals/fixtures/app`
(the `appfixture` module: a real call chain + a comparable pair). With these, all seven
`/explain` output contracts are now exercised on a live run.

Command: `/workflow-eval --tasks 15,16` · repeat 1 · driver `/explain` · fixture `app`

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS.

## Layer 2 — results

| Task | Case | Question | Routing | Outcome | Efficiency | Score |
|---|---|---|---|---|---|---|
| 15 | **Flow / trace (3)** | trace `cart.Checkout` | 100 | 100 | 100 | **100** |
| 16 | **Compare (6)** | `discountPercent` vs `discountFlat` | 100 | 96 | 100 | **98** |

(No-escaped + Gate n/a; renormalized over 65. Judge verified every citation against
`fixtures/app` source. Each run: git clean, no `architect`/opus, inline synthesis,
~35k tokens.)

## Highlights

- **Flow (case 3)** produced the ordered entry→hops→exit sequence with each hop cited,
  correctly including the validation error **short-circuit** and the `code` branch, **plus
  a Mermaid `sequenceDiagram`** — the structural-case diagram contract. Chain
  (`Checkout → validate → subtotal → applyDiscount → discountPercent|discountFlat`) exact,
  no invented call.
- **Compare (case 6)** produced the comparison table + when-to-use, capturing the real
  contrasts (multiplicative vs subtractive, scaling vs fixed cents) and — the insightful
  part — the **asymmetry the code actually has**: `discountFlat` clamps to zero while
  `discountPercent` has no guard and trusts its input. Text-only (correctly no diagram).
  −2 for one trivial line-range off-by-one in a citation (`13-19` vs `13-18`); not a
  fabrication.

## Coverage — now 7 of 7

Every `/explain` case is measured live at least once, all grounded, 0 fabrications:

| Case | Task | Score |
|---|---|---|
| Locate (1) | 12 | 100 |
| Mechanism (2) | 10 | 100 |
| Flow/trace (3) | 15 | 100 |
| Architecture (4) | 14 | 100 |
| Impact/usage (5) | 13 | 100 |
| Compare (6) | 16 | 98 |
| Why/rationale (7) | 11 | 100 |

## Verdict

All seven `/explain` output contracts hold on live runs, classification was correct on
every case, grounding verified against source with zero fabrication, and every run stayed
at the cheapest tier. The command is now functionally proven across its full surface. Only
remaining follow-up: higher `--repeat` to firm the per-case single samples.
