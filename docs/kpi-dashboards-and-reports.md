# KPI Dashboards And Reports Plan

## Goal

Add KPI dashboards and reports to Fizzy in two phases: first a live operational dashboard built from existing account-scoped data, then historical trend reports backed by durable daily snapshots.

## Phase 1: Operational Dashboard

Build a first dashboard without new persistence. Query the existing cards, closures, assignments, tags, columns, boards, users, and events tables through the current account and access-control model.

### Scope

- Add an authenticated Reports area.
- Reuse existing filter dimensions where possible: boards, assignees, creators, tags, columns, deadlines, creation window, closure window, closed-by, open/closed/not-now.
- Derive records from `Current.user.accessible_cards`, not directly from account-wide card tables.
- Show current-state and selected-window metrics.

### Initial Metrics

- Open cards
- Done cards
- Not now cards
- Overdue cards
- Due this week
- Unassigned cards
- Cards created in selected window
- Cards closed in selected window
- Average age of open cards
- Average time to close
- Throughput by board, assignee, creator, and tag

### Implementation Shape

- Route: add a Reports route, likely `resource :reports, only: :show` or `resources :reports, only: :index`.
- Controller: `ReportsController`.
- View: `app/views/reports/`.
- Models: add plain query objects under `app/models/report/`.
- Suggested objects:
  - `Report::Dashboard`
  - `Report::CardMetrics`
  - `Report::Throughput`
  - `Report::Aging`

### UI

- Start with KPI cards and breakdown tables.
- Prefer existing Rails/Hotwire patterns and CSS conventions.
- Avoid introducing a charting dependency for v1 unless the product need is clear.
- Use simple tables or CSS-only bars for breakdowns.

### Tests

- Unit tests for metric calculations.
- Controller tests for authentication and account scoping.
- Tests proving inaccessible board data is excluded.
- A light system/integration test for rendering and filtering.

## Phase 2: Historical Trend Reports

Add durable snapshots once Phase 1 metrics are validated. Current normalized data can answer many live questions, but it cannot reliably reconstruct every historical board, assignee, tag, or column state.

### Scope

- Add daily account and board snapshots.
- Compute snapshots from the same metric query objects where possible.
- Use Solid Queue recurring jobs for daily snapshot creation.
- Build trend views from snapshots, not expensive live historical queries.

### Suggested Schema

`report_snapshots`:

- `account_id`
- `board_id`, nullable for account-wide snapshots
- `snapshot_on`
- `metrics` JSON
- timestamps

Indexes:

- Unique index on `[account_id, board_id, snapshot_on]`.
- Index on `[account_id, snapshot_on]`.

### Historical Reports

- Created vs closed over time
- Open-card trend
- Overdue trend
- Not-now trend
- Average time-to-close trend
- Board throughput trend
- User workload trend

### Backfill

- Backfill only metrics that can be reconstructed reliably from existing data.
- Treat tag, assignee, and column historical breakdowns as forward-looking unless event coverage is proven complete.

## Access And Authorization

- Reports must respect board access.
- Members should not see aggregate data from private boards they cannot access.
- Decide whether Reports are available to all members or restricted to admins/owners before implementation.

## Open Product Decisions

- Should Reports be top-level navigation, account settings, or board-level only?
- Should reports be account-wide, board-level, or both in v1?
- Should v1 include CSV export?
- Which date ranges should be preset: last 7 days, 30 days, quarter, year?
- Are trend charts required immediately, or are tables enough for the first release?

## Recommended Rollout

1. Ship Phase 1 live operational metrics using existing data and filters.
2. Validate KPI definitions with real usage.
3. Add snapshot schema and recurring jobs.
4. Build historical trend reports from snapshots.
5. Add exports and richer visualizations after report usage patterns are clear.
