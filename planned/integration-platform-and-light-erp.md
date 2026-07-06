# Integration Platform And Light ERP Plan

## Context

Fizzy is currently a collaborative project management and issue tracking tool. As this local version replaces the GHCR-packaged production version, we can evolve Fizzy beyond basic boards and cards.

Existing and planned needs include:

- Native GitHub issue and pull request integration.
- Daily updates and KPI evaluation.
- MCP access for agents and approved clients.
- Hermes integration for AI-assisted operations.
- Discord integration for team communication.
- Reporting and accountability dashboards.

These should not be implemented as unrelated one-off features. Fizzy should grow a shared integration foundation that can support multiple providers and gradually move toward a light ERP for work, people accountability, operations, and reporting.

## Product Direction

Fizzy should become the system of record for operational work.

The direction is:

- Work tracking: boards, cards, columns, assignments, deadlines, priorities.
- Accountability: daily updates, KPIs, performance visibility, manager summaries.
- Integrations: GitHub, MCP, Hermes, Discord, and future providers.
- Reporting: team, user, board, project, and integration-level reporting.
- Light ERP: operational workflows, capacity, blockers, approvals, recurring work, and eventually client/project grouping.

Avoid positioning Fizzy as a heavy ERP too early. Internally, design toward light ERP capabilities. Externally, keep the language simple: work tracking, accountability, and operations.

## Guiding Principles

- Fizzy remains the source of truth for work and accountability.
- External systems enrich Fizzy, but should not own Fizzy's core state.
- Integrations should share common models for events, external links, credentials, and processing.
- Every integration must respect account scoping and board permissions.
- Every external event should be idempotent and auditable.
- Start with hardcoded behavior where necessary, but leave room for configurable automation later.
- Keep the first UI simple: settings, status, links, tables, and dashboards.

## Non-Goals For The First Platform Version

- A full ERP suite.
- A generic Zapier-style automation builder.
- Full two-way sync for every provider and every field.
- Complex approval chains.
- Payroll or HR-grade performance management.
- Direct database access for bots, agents, or external services.
- Provider-specific logic scattered throughout unrelated models and controllers.

## Target Architecture

External systems should enter Fizzy through a consistent flow:

```text
External Provider
-> Webhook/API/MCP Request
-> Integration Authentication
-> Integration Event
-> Async Processing Job
-> Fizzy Domain Change
-> Event/Notification/Report
```

Examples:

```text
GitHub issue opened
-> github.issue.opened integration event
-> create/link Fizzy card
-> notify assignee or update dashboard
```

```text
Discord message creates task
-> discord.message.created integration event
-> create Fizzy card
-> link card to Discord thread
```

```text
Hermes asks who missed daily updates
-> MCP read tool
-> Daily updates report
-> Hermes summary response
```

## Shared Models

### Integration

Represents a connected provider for an account.

Suggested fields:

- `account_id`
- `provider`
- `name`
- `enabled`
- `settings`
- `credentials`
- timestamps

Suggested providers:

- `github`
- `discord`
- `hermes`
- `mcp`
- future providers as needed

Notes:

- Credentials should be encrypted if persisted.
- Settings can start as JSON for provider-specific configuration.
- Provider-specific models can be added when JSON settings become insufficient.

### IntegrationEvent

Stores incoming external events before processing.

Suggested fields:

- `account_id`
- `integration_id`
- `provider`
- `external_id`
- `event_type`
- `payload`
- `received_at`
- `processed_at`
- `failed_at`
- `error_message`
- timestamps

Examples of event types:

- `github.issue.opened`
- `github.pull_request.merged`
- `discord.message.created`
- `hermes.daily_summary.requested`
- `mcp.tool.called`

Recommended indexes:

- Unique index on `[account_id, provider, external_id]` for idempotency.
- Index on `[account_id, provider, event_type]`.
- Index on `[account_id, processed_at]`.
- Index on `[account_id, failed_at]`.

### ExternalLink

Links Fizzy records to external objects.

Suggested fields:

- `account_id`
- `linkable_type`
- `linkable_id`
- `provider`
- `external_type`
- `external_id`
- `external_url`
- `metadata`
- timestamps

Examples:

- Card linked to GitHub issue.
- Card linked to GitHub pull request.
- Card linked to Discord thread.
- User linked to GitHub user.
- User linked to Discord user.
- Daily update linked to Hermes conversation or Discord message.

Provider-specific tables can still exist for rich data, but `ExternalLink` gives a common cross-provider relationship layer.

### AutomationRule

Do not build this immediately, but design toward it.

Possible future fields:

- `account_id`
- `name`
- `trigger`
- `conditions`
- `actions`
- `enabled`
- timestamps

Example future rules:

- When GitHub PR is merged, close linked card.
- When daily update is missing, notify manager.
- When Discord message uses a task command, create card.
- When Hermes detects a blocker, tag card as blocked.

Start with hardcoded service objects and jobs. Add configurable automation only after repeated patterns are clear.

## Provider Roadmap

## GitHub

Purpose:

- Developer issue tracking.
- Pull request visibility.
- Engineering KPI reports.
- Code-to-work traceability.

Initial capabilities:

- Sync GitHub issues to Fizzy cards.
- Link GitHub issues and pull requests to cards.
- Move cards when PRs enter review.
- Close cards when issues close or PRs merge.
- Map GitHub labels to Fizzy tags.
- Map GitHub users to Fizzy users.
- Show repo, issue, and PR metadata on cards.

Long-term capabilities:

- GitHub App installation flow.
- Repository settings in Fizzy.
- Branch naming and PR auto-linking.
- Engineering reports: PRs in review, merged work, stale PRs, bugs by repo.

Relationship to `aqui-fizzy-bridge`:

- The bridge exists because production currently runs an unmodifiable GHCR Fizzy image.
- Once this local Fizzy replaces GHCR production, native GitHub integration should take over mutation paths.
- The bridge can remain temporarily for migration, compatibility, or emergency fallback.

## MCP

Purpose:

- Let approved agents and tools read and update Fizzy safely.
- Support Hermes and other AI/operator clients.
- Provide structured access without direct database access.

Initial read tools:

- List boards.
- List cards.
- Get card details.
- List blockers.
- List overdue work.
- Get project report.
- Get daily update compliance.
- Get KPI dashboard summary.

Initial write tools:

- Create card.
- Comment on card.
- Update card fields.
- Assign card.
- Submit daily update.
- Mark blocker.

Security requirements:

- MCP access must authenticate with scoped tokens.
- Read and write scopes must be separate.
- Tools must respect account and board permissions.
- Raw user IDs should not be accepted from clients unless mapped through approved aliases.
- All MCP write actions should be attributable to a Fizzy user or integration identity.

Implementation options:

- Short term: keep MCP in `aqui-fizzy-bridge` if that is faster.
- Target: expose MCP from Fizzy itself or through an official Fizzy integration adapter.
- Avoid MCP clients connecting directly to the database.

## Hermes

Purpose:

- AI-assisted operational oversight.
- Manager summaries.
- Daily update reminders.
- KPI explanations.
- Work triage and blocker detection.

Hermes should use MCP or official Fizzy APIs.

Suggested Hermes capabilities:

- Ask who missed daily updates.
- Summarize team progress.
- Identify blockers.
- Generate daily manager summary.
- Remind users to submit updates.
- Create cards from approved instructions.
- Comment on cards with summaries or follow-ups.

Hermes should not:

- Bypass Fizzy authorization.
- Write directly to the database.
- Make irreversible workflow changes without explicit permission.
- Generate performance judgments without showing source data.

## Discord

Purpose:

- Team communication bridge.
- Reminders and lightweight actions where people already communicate.
- Optional task creation from messages.

Initial capabilities:

- Send daily update reminders to users.
- Send missing update summaries to manager channels.
- Send overdue work summaries.
- Link Discord users to Fizzy users.
- Link Discord threads/messages to Fizzy cards.

Later capabilities:

- Create Fizzy cards from Discord messages.
- Submit daily updates from Discord.
- Comment on Fizzy cards from linked Discord threads.
- Post card status changes to selected channels.

Discord should not become the source of truth. Fizzy should own tasks, reports, and KPI state.

## Daily Updates And KPIs

Purpose:

- Create accountability for daily planning.
- Automatically detect missing or late updates.
- Combine report compliance with actual task progress.

Relationship to integrations:

- Hermes can summarize daily update status.
- Discord can remind users and managers.
- MCP can expose daily update and KPI tools.
- GitHub-linked tasks can contribute to developer performance metrics.

KPIs should be explainable and source-backed. Avoid opaque scores.

## Light ERP Direction

Fizzy can gradually become a light ERP by adding operational modules around the existing work system.

Possible future modules:

- Workload and capacity planning.
- Recurring operational tasks.
- Approvals.
- Departments or teams.
- Clients or projects.
- Incident tracking.
- Asset or inventory tracking if needed later.
- Procurement or expense requests only if there is a clear need.

Recommended sequence:

1. Strengthen work tracking and accountability.
2. Add native integrations.
3. Add reporting and dashboards.
4. Add simple operational workflows.
5. Add ERP-like modules only when real usage demands them.

## Reporting Strategy

Reports should pull from Fizzy-owned data, not provider-local databases.

Core report categories:

- Work progress.
- Daily update compliance.
- User KPIs.
- Board/team health.
- GitHub engineering metrics.
- Integration activity and failures.
- Overdue and stale work.

Recommended approach:

- Start with live reports from current data.
- Add snapshot tables later for historical trend accuracy.
- Keep report calculations in plain Ruby objects.
- Keep provider-specific calculations behind provider modules.

## Security And Permissions

- Every integration belongs to an account.
- Every integration event is account-scoped.
- Every external link is account-scoped.
- Integration actions should run as either a mapped user or an explicit integration/system user.
- Board access must be respected when showing integration metadata.
- Secrets must not appear in logs, webhook delivery records, or error messages.
- Webhook signatures must be verified before processing.
- Idempotency keys must prevent duplicate processing.
- Failed events should be visible to admins for debugging.

## Operational Reliability

Requirements:

- Store incoming events before processing when possible.
- Process integration events asynchronously.
- Make jobs retryable and idempotent.
- Record processing failures.
- Provide an admin view for failed integration events.
- Add cleanup policies for old payloads if storage grows too much.

Suggested status values for integration events:

- `pending`
- `processed`
- `failed`
- `ignored`

## Recommended Roadmap

## Phase 1: Core Accountability

Build or complete:

- Daily updates.
- Missing/late update detection.
- KPI dashboard.
- Deadline and overdue reporting.
- Priority reporting.

Why first:

- This solves the immediate management problem.
- It gives integrations meaningful data to read and summarize.

## Phase 2: Native GitHub

Build:
- GitHub data model.
- GitHub webhook receiver.
- GitHub issue/PR sync jobs.
- Card GitHub metadata UI.
- Bridge migration/import task.

Why second:

- Developers need GitHub-connected work tracking.
- Existing bridge behavior provides a clear acceptance checklist.

## Phase 3: Shared Integration Foundation

Build:

- `Integration` model.
- `IntegrationEvent` model.
- `ExternalLink` model.
- Shared webhook processing conventions.
- Admin view for integration status and failures.

Why third:

- GitHub will reveal the patterns needed by Discord, Hermes, and future providers.
- Avoid over-abstracting before the first native provider is implemented.

## Phase 4: MCP And Hermes

Build:

- Native or official MCP endpoint.
- Read tools for boards, cards, blockers, reports, daily updates, and KPIs.
- Write tools for cards, comments, assignments, and daily updates.
- Hermes summaries and reminders through MCP or official APIs.

Why fourth:

- MCP and Hermes become much more valuable after KPI and GitHub data live inside Fizzy.

## Phase 5: Discord

Build:

- Discord integration settings.
- Discord user mapping.
- Reminder delivery.
- Manager summary delivery.
- Optional task creation from Discord messages.

Why fifth:

- Discord is best as a communication layer after Fizzy owns the workflow and accountability data.

## Phase 6: Light ERP Modules

Build only after usage validates the need:

- Capacity dashboard.
- Recurring tasks.
- Approvals.
- Departments/teams.
- Project/client grouping.
- Operational request workflows.

## Recommended First Implementation

Do not start by building the full platform abstraction. Start with immediate business value, but leave architecture room.

Recommended first sequence:

1. Implement daily updates and KPI evaluation.
2. Implement native GitHub models and webhook sync.
3. Extract shared `ExternalLink` behavior if GitHub links prove useful across cards and users.
4. Add `IntegrationEvent` once native GitHub webhook processing exists.
5. Add MCP tools for daily updates, KPIs, and GitHub-linked work.
6. Add Hermes workflows on top of MCP.
7. Add Discord reminders and summaries.

## Open Questions

- Should MCP live inside Fizzy, or remain in `aqui-fizzy-bridge` as an official adapter?
- Which users should be allowed to configure integrations?
- Should each provider have a dedicated system user for actions?
- Should Discord be used only for notifications, or also for creating/updating work?
- Should Hermes be allowed to write changes automatically, or only suggest actions for approval?
- Which light ERP module is most valuable after KPIs and GitHub: capacity, approvals, projects, or recurring tasks?
- How long should raw integration event payloads be retained?
- Should integration settings be account-wide only, or also board-specific?

## Related Plans

- `planned/github-integration.md`
- `planned/daily-updates-and-kpis.md`
- `docs/kpi-dashboards-and-reports.md`
