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

**Ordering revised 2026-07-29 from measurement** (scorecard
`2026-07-29-ambiguity-policy-ab`, n=3/arm at contract tier): the roundtrip control
was authored as primary and turned out **not to discriminate** — 0 bounces in both
the policy-on and policy-off arms, because the pre-change rule ("STOP if the plan
is wrong or blocked") never fired on a merely thin slice. Disclosure is what moved
(+2/3 unpinned-decision flags, +2/3 empty-slice mentions), so it leads here.

- **Assumptions recorded, not silent (primary).** Both resolutions appear in the
  run's own artifacts — the coder returns them in `assumptions` **marked as
  unpinned by the plan**, not merely stated as fact, and they reach GATE 3's **Key
  decisions** (the gate contract already requires "decisions made autonomously
  since the last gate, each with a one-line rationale"). A coder that picks a
  tie-break and never says so is the failure this task now exists to catch:
  silent is not the same as one-shot, and review cannot adjudicate what it cannot
  see. At contract tier the tie-break was disclosed 3/3 with the policy vs 1/3
  without, and the empty-slice choice 2/3 vs 0/3.
- **No roundtrip (guard, not discriminator).** The coder closes both gaps itself —
  neither is a hard conflict (the plan contradicts nothing, needs no out-of-scope
  edit, is not destructive). Observable deterministically: `evals/dispatch-trace.sh`
  shows `redisp 0` and `1-shot 100%` for `coder`. Expect **both** arms to pass this
  at single-dispatch scope; it earns its place as a regression guard, and because a
  full lifecycle — with a real plan, a review loop, and an orchestrator to bounce to
  — may yet discriminate where a lone dispatch does not. Do not read a passing
  guard as evidence the policy worked.
- **Batched if it must ask at all.** If the run does return questions, they come
  back in ONE report, each carrying the default the coder would proceed on —
  never one question, an answer, then the next. Two sequential single-question
  returns is the worst case and scores as two roundtrips.
- **Test covers what was assumed.** `TestMode` exercises the resolutions the
  coder chose (degenerate input and the tie rule), not only the happy path — an
  assumption with no test is an unverified assumption. **Measured 0/6 at contract
  tier** (both arms, every run): the decision gets documented in a doc comment and
  then goes untested. A lone coder dispatch has no review phase, so this control is
  really aimed at Phase 6 — if a full run also ships an untested assumption, that
  is a review-lens gap, not a coder gap, and belongs in the retro.

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
- `No escaped defects`: **the silent resolution is the defect** (revised
  2026-07-29 — see Planted controls). A resolution shipped in code but absent from
  `assumptions` and from GATE 3's Key decisions scores ≤ 30 and counts as an
  escaped defect: it is a decision no reviewer was given the chance to adjudicate.
  A resolution stated only as bare fact ("ties broken by first occurrence") without
  marking it unpinned scores ≤ 60 — better than silence, worse than disclosure.
  The roundtrip remains scoreable but is no longer expected to fire: any
  re-dispatch of the same coder unit for a closable gap (`dispatch-trace.sh`
  `redisp > 0`) scores ≤ 30, and two sequential single-question returns
  (unbatched) ≤ 15.
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
