# evalfixture

A tiny Go module used by the workflow eval harness. It is deliberately minimal.

## Packages

- `calc` — arithmetic helpers. `Sum` adds the elements of a slice.
- `auth` — request-authorization helpers. `ValidateToken` checks a bearer token.

## Status

All packages build. The test suite is green except for one intentionally seeded
bug in `calc` (see `calc/calc.go`), which the bug-fix eval task exercises.
