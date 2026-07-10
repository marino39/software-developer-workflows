# Task 15 — explain FLOW/TRACE (drives /explain case 3, exercises the Mermaid sequence)

## Command

`/explain Trace what happens when cart.Checkout is called in the appfixture module.` —
drives **`/explain`**, exercising **case 3 (Flow / trace)** and its ordered-sequence +
Mermaid contract.

## Fixture

`fixtures/app` — a richer module (`appfixture`) with a real call chain, which the
minimal `base` fixture lacks. `cart.Checkout` (`cart/cart.go`) validates → subtotals →
dispatches to a discount strategy.

## Seed

```sh
git init -q
git add -A && git commit -q -m "base"
```

## Expected behaviour

- **Classification: Flow / trace (case 3)**, stated in the header.
- **Output is the ordered-sequence contract** — entry → hops (each cited `file:line`) →
  exit — **plus a Mermaid diagram**.
- The trace correctly follows `Checkout` (`cart/cart.go`) → `validate` → `subtotal` →
  `applyDiscount` → the selected strategy (`discountPercent` / `discountFlat` in
  `cart/discount.go`) → return, each hop cited, including the `code`-based branch in
  `applyDiscount`.
- **Read-only:** no files modified.

## expect (scoring overrides)

- `Routing`: resolved to **Flow / trace (case 3)** with the header = 100; a wrong case = 0.
- `Outcome correctness`: the answer is the **ordered-sequence** contract (entry → cited
  hops → exit) AND includes a **Mermaid diagram**; the call chain is correct
  (`Checkout → validate → subtotal → applyDiscount → discountPercent|discountFlat`) with
  each hop cited `file:line`. A wrong/missing hop, an invented call, or a missing diagram
  scores this dimension ≤ 40.
- `No escaped defects`: **n/a** — renormalize.
- `Gate discipline`: **n/a** — renormalize.
- `Efficiency`: searcher-tier only; NO `architect`/opus; synthesis inline.
- Fail the run if any fixture file was modified, the case was misclassified, the Mermaid
  diagram is missing, or a call that doesn't exist is asserted.
