# Variant — comment-hygiene-off

Ablates the 2026-07-23 comment-hygiene strengthening to measure whether the added
rule classes earn their cost. Reverts the coder `<comment-policy>` to its
pre-2026-07-23 form (WHY-not-WHAT; private members no doc; public ≤~3 lines; no
control-flow narration; density-match; escape hatch) and drops the reviewer's
comment-hygiene lens. The *original* rules stay in force under both conditions —
this variant isolates only the added classes.

## Delta (prepended to the dispatched coder / driver)

> VARIANT comment-hygiene-off: Your comment-policy is the SHORT form only —
> "Comments explain WHY, not WHAT. Private methods/fields: no doc comment by
> default. Public methods/interfaces: a doc comment up to ~3 lines. No inline
> comments narrating control flow. Break these only when intent isn't recoverable
> from the code itself, and match the surrounding file's comment density." There
> is NO rule against commented-out/dead code, meta/process comments (referencing
> the task/plan/PR/review or that code was added/changed/fixed), TODO/FIXME
> without an issue reference, or attribution/date comments, and NO stale-comment
> rule. The reviewer applies NO comment-hygiene lens. Everything else is unchanged.

## Discriminating probe (why task 17 is not enough)

Task 17 (add `calc.Median`) scores only on the *original* rules (doc-on-private,
≤3-line public doc, no narration) — both conditions keep those, so a task-17 A/B
is expected to be ~null and cannot price the added classes. The added classes fire
on *edit/refactor* work, not clean greenfield additions, so the A/B uses a probe
that baits them:

> Probe statement: In package `calc`, change `Sum` to accumulate into `int64` and
> return `int64` to guard against overflow on large slices. A configurable
> rounding mode is planned for a later change but is out of scope here.

This tempts exactly the added-class noise: a commented-out old `Sum` (dead code),
a `// changed to int64 …` meta/process line, and a `// TODO: rounding mode` orphan
marker. Under the full policy all three are forbidden and stripped at authoring +
flagged at review; under the variant only narration/WHAT is forbidden, so any such
comment the model emits survives.

## What to read from the A/B

- **No escaped defects (comment lens)** — the headline: does the variant ship
  dead code / meta / orphan-TODO comments that the full policy suppresses? Count
  each surviving added-class comment as an escaped hygiene defect.
- **Efficiency** — the full policy costs ~a handful of prompt tokens per agent
  (the extra sentence) and one review lens; the payoff is avoided later
  removal passes. Note token delta but expect it small.

Verdict shape: `comment-hygiene-off: <Δ escaped hygiene defects>, <Δ tokens> →
<the added comment-hygiene classes are justified | not justified> on this probe`.
Single-run variance applies — raise `--repeat` before trusting a small delta.
