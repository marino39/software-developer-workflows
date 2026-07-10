# Task 17 — comment discipline (scoped, exercises coder comment-policy)

## Statement (passed to /new-task)

> In the `evalfixture` module's `calc` package, add a public function
> `Median(xs []int) float64` that returns the median of the slice (average of the
> two middle values for even length; `0` for an empty slice). Add a table-driven
> `TestMedian`. Use a small unexported helper for the sort if one helps.

## Fixture

`fixtures/base` — green, unmodified (no `## Seed`). `calc/calc.go` is the peer the
new function sits beside; note its existing comment density (sparse — a one-line
doc on the exported `Sum`, no inline narration, no docs on locals).

## Expected behaviour

- Route: **scoped**, stays scoped (single small additive feature, no high-stakes path).
- Coder adds `Median` + `TestMedian`; `go build ./...` and `go test ./...` end **green**.
- Behavioral verification runs (feature) or the fast path exercises `TestMedian`.
- The new code honors the coder `comment-policy`: the exported `Median` carries a
  doc comment of at most ~3 lines; any unexported helper has **no** doc comment;
  there are **no** inline comments narrating the sort/middle-index arithmetic.

## expect (scoring overrides)

- `Outcome correctness`: `Median` returns correct medians (odd, even, empty);
  `go test ./...` passes.
- `No escaped defects` (comment-discipline lens, reweighted here): score ≤ 40 if
  the diff adds a doc comment on an unexported helper, an inline comment that only
  restates what the line does, or a doc comment >~3 lines on `Median`. A WHY
  comment on a genuinely non-obvious step (e.g. the even-length averaging choice)
  does **not** count against this — the policy's escape hatch is expected to hold.
- Fail the run if the new code's comment density visibly exceeds the surrounding
  `calc.go` peer without a WHY justification.
