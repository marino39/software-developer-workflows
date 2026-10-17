# `/research` — multi-source external research lane

Date: 2026-10-17. Status: implemented on `claude/research-command` (user directive);
live scorecard OWED. Spec: `commands/research.md`.

## The gap

External questions had two lanes, both wrong-sized: one `researcher` call (≤400
words, no verification, no artifact) or `/new-task`, which is built to ship code.
Nothing held multi-source research to the grounding standard `/explain` holds codebase
answers to.

## Decisions

| Decision | Why |
|---|---|
| The **claim** is the unit of work (`claims.jsonl`) | verify, gap check and critique all join on claim ids; prose-level checks are judgment calls |
| `researcher` does sweep **and** verify (`mode: verify`) | no new agent; blindness comes from what the dispatch withholds, not from a different agent |
| Verify is refutation-first, fetch-the-cited-page | "I believe it is true" is not support — the failure mode is a plausible claim attributed to a page that does not state it |
| ≤2 waves, deterministic coverage rule | an unbounded gap loop is the expensive failure; leftovers become **Gaps** |
| Critique is codex (§5.6), `reviewer` fallback | the suite's rule: a second head is bought out-of-model; the audit needs only two local files |
| `report.md` canonical; HTML = pandoc, opt-in | diffable, Obsidian-readable, cheap for later agents; a model never writes layout tokens |
| Numbers derived from >1 claim run in `calc/` | arithmetic in prose is unverifiable |

## Deliberately not done (vs the first chat sketch)

- **No `shared/ dev/ research/` restructure.** The shared primitives already are
  skills/agents (`codex-exec`, `reviewer`, Review loop conventions); `install.sh`
  copies flat dirs. A restructure would cost a lint/install rewrite for no reuse gain.
- **No separate analyst agent** — `calc/` scripts cover it at zero dispatches.
- **No research learnings file yet.** Add one when a retro shows a repeated
  research-specific mistake (ledger rule: a construct needs a sourced failure).
- **No `/new-task` wrong-lane bounce to `/research` yet** — that edits the biggest
  prompt; do it after task 25 has a scorecard.

## Checked so far

- Lint green; R6's pandoc command renders a standalone page with a TOC.
- Researcher verify-mode contract dispatched live in a sandbox with no outbound web:
  both ids came back as well-formed `unreachable` verdicts, in order — it declined to
  mark either claim from belief. Shape holds; the content check needs a networked run.

## Owed

Live scorecard on task 25; `--contracts --agent researcher` (two new stimuli); A/B
`research-verify-off`; a guide page (`docs/guide/research.html`).
