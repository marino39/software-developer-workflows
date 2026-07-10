# Task 11 — explain WHY (drives /explain case 7, the differentiator)

## Command

`/explain Why does auth.ValidateToken accept an empty bearer token?` — drives
**`/explain`**, exercising **case 7 (Why / rationale)** — the case ad-hoc exploration
can't do. It must ground the *reason* in recorded evidence (a comment / doc / commit),
not rationalize.

## Fixture

`fixtures/base` — green. `## Seed` only makes it a git repo. `auth/auth.go` carries a
`NOTE` comment documenting exactly this behavior: it only checks the `"Bearer "` scheme
prefix and does not reject an empty token. That comment is the **recorded rationale**;
the git history (single `base` commit) carries none.

## Seed

```sh
git init -q
git add -A && git commit -q -m "base"
```

## Expected behaviour

- **Classification: Why / rationale (case 7)**, stated in the header.
- **Rationale sourced to evidence:** the answer attributes the empty-token acceptance to
  the documented `NOTE` in `auth/auth.go` (the scheme-prefix-only design), cited by
  `file:line` — NOT a guessed security rationale.
- **Honest about the gap:** git history has no rationale beyond the base commit, so the
  answer says the recorded rationale is the code comment and that **no further rationale
  is recorded in history** — it does not invent intent (the case-7 contract's
  "no recorded rationale found" discipline, applied to the history axis).
- **Read-only:** no files modified.

## expect (scoring overrides)

- `Routing`: resolved to **Why / rationale (case 7)** with the header = 100; a wrong case
  (e.g. Mechanism) = 0.
- `Outcome correctness`: the rationale is **sourced to the `NOTE` comment** in
  `auth/auth.go` with `file:line`, follows the case-7 rationale-list contract, and does
  NOT fabricate an undocumented reason. Inventing a rationale not present in the
  code/comment/history scores this dimension ≤ 30 (fabricated intent is the worst failure
  for the Why case).
- `No escaped defects`: **n/a** — renormalize.
- `Gate discipline`: **n/a** — renormalize.
- `Efficiency`: searcher-tier only (may read comments + `git log`/`blame`); NO
  `architect`/opus; synthesis inline.
- Fail the run if any fixture file was modified, the case was misclassified, or a
  rationale is asserted with no comment/doc/commit citation.
