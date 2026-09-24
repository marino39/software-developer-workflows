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

## The failure, and the fix — corrected

The finding-bearing stimulus exercises `severity` + `confidence`, and the contract
spec names the failure mode in advance: a severity invented outside the declared
`blocker | minor` enum is a contract deviation.

The reviewer found **all three planted defects** (out-of-plan public function,
unguarded `len(xs)` division, two WHAT-restating comments) with well-discriminated
confidences (98/85/80) — detection was not the problem. It then filed a fourth
finding as `Informational (confidence 60)`. **Drift, not a deterministic break**:
the merged-remit stimulus, same agent and same planted defects, used the enum
correctly — 1 of 2 finding-bearing runs violated it.

**Correction (2026-09-24, after branch review).** The first fix was built on a false
premise, copied from this spec: that "consolidation buckets on this field". It does
not. Phase 6 step 4 re-scores every finding's **confidence** and buckets on that
(drop <50, 50–79 Should-fix, ≥80 Must-fix); it never reads severity. Worse, the first
fix told reviewers to file a non-blocking finding as `minor` *with a low
confidence* — which steers real findings into the <50 drop. The "2/2 conform"
re-run reported here earlier satisfied the enum while doing exactly that (one
finding at confidence 40), so it was not evidence the fix worked.

What severity actually governs is the **reviewer's own PASS/FAIL** ("FAIL only on
blockers"), so an invented level leaves the verdict undefined — a real reason to
keep the enum, and a smaller one than first claimed.

**Fix as corrected** — `agents/reviewer.md`:

> each with `severity` — **exactly one of `blocker` or `minor`, never a third
> level**: your PASS/FAIL turns on it, so an invented level (`informational`,
> `note`) leaves the verdict undefined. **Severity and confidence are
> independent**: a certain but non-blocking finding is `minor` at HIGH confidence
> — consolidation drops anything under 50, so low confidence used to mean
> "unimportant" deletes the finding

`evals/contracts/reviewer.md` corrected to match: the false "buckets on this field"
reason is replaced, and a new expected-field bullet makes low-confidence-as-
unimportance a contract smell even when the enum holds.

**Re-run after the correction.** Pass bar: enum held, all three planted defects
found, and the two WHAT-restating comments (certain, non-blocking) filed as `minor`
at confidence ≥ 50, so they survive consolidation.

| Repeat | Enum | Planted defects | WHAT-comment confidences | Verdict |
|---|---|---|---|---|
| C | `blocker`/`minor` only | 3/3 | **85, 75** (both survive) | **pass** |
| D | `blocker`/`minor` only | 3/3 | **85, 80** (both survive) | **pass** |

**2/2 pass on the corrected bar.** Both repeats filed the certain-but-minor comment
findings at high confidence; nothing real would fall under the <50 drop. D reported
a revert-discriminate check via "checking out" commits; the fixture's reflog shows
no checkout and `git status` is clean with HEAD unmoved, so the read-only
constraint held.

Per CLAUDE.md, an agent edit is behavior-affecting; the owed `--contracts` re-run
is the one recorded above. `evals/contracts/reviewer.md` WAS changed — its stated
reason for the enum was the false premise the first fix inherited.

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
