# Linear-style GitHub integration

## Why

Our current GitHub integration is an **issue-mirror**: a GitHub Issue opening creates a Fizzy Card (1:1 via `github_issues.card_id`, system-user-owned), and everything flows GitHub → Fizzy one-way. On top of that we do a crude PR automation — `PullRequestSync#linked_card` grabs the first bare `#N` from a PR's title/body/branch, links the PR to *issue #N's* card, moves it to a hard-coded "In Review" column on PR open, and closes it on merge (`app/models/github/pull_request_sync.rb:37-60`).

The machinery exists but is **inverted and shallow**. Linear's integration is loved because **the tracker card is the hub**: developers start from a card, PRs/branches/commits *attach* to it, and the card flows through its workflow automatically as the PR progresses. Developers barely touch the tracker UI. That is the opposite of mirroring GitHub Issues into cards.

This spec re-aims the integration to the Linear model. It is a re-aiming, not a rewrite — the webhook pipeline (`IntegrationEvent` → `Integrations::ProcessEventJob` → `Router` → `Github::EventProcessor`), signature verification, dedup, and the PR-sync skeleton are all reused.

## Decisions (confirmed)

- **Card-ref token = board prefix**, e.g. `CORE-54`, `AGENT-12` (per-board `key` + card number). Linear-like, human-readable, board-scoped.
- **Primary model pivots to card-as-hub / PR-linking.** GitHub-issue mirroring (`IssueSync`) is demoted to an opt-in secondary mode, kept for the OSS/inbound case.
- **No Fizzy → GitHub write-back** in this project (avoids echo loops / conflict resolution / write scopes). Revisit only for a narrow, concrete need later.

## Phase 1 — Invert + smart automation (PAT auth, reuses existing pipeline) — ✅ DONE

Shipped in commits: board key (`5da95f8e5`), card ref + copy-branch (`b5b216839`),
card-ref PR linking + automation (`594ffe541`), e2e webhook test (`26d444d1a`),
issue-mirror opt-in toggle (`25a2dd3a1`). Verified via unit + webhook integration
tests and a live dev run. Config landed as account-level column-name settings
(`in_progress_column_name`/`in_review_column_name`) with the target branch read
from the webhook payload; issue mirroring is a per-repo `sync_issues` toggle
(default off).


### Board key + card ref
- `Board.key` — short uppercase prefix (`^[A-Z][A-Z0-9]{1,9}$`), **unique per account**. Auto-derive from board name on create (e.g. "aqui-core" → `CORE`); editable in board settings. Migration + backfill existing boards.
- Card ref string = `"#{board.key}-#{card.number}"` (card number is the existing per-account sequential).
- Parser: regex `\b([A-Z][A-Z0-9]+)-(\d+)\b`, resolve `(key, number)` → card, scoped to the account. Ignore refs whose key/number don't resolve.

### Copy git branch name
- Action on the card (button + keyboard shortcut) yielding `#{login-or-slug}/#{key.downcase}-#{number}-#{title-slug}`, e.g. `melvin/core-54-fix-otp-bypass`. Native Fizzy design system.

### Linking (card-ref, keyword-aware)
- Rewrite `PullRequestSync#linked_card` to resolve by **card-ref token**, scanning branch → PR title → PR body (commits in Phase 2), replacing the bare-`#N`→issue lookup.
- **Closing keywords**: `close, closes, closed, closing, fix, fixes, fixed, fixing, resolve, resolves, resolved, resolving, complete, completes, completed, completing, implement, implements, implemented, implementing`.
- **Non-closing keywords**: `ref, refs, references, part of, related to, relates to, contributes to, toward, towards`.
- A bare token (no keyword) links but does not close on merge; a closing keyword marks the card done on merge to the target branch.
- Because linking is by card ref, a **native Fizzy card with no GitHub issue** can attach to a PR — the key unlock vs today.
- Store the PR as a first-class link/attachment on the card (extend `Github::PullRequest` / `ExternalLink`), rendered on the card (basic state string in P1).

### Status automation (per board, guarded)
- Replace the single hard-coded "In Review" move with a configurable per-board mapping:
  - branch pushed / **draft PR** → *In Progress* column (Phase 2 for push; draft handled in P1 via `converted_to_draft`/opened-as-draft)
  - PR **opened / ready_for_review** → *In Review* column
  - PR **merged to the default/target branch** → *Done* / close (only when a closing keyword linked it)
- **Guards**: never revert an already-closed card; only advance from allowed prior states; Done fires only on merge to the configured target branch (default = repo default branch).
- Config on the `Integration`/`Repository`/`Board` (decide during build): `in_progress_column`, `in_review_column`, `done_behavior`, `target_branch`.

### PR events handled
`opened`, `ready_for_review`, `converted_to_draft`, `reopened`, `closed` (+ `merged`), `edited` (re-parse links).

### Keep IssueSync as opt-in secondary mode
Repo mapping gains a mode toggle (pr-linking [default] vs issue-mirror). PR-linking works regardless of mode.

### Tests
Card-ref parse/resolve; branch-name generation; keyword closing vs non-closing; per-board column transitions + guards; native-card (no issue) linking; merge-to-non-target-branch does not close; reopened handling.

## Phase 2 — Live PR panel + GitHub App (fast-follow) — ✅ DONE

Shipped in commits: live review/checks state (`06d015862`), push/commit → In
Progress (`de5f23f93`), GitHub App auth (`47dd9a81e`). Full suite green (1671).

- **GitHub App** auth: `Github::App` signs an RS256 JWT with the app private key
  and exchanges it for a cached installation token; `Github::Auth.token` prefers
  it over the PAT. Settings screen gained App ID / installation ID / private key.
  (Client stays read-only. Real token exchange is stubbed in tests — not yet
  exercised against a live GitHub App.)
- New events wired in `Github::EventProcessor`: `pull_request_review` →
  `PullRequestReviewSync` (review verdict), `check_suite`/`status` →
  `ChecksSync` (CI state), `push`/`create` → `PushSync` (commit/branch parsing →
  untriaged card advances to In Progress, guarded against demotion/closed cards).
- **Enriched card PR panel**: draft/open/merged state plus review (approved /
  changes requested) and checks (success/failure/pending) badges. Reviewer
  avatars were not added (would need per-reviewer storage) — deferred.

## Phase 3 — Narrow bidirectional (deferred, only if needed)

Not planned. If a concrete need appears (e.g. mirror a card comment to the PR, or close the GitHub issue when the card closes in issue-mirror mode), add a single narrow write path behind the GitHub App — never a general two-way sync.

## References
- Research notes: Linear docs (github-integration), feedvote guide, Zero webhook pattern.
- Current-code map: issue-mirror in `app/models/github/issue_sync.rb`; PR automation in `app/models/github/pull_request_sync.rb`; pipeline in `app/models/integrations/`, `app/models/integration_event.rb`, `app/controllers/integrations/github/webhooks_controller.rb`.
