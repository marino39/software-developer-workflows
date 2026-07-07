# /new-task learnings — slatedb-go

Lessons specific to the slatedb-go repo. Same v2 format and rules as `../LEARNINGS.md`: `- YYYY-MM-DD [tag][tag] <lesson> — src: <ref>`, lesson text ≤300 chars, ≥1 tag + a `src:`, curated in place at Phase 7 / GATE 4, soft cap 30 bullets. Read at Phase 0 when the task's repo key is `slatedb-go`; Phase 0 applies only the tag-matching bullets.

- 2026-07-03 [go][test][concurrency] No-base merge chains resolve only on buffered `tx.Get`, not `d.Get` (`TestDB_GetUnresolvedMergeNoBaseReturnsNotFound`) — don't write tests expecting folded no-base values via `d.Get`. — src: retro 2026-07-03
- 2026-07-03 [rust][format-compat][port] `num_probes` is decoded as an unbounded u16 inside a CRC-protected block in Rust's filter decode path — values >32 are valid data: accept with heap fallback, never reject. — src: retro 2026-07-03
- 2026-07-04 [go][concurrency] The recycled `flushSignal` channel has multiple readers (`waitForBackPressure` and `Flush` step 2) — any lost-wakeup fix must cover every reader, not just the reported site. — src: retro 2026-07-04
- 2026-07-04 [go][test][scope-gate] The GC delete TOCTOU is asserted by `TestInvariant_AdjacentSortedRunsCompactedAndDeleted` (adversarial `GcGraceWindow=-1ns`) — "document + accept" ships a red test; a fix is forced. — src: retro 2026-07-04
- 2026-07-04 [go][upstream-port][port] The Go port never advances persisted `last_l0_clock_tick` on flush (stays 0) — upstream-faithful logic reading it is permanently inert until the write path advances it. — src: retro 2026-07-04
