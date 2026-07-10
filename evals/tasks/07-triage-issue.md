# Task 07 — triage a bug issue (drives /triage-issue, exercises classify + repro + root-cause)

## Command

`/triage-issue --local` — this task drives **`/triage-issue`** (local/offline mode),
not `/new-task`. The `## Seed` reintroduces a real bug into the fixture copy; the run
triages the `## Issue` below against that code and returns a triage report **without
fixing anything**. See the driver note in `commands/workflow-eval.md` Layer 2.

## Issue (stands in for the fetched GitHub issue — passed as the issue text)

> **Title:** `calc.Sum` returns the wrong total
> **Body:** In the `evalfixture` module, `calc.Sum([]int{1,2,3})` returns 5, but it
> should return 6. Looks like it's dropping an element. Can someone look into this?

## Fixture

`fixtures/base` — green. The `## Seed` reintroduces the off-by-one in `calc/calc.go`
(same seed as task 02), so `TestSum` fails only after seeding — the existing test is
the discriminating repro the triage should find.

## Seed

Applied to the fixture copy after copy, before dispatch:

```sh
sed -i 's/for i := 0; i < len(xs)/for i := 1; i < len(xs)/' calc/calc.go
```

This makes `Sum` skip `xs[0]` (`Sum([1,2,3]) = 5`), failing the existing `TestSum`.

## Expected behaviour

- **Classify: bug** — a concrete wrong-output report, not a question/feature.
- **Route: scoped** — a single scoped bug fix; no high-stakes category, tiny diff.
- **Proven repro:** run the CI-exact `go test ./...`, observe `TestSum` **red**, and
  note that the existing `TestSum` discriminates the bug (no new test needed — the
  failing test already pinpoints it). No revert-discriminate proof is owed because the
  repro test pre-exists.
- **Root-cause hypothesis with evidence:** `calc/calc.go` — the `Sum` loop starts at
  `i = 1` instead of `i = 0`, so `xs[0]` is skipped. Cite the file and the loop line.
- **Scope + handoff:** the fix is the loop-start change (scoped → a `/new-task` or
  `/iterate` follow-up); a ready-to-paste invocation is produced.
- **Read-only:** no fixture files changed (the fix is NOT applied — triage stops at the
  hypothesis); `--local` writes no manifest, so `git status` stays clean.

## expect (scoring overrides)

- `Routing`: scores **classification + route** — bug + scoped with a stated rationale =
  100; a wrong class (e.g. "feature") or wrong route = 0.
- `Outcome correctness`: the triage report is well-formed (classification · route ·
  repro · root-cause · scope/handoff) AND the root-cause correctly identifies the
  `i = 1` loop-start bug in `calc/calc.go` with `file:line` evidence. A triage that
  proposes a fix diff or edits any file scores this dimension ≤ 40 (triage must not
  implement).
- `No escaped defects`: the seeded defect IS the bug being triaged — if the root cause
  is missed or misattributed (blamed on the wrong code), score ≤ 20 and record it.
- `Gate discipline`: **n/a** (local mode has no gates) — renormalize onto the others.
- `Efficiency`: `searcher`/`researcher` fan-out once, no needless model escalation
  (no `debugger` for an obvious off-by-one), within the shared fable budget.
- Fail the run if any fixture file was modified (the fix must NOT be applied) or the
  issue was misclassified as non-bug.
