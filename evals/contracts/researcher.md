# Contract test — researcher

`network-dependent` — `/workflow-eval --contracts` skips this when offline and
records `skipped (network)`.

## Stimulus

> Does Go's standard library provide a built-in to compute the product of an
> integer slice, or is a manual loop idiomatic? Cite sources.

## Expected output fields (per `agents/researcher.md` Output contract)

- `findings` — synthesized prose answer.
- `facts` — key facts each with a source URL.
- `confidence` — explicit confidence level.
- `open_questions` — remaining unknowns (or `none`).

## Stimulus — claim lines (`claim_prefix`)

> `question`: When was `errors.Join` added to Go's standard library? `claim_prefix`:
> `SQ1`.

Expected: `facts` as claim lines `SQ1.<n> | claim | url | date | confidence`, with at
least one line stating Go 1.20 and citing go.dev (release notes or `pkg.go.dev/errors`).

## Stimulus — verify mode

Write this ledger to a scratch `claims.jsonl` first, then dispatch with `mode: verify`,
`claims_path` = that file, `ids` = `SQ1.1,SQ1.2`:

```
{"id":"SQ1.1","claim":"errors.Join was added in Go 1.20","url":"https://go.dev/doc/go1.20"}
{"id":"SQ1.2","claim":"errors.Join was added in Go 1.18","url":"https://go.dev/doc/go1.18"}
```

Expected `verdicts`: exactly two lines, in order — `SQ1.1 | supported`,
`SQ1.2 | unsupported` (the 1.18 notes do not state it). Failing the seeded false
claim, or returning anything beyond the two verdict lines' scope, fails the contract.

## Role constraints

- No implementation work; no codebase changes.
- Verify mode: checks only the listed ids; no research on the wider question.
