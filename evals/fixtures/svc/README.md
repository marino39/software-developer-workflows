# evalsvc

A three-package Go module for eval scenarios that need **cross-slice coupling** —
work that splits into plan steps owned by different coders, where one step's
correctness depends on a contract another step defines.

## Packages

- `store` — in-memory item store. `Get` currently signals absence with a `bool`.
- `validate` — `ID` currently signals rejection with a `bool`.
- `api` — `Lookup` calls both and collapses every failure to `""`, so callers
  cannot tell "invalid id" from "no such item".

That collapse is the seam: any task that makes the failures distinguishable has
to introduce an **error contract shared across all three packages**, and the
package that consumes it (`api`) cannot be implemented correctly without knowing
what the packages that produce it (`store`, `validate`) chose.

`fixtures/base` cannot host this — one package, one function, no slice can strand
another. See `evals/tasks/24-cross-slice-contract.md`.

## Status

All packages build; the test suite is green.
