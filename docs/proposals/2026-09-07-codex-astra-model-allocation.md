# Cross-vendor model allocation: where GPT-6 Astra belongs in the workflow

**Date:** 2026-09-07 · **Status:** evaluation + recommendations — **nothing applied**
(every row below is behavior-affecting and gated on `/workflow-eval` per `CLAUDE.md`
rules 2–3; four ablation variants authored in `evals/variants/`)
**Question asked:** where can more codex — specifically **GPT-6 Astra** — be brought
into the workflow; how do the Anthropic and OpenAI fleets compare on strengths,
weaknesses and cost; which model should sit in which seat, and what escalates to what.

## 0. What changed underneath the workflow

The 2026-08-11 cost pass installed one organising rule: **a second opinion is bought
out-of-model, not as a second Claude call.** It rests on one premise, stated in
`skills/codex-exec/SKILL.md` and `commands/new-task.md` — *"codex time is not Claude
spend, so a slow codex is cheap"* — and treats codex as a single undifferentiated,
effectively free, unbounded resource.

Three things have changed since:

1. **Codex is no longer one model.** The Codex CLI now selects between
   `gpt-6-astra` (flagship, the bundled default from v0.153.4), `gpt-5.6-sol` (the
   stable "Power" fallback) and `gpt-5.6-terra` / `gpt-5.6-luna` (the cheaper, faster
   tiers). The workflow pins none of them, so **the model running its three codex
   passes changed when the CLI updated** — silently, and in the direction of more
   cost and more latency.
2. **Codex is not free; it is quota-metered.** On a plan-billed Codex CLI, Astra is
   reported at **5–45 local messages per 5-hour window on Plus / Business Standard**,
   25–225 on Pro $100, 100–900 on Pro $200. A standard `/new-task` run spends
   **3–5 codex invocations** (Phase 1.2 lens, Phase 2.1 design review, Phase 6.3
   review × up to 3 iterations). On Plus that is plausibly a whole window per run.
   Codex is off the *Claude* bill; it is not off *a* bill.
3. **On API billing Astra is the most expensive seat in the fleet** — more expensive
   than Fable 5.1, the model the one-fable-per-run budget exists to ration (§2).

So the premise survives in shape but not in strength: out-of-model is still the right
place to buy a second opinion, but it is now a **budgeted, tiered** resource that
needs the same discipline the fable budget already gets.

## 1. The two fleets

### Anthropic (per-token, first-party API)

| Model | ID | Input $/MTok | Output $/MTok | Cache read $/MTok | Context |
|---|---|---|---|---|---|
| Fable 5.1 | `claude-fable-5-1` | 10.00 | 50.00 | **0.25** (0.025×) | 1M |
| Opus 5 | `claude-opus-5` | 5.00 | 25.00 | 0.50 (0.1×) | 1M |
| Sonnet 5 | `claude-sonnet-5` | 2.00 | 10.00 | 0.20 | 1M |
| Haiku 4.5 | `claude-haiku-4-5` | 1.00 | 5.00 | 0.10 | 200K |

Effort `low`–`max` on Opus 5 / Fable 5.1 / Sonnet 5; adaptive thinking; Opus 5 caches
from a 512-token prefix.

### OpenAI (via Codex CLI — plan-metered, or per-token on the API)

| Model | Role in the CLI | API input $/MTok | API output $/MTok | Cached input $/MTok | Context |
|---|---|---|---|---|---|
| `gpt-6-astra` | flagship; bundled default ≥ v0.153.4 | 10.00 | 50.00 | **1.00** | ~1.05M |
| `gpt-5.6-sol` | stable fallback ("Power") | — | — | — | — |
| `gpt-5.6-terra` / `-luna` | cheap/fast tiers | — | — | — | — |

Astra: effort `low|medium|high|xhigh|max` (`model_reasoning_effort` in `config.toml`,
`--model` on the command line); cache **writes** bill at 1.25× uncached input; any
prompt past **272K input tokens reprices the entire request** to $20 input / $75
output; Batch and Flex halve the rates, Fast doubles them.

### The cost comparison that matters

Astra and Fable 5.1 are **priced identically on fresh tokens** ($10 / $50). They
diverge on cache reads, which is where a long-lived agent context actually lives:

- Astra cache read **$1.00** = **2× Opus 5** and **4× Fable 5.1**.

So on API billing there is no cost argument for Astra over the Anthropic top rung —
it is strictly more expensive than Fable 5.1 for the same headline price, and 2× Opus
5. **Astra's economic case exists only under a plan-billed Codex CLI**, and there it
is bounded by the 5-hour message quota rather than by dollars. That inverts how the
resource should be rationed: not "spend freely because it is free", but "spend the
scarce Astra messages on the passes with the largest measured Astra delta."

## 2. Strengths and weaknesses, by measured evidence

Ordered by how directly each result bears on a seat in this workflow.

| Evidence | Result | What it says about seat assignment |
|---|---|---|
| CodeRabbit code-review eval (actionable bug coverage) | Astra catches **~22% more labeled bugs than Opus 5**; **+33% on harder cross-file reviews**; **+2.3 pts over GPT-5.6 Sol** overall (+20% cross-file) | The single strongest signal in this pass. Astra is a **detection** specialist, and its edge is concentrated exactly where a diff spans files. |
| Same eval | The best model still **misses 38.7%** of labeled bugs | Independent confirmation that the **two-channel** review design is right, and that neither channel may be dropped to save the other. |
| Terminal-Bench 4.0 | Astra **57.7** vs Opus 5 **52.3** | Long, messy, multi-step terminal work with error recovery — the shape of **CI triage** and **stubborn root-cause**. |
| Deep SWE | Astra 74.1 vs Opus 5 73.7 | Parity. No case for moving implementation work out-of-model. |
| Artificial Analysis Intelligence Index (broad aggregate) | Astra **61.2**, placed **behind Opus 5 and Fable 5.1** | Astra is **not** the model for synthesis, ranking, or gate-facing judgment. Keep Phase 1 synthesis on Opus. |
| Vals AI SWE-bench Verified (minimal bash harness) | Opus 5 **97.0%**; no same-harness Astra number (benchmark archived as saturated) | There is **no clean cross-vendor coding head-to-head**. Treat any single table with suspicion — which is why every row in §4 owes an A/B on *this* suite. |
| Reported weaknesses | Higher effort materially increases **latency** and token use; verbosity/noise in CI review contexts; first-party evals do not transfer to your repo | Latency is the binding constraint on any codex pass that sits on a barrier a human or a loop is waiting behind. |

**Summary of comparative advantage.**

- **Astra wins:** cross-file defect detection, long-horizon terminal/agentic recovery,
  computer use, cyber. Plus the irreducible win that motivated codex in the first
  place — it is a *different vendor*, so its misses are not correlated with Claude's.
- **Anthropic wins:** broad reasoning and synthesis (Opus 5 / Fable 5.1 both above
  Astra on the aggregate), cost per token on cached context (Fable 5.1 cache reads are
  ¼ of Astra's), latency, and — decisively for this repo — **repo context**: the
  Claude agents read `CLAUDE.md`, the plan, the learnings and the run ledger. A
  read-only codex pass given a path does not carry that.
- **Neither wins the review outright**, which is why the answer below is a *split of
  remits by comparative advantage*, not a swap.

## 3. Where codex is today, and the gaps

Codex occupies exactly three slots: `new-task` Phase 1.2 (design lens), Phase 2.1
(adversarial design review), Phase 6.3 / `review-pr` R1 / `iterate` I2 (review Channel
B). It is absent from every other command and from every escalation rung.

| Candidate seat | Today | Astra fit | Verdict |
|---|---|---|---|
| Phase 6.3 review Channel B | codex, unpinned model | **Strongest** (+22% vs Opus 5, +33% cross-file) | **Pin and tier** (R1, R3) |
| Phase 6.5 CI triage | `test-runner` (haiku) digest → coder → debugger → fable debugger | **Strong** (Terminal-Bench profile) | **Add a rung** (R4) |
| `debugger` escalation | opus → fable (the one fable escalation) | **Strong**; and it protects the scarcest Claude budget | **Add a rung before fable** (R4) |
| `/triage-issue` T2 root-cause | coder repro + debugger escalation | **Strong** — cross-file root-cause | **Add a lens** (R5) |
| `/address-review` A3 skeptic | **one fresh Claude `reviewer` per item** — the largest surviving Claude fan-out in the suite | Good — refuting a claim against a diff is detection, not synthesis | **Add a batched codex pass** (R6) |
| Phase 1.2 design lens | codex | Neutral — lens diversity is the point, not raw capability | Keep; run it on the **cheap tier** (R3) |
| Phase 2.1 adversarial design review | codex | Neutral-to-weak — this is judgment, and Astra trails on the aggregate | Keep; **cheap tier**, Astra only on high-stakes (R3) |
| Phase 1.3 synthesis / ranking | opus `architect` | **Poor** — synthesis is Astra's weakest measured band | **Do not move** |
| `/explain` | haiku `searcher` fan-out; "cost is the point" | **Poor fit** — a 10-min codex pass destroys the command's defining property | **Do not add** |
| `coder` | sonnet | Parity on Deep SWE, and codex runs `--sandbox read-only` by design | **Do not move** |
| `searcher` / `test-runner` | haiku, low | Mechanical; codex quota is scarcer than haiku tokens | **Do not move** |

## 4. Recommendations

Each row names the failure it addresses, the seat it changes, and the A/B that owes it.
Four variants are authored; two rows are corrections of fact that carry no A/B.

### R1 — Pin the codex model explicitly; stop inheriting the CLI default

`skills/codex-exec/SKILL.md` never passes `--model`. When the CLI's bundled default
moved to Astra at v0.153.4, every codex pass in the workflow silently changed model,
cost tier, latency profile and quota bucket. The skill's own principle — *"flag names
track the installed codex; the principles are what matter"* — needs a model-pinning
companion: **the pass, not the CLI, chooses the model**, and the choice is recorded in
the run ledger alongside `codex: ok`.

`codex exec --model <pinned> -c model_reasoning_effort=<level> …`, with the existing
stdin/timeout/sandbox discipline unchanged.

*Correction of fact + determinism; no A/B owed. Applying it is a prerequisite for
R2–R4, which cannot be measured while the model is whatever the CLI last shipped.*

### R2 — Correct the "codex is free" claim, and give codex a budget

Three places assert or imply that codex is free and unbounded:
`skills/codex-exec/SKILL.md` §2 (*"codex time is not Claude spend, so a slow codex is
cheap"*), `commands/new-task.md` **Token hygiene**, and the **Escalation ladder**'s
*"codex … never counts against the fable budget"*.

The shape is still right — codex is off the Claude bill and outside the fable budget —
but "free" is now false in two ways: a plan-billed CLI meters Astra at 5–45 messages /
5h on Plus, and an API-billed one prices Astra above Fable 5.1 on cached context. The
text should say **off the Claude bill, on its own quota**, and the ladder should gain a
**codex budget** mirroring the fable rule:

> **AT MOST ONE `gpt-6-astra` pass per run** by default. It is spent on the pass with
> the largest measured Astra delta — the Phase 6 review channel on a cross-file or
> high-stakes diff — unless a CI/debug escalation (R4) claims it first. Every other
> codex pass runs on the cheap tier.

*Correction of fact + one new budget construct; the budget owes a ledger row and rides
the `codex-astra-review-on` A/B.*

### R3 — A codex ladder, mirroring the Claude ladder

Codex currently sits outside the escalation ladder as a single undifferentiated rung.
Give it its own two-rung ladder, so the scarce quota is spent where the evidence says
it pays:

| Codex pass | Default | Escalate to | When |
|---|---|---|---|
| Design lens (1.2) | `gpt-5.6-terra` | `gpt-5.6-sol` | lens returns off-brief or empty |
| Adversarial design review (2.1) | `gpt-5.6-sol` | `gpt-6-astra` | high-stakes route only |
| Review Channel B (6.3 / review-pr R1 / iterate I2) | `gpt-5.6-sol` | **`gpt-6-astra` @ `xhigh`** | diff spans ≥2 interdependent files, **or** high-stakes route, **or** the same issue survives 2 iterations |
| CI / root-cause rung (R4) | `gpt-6-astra` @ `xhigh` | — | it is already the top rung |

Rationale: Astra is only **+2.3 pts over Sol overall** but **+20% on cross-file** — so
Sol is the right default and Astra is the right *escalation*, triggered by the property
that predicts the gap. Effort tracks the same logic: `high` is the vendor's coding
default, `xhigh` for the escalated pass, and `max` is not used (latency on a barrier).

*Owes:* `evals/variants/codex-astra-review-on.md`.

### R4 — Insert a codex root-cause rung **before** the one fable escalation

Today `debugger` (opus) → fable `debugger` is the terminal rung, and Phase 6.5's CI
ladder shares that single fable budget. Both are the Terminal-Bench profile — messy,
multi-step, error-recovery work — where Astra leads Opus 5 by 5.4 points, and both
currently burn the run's most expensive Claude escalation.

Proposed rung, for `debugger` escalation and Phase 6.5 CI triage alike:

> coder → `debugger` (opus) → **codex `gpt-6-astra` root-cause pass** (read-only;
> returns a root-cause digest, never a fix) → fable `debugger` (implements the fix, if
> still needed).

The read-only sandbox invariant is load-bearing here and is *why* this works as a
ladder rung rather than a replacement: codex produces the diagnosis, a Claude agent
carrying the repo context and write access applies it. On a hit, the run never spends
its fable escalation at all.

*Owes:* `evals/variants/codex-debug-rung-on.md`. Ledger row required (new rung).

### R5 — A codex root-cause lens in `/triage-issue` T2

`/triage-issue` classifies, reproduces and root-causes with a `coder` plus a `debugger`
escalation, entirely in-model. Root-causing an unfamiliar bug across files is Astra's
best-measured band, and triage is read-only by construction — it is the cleanest fit in
the suite for a read-only sandbox. Run it **in parallel** with the `coder` repro (it
does not sit on a barrier: T2 already waits on the repro) and feed both digests to the
scoping step.

*Owes:* covered by the `codex-debug-rung-on` A/B, whose root-cause arm is the same
mechanism; a separate variant is only warranted if that A/B lands positive.

### R6 — Batch `/address-review`'s skeptic verification out-of-model

A3 dispatches *"one fresh parallel `reviewer` per item, default-refute"* — N Claude
dispatches, the largest surviving Claude fan-out after the 2026-08-11 cuts, on a
command whose whole point is to be cheap. Phase 6 already learned this lesson once
(per-finding skeptics → one batched dispatch). Verifying whether a reviewer's claim is
real against a diff is detection, not judgment.

Proposal: **one batched codex pass** over all candidate items (default-refute, same
output shape), consolidated orchestrator-side; the Claude `reviewer` skeptic survives
as the named fallback and for items whose claim turns on repo convention or plan
intent, which codex cannot judge without the repo context.

*Owes:* `evals/variants/codex-skeptic-batched-on.md`. Ledger row required.

### R7 — Split the review remit by comparative advantage, don't duplicate it

Channel A (one Claude `reviewer`, **sonnet**) carries a merged four-lens remit — plan
compliance · bug scan · git history · `CLAUDE.md` compliance — and Channel B (codex)
also does a bug scan. The bug-scan lens is therefore duplicated across the two
channels, and it is duplicated on the *weaker* side: Astra out-detects **Opus 5** by
22%, and Channel A is a rung below that.

Meanwhile the three lenses codex is structurally worst at — plan compliance, repo
conventions, git history — are the ones that need `CLAUDE.md`, the plan and the
history, and they are sharing a ~500-word budget with the duplicated lens.

Proposal: **weight, don't drop.** Channel A leads on the three repo-context lenses and
keeps the bug scan as an explicit secondary (the 38.7% miss rate says overlap has
value); Channel B leads on correctness and cross-file bug scan. Both still report per
lens, so an unreported lens can never read as "clean" to consolidation.

*Owes:* `evals/variants/codex-review-remit-split.md`.

### R8 — What must **not** move out-of-model

Recorded so a future pass does not re-derive it: **Phase 1.3 synthesis / ranking**
(Astra trails both Opus 5 and Fable 5.1 on the broad aggregate; this is the judgment
seat that writes the artifact a human approves), **`/explain`** (a 10-minute codex pass
contradicts the command's defining cheapness, and Q&A synthesis is not Astra's band),
**`coder`** (parity on Deep SWE, and every codex pass here runs `--sandbox read-only`
by design), and **`searcher` / `test-runner`** (mechanical work, and haiku tokens are
cheaper than a scarce Astra message).

### R9 — Quota exhaustion needs its own exit class

`codex-exec` §3 classifies `0`, `124` (timeout), `127` (not installed) and *"any other
nonzero"*. A plan-quota or rate-limit refusal lands in that catch-all and is recorded as
a mysterious skip — the exact failure mode the classification exists to prevent, and now
the *most likely* codex failure under a 5-hour window. It needs its own class with its
own degrade path:

> quota/rate-limit → **downshift to `gpt-5.6-terra`/`-luna`** (a different quota bucket)
> and record `codex: downshifted (quota) → <model>`; only if that also fails does the
> pass fall back to its named Claude agent.

*Correction/robustness; no A/B owed beyond the lint.*

## 5. Recommended allocation, end state

| Seat | Model | Effort | Change |
|---|---|---|---|
| Orchestrator | Opus 5 | high | unchanged — highest broad aggregate per dollar; Fable's cache-read edge does not offset its 2× on the orchestrator's fresh-input volume |
| `architect` (design, synthesis, plan) | Opus 5 | high | unchanged — the judgment seat |
| `coder` | Sonnet 5 | high | unchanged |
| `reviewer` Channel A | Sonnet 5 → Opus 5 → Fable 5.1 | high | unchanged ladder; **remit re-weighted** to repo-context lenses (R7) |
| `debugger` | Opus 5 → **codex Astra digest** → Fable 5.1 | high | new out-of-model rung (R4) |
| `searcher` | Haiku 4.5 | low | unchanged |
| `test-runner` | Haiku 4.5 | low | unchanged |
| Codex design lens (1.2) | `gpt-5.6-terra` | high | pinned + downshifted (R1, R3) |
| Codex design review (2.1) | `gpt-5.6-sol` → Astra on high-stakes | high | pinned + tiered (R1, R3) |
| Codex review Channel B | `gpt-5.6-sol` → **Astra @ xhigh** on cross-file / high-stakes | high → xhigh | pinned + tiered (R1, R3); **remit re-weighted** to correctness (R7) |
| Codex CI / root-cause rung | `gpt-6-astra` | xhigh | new (R4, R5) |
| Codex skeptic (address-review) | `gpt-5.6-sol` | high | new, batched (R6) |

**Budgets:** at most **one fable escalation** per run (unchanged) and at most **one
Astra pass** per run (new, R2). The two are independent — the point of R4 is that
spending the Astra message can *avoid* spending the fable one.

## 6. What is owed

- Every row except R1, R2's text correction and R9 is behavior-affecting and needs a
  live `/workflow-eval` scorecard with a regression diff before merge (`CLAUDE.md`
  rule 2). R2's budget, R4's rung and R6's pass each add a construct and additionally
  need a `complexity-ledger.md` row and an ablation A/B (rule 3).
- Variants authored: `codex-astra-review-on`, `codex-debug-rung-on`,
  `codex-skeptic-batched-on`, `codex-review-remit-split`.
- **The measurement has a hard prerequisite:** codex is not installed in the
  environment this evaluation was written in (`command -v codex` fails), so none of
  these numbers are from this suite. The vendor and third-party results in §2 are
  evidence about the **models**, not about this workflow — the same standing this
  repo gave Anthropic's own guidance on 2026-09-07. Each A/B must run on a machine
  with Codex CLI ≥ v0.153.4 authenticated, and each scorecard must record which codex
  model actually served the pass (R1 is what makes that recordable).
- Astra's long-context repricing (>272K input → $20/$75) is not currently reachable —
  every codex pass here is given paths, not payloads — but it becomes reachable the
  moment a pass is handed a large diff inline. Worth a note in `codex-exec` if R6
  lands, since a batched skeptic pass is the one that could grow.

## Sources

- [GPT-6 Astra: A new generation of intelligence — OpenAI](https://openai.com/index/gpt-6-astra/)
- [GPT-6 Astra in code review: gains, privacy, and cost — CodeRabbit](https://www.coderabbit.ai/blog/gpt-6-astra-code-review-evaluation)
- [Benchmarking GPT-6 Astra — Artificial Analysis](https://artificialanalysis.ai/articles/benchmarking-gpt-6-astra)
- [GPT-6 Astra vs Claude Opus 5: Tested — ComputingForGeeks](https://computingforgeeks.com/gpt-6-astra-vs-claude-opus-5/)
- [GPT-6 Astra Arrives: Configuring OpenAI's Most Capable Model in Codex CLI](https://codex.danielvaughan.com/2026/09/03/gpt-6-astra-codex-cli-configuration-context-notes-safety/)
- [GPT-6 Astra in Codex CLI: 1.05M Context, and What the New Model Actually Costs](https://codex.danielvaughan.com/2026/09/04/gpt-6-astra-codex-cli-integration-guide-critical-cyber-threshold/)
- [GPT-6 Astra Codex Usage Limits: Quota, Plus vs Pro & Resets](https://www.codexusage.dev/limits/astra)
- [GPT-6 Astra pricing — CloudZero](https://www.cloudzero.com/blog/gpt-6-pricing/)
- [OpenAI API Pricing (September 2026)](https://www.aipricing.guru/openai-pricing/)
- Anthropic model pricing and effort levels: bundled `claude-api` skill (current-models table, `shared/prompt-caching.md` § Economics)
