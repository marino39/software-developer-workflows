# Contract report — reviewer (2026-09-07)

Scope: `--contracts --agent reviewer`, run to discharge the obligation CLAUDE.md
attaches to an Output-contract change ("re-run `/workflow-eval --contracts --agent
<name>` to confirm the live agent still honors it"). The 2026-09-07 model-tuning
pass added a per-finding `confidence` field and removed the reviewer's pre-report
severity filter.

Fixture: `evals/fixtures/base` copy, git-initialized, BASE = seeded off-by-one,
HEAD = the fix. Agent dispatched at its pinned default (`model: sonnet`).

## Result

| Stimulus | conform | missing fields | violations |
|---|---|---|---|
| Single-lens (clean diff) | **pass** | none | none |
| Merged four-lens remit (clean diff) | **pass** | none | none |
| Finding-bearing (3 planted defects) | **pass** | none | one deviation — see below |

`git status` clean in the fixture copy after every run: the read-only role
constraint held, no agent edited a file.

## What each stimulus established

**Single-lens.** PASS with no issues, correctly omitting `lens_coverage` (declared
absent for single-lens dispatches). It volunteered the revert-discriminate proof
unprompted — confirmed `TestSum` fails at BASE (`5, want 6`) and passes at HEAD.

**Merged remit.** Reported all four lenses by name (plan compliance, bug scan, git
history, CLAUDE.md compliance), each with findings or `none` — the failure mode the
merged remit exists to prevent (a silently dropped lens reading as clean at
consolidation) did not occur. Lens (d) was correctly resolved as not-applicable
rather than skipped: it noted the fixture module has no `CLAUDE.md` and that the
workflow repo's own does not govern it.

**Finding-bearing — the load-bearing one for this pass.** Three defects were
planted (an out-of-plan public `Mean`, an unguarded `total / len(xs)` where `Sum`
supports nil, and two WHAT-restating comments). All three were caught, verdict
`FAIL`, and:

- **Every issue carried a `confidence`** — the new field is honored.
- **The values discriminate**: 97 for the scope violation (unambiguous from the
  plan text), 60 for the division (real, but in code the plan never sanctioned),
  90/90 for the comment-hygiene pair. A uniform score across findings of visibly
  different certainty would have been a contract smell; this is not that.
- **Nothing was suppressed for being minor.** Both comment-hygiene findings were
  reported under the FAIL, and the reviewer additionally reported the *correct*
  part of the diff as an explicit item rather than staying silent about it. This
  is the M3 behavior change working: the pre-report severity filter is gone and
  the filtering has moved to the orchestrator's confidence-scored consolidation
  pass, which now receives a confidence it was previously guessing.

## Deviation recorded

The finding-bearing run used a **third severity value, `Note`**, outside the
declared enum (`blocker` | `minor`). Phase 6 step 4 buckets on `severity`, so an
unrecognized value is a real (if small) integration risk — an out-of-enum severity
has no defined confidence band. Not scored as a contract failure: the field is
present and the finding is legible, and the item it labelled was a positive
observation the contract has no bucket for. Logged as the open item below.

## Method note — the stimulus gap this run exposed

The reviewer contract's only stimuli were **clean diffs**, on which a conforming
reviewer returns PASS with no issues. `severity` and `confidence` are therefore
never exercised by them, and the per-finding rules added to the contract spec in
this pass **could not have failed** on the existing stimuli. The gap was invisible
until the field was actually looked for. A finding-bearing stimulus has been added
to `evals/contracts/reviewer.md` so the fields are exercised from now on; this
report's third row is its first run.

The general lesson: a contract test whose stimulus cannot produce the output field
it checks passes vacuously.

## Open items

- Pin the `severity` enum at the reporting boundary, or widen it deliberately to
  admit a positive/observation bucket and give it a consolidation rule. Currently
  the agent invents one under pressure and consolidation has no bucket for it.
- The other six agents were not run in this scope. Their contracts did not change
  in this pass, but they have not been exercised since the 2026-07-20 report.
