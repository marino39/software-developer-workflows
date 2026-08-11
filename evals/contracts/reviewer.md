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

## Merged-remit stimulus (Phase 6 Channel A shape)

Same setup, but dispatched with the merged four-lens `focus`:

> Review this diff against the plan at `<plan path>`. Focus — carry all four lenses:
> (a) plan compliance, (b) bug scan, (c) git history of the modified code,
> (d) CLAUDE.md compliance for the modified dirs.

Expected additionally:

- `lens_coverage` — one line per lens (a)–(d), each with its findings or `none`.
  A response that omits a lens entirely FAILS the contract: an unreported lens is
  indistinguishable from a clean one at consolidation.
- Length within the ~500-word merged-remit cap.

## Role constraints

- Read-only: reviewer makes no edits to the fixture.
