# Task 24 — cross-slice contract (the stranding probe: a gap a coder CANNOT close locally)

## Statement (passed to /new-task)

> In the `evalsvc` module, make failures distinguishable to callers of
> `api.Lookup`: a caller must be able to tell an invalid id from an id that
> simply isn't stored. Today both collapse to `""`. Change `store.Get` and
> `validate.ID` to report failures as errors, and have `api.Lookup` return the
> name plus an HTTP status — 200, 400 for an invalid id, 404 for a missing item,
> 500 otherwise.

## Fixture

`fixtures/svc` — green, unmodified (no `## Seed`). Three packages with a real
call chain: `api` → `store` + `validate`.

## Why this task exists

Tasks 17/20/23 all failed to strand a coder, and the 2026-07-29 A/Bs measured
**zero roundtrips at both contract and lifecycle tier**. The diagnosis: those
tasks' gaps were *locally closable*. `Mode`'s tie-break, `Product`'s empty slice —
any coder settles those from the surrounding file and idiom, so the ambiguity
policy had nothing to prevent and the Dispatch brief nothing to supply. A
one-function fixture cannot produce the failure the source telemetry describes,
because there is no sibling slice to be out of step with.

This task supplies the missing ingredient: **a contract that spans slices**. The
work splits naturally into three steps in three packages, and the middle one
(`api`) must *match on* error values that the other two *define*. A coder holding
only the `api` slice cannot invent the answer — whatever it picks, the other
slices have to agree, and it has no way to know what they chose.

That is the shape of the reported failure: not "this detail is unstated" but
"this detail is owned elsewhere and I am not holding it."

## Planted controls (what a correct run does)

- **The plan must pin the error contract (primary).** A correct plan names the
  shared identity — the sentinel/type, its package, and how `api` matches on it
  (`errors.Is`, `errors.As`, a code) — BEFORE any coder is dispatched. This is
  exactly the Phase 4 **dispatch-readiness** column's remit ("the interface
  contract the coder must honor"), so task 24 is the first case that actually
  exercises S3. A plan that says only "return an error when absent" and leaves
  `api` to guess is an **unready** step and must fail Phase 4.
- **No cross-slice mismatch shipped.** The three packages agree at the end:
  `go build ./...` and `go test ./...` green, and `api` distinguishes 400 from
  404 through the contract the other steps actually produce — not a second,
  parallel error vocabulary invented inside `api`.
- **If dispatched thin, the coder does not silently guess.** Should a slice go out
  without the contract, the correct return is a batched question naming the
  missing contract with a proposed default (per the ambiguity policy), or a
  clearly-declared assumption. A coder that invents a private sentinel, ships it,
  and says nothing is the worst case: it is the silent-resolution defect AND a
  latent cross-package break.
- **Roundtrip is now a live possibility, not a formality.** Unlike task 23, `rtrip
  > 0` here is a real outcome rather than an expected-zero guard — this is the
  task where `dispatch-trace.sh` can actually move.

## Expected behaviour

- Route: **standard** (three packages, changed public signatures across a call
  chain — beyond a single scoped fix). This also makes task 24 the suite's first
  task that reliably reaches **Phase 4**, which the fast path skips.
- Plan has ≥3 file-level steps with the shared error contract pinned in the
  Interfaces section.
- All three packages updated consistently; `go test ./...` green.
- Behavioral verification exercises all three status codes (200/400/404).

## expect (scoring overrides)

- `Routing`: standard (or high-stakes if the run argues the public-signature
  change warrants it) with stated rationale. A `scoped` route here is a misroute —
  three packages and three changed signatures — and caps Routing at 40.
- `Outcome correctness`: `go build ./...` and `go test ./...` green; `api.Lookup`
  returns 400 for an invalid id, 404 for an absent one, 200 with the name on
  success — verified against the error values the other packages actually define.
- `No escaped defects`: **the cross-slice mismatch is the defect.** Any of these
  scores ≤ 25 and counts as escaped: `api` matching on an error identity that
  `store`/`validate` do not produce; a private duplicate error vocabulary inside
  `api`; a compile failure across packages at any commit the run treats as done;
  or a status mapping that cannot actually distinguish 400 from 404 at runtime.
- `Gate discipline`: GATE 2's Results must carry the dispatch-readiness verdict,
  and the error contract must be visible there — if the plan pinned it, the gate
  shows it; if it did not, the gate shows the unready row. A GATE 2 that reports
  "mapping complete" while `api`'s step names no matching mechanism caps this
  dimension at 50.
- `Efficiency`: report coder/reviewer `rtrip` and `rt-free` from
  `dispatch-trace.sh` per repeat. Unlike task 23, do **not** treat `rtrip 0` as
  the expected result — the point of this task is that a roundtrip is reachable.
  A run that pins the contract at Phase 4 and then needs no roundtrip is the
  *best* outcome, and the one S3 predicts.
