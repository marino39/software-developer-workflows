# Task 01 — doc-only (scoped, fast path)

## Statement (passed to /new-task)

> In the `evalfixture` module, add a short "Usage" section to `README.md` showing
> how to call `calc.Sum`. Documentation only — do not change any `.go` file.

## Fixture

`fixtures/base` — unmodified.

## Expected behaviour

- Route: **scoped**, stays scoped (no high-stakes path, tiny diff).
- Takes the fast path; behavioral verification is **exempt** (doc-only).
- **GATE 3 auto-approves** (all criteria hold, route not escalated).
- No `.go` files touched; `go build ./...` still passes.

## expect (scoring overrides)

- `Outcome correctness`: README gains a correct `calc.Sum` usage example; no code changed.
- `No escaped defects`: **n/a** (doc-only) — reweight its 20 points onto Routing (+10) and Gate discipline (+10).
- Fail the run if any `.go` file changed or GATE 3 did not auto-approve.
