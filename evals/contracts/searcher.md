# Contract test — searcher

## Stimulus

> In the `evalfixture` module (fixture copy), where is `Sum` defined and what
> calls it?

## Expected output fields (per `agents/searcher.md` Output contract)

- `answer` — states `Sum` is defined in `calc/calc.go`.
- `refs` — at least one `file:line` reference into `calc/calc.go`.

## Role constraints

- Read-only: no files created or modified in the fixture copy.
- No design opinions, no whole-file dumps.
