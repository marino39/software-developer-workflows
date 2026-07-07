---
name: convention-scan
description: Design-from-convention for observability/logging/error-handling additions — lock the spec to a named peer component before any code is written. Use when the task is "add logging/metrics/error handling to X".
---

# Convention scan

First-principles designs for cross-cutting additions collect reviewer convention nits; designs locked to an existing peer collect zero. Do this before writing the spec, not during review.

## 1. Find the peer

Dispatch a `searcher` (or search directly) for the component most similar to the target that already has the concern being added: same layer, same lifecycle, already logging/instrumented/handling errors. Name it in the spec.

## 2. Lock the spec to the peer

The spec must state: "follow `<peer component>` conventions" and enumerate the concrete conventions found — logger acquisition, level choices, field naming, error wrapping style, metric naming. The coder implements against the named peer, not taste.

## 3. Transitions, not ticks (high-frequency loops)

Observability in a poll/retry loop logs STATE TRANSITIONS, never per-tick status:

- first failure of a streak → `Warn`
- continued failure → `Debug` (or nothing)
- recovery → `Info`

Implement with a loop-local "was failing" bool. Settle this in the spec — before a coder writes per-tick spam, not after.
