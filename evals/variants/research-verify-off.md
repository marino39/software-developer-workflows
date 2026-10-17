# Variant — research-verify-off

Ablates `/research` Phase R2 (the blind verify pass) to measure whether it earns its
cost next to the R5 codex support audit.

## Delta (prepended to the dispatched /research)

> VARIANT research-verify-off: Skip Phase R2 entirely — dispatch no verifier. In R3
> and R4 treat every `unverified` claim as `supported`. Everything else is unchanged.

## What to read from the A/B

Run task 25 (raise `--repeat`; one run is noise) as baseline and with this variant:

- **No escaped defects** — does the seeded false premise (Go 1.18) or any wrong
  version/date survive to the final report without R2? Does R5 catch what R2 would?
- **Efficiency** — tokens and wall-clock saved by dropping the verifier dispatch(es).

Verdict shape: `research-verify-off: <Δ escaped defects>, <Δ tokens> → <justified |
not justified> on this suite`.
