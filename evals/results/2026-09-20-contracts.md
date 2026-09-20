# Contract report — 2026-09-20

`/workflow-eval --contracts` (Layer 3), all 7 agents, dispatched at their pinned
frontmatter models via the Agent tool against isolated `fixtures/base` copies.
Judged against each `evals/contracts/<agent>.md` expected-fields spec plus the
agent's own `## Output contract`; read-only role adherence determined
deterministically by `git status` in the fixture copy.

## Results

| Agent | Stimulus | conform | Missing fields | Violations |
|---|---|---|---|---|
| `searcher` | where is `Sum` / what calls it | **pass** | none | none — read-only, `git status` clean |
| `architect` | A: inline mode | **pass** | none (6/6 sections) | none — fixture untouched |
| `architect` | B: artifact mode | **pass** | none | none — **only** `artifact_path` created; 904-word plan on disk with all six sections, inline reply carried `artifact_path` + summary + step titles only |
| `coder` | `Mode` + `TestMode` (unpinned tie-break) | **pass** | none (6/6) | none — scope stayed in `calc/`; suite green |
| `debugger` | `TestSum` off-by-one digest | **pass** | none (4/4) | none — root cause verified by bisect *before* the fix; fix minimal |
| `researcher` | stdlib product helper? | **pass** | none (4/4) | none — network reachable, so **not** skipped |
| `test-runner` | run `go test ./...` on a seeded-red fixture | **pass** | none | none — no source modified, `git status` clean |
| `reviewer` | 1: clean diff | **pass** | none | none — PASS with no issues, as the spec expects |
| `reviewer` | 2: finding-bearing | **FAIL** | none | **invented a severity level outside the declared enum** — see below |
| `reviewer` | 3: merged four-lens remit | **pass** | none | none — all 4 lenses reported, confidences 95/92/85/50, within the ~500-word cap |

**Suite: 9/10 pass, 1 fail** (before the fix below).

## The failure, and the fix

The finding-bearing stimulus exists to exercise `severity` + `confidence`, and the
contract spec names this exact failure mode in advance: *"`severity` uses only the
declared enum (`blocker` | `minor`). A third value invented at report time (e.g.
`note`) is a contract deviation: consolidation buckets on this field."*

The reviewer found **all three planted defects** (out-of-plan public function,
unguarded `len(xs)` division, two WHAT-restating comments) with well-discriminated
confidences (98/85/80) — detection was not the problem. It then filed a fourth
finding as `Informational (confidence 60)`. `Informational` is in neither bucket,
so Phase 6 step 4's consolidation would route it nowhere and the finding is lost
silently.

Note it is **drift, not a deterministic break**: the merged-remit stimulus, same
agent and same planted defects, used the enum correctly. 1 of 2 finding-bearing
runs violated it.

**Fix applied** — `agents/reviewer.md` verdict-format line now pins the enum and
names the consequence, rather than parenthesising it:

> each with `severity` — **exactly one of `blocker` or `minor`, never a third
> level**: consolidation buckets on this field, so an invented one
> (`informational`, `note`, `nit`) lands in neither bucket and the finding is
> silently lost. A real but non-blocking finding is `minor` with a low
> confidence, not a new severity

**Re-run after the fix: 2/2 conform.** Both repeats returned only `blocker`/`minor`
(98/85/60/85/80 and 98/90/85/80/40), kept all three planted defects, and kept
confidence discrimination. The finding that had been filed as `Informational`
reappeared as `minor` with a low confidence — which is the routing the
consolidation pass can actually act on.

Per CLAUDE.md, an agent edit is behavior-affecting; the owed `--contracts` re-run
is the one recorded above. No `evals/contracts/reviewer.md` change was needed — the
spec was already correct and is what caught this.

## Recorded, not scored

- **`coder` stretch check not met.** `assumptions` named the tie-break and marked it
  unpinned ("The plan didn't specify tie-breaking behavior") — the **required**
  check, met. It did not name the empty-slice choice (the stretch check, measured
  2/3 historically). Consistent with the spec's own note that the stretch signal is
  real but not reproducible enough to fail a run on.
- **Nested delegation was unavailable** (see the Layer-2 scorecard). `coder`,
  `architect` and `debugger` declare `Agent` in their tools and would normally reach
  `test-runner`/`searcher`; here they did that work inline. It changed no contract
  outcome — every agent still filled its declared fields — but `coder`'s
  `test_status` came from its own Bash call rather than a `test-runner` digest.
