# Contract test — debugger

## Stimulus

> Failure digest: `TestSum` fails in the `evalfixture` module —
> `Sum([]int{1,2,3}) = 5, want 6`. Root-cause and fix it.

## Expected output fields (per `agents/debugger.md` Output contract)

- `root_cause` — identifies the loop starting at index 1 (skips `xs[0]`).
- `fix` — the `calc/calc.go` change.
- `verification` — how the fix was proven (e.g. `TestSum` green).
- `avoid_reintro` — guidance to prevent recurrence.

## Role constraints

- Root cause verified before the fix; fix is minimal (no opportunistic refactor).
- Spawns only `searcher`/`test-runner`.
