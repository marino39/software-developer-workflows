# Cost optimization pass — 2026-08-11

**Trigger:** user directive — `/new-task` and `/review-pr` cost too much to run.
Specific instruction: two architects only (one Claude, one codex); for review, one
Claude and one codex. Plus: propose further optimizations.

This document records what was **applied** in this change, and what is **proposed but
deliberately not applied** — the second list is the decision the user still owns.

---

## 1. Where the money actually goes

Claude dispatches on a `standard`-route `/new-task`, iteration 1 of each phase,
excluding Phase 5 (which scales with the plan, not with workflow structure):

| Phase | Before | After |
|---|---|---|
| 0 — setup | searcher + researcher = 2 | 2 |
| 1 — brainstorm | researcher + 3× architect (opus/xhigh) + fable synthesizer + artifact writer = **6** | researcher + 1× architect + 1× synthesizer-writer = **3** (+1 free codex lens) |
| 2 — design review | 1× **fable** architect | **0** (codex; opus fallback only if codex is absent) |
| 3 — plan | 1× architect | 1 |
| 4 — plan review | 1× reviewer | 1 |
| 6 — impl review | verify coder + Channel A + C1 + C2 + C3 + consolidator + K skeptics = **6+K** (+codex) | verify coder + Channel A + 1 batched skeptic = **3** (+1 free codex) |
| **Total (ex-Phase 5)** | **17+K**, incl. 2 fable and ~5 opus/xhigh architect calls | **10**, incl. **0 fable** and 2 opus architect calls |

`/review-pr` is the same engine with no authoring phases: **6+K Claude dispatches → 2**
(one reviewer, one batched skeptic) plus one free codex channel.

Two structural facts drive the whole pass:

1. **The expensive dispatches were the redundant ones.** The wide fan-outs were
   concentrated in the deepest tiers — three opus/`xhigh` architects, a fable
   synthesizer, a fable adversarial reviewer, and up to K parallel skeptics.
2. **Codex tokens are not on the Claude bill.** Every pass that needed "a second,
   independent head" was buying that with a second Claude call. Buying it
   out-of-model is *cheaper and more diverse at the same time* — a different model
   is a better second opinion than another instance of the same one.

Hence the organising rule now written into `new-task.md` Token hygiene: **a second
opinion is bought out-of-model, not as a second Claude call.**

---

## 2. Applied in this change

| # | Change | Where |
|---|---|---|
| A1 | Phase 1: 3 Claude architects → **1 `architect` + 1 codex design lens** (codex absent → named architect fallback, recorded as a Deviation) | `new-task.md` Phase 1.2; `codex-exec` §5.1 |
| A2 | Phase 1: fable synthesizer → **opus synthesizer that also writes the design doc** — two dispatches collapse to one; a human override costs one revision pass | `new-task.md` Phase 1.3 |
| A3 | Phase 2: always-fable adversarial design reviewer → **codex**, with a fresh-opus-architect fallback. The property being bought (a reviewer that doesn't share the author's priors) is better served out-of-model | `new-task.md` Phase 2.1; `codex-exec` §5.2 |
| A4 | Phase 6 / `review-pr` R1: Channel A (superpowers) + C1 + C2 + C3 → **ONE `reviewer` carrying the merged four-lens remit** (plan compliance · bug scan · git history · CLAUDE.md compliance) + **codex**. Lens *coverage* is kept as a checklist inside one remit | `new-task.md` Phase 6.3; `review-pr.md` R1 |
| A5 | Phase 6.4: **consolidator subagent dropped** (merging ≤2 capped lists is routing work); **skeptic pass batched** into one dispatch over the whole Must-fix list | `new-task.md` Phase 6.4; `review-pr.md` R2 |
| A6 | Escalation ladder: **zero by-design fable slots**; fable is reachable only as the last rung after opus fails, one per run | `new-task.md` Escalation ladder |
| A7 | High-stakes safety valve: a high-stakes diff **buys the lens split back** (A1 + A2 reviewers, opus, plus codex) — the only place the wide fan-out survives | `new-task.md` Phase 6.7 |
| A8 | `codex-review` skill generalized to **`codex-exec`** — three prompt recipes (design lens, design review, code review), per-pass degrade policy, unchanged stdin/timeout/sandbox discipline | `skills/codex-exec/SKILL.md` |

**Honest status:** cost saving certain, quality delta **unmeasured**. CLAUDE.md rule 3
wants an ablation before a layer is cut; these were cut on a cost directive instead.
The reverse-ablation variants are authored (`brainstorm-3head-restore`,
`review-fanout-full-restore`) and every affected ledger row carries an explicit OWED.

---

## 3. Proposed, NOT applied — the user's call

Ordered by (saving ÷ risk). Each is a small diff; none is started.

### P1. Orchestrator effort `xhigh` → `high` — biggest remaining lever

Every command header says *"run this on Opus at `xhigh` effort"*. That is the
**largest context in the system, on the most expensive model, at the deepest
reasoning setting, on every one of 100+ turns** — and the orchestrator's own job is
routing, gating, and dispatching, not deep reasoning. The deep reasoning is already
delegated: `architect` and `debugger` carry `effort: xhigh` in their frontmatter.

- **Diff:** one line in each of `new-task.md`, `iterate.md`, `review-pr.md`, etc.
- **Risk:** gate summaries and route judgments get shallower. Route errors are the
  expensive kind (a mis-routed high-stakes task ships under-reviewed) — but the route
  is re-checked at two later checkpoints by construction.
- **Verify:** suite score with attention to the Gate-discipline and Routing rubric
  dimensions; `evals/context-trace.sh` for the cost column.
- **Note:** the effort-defaults ledger row measured per-agent effort **inert in the
  SDK eval harness** — so this must be evaluated in a real CLI run, not in-harness.

### P2. Merge Phases 3–4 into Phase 1–2 for the `standard` route

Today a standard run pays **two** artifact-authoring passes (design doc, plan),
**two** adversarial review loops (Phase 2, Phase 4), and **two** human gates
(GATE 1, GATE 2) before a line of code. Proposal: on `standard` (never
`high-stakes`), the architect writes **design + plan as one artifact**, codex reviews
it once, and GATE 1 + GATE 2 merge into a single design-plan gate.

- **Saves:** one architect dispatch, one reviewer dispatch, an entire review loop
  (up to 5 iterations), and one human touchpoint per run.
- **Supporting evidence already in the ledger:** the Phase 4 dispatch-readiness A/B
  came back **NULL — the construct never bound** (4/4 plans pinned the contract in
  both arms), because the architect's plan format and the Phase 2 design review
  already deliver what Phase 4 re-checks. That is a direct hint that the second loop
  is largely re-verifying the first.
- **Risk:** the mapping table (design decision → step → verification) is a real
  artifact and would need to survive inside the merged review. High-stakes keeps
  both loops unchanged.
- **Verify:** `--variant` A/B on tasks 23–24 (the reliably standard-routing ones).

### P3. Run codex on the **reduced** tier too

Codex costs wall-clock, not Claude tokens. Today the reduced tier skips it
(`codex: skipped (small diff)`) — a rule written when the tier logic was about
saving *tokens*. Running it always would **raise** review quality on small diffs at
**zero** Claude cost.

- **Cost:** ~10 min of latency per small-diff review, wall-clock only.
- **Recommendation:** worth it for `/review-pr` (a human is reading a report, not
  waiting on a loop); marginal for tight `/iterate` loops. Could be gated on the
  command rather than the tier.

### P4. Make Phase 7 (retro + GATE 4) conditional

A clean fast-path run — zero deviations, zero Must-fix, ≤1 review iteration — has
nothing durable to learn, yet still pays a retrospective write, a lesson-distillation
pass, and a per-item GATE 4 decision table.

- **Proposal:** skip the retro when all of those hold, recording
  `retro: skipped (clean scoped run)` in the manifest. Any deviation, escalation,
  Must-fix, or gate rejection re-arms it.
- **Risk:** the review-gap learnings loop (a ledger `keep`) feeds on exactly these
  retros — but its trigger (an escaped defect found later) is by definition *not* a
  clean run, so it is unaffected.

### P5. Cap review loops at 3 iterations instead of 5

Phases 2/4/6/6.5 each allow 5. In practice the escalation ladder and the
"different issue each iteration → go back a phase" rule fire well before then, so
iterations 4–5 are mostly pathological-run tail cost paid at the most expensive
tier.

- **Diff:** four constants. **Risk:** more halts-with-digest (which is the *safe*
  failure — a halt shows the human a failure digest; it never silently passes).

### P6. Route more work away from `/new-task`

Not a code change — usage discipline, and probably the largest real-world saving.
`/new-task` is the full lifecycle; most day-to-day work is a delta on a reviewed
baseline (`/iterate`), a question (`/explain`, ~34k tokens, cheapest tier), or an
inbound issue (`/triage-issue`). A `/new-task` run on work that `/iterate` could
carry pays the entire brainstorm + plan + gate machinery for nothing.

### Considered and rejected

- **Folding Phase 6.1 behavioral verification into the last coder's slice** (saves
  one dispatch): rejected — a coder verifying its own work is precisely the failure
  `verify-feature` exists to prevent, and the ledger row for it is a `keep` with a
  named failure mode (green-tests-but-broken feature shipping).
- **Dropping the skeptic pass entirely**: rejected — it is the one layer with a
  decisive A/B behind it (`comment-skeptic-off` = +1 escaped defect, and the
  `skeptic-off` variant remains queued). Batching it (A5) captures most of the
  saving without removing the mechanism.
- **Switching the orchestrator to a cheaper model mid-run**: rejected — invalidates
  the prompt cache for the entire context, so the next turn re-pays full input price
  on everything. Already forbidden under Session hygiene.

---

## 4. What is owed before this pass can be called *evidence-based*

1. `/workflow-eval` live scorecard on the affected tasks (02, 06, 23, 24) with the
   regression diff vs `evals/results/2026-08-11-readiness-route-controlled-scorecard.md`.
2. `--variant review-fanout-full-restore` at `--repeat ≥ 3` on the review-heavy
   tasks — read escaped defects **by lens class**, not just the total.
3. `--variant brainstorm-3head-restore` — read the *chosen* approach's quality, not
   the number of alternatives generated.
4. A batched-vs-per-finding skeptic comparison (anchoring risk).
5. A machine **without** codex installed, to confirm the Phase 1/2 fallbacks fire and
   are disclosed as Deviations rather than silently dropping a pass.
