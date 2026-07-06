# /new-task learnings — slatedb-go

Lessons specific to the slatedb-go repo. Same rules as `../LEARNINGS.md`: one dated bullet ≤300 chars, curated in place at Phase 7 / GATE 4, soft cap 30 bullets. Read at Phase 0 when the task's repo key is `slatedb-go`.

- 2026-07-03: No-base merge chains resolve only on buffered `tx.Get`, not `d.Get` (`TestDB_GetUnresolvedMergeNoBaseReturnsNotFound`) — don't write tests expecting folded no-base values via `d.Get`.
- 2026-07-03: `num_probes` is decoded as an unbounded u16 inside a CRC-protected block in Rust's filter decode path — values >32 are valid data: accept with heap fallback, never reject.
- 2026-07-04: The recycled `flushSignal` channel has multiple readers (`waitForBackPressure` and `Flush` step 2) — any lost-wakeup fix must cover every reader, not just the reported site.
- 2026-07-04: The GC delete TOCTOU is asserted by `TestInvariant_AdjacentSortedRunsCompactedAndDeleted` (adversarial `GcGraceWindow=-1ns`) — "document + accept" ships a red test; a fix is forced.
- 2026-07-04: The Go port never advances persisted `last_l0_clock_tick` on flush (stays 0) — upstream-faithful logic reading it is permanently inert until the write path advances it.
