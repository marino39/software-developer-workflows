# Task 20 — learnings retrieval, activity vs subject tags (exercises /new-task Phase 0 two-class tag matching)

## Statement (passed to /new-task)

> Add `calc.Min(xs []int) (int, bool)` to the `evalfixture` module, returning the
> smallest element and `true`, or `(0, false)` for an empty/nil slice — mirroring
> the existing `calc` conventions. Add a test covering a normal slice and the
> empty case.

## Fixture

`fixtures/base` — green, no `## Seed`. The task itself is a routine small feature;
what is under test is **which learnings bullets Phase 0 applies**.

## Learnings (stands in for `~/.claude/new-task/LEARNINGS.md` — supplied via the preamble; the real live file must NOT be read)

```markdown
# /new-task learnings — general

- 2026-07-10 [review] In every implementation review, explicitly verify that new
  exported functions handle degenerate inputs (empty/nil slices, zero values) and
  state the check's result in the review report. — src: retro 2026-07-10-degenerate
- 2026-07-09 [rust] Run `cargo clippy --all-targets` and treat warnings as blockers
  before any commit. — src: retro 2026-07-09-clippy
- 2026-07-08 [pr][ci] Re-fetch origin and re-check `HEAD..origin/<default>` for the
  task ID immediately before `gh pr create`. — src: retro 2026-07-08-refetch
```

## Planted controls (what a correct run does)

- **`[review]` (activity tag) MUST be applied** — every route reviews, so the
  bullet is in force regardless of the task's subject. Observable twice: (a) the
  first human touchpoint lists it as applied with the activity-class reasoning;
  (b) the implementation-review output explicitly states the degenerate-input
  check and its result for `calc.Min`.
- **`[rust]` (subject tag) MUST NOT be applied** — the task's subject is Go; no
  rust signal. Observable: no clippy invocation anywhere; the first touchpoint
  lists it as excluded with the subject-class reasoning.
- **`[pr][ci]` (activity tags) MUST NOT be applied** — activity matching cuts
  both ways: this run's outcome is a local fixture change, no PR is planned, so
  the pr/ci activities never run. Observable: listed as excluded because the
  activity is not planned (NOT because the subject doesn't match).
- The disclosure requirement is Phase 0's own text: "State which bullets were
  applied (and which were excluded, with the class reasoning) at the first human
  touchpoint."

## Expected behaviour

- Phase 0 applies exactly one bullet (`[review]`) and excludes two, with per-class
  reasoning disclosed at the first gate.
- The route is `scoped` or `standard` (a small new exported function sits between
  Phase 0's enumerations; either is credited **iff the rationale is stated**).
- `calc.Min` implemented per conventions; tests cover normal + empty/nil; suite
  green; behavioral verification runs (feature with a runtime surface).
- The review phase's report contains the degenerate-input check for `Min` (the
  applied bullet's behavioral delta) — on the fast path this lands in the Phase 6
  reduced-tier review; on the standard route in the Phase 6 fan-out/consolidation.
- No clippy, no PR machinery, nothing posted.

## expect (scoring overrides)

- `Routing`: scoped or standard with stated rationale = full credit; also
  requires the Phase 0 learnings disclosure (applied/excluded + class reasoning)
  at the first touchpoint — absent disclosure caps Routing at 60.
- `Outcome correctness`: `calc.Min` correct for normal + empty/nil (`(0,false)`),
  tests cover both, `go test ./...` green.
- `No escaped defects`: **the retrieval controls are the defects** — (a) the
  `[review]` bullet not in force (review report lacks the degenerate-input check
  statement) scores ≤ 20 + an escaped defect; (b) the `[rust]` bullet applied
  (any clippy attempt) or the `[pr][ci]` bullet applied (PR machinery on a local
  run) likewise.
- `Gate discipline`: gate summaries well-formed AND the learnings disclosure
  present with per-class reasoning (activity vs subject named, not just a list).
- `Efficiency`: no needless model escalation; no machinery the route doesn't
  call for.
- Fail the run if the real `~/.claude/new-task/LEARNINGS.md` was read instead of
  the supplied block.
