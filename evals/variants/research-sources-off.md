# Variant — research-sources-off

Ablates the `/research` source plan and absence rules to measure whether they earn
their words.

## Delta (prepended to the dispatched /research)

> VARIANT research-sources-off: Skip R0 step 3 — no mandatory sources, no
> `sources.md`, no `sources` in dispatches. Treat absence lines as ordinary claims.
> Everything else is unchanged.

## What to read from the A/B

Run task 26 (and 25 as a control; raise `--repeat`) as baseline and with this variant:

- **Outcome correctness** — does the variant still reach the business registry?
- **No escaped defects** — does a false "not found" survive to the report without the
  absence rule?
- **Efficiency** — tokens saved by dropping the source plan and status lines.

Verdict shape: `research-sources-off: <Δ escaped defects>, <Δ registry reached>,
<Δ tokens> → <justified | not justified> on this suite`.
