# Task 14 — explain ARCHITECTURE (drives /explain case 4, exercises the Mermaid contract)

## Command

`/explain Give me an overview of the evalfixture module's structure.` — drives
**`/explain`**, exercising **case 4 (Architecture)** and its diagram contract. (The
fixture is small, so the map is small — but the case's output shape is what is scored.)

## Fixture

`fixtures/base` — green. `## Seed` only makes it a git repo. The module `evalfixture`
(`go.mod`) has two independent packages: `calc` (`calc/calc.go` — `Sum`) and `auth`
(`auth/auth.go` — `ValidateToken`), plus a `README.md`. The packages do not depend on
each other.

## Seed

```sh
git init -q
git add -A && git commit -q -m "base"
```

## Expected behaviour

- **Classification: Architecture (case 4)**, stated in the header.
- **Output is the component-map contract** — a table (component → responsibility →
  `path`), a "how they connect" note, and entry points; **plus a Mermaid diagram**.
- Correctly maps the two packages (`calc` → summation, `path` `calc/calc.go`; `auth` →
  bearer-token check, `path` `auth/auth.go`) and states they are **independent** (no
  inter-package dependency) — a library module with no single entry point.
- **Read-only:** no files modified.

## expect (scoring overrides)

- `Routing`: resolved to **Architecture (case 4)** with the header = 100; a wrong case = 0.
- `Outcome correctness`: the answer is the **component-map** contract (table with
  `path`s + connections + entry points) AND includes a **Mermaid diagram**; it correctly
  identifies the two independent packages and that they don't depend on each other.
  Inventing a dependency/component that doesn't exist scores this dimension ≤ 40.
- `No escaped defects`: **n/a** — renormalize.
- `Gate discipline`: **n/a** — renormalize.
- `Efficiency`: searcher-tier only; NO `architect`/opus; synthesis inline.
- Fail the run if any fixture file was modified, the case was misclassified, the Mermaid
  diagram is missing, or a non-existent component/dependency is asserted.
