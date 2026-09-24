# Model-tuning notes — maintainer record

**Moved out of `commands/new-task.md` on 2026-09-20** (proposal
`docs/proposals/2026-09-20-workflow-leanness-verification.md` P3). This is the design
record for how seats are pinned across Claude tiers and across vendors — read it before
changing a model, an effort level, or a codex allocation. It is **not** needed to run a
task: the orchestrator paid for these ~580 words on every turn while acting on almost none
of them. The operative pieces stay where they act:

- Fable's cost profile (2× fresh input, cheaper cache reads) — each command's header line.
- Never switch your own model or effort mid-run — `new-task.md` § Token hygiene, Session
  hygiene. (The second reason recorded below — on Fable-tier models thinking blocks are
  bound to the producing model — is rationale for that rule, not a separate rule.)
- The codex ladder, budget and per-pass tiers — `new-task.md` § Escalation ladder and
  `skills/codex-exec/SKILL.md` §0.
- The seats that must NOT move out-of-model — inlined in `skills/codex-exec/SKILL.md`,
  the one file that acts on the list.
- Effort levels — `new-task.md` § Effort defaults.

The text below is the section as it stood, unchanged.

---

## Model-tuning notes (as moved)

The fleet is **heterogeneous under one set of prompts**: this command is read by the
Opus orchestrator, each `agents/*.md` by the model that agent is pinned to, and by
whatever rung the ladder overrides it to. Vendor prompting guidance is therefore
**per file, by the model that reads it** — never applied repo-wide.

- **Opus 5 and Fable 5.1 disagree on two axes.** Opus 5 reaches for subagents readily
  and self-verifies unasked (so it wants a delegation cap and no verification nudges);
  Fable 5.1 wants the opposite — delegate freely, and keep verification instructions.
  A change justified by one model's guidance must name which files it touches and
  which model reads them.
- **Fable is 2× on fresh input, not on cached context.** The per-command header framing
  ("doubles the price of every context token") holds for uncached input. Cache reads
  invert it: Fable 5.1 reads at 0.025× its base rate, roughly **half** the Opus cache-read
  price. The orchestrator context is cache-read-dominated, so the 2× penalty is smallest
  exactly where the context is largest — weigh a Fable orchestrator on fresh-input volume,
  not on total context size.
- **Never switch your own model mid-run** (Session hygiene, below) now has a second
  reason beyond cache invalidation: on Fable-tier models thinking blocks are bound to
  the model that produced them, so a mid-run switch drops them from the prompt. Subagent
  `model` overrides remain safe — separate contexts.
- **Opus 5 caches from 512 tokens** (down from 1024), so short dispatch prompts
  previously below the floor now cache. Prompt-caching-shaped decisions written against
  the old floor are worth re-checking.
- **Effort defaults do not transfer across model generations.** `high` is the API
  default and the intended starting point; `xhigh`/`max` are for a measured win, not a
  starting posture. Re-sweep after any model change rather than carrying a level over.

### Cross-vendor allocation (2026-09-07)

The fleet is heterogeneous across **vendors** too, not just across Claude tiers
(`docs/proposals/2026-09-07-codex-astra-model-allocation.md`).

- **Out-of-model is off the Claude bill, not free.** A plan-billed codex CLI meters the
  flagship per 5-hour window; an API-billed one prices it **above Fable 5.1 on cached
  context**. So codex is tiered and bounded like fable — a ladder plus a soft
  two-flagship-per-run cap (`codex-exec` §0), not an unbounded resource. The cap is
  soft by design: it downshifts and records, never halts a pass.
- **Allocate by comparative advantage, and never by headline capability.** The
  out-of-model flagship's measured edge is concentrated in **detection** — cross-file
  defect finding, and long-horizon terminal/error-recovery work. It **trails** both
  Opus 5 and Fable 5.1 on broad reasoning aggregates. So it leads the review channel's
  correctness lens and the root-cause rung, and it stays out of the synthesis seats.
- **What must NOT move out-of-model** (recorded so a future pass does not re-derive
  it): **Phase 1.3 synthesis/ranking** — judgment, and the seat that writes the
  artifact a human approves at GATE 1; **`/explain`** — a ~10-min pass contradicts the
  command's defining cheapness, and Q&A synthesis is not the band codex wins;
  **`coder`** — parity on the coding benchmarks, and every codex pass here runs
  `--sandbox read-only` by design; **`searcher`/`test-runner`** — mechanical work, and
  haiku tokens are cheaper than a metered codex message.
- **A read-only pass does not carry repo context.** The Claude agents read `CLAUDE.md`,
  the plan, the learnings and the run ledger; a codex pass handed a path does not. That
  asymmetry — not raw capability — is what assigns the lenses in Phase 6.3 and what
  routes convention/intent claims back to Claude in `/address-review` A3.
