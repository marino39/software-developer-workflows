# Contract test — reviewer

## Stimulus

Setup: in the fixture copy, apply the one-line `Sum` fix (loop starts at `0`) and
commit it so a `BASE..HEAD` diff exists. Then:

> Review this diff against the plan: "Fix `calc.Sum` off-by-one so it includes
> `xs[0]`; no other change."

## Expected output fields (per `agents/reviewer.md` Output contract)

- `verdict` — `PASS` or `FAIL`.
- `issues` — numbered issues each with `severity`, `file:line`, and what's wrong
  (empty/none is acceptable under PASS).

## Role constraints

- Read-only: reviewer makes no edits to the fixture.
