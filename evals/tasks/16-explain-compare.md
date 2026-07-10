# Task 16 — explain COMPARE (drives /explain case 6)

## Command

`/explain What's the difference between discountPercent and discountFlat in the cart package?` —
drives **`/explain`**, exercising **case 6 (Compare)**.

## Fixture

`fixtures/app` — the `appfixture` module. `cart/discount.go` defines two comparable
discount strategies: `discountPercent` (multiplicative) and `discountFlat` (subtractive).

## Seed

```sh
git init -q
git add -A && git commit -q -m "base"
```

## Expected behaviour

- **Classification: Compare (case 6)**, stated in the header.
- **Output is the comparison-table contract** — dimension → `discountPercent` →
  `discountFlat` (each cited) → when-to-use guidance.
- The comparison correctly captures the real differences (both in `cart/discount.go`):
  multiplicative vs subtractive; scales with total vs fixed cents; `pct` input vs
  `amount` (cents) input; rounds down / can't go negative for a valid pct vs explicitly
  **clamps to zero**. When-to-use follows from those.
- **Read-only:** no files modified.

## expect (scoring overrides)

- `Routing`: resolved to **Compare (case 6)** with the header = 100; a wrong case = 0.
- `Outcome correctness`: the answer is the **comparison-table** contract (dimension → X →
  Y, cited `file:line`, + when-to-use); it correctly contrasts multiplicative vs
  subtractive, scaling vs fixed, and the zero-clamp on `discountFlat`. Inventing a
  difference that isn't in the code scores this dimension ≤ 40.
- `No escaped defects`: **n/a** — renormalize.
- `Gate discipline`: **n/a** — renormalize.
- `Efficiency`: searcher-tier only; NO `architect`/opus; synthesis inline.
- Fail the run if any fixture file was modified, the case was misclassified, or a
  fabricated difference is asserted.
