# Priority Feature Plan

## Purpose

Priority should help people quickly identify which cards need attention first, without changing workflow status or deadline behavior.

Priority is separate from:

- Card publication status: drafted or published.
- Workflow position: Maybe, column, Done, or Not Now.
- Deadline state: due today, due soon, or overdue.

## Recommended Priority Levels

Use fixed priority levels:

- `none` default
- `low`
- `medium`
- `high`
- `urgent`

User-facing labels:

- No priority
- Low
- Medium
- High
- Urgent

## Phase 1: Basic Priority

Status: Implemented.

Add persistence:

- Add `priority` to `cards`.
- Default to `none`.
- Store as a string for readability and simple export/import behavior.

Add model behavior:

- Add priority enum-style helpers/scopes to `Card`.
- Add ordered priority constants.
- Add validation so only known priority values are accepted.

Add controller/API support:

- Permit `priority` in card create/update params.
- Include `priority` in card JSON responses.
- Include `priority` in card export JSON.

Add UI:

- Add priority picker to card draft/edit forms.
- Show priority badge on card detail pages.
- Show priority badge on card previews.

Add tests:

- Card accepts valid priorities.
- Card rejects invalid priorities.
- Create/update supports priority.
- JSON includes priority.
- Export JSON includes priority.
- Priority badges render in card views.

## Phase 2: Filtering And Sorting

Add priority filters:

- Any priority
- No priority
- Low
- Medium
- High
- Urgent

Add priority sorting:

- Highest priority first.
- Lowest priority first.

Add tests:

- Priority filters return expected cards.
- Priority sorting orders cards correctly.
- Filter params and summaries include priority.
- Saved filters preserve priority settings.

## Phase 3: UX Polish

Add visual treatment:

- No priority: hidden or muted.
- Low: calm/muted.
- Medium: neutral.
- High: strong attention color.
- Urgent: strongest attention color.

Possible extras:

- Quick priority actions in the card editor.
- Board/column counts for urgent cards.
- Keyboard shortcut or command menu action for changing priority.

## Deferred Ideas

Do not implement initially unless there is a clear need:

- Priority notifications.
- Automatic card movement based on priority.
- Per-board custom priority labels.
- Priority change history.
- Priority-specific permission rules.

## Recommended First Implementation

Start with Phase 1 only:

1. Add `priority` column to cards.
2. Add model validation/helpers/scopes.
3. Permit priority in controller params.
4. Include priority in JSON/export.
5. Add a priority picker to card draft/edit forms.
6. Show priority badges on card detail and previews.
7. Add focused tests.

After Phase 1 is stable, add filtering and sorting in Phase 2.
