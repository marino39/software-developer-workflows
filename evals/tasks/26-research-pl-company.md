# Task 26 — research a Polish business behind a JavaScript site (drives /research, exercises the source plan + absence rules)

`network-dependent` — skipped and recorded `skipped (network)` when offline. Live-web
target: the expected facts below were true on 2026-10-17; if the site or registry
changes, refresh the `## Expected behaviour` facts and note the date in the scorecard.

## Command

`/research Kto prowadzi energia-siedlce.pl, od kiedy działa ta firma i co dokładnie oferuje? --yes`
— this task drives **`/research`** (driver note in `commands/workflow-eval.md` Layer 2).

## Why this task exists

Retro of the 2026-10-17 run on this site (proposal `2026-10-17-research-command.md`,
§ Retro): the site is a client-rendered app, so plain fetches return only meta tags.
Five scouts never queried a business registry, and five "nothing found" claims were
really "the fetch saw only metadata". Task 25 (Go release notes) cannot exercise either
failure.

## Fixture

`fixtures/base` — working directory only; `/research` writes nothing outside `--out`.

## Seed

```sh
git init -q
git add -A && git commit -q -m "base"
```

## Expected behaviour

- **Source plan at GATE R:** the sub-question table lists mandatory sources from the
  `research-sources` playbook, including the VAT whitelist lookup for the business.
- **Registry reached:** `sources.md` marks the VAT whitelist `reached`; a `supported`
  claim gives the registered name (Piotr Bugdał), REGON 141391468, the Siedlce working
  address and the VAT registration date 2021-07-20. No bank account number anywhere.
- **App shell recognised:** site routes fetched without rendering are recorded as
  `blocked (js-render)`, never as absence. If the session has a browser tool, the R3
  render step produces `captures/` and the offer (EV-BPM, second-life storage, SOFAR
  EMS, EMS House) is claimed from them; without one, the offer goes to Gaps with the
  blocked routes named.
- **No false absence:** no report sentence says the site has no contact, prices or Home
  Assistant mention.
- **Founder scope:** professional information only.

## expect (scoring overrides)

- `Routing`: full lane (not bounced) with a source plan at GATE R = 100; no source plan = 0.
- `Outcome correctness`: registry facts correct and cited (≤ 30 if the registry was not
  reached); the offer either correctly claimed from captures or honestly in Gaps.
- `No escaped defects`: any absence stated as fact while a mandatory source was blocked,
  or a bank account number in any output file, is an escaped defect.
- `Gate discipline`: GATE R decidable (sub-questions + mandatory sources + dispatch count).
- `Efficiency`: ≤ 2 waves, ≤ 6 scouts, no `architect`/opus.
- Fail the run if any file outside `--out` was modified.
