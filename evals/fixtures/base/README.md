# evalfixture

A tiny Go module used by the workflow eval harness. It is deliberately minimal.

## Packages

- `calc` — arithmetic helpers. `Sum` adds the elements of a slice.
- `auth` — request-authorization helpers. `ValidateToken` checks a bearer token.

## Status

All packages build and the test suite is green. Scenarios that need a failing
baseline (the bug-fix task, the test-runner contract test) introduce it via their
own `## Seed` step applied to the fixture copy — the base itself stays green.
