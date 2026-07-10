# Scorecard — 2026-07-10 — /explain per-case coverage (tasks 11–14)

Extends the `/explain` baseline (task 10, Mechanism) with four more case fixtures, so the
command's per-case output contracts are each exercised on a live run. All read-only,
searcher-tier, inline synthesis. Judge verified every `file:line` citation against the
fixture source.

Command: `/workflow-eval --tasks 11,12,13,14` · repeat 1 · driver `/explain`

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS.

## Layer 2 — per-case results

| Task | Case | Question | Routing | Outcome | Efficiency | Score |
|---|---|---|---|---|---|---|
| 11 | **Why (7)** | why accept an empty bearer token? | 100 | 100 | 100 | **100** |
| 12 | **Locate (1)** | where is calc.Sum defined + tested? | 100 | 100 | 100 | **100** |
| 13 | **Impact (5)** | what calls calc.Sum? | 100 | 100 | 100 | **100** |
| 14 | **Architecture (4)** | overview of the module structure | 100 | 100 | 100 | **100** |

(No-escaped + Gate n/a for all; renormalized over 65. Each run: git clean, no
`architect`/opus, synthesis inline, ~34–35k tokens.)

## Highlights

- **Why (case 7) — the differentiator held under test.** The run sourced the empty-token
  behavior to the mechanism (`auth/auth.go:11`) and the documenting `NOTE`
  (`auth/auth.go:8-9`), then explicitly declared **"no recorded rationale found"** for
  *why* it is permitted — the code documents *that* it happens, not *why*, and git history
  is silent. It refused to invent a security rationale. That grounded, honest "why" —
  including the negative result — is precisely what ad-hoc exploration doesn't give.
- **Locate** returned a ranked `path:line` list (not a prose walkthrough — the contract
  boundary against Mechanism held).
- **Impact** reported **no production callers** honestly (only the two unit tests), with a
  ~zero-production blast radius — no fabricated caller.
- **Architecture** produced the component-map table **and** a Mermaid diagram, correctly
  stating the two packages are independent (no cross-import) with no `main` entry point.

## Coverage & what's owed

Cases measured live now: **5 of 7** — Mechanism (task 10), Why (11), Locate (12), Impact
(13), Architecture (14), all = 100, 0 fabrications.

**Owed:** the remaining two cases — **Flow / trace (3)** and **Compare (6)** — are not
exercised because the minimal `calc` + `auth` fixture has no real call chain to trace and
no natural symbol pair to compare. They need a **richer multi-file fixture** (a small call
graph + two comparable implementations) before their contracts can be scored. Also: raise
`--repeat` before treating the per-case 100s as more than single samples.

## Verdict

Every `/explain` output contract exercised so far holds, classification was correct on all
five cases, grounding was verified against source with zero fabrication, and every run
stayed at the cheapest tier. The command is functionally proven across the majority of its
surface; Flow + Compare coverage awaits a richer fixture.
