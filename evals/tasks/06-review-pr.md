# Task 06 — review a foreign PR (drives /review-pr, exercises the Phase 6 engine offline)

## Command

`/review-pr --local HEAD~1..HEAD` — this task drives **`/review-pr`** (local/offline
mode), not `/new-task`. The `## Seed` builds a two-commit git history in the fixture
copy: the base, then a "PR" commit whose diff carries the planted defects below. The
harness reviews `HEAD~1..HEAD` as if it were a foreign PR. See the driver note in
`commands/workflow-eval.md` Layer 2.

## Intent (stands in for the PR body / linked issue — passed as the intent digest)

> Harden `auth.ValidateToken`: reject bearer tokens longer than 64 characters to
> limit abuse, and return the extracted token alongside the validity bool.

`ci: green` — the PR's CI is passing (no local test run; CI adjudicates the run, the
review judges the code). The planted Must-fix is therefore a defect CI did **not**
catch — the review engine must.

## Fixture

`fixtures/base` — green. The `## Seed` turns it into a git repo, commits the base,
then commits the PR diff. The diff touches `auth/` → high-stakes category → the run
must pick the **full** review tier.

## Seed

Applied to the fixture copy after copy, before dispatch:

```sh
git init -q
git add -A && git commit -q -m "base"
cat > auth/auth.go <<'EOF'
package auth

import "strings"

const maxTokenLen = 64

// ValidateToken reports whether the Authorization header carries a well-formed
// bearer token no longer than maxTokenLen, and returns the extracted token.
func ValidateToken(header string) (string, bool) {
	if !strings.HasPrefix(header, "Bearer ") {
		return "", false
	}
	token := header[len("Bearer"):]
	if len(header) > maxTokenLen {
		return "", false
	}
	return token, true
}
EOF
git add -A && git commit -q -m "harden ValidateToken with length cap"
```

## Planted defects (what a correct review catches)

- **P1 — Must-fix (real, CI-green):** `token := header[len("Bearer"):]` slices at
  offset 6 (`"Bearer"`) instead of 7 (`"Bearer "`), so the returned token keeps a
  leading space — every extracted token is malformed. A shallow-bug lens catches it;
  it survives the skeptic pass.
- **P2 — Should-fix:** the length cap is applied to `len(header)` (whole header,
  including the `"Bearer "` prefix) rather than the extracted token, so the effective
  limit is off by the prefix length.
- **Bait — must land in Rejected:** the changed function signature (`bool` →
  `(string, bool)`) looks like a compliance concern, but no CLAUDE.md rule in the
  fixture forbids it and the intent explicitly asks for it. A correct run either never
  raises it or the skeptic rejects it — it must NOT reach Must-fix.

## Expected behaviour

- **Tier: full** — the diff touches `auth/` (a high-stakes category), so R0 picks the
  full tier with rationale stated, not reduced.
- Report carries the three sections (Must-fix / Should-fix / Rejected), `ci: green`,
  and an advisory assessment (`request-changes`, given P1).
- **P1 reported as Must-fix**; P2 as Should-fix; the bait in Rejected (or absent).
- Read-only: no fixture files changed, nothing posted (local mode, no `--comment`).

## expect (scoring overrides)

- `Routing`: scores tier selection — **full tier on the auth diff** with a stated
  rationale = 100; picking reduced tier on an auth diff = 0.
- `Outcome correctness`: the report is well-formed (three sections + `ci` + advisory)
  AND P1 is surfaced as Must-fix. A false positive (the signature-change bait)
  reaching Must-fix without skeptic rejection scores this dimension ≤ 60.
- `No escaped defects`: **P1 is the seeded defect** — if it is missed (absent, or
  demoted below Must-fix), score ≤ 20 and record an escaped defect.
- `Gate discipline`: **n/a** (local mode has no gates) — renormalize onto the others.
- `Efficiency`: full tier run once, no needless model escalation, within the shared
  fable budget.
- Fail the run if any fixture file was modified or anything was posted (read-only).
