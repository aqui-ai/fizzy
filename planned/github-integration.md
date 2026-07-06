# GitHub Integration Plan

## Context

Production currently runs the GHCR-packaged version of Fizzy. That version cannot be changed directly, so `aqui-fizzy-bridge` exists as an external service that connects GitHub to production Fizzy.

This local Fizzy repo is intended to replace the GHCR version. Once that happens, the core GitHub integration should move into Fizzy itself. The bridge should become a migration and compatibility tool, not permanent required infrastructure.

Current production flow:

- GitHub sends webhooks to `aqui-fizzy-bridge`.
- The bridge creates and updates Fizzy cards through the Fizzy API.
- The bridge stores GitHub issue to Fizzy card mappings in its own mapping database.
- Fizzy itself does not natively know that a card is linked to GitHub.

Target flow:

- GitHub sends webhooks directly to Fizzy.
- Fizzy owns GitHub repository, issue, pull request, and user mapping data.
- Fizzy cards can show GitHub metadata directly.
- Reports and filters can use GitHub data without depending on bridge-local state.

## Current Bridge Behavior To Preserve

The native integration should preserve the important behavior already handled by `aqui-fizzy-bridge`:

- Backfill GitHub issues into Fizzy cards.
- Create Fizzy cards when GitHub issues are opened.
- Link GitHub issues to Fizzy cards.
- Apply `repo:*`, `type:*`, `priority:*`, and `phase:*` tags.
- Map GitHub assignees to Fizzy users.
- Move cards based on GitHub status labels.
- Move cards to `In Review` when pull requests open or become ready for review.
- Close Fizzy cards when GitHub issues close.
- Close Fizzy cards when linked pull requests merge.
- Attribute actions to mapped Fizzy users where possible.
- Support developer and agent workflows currently exposed through the bridge MCP tools.

## Goals

- Make GitHub-linked work first-class in Fizzy.
- Support both developers and non-developers in the same boards.
- Keep non-developer card views simple.
- Give developers direct visibility into repositories, issues, pull requests, labels, and merge state.
- Preserve account and board access controls.
- Make GitHub data available to filters, reports, exports, and search.
- Retire bridge mutation paths after the native integration is deployed and verified.

## Non-Goals For The First Native Version

- Full GitHub App marketplace/public installation flow.
- Complex bidirectional synchronization for every card field.
- Replacing GitHub as the code review interface.
- Reconstructing complete historical GitHub state before native sync exists.
- Permanent dependence on the bridge mapping database.

## Phase 1: Native GitHub Data Model

Add models under a GitHub namespace.

Recommended models:

- `Github::Repository`
- `Github::Issue`
- `Github::PullRequest`
- `Github::UserLink`
- Optional later: `Github::Installation`

Suggested `github_repositories` fields:

- `account_id`
- `board_id`
- `github_id`
- `owner`
- `name`
- `full_name`
- `html_url`
- `active`

Suggested `github_issues` fields:

- `account_id`
- `board_id`
- `card_id`
- `repository_id`
- `github_id`
- `number`
- `title`
- `body`
- `html_url`
- `state`
- `labels`
- `assignees`
- `opened_at`
- `closed_at`
- `last_synced_at`

Suggested `github_pull_requests` fields:

- `account_id`
- `board_id`
- `card_id`
- `repository_id`
- `github_id`
- `number`
- `title`
- `html_url`
- `state`
- `merged`
- `merged_at`
- `head_ref`
- `last_synced_at`

Suggested `github_user_links` fields:

- `account_id`
- `user_id`
- `github_id`
- `github_login`

Recommended indexes:

- Unique repository index on `[account_id, github_id]`.
- Unique repository index on `[account_id, full_name]`.
- Unique issue index on `[account_id, repository_id, number]`.
- Unique issue index on `[account_id, card_id]` where possible.
- Unique pull request index on `[account_id, repository_id, number]`.
- Unique user link index on `[account_id, github_login]`.

## Phase 2: Native GitHub Webhook Receiver

Add an authenticated webhook endpoint inside Fizzy.

Suggested route:

```ruby
namespace :integrations do
  namespace :github do
    resource :webhook, only: :create
  end
end
```

Webhook controller responsibilities:

- Read the raw request body.
- Verify `X-Hub-Signature-256` with the configured GitHub webhook secret.
- Read `X-GitHub-Event` and `X-GitHub-Delivery`.
- Store or enqueue the event for processing.
- Return `202 Accepted` quickly.
- Do not run heavy sync work inline in the request.

Initial supported GitHub events:

- `issues`
- `pull_request`
- `issue_comment`

Optional later events:

- `label`
- `repository`
- `installation`
- `installation_repositories`

## Phase 3: Sync Jobs

Use Solid Queue jobs so webhook requests stay fast and retryable.

Suggested jobs:

- `Github::ProcessWebhookJob`
- `Github::SyncIssueJob`
- `Github::SyncPullRequestJob`
- `Github::BackfillRepositoryJob`

Issue sync behavior:

- `opened`: create or link a Fizzy card.
- `edited`: update linked card title and GitHub issue metadata.
- `assigned`: add mapped Fizzy assignees.
- `unassigned`: remove mapped Fizzy assignees.
- `labeled`: apply mapped Fizzy tags and possibly move workflow column.
- `unlabeled`: remove mapped Fizzy tags and possibly update workflow column.
- `closed`: close linked Fizzy card.
- `reopened`: reopen linked Fizzy card and move it to the configured open column.

Pull request sync behavior:

- `opened`: link PR to the card, usually by card number in branch/title/body.
- `ready_for_review`: move linked card to `In Review`.
- `synchronize`: keep PR metadata fresh.
- `closed` with `merged: true`: close linked card.
- `closed` with `merged: false`: keep card open and update PR metadata.

Comment sync behavior:

- Start with GitHub issue comments to Fizzy comments only if the team wants comments mirrored.
- Avoid noisy bidirectional comment sync in the first version.
- Always include a source link when mirroring comments.

## Phase 4: GitHub Settings UI

Add account-level settings for GitHub.

Suggested location:

- Account Settings -> Integrations -> GitHub

Initial settings:

- Webhook secret.
- Active repositories.
- Repository to Fizzy board mapping.
- GitHub login to Fizzy user mapping.
- Label to tag mapping.
- Label to column mapping.
- Whether GitHub issue close should close Fizzy cards.
- Whether PR merge should close Fizzy cards.

Manual setup is acceptable for the first native version. A full GitHub App installation flow can come later.

## Phase 5: Card UI

Show GitHub metadata on linked cards.

Developer-facing details:

- Repository name.
- GitHub issue number.
- GitHub issue state.
- Link to GitHub issue.
- Linked pull requests.
- Pull request merge/review state.
- Last synced time.

Non-developer-facing summary:

- `GitHub: aqui-core#42`
- `Status: PR in review`
- `Status: merged`

The GitHub panel should enhance cards without making Fizzy feel developer-only.

## Phase 6: Filters And Reports

Once GitHub data is stored in Fizzy, add filters and reports for developer workflows.

Suggested filters:

- Repository.
- GitHub issue state.
- Pull request state.
- Has pull request.
- Merged.
- GitHub assignee.
- `repo:*`, `type:*`, `priority:*`, and `phase:*` tags.

Suggested developer reports:

- Open GitHub-linked cards by repo.
- Issues in review.
- Merged this week.
- Bugs by priority.
- Stale developer cards.
- Cycle time from GitHub issue opened to Fizzy card closed.
- Throughput by repo.
- Workload by developer.

## Phase 7: Bridge Migration

When replacing the GHCR version with this local Fizzy version, migrate existing bridge state.

Migration steps:

1. Keep `aqui-fizzy-bridge` running against current production until native Fizzy is ready.
2. Export or read the bridge mapping database.
3. Import mappings into native `Github::Issue` records.
4. Match existing Fizzy cards by card number.
5. Fetch current issue and pull request metadata from the GitHub API.
6. Preserve existing tags, assignments, comments, and card history.
7. Run native sync in staging first.
8. Cut GitHub webhooks over from the bridge endpoint to the native Fizzy endpoint.
9. Disable bridge mutation paths.
10. Keep bridge read-only or archived until the cutover is proven stable.

Only one system should mutate Fizzy during cutover. Avoid running bridge mutation and native mutation against the same cards at the same time.

## Security And Reliability

- Verify GitHub webhook signatures before processing.
- Treat webhook delivery IDs as idempotency keys.
- Make all sync jobs idempotent.
- Do not trust GitHub usernames as Fizzy users without an explicit `Github::UserLink`.
- Store secrets encrypted if they are persisted.
- Log sync failures without leaking tokens or webhook secrets.
- Keep all data account-scoped.
- Respect board access when showing GitHub metadata.

## Recommended First Implementation

Build the smallest native path that can replace the bridge for issue and PR tracking:

1. Add GitHub repository, issue, pull request, and user-link models.
2. Add GitHub webhook signature verification.
3. Add webhook receiver and async processing job.
4. Implement issue opened, edited, closed, and reopened sync.
5. Implement PR opened, ready-for-review, and merged sync.
6. Show GitHub issue and PR metadata on card pages.
7. Add manual repository and user mapping settings.
8. Add bridge mapping import task.
9. Test cutover in staging before replacing the GHCR deployment.

## Test Coverage

Add tests for:

- Valid GitHub signatures are accepted.
- Invalid GitHub signatures are rejected.
- Duplicate webhook deliveries are idempotent.
- Issue opened creates one card and one GitHub issue link.
- Issue edited updates linked metadata and card title.
- Issue closed closes the linked card.
- Issue reopened reopens the linked card.
- PR opened links to the correct card from branch/title/body references.
- PR ready for review moves the card to the review column.
- PR merged closes the linked card.
- GitHub assignees map only through explicit user links.
- Users cannot see GitHub metadata for inaccessible boards.
- Bridge mapping import links existing cards correctly.
