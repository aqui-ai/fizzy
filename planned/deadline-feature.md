# Deadline Feature Plan

## Current Behavior

- Cards already have a `due_on` date column.
- Users can set and clear a deadline on cards.
- Card detail pages and board previews show the deadline.
- Past deadlines render as overdue.
- Card JSON and export JSON include `due_on`.

## Goals

- Make deadline cards easy to find.
- Notify the right people when cards become due or overdue.
- Avoid noisy repeated notifications.
- Avoid surprising automatic card movement unless explicitly added later.

## Phase 1: Deadline Awareness

Status: Implemented.

Add card scopes:

- `with_deadline`: cards where `due_on` is present.
- `without_deadline`: cards where `due_on` is blank.
- `due_today`: cards where `due_on` is today.
- `overdue`: cards where `due_on` is before today.
- `due_soon`: cards due in the next 7 days.

Add filter options:

- Overdue
- Due today
- Due this week
- No deadline

Add sorting options:

- Deadline soonest first
- Deadline latest first

## Phase 2: Notifications

Status: Implemented.

Recommended behavior:

- Notify card assignees when a card becomes due.
- Notify card assignees when a card becomes overdue.
- If a card has no assignees, notify watchers instead.
- Send each notification only once per card/deadline state.
- Ignore closed and postponed cards.

Avoid for now:

- Daily repeated reminders.
- Automatic card movement.
- Escalation rules.

Suggested persistence:

- Add `due_notified_at` to `cards`.
- Add `overdue_notified_at` to `cards`.

Suggested background entry point:

- `Card.notify_deadlines_due(as_of: Date.current)`

Suggested recurring schedule:

- Run hourly or daily.
- Hourly is better if users expect due-today notices during the day.
- Daily is simpler and less noisy.

## Phase 3: UX Polish

Status: Partially implemented.

Implemented:

- Deadline status variants for due today, overdue, due soon, and future deadlines.
- Quick deadline actions for today, tomorrow, next week, and clear deadline.
- Overdue counts on active board columns and the Maybe column.

Add deadline status variants:

- Due today
- Overdue
- Upcoming

Add quick deadline actions:

- Today
- Tomorrow
- Next week
- Clear deadline

Add overview counts:

- Board overdue count.
- Column overdue count. Implemented for active workflow columns and Maybe.
- Optional account-level overdue count.

## Phase 4: Optional Automation

Only add these if users explicitly want workflow automation:

- Auto-move overdue cards to a configured column.
- Escalate overdue cards after a configured number of days.
- Daily deadline digest.
- Board-level deadline notification policy.

## Recommended First Implementation

Build Phase 1 plus one-time notifications from Phase 2:

1. Add deadline scopes to `Card`.
2. Add filter options for overdue, due today, due this week, and no deadline.
3. Add `due_notified_at` and `overdue_notified_at` migration.
4. Add deadline notification method.
5. Add recurring schedule entry.
6. Add tests for scopes, filtering, and notification deduplication.

## Test Coverage

Add tests for:

- Overdue scope excludes cards due today and future cards.
- Due-today scope matches today only.
- Due-soon scope matches the next 7 days.
- Closed cards are ignored by deadline notifications.
- Postponed cards are ignored by deadline notifications.
- Assignees receive due notifications.
- Watchers receive notifications when there are no assignees.
- Duplicate due notifications are not sent.
- Duplicate overdue notifications are not sent.
