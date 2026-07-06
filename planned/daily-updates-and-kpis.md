# Daily Updates And KPI Evaluation Plan

## Problem

People were asked to update their daily plans, but the process is not being followed consistently. Management needs a way to automatically evaluate whether each person is keeping their daily report updated and whether their assigned work is progressing.

Fizzy already tracks cards, assignments, comments, deadlines, closures, activity events, notifications, users, boards, and recurring jobs. It does not yet have a formal daily report submission workflow or automatic per-user KPI evaluation.

## Goals

- Make daily plan/report updates a first-class workflow in Fizzy.
- Automatically detect who submitted, submitted late, or missed their daily update.
- Remind users before the daily report deadline.
- Notify managers when users miss daily updates.
- Evaluate performance from both report compliance and actual task progress.
- Give every user visibility into what is expected daily.
- Give managers a simple dashboard for accountability.
- Keep the system useful for non-developers and developers.

## Non-Goals For The First Version

- Payroll-grade performance scoring.
- Complex OKR management.
- AI-written performance reviews.
- Punitive automation that closes or moves work automatically.
- Full HR workflows.
- Replacing normal manager judgment.

## Core Product Idea

Add a daily update/check-in system.

Every active user should submit one daily update per work day. The update records what they completed, what they plan to do, and what is blocked.

Fizzy then combines daily update compliance with task activity to produce simple KPI indicators.

Separate two concepts:

- Daily report compliance: did the user submit their update on time?
- Work performance: did assigned work move forward?

This matters because someone can submit daily reports without completing work, and someone can complete work but forget to report. Fizzy should make both visible.

## Phase 1: Daily Update Submission

Add a `DailyUpdate` model.

Suggested fields:

- `account_id`
- `user_id`
- `work_on`
- `completed_yesterday`
- `planned_today`
- `blockers`
- `submitted_at`
- `status`
- timestamps

Suggested statuses:

- `draft`
- `submitted`
- `late`
- `missing`

Rules:

- One daily update per active user per work day.
- Users can save a draft before submitting.
- Users can submit after the cutoff, but the update is marked `late`.
- Missing updates are created or marked automatically after the cutoff.
- Weekends and holidays should be configurable later. Start with weekdays only if needed.

Suggested model namespace:

- `DailyUpdate`
- Optional later: `DailyUpdate::Reminder`, `DailyUpdate::KpiSnapshot`

## Phase 2: User Workflow

Add a daily update page.

Suggested route:

```ruby
resource :daily_update, only: [ :show, :update ]
resources :daily_updates, only: [ :index, :show ]
```

User-facing fields:

- What did you complete yesterday?
- What are you working on today?
- What is blocked?
- Which Fizzy cards are related?

Suggested behavior:

- If the user has no update for today, show a blank form.
- If the user has a draft, reopen the draft.
- If the user submitted today, show their submitted update and allow edits until the cutoff.
- After cutoff, allow edits but keep the report marked late if it was not submitted on time.

Optional card linking:

- Allow selecting related assigned cards.
- Start without card linking if the first version needs to stay small.
- KPI calculations can still use assignments, closures, deadlines, comments, and events.

## Phase 3: Automatic Reminders And Missing Detection

Use Solid Queue recurring jobs.

Suggested recurring entries:

- Morning reminder: remind active users to submit the daily update.
- Pre-cutoff reminder: remind users who have not submitted yet.
- Cutoff evaluation: mark missing updates and notify managers.

Example schedule:

- 09:00: daily update reminder.
- 16:30: missing update warning.
- 17:00: mark missing updates.
- 17:05: manager summary notification.

Suggested jobs/services:

- `DailyUpdate.remind_due`
- `DailyUpdate.remind_missing`
- `DailyUpdate.mark_missing_due`
- `DailyUpdate.notify_managers_of_missing_updates`

Configuration needed:

- Daily update cutoff time.
- Reminder times.
- Which roles receive manager summaries.
- Whether weekends are excluded.

Start with account-level defaults. Board-level or team-level settings can come later.

## Phase 4: KPI Evaluation

Add a per-user daily KPI calculation.

Suggested object:

- `Kpi::DailyUserScore`

Inputs:

- User.
- Date.
- Account.
- Assigned cards.
- Card closures.
- Deadlines.
- Comments/events.
- Daily update status.

Initial metrics:

- Daily update submitted.
- Daily update submitted late.
- Daily update missing.
- Assigned open cards.
- Assigned cards closed today.
- Overdue assigned cards.
- Due-today assigned cards.
- Stale assigned cards with no recent activity.
- Cards with blockers.
- User comments or activity today.

Suggested scoring for the first version:

- Daily update compliance: 40%.
- Task completion/progress: 30%.
- Deadline health: 20%.
- Communication/activity: 10%.

Example scoring:

- Submitted daily update on time: +40.
- Submitted daily update late: +25.
- Missing daily update: +0.
- Closed assigned cards or moved work forward: up to +30.
- No overdue assigned cards: up to +20.
- Commented or updated active work: up to +10.

Keep scores explainable. Every score should show the reasons behind it.

Example explanation:

- Daily update missing: -40.
- 2 overdue assigned cards: -15.
- 0 cards closed today: -10.
- No activity today: -10.

## Phase 5: Manager Dashboard

Add a dashboard for owners/admins.

Suggested route:

```ruby
namespace :reports do
  resource :daily_performance, only: :show
end
```

Dashboard sections:

- Submitted today.
- Missing today.
- Late today.
- Users with overdue assigned work.
- Users with no activity today.
- Blocked users.
- Cards completed today.
- Average KPI score today.

Per-user row:

- User name.
- Daily update status.
- Assigned open cards.
- Overdue cards.
- Cards closed today.
- Last activity.
- KPI score.
- Link to detail.

Per-user detail:

- Today's daily update.
- Assigned cards.
- Closed cards for the day.
- Overdue cards.
- Blockers.
- Activity timeline.
- KPI explanation.

## Phase 6: User Visibility

Users should see their own status before managers need to chase them.

Add visible cues:

- Header or home page reminder when today's update is missing.
- Badge or notice when the update is due soon.
- Personal daily KPI summary after submission.
- List of overdue assigned cards.
- List of assigned cards with no recent activity.

Tone should be direct but not hostile.

Example copy:

- `Your daily update is due today by 17:00.`
- `Your daily update is missing.`
- `You have 2 overdue assigned cards.`
- `Your update was submitted late.`

## Phase 7: Weekly And Monthly Reports

After daily tracking is stable, add trend reports.

Suggested weekly metrics:

- Daily update compliance rate.
- Late update count.
- Missing update count.
- Cards completed.
- Average overdue card count.
- Stale card count.
- Average KPI score.
- Most common blockers.

Suggested monthly metrics:

- Compliance trend.
- Completion trend.
- Overdue trend.
- Stale work trend.
- Performance by board/team.
- Performance by user.

These can connect to the broader KPI dashboard and reporting work.

## Phase 8: Optional Daily Plan Card Automation

Only add this if users need more structure.

Option:

- Automatically create a daily planning card for each user.
- The user checks off daily planning/reporting steps.
- The daily update form can be linked to that card.

Avoid this initially unless a card-based workflow is preferred. A dedicated `DailyUpdate` model is cleaner for compliance and reporting.

## Authorization

Recommended permissions:

- Users can view and edit their own daily updates.
- Users can view their own KPI summary.
- Owners/admins can view all daily updates and KPI dashboards.
- Managers/team leads can view users they manage if team hierarchy is added later.
- System users should not be evaluated.
- Inactive users should not be evaluated.

## Notifications

Notification types to add:

- Daily update due.
- Daily update still missing.
- Daily update marked missing.
- Manager summary of missing updates.

Notification recipients:

- Users receive their own reminders.
- Owners/admins receive missing update summaries.
- Optional later: board owners or team leads receive summaries for their teams.

## Data Retention

Daily updates are management records and should be retained unless account data is deleted.

Consider export/import support later:

- Include daily updates in account exports.
- Include KPI snapshots if persisted.

For v1, KPI scores can be calculated live. Persist snapshots later if historical reporting needs stable past scores.

## Recommended First Implementation

Build a minimal but useful version:

1. Add `DailyUpdate` model and migration.
2. Add one daily update per active user per work day.
3. Add a simple daily update form.
4. Add submitted, late, and missing statuses.
5. Add recurring reminder and cutoff jobs.
6. Add owner/admin dashboard for today's submitted, late, and missing users.
7. Add simple KPI calculation object.
8. Show KPI score explanations.
9. Add tests for submission, late submission, missing detection, reminders, and KPI scoring.

## Implementation Notes

- Reuse existing account scoping patterns.
- Reuse existing notification infrastructure where possible.
- Reuse recurring jobs in `config/recurring.yml`.
- Keep KPI calculation in plain Ruby objects rather than embedding it in controllers.
- Keep the first UI simple: forms, tables, and status badges.
- Do not add a charting dependency for the first version.

## Test Coverage

Add tests for:

- One daily update per user per date.
- Active users are evaluated.
- Inactive users are ignored.
- System users are ignored.
- On-time submission is marked submitted.
- Late submission is marked late.
- Missing updates are marked after cutoff.
- Users are reminded before cutoff.
- Users are not reminded after submitting.
- Owners/admins receive missing update summaries.
- KPI score includes daily update compliance.
- KPI score includes overdue assigned cards.
- KPI score includes closed assigned cards.
- KPI score includes user activity.
- Users cannot edit another user's daily update.
- Non-admin users cannot see the manager dashboard.

## Open Questions

- What is the daily update cutoff time?
- Should weekends be excluded?
- Should holidays be configurable?
- Who counts as a manager for summary notifications?
- Should daily updates be mandatory for all active users or only selected roles?
- Should users link specific cards in their daily update?
- Should comments be required when marking blockers?
- Should KPI scores be visible to all users or only managers?
