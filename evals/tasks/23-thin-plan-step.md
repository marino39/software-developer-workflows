# Task 23 — thin plan step (exercises the coder ambiguity policy + the dispatch 1-shot rate)

## Statement (passed to /new-task)

> In the `evalfixture` module's `calc` package, add a public function
> `Mode(xs []int) int` that returns the most frequently occurring element of the
> slice. Add a `TestMode`.

## Fixture

`fixtures/base` — green, unmodified (no `## Seed`). Purely additive, like task 17.

The statement is **deliberately thin**: it pins the signature and the happy path
and leaves two decisions unstated that no plan is likely to pin either, because
they sit below plan granularity. Both are answerable from the surrounding code
without asking anyone:

- **Empty/nil slice** — there is no most-frequent element. `calc.Sum(nil) = 0`
  (asserted by the existing `TestSumEmpty`) establishes the package's
  zero-value-for-degenerate-input convention.
- **Ties** — two values sharing the top count. Nothing in the package speaks to
  this, so any *deterministic, stated* rule (smallest value wins, first-seen
  wins, …) is a correct resolution.

## Planted controls (what a correct run does)

The control is **not which resolution was chosen** — it is that a resolution was
chosen, recorded, and not bounced back to the orchestrator. Grading on a
particular answer would test taste; grading on the bounce tests the policy.

- **No roundtrip (primary).** The coder closes both gaps itself under
  `agents/coder.md`'s ambiguity policy — neither is a hard conflict (the plan
  contradicts nothing, needs no out-of-scope edit, is not destructive).
  Observable deterministically: `evals/dispatch-trace.sh` over the driver
  transcript shows `redisp 0` and `1-shot 100%` for `coder`. A re-dispatch of the
  same plan slice in a later turn is the failure this task exists to catch.
- **Assumptions recorded, not silent.** Both resolutions appear in the run's own
  artifacts — the coder returns them in `assumptions`, and they reach GATE 3's
  **Key decisions** (the gate contract already requires "decisions made
  autonomously since the last gate, each with a one-line rationale"). A coder
  that picks a tie-break and never says so is *also* a failure: silent is not the
  same as one-shot, and review cannot adjudicate what it cannot see.
- **Batched if it must ask at all.** If the run does return questions, they come
  back in ONE report, each carrying the default the coder would proceed on —
  never one question, an answer, then the next. Two sequential single-question
  returns is the worst case and scores as two roundtrips.
- **Test covers what was assumed.** `TestMode` exercises the resolutions the
  coder chose (degenerate input and the tie rule), not only the happy path — an
  assumption with no test is an unverified assumption.

## Expected behaviour

- Route: **scoped**, stays scoped (small additive feature, no high-stakes path).
- `Mode` + `TestMode` added; `go build ./...` and `go test ./...` end **green**.
- Behavioral verification runs (feature with a runtime surface) or the fast path
  exercises `TestMode`.
- GATE 3 auto-approve is acceptable when its criteria hold.
- The two resolutions are visible at GATE 3 and consistent with the code shipped.

## expect (scoring overrides)

- `Outcome correctness`: `Mode` returns the most frequent element for a normal
  slice; the empty/nil and tie cases behave as the run's own stated assumptions
  say they do (self-consistency is the bar, not a fixed expected value);
  `go test ./...` passes.
- `No escaped defects`: **the roundtrip is the defect.** Any re-dispatch of the
  same coder work unit for a gap that was closable (`dispatch-trace.sh`
  `redisp > 0` for `coder`, or a coder return whose `open_questions` names the
  empty-slice or tie decision without a proceed-on default) scores this dimension
  ≤ 30 and counts as an escaped defect. Two sequential single-question returns
  (unbatched) scores ≤ 15. A resolution shipped in code but absent from
  `assumptions` and from GATE 3's Key decisions scores ≤ 50.
- `Efficiency`: the headline number for this task is the **coder 1-shot rate**
  from the dispatch trace, recorded in the scorecard's orchestrator-cost column
  alongside tokens and context high-water. Full credit requires 100% with no
  needless escalation; this is the task whose rate an ablation of the ambiguity
  policy is expected to move, so report it per repeat rather than only averaged.
- `Gate discipline`: gate summaries well-formed AND the autonomous resolutions
  present in Key decisions with their one-line rationale — a gate that hides them
  caps this dimension at 60.
- Fail the run if `TestMode` was written to assert behavior the implementation
  does not have, or if a degenerate-input panic ships (an unhandled empty slice
  is a real defect, not an assumption).
