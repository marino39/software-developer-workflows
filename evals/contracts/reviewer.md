# Contract test — reviewer

## Stimulus

Setup: in the fixture copy, apply the one-line `Sum` fix (loop starts at `0`) and
commit it so a `BASE..HEAD` diff exists. Then:

> Review this diff against the plan: "Fix `calc.Sum` off-by-one so it includes
> `xs[0]`; no other change."

## Expected output fields (per `agents/reviewer.md` Output contract)

- `verdict` — `PASS` or `FAIL`.
- `issues` — numbered issues each with `severity`, `confidence` (0–100 that the
  finding is real), `file:line`, and what's wrong (empty/none is acceptable under
  PASS). A response that reports a `severity` but no `confidence` FAILS the
  contract: consolidation scores confidence, and an unstated one is guessed rather
  than read.

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
- No pre-filtering on severity: a reviewer that states it withheld findings for
  being minor, stylistic, or uncertain FAILS the contract — filtering belongs to
  the orchestrator's consolidation pass, not the reviewer.
