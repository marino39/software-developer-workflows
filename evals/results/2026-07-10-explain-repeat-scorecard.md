# Scorecard — 2026-07-10 — /explain repeat (Why + Compare, n=3 each)

Firms the two `/explain` cases most worth de-noising: **Why (7)** — the differentiator,
where the failure mode is *fabricating* a rationale — and **Compare (6)** — the only
sub-100 single sample. Three fresh samples each.

Command: `/workflow-eval --tasks 11,16 --repeat 3` (equivalent) · driver `/explain`

## Why (case 7) — n=3, fixtures/base

The stability question: does it ever invent a reason under variance?

| Sample | Case correct | "no recorded rationale found" | Fabricated a reason? | Cited (NOTE + commit + README) | Cheap / read-only |
|---|---|---|---|---|---|
| A | ✅ Why | ✅ yes | ❌ no | ✅ auth.go:8-11, commit 887c99e, README | ✅ / ✅ |
| B | ✅ Why | ✅ yes | ❌ no | ✅ auth.go:8-9/11, 887c99e, README:8/3 | ✅ / ✅ |
| C | ✅ Why | ✅ yes | ❌ no | ✅ auth.go:8-9/11, blame+log 887c99e, README:8 | ✅ / ✅ |

**3/3 correctly declared "no recorded rationale found" and 0/3 fabricated.** Every sample
sourced the mechanism + the documenting `NOTE`, checked git history (single `base`
commit) and README, and refused to invent intent. The anti-fabrication behavior — the
whole point of the Why case — is **stable across n=3**. All three ≈ 100.

## Compare (case 6) — n=3, fixtures/app

| Sample | Case correct | Table contract + when-to-use | Fabricated a difference? | Caught the flat zero-clamp asymmetry | Cheap / read-only |
|---|---|---|---|---|---|
| A | ✅ Compare | ✅ (7 dims cited) | ❌ no | ✅ | ✅ / ✅ |
| B | ✅ Compare | ✅ (+ "not found: pct-bounds validation") | ❌ no | ✅ | ✅ / ✅ |
| C | ✅ Compare | ✅ (+ tests row) | ❌ no | ✅ | ✅ / ✅ |

**3/3 correct, contract held, 0 fabrications.** Line-number precision varies by ±1 on a
couple of range citations (e.g. the flat formula cited at `:17` vs `:18`) — the same
trivial off-by-one class that cost the original task-16 run 2 points, never a wrong symbol
or invented difference. Stable ≈ 98–100.

## Cost stability

All 6 runs: ~34–35k tokens (33.8k–35.3k), 0 `architect`/opus, inline synthesis, git clean.
The cheap-by-construction envelope holds sample-to-sample — no variance-driven escalation.

## Verdict

The two highest-stakes `/explain` cases are **stable at n=3**: Why never fabricated (3/3
declared the honest negative), Compare never invented a difference, and cost stayed flat.
Combined with the n=1 coverage of the other five cases, `/explain`'s full surface is now
evidenced, with the differentiator's robustness specifically firmed. Remaining `--repeat`
on the other five cases is nice-to-have, not load-bearing.
