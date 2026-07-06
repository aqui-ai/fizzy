# Board-Specific Tags Plan

## Problem

Fizzy currently uses account-level tags. This means tags from different boards are mixed together in the same tag list.

For project control, each board should have its own tag set so that QLT DUAT, THL DUAT, environmental licensing, community relations, and government relations do not share one confusing tag pool.

Concrete example:

- If a user is working on the IT board, they should not see HR tags.
- If a user is working on the HR board, they should not see IT tags.
- Tags should feel local to the board where the work is happening.

## Current Behavior

- Tags belong to an account.
- Cards are tagged through taggings.
- Boards only see tags indirectly through their cards.
- The card tag picker shows tags from the whole account.
- Adding a tag to a card creates or finds the tag under the account.

This causes users to see and reuse tags from unrelated boards.

## Objective

Make tags board-specific.

Each board should have its own tags, even when the tag names are the same.

Example:

- QLT DUAT can have `blocked`.
- THL DUAT can also have `blocked`.
- These should be separate tags attached to separate boards.

Primary user-facing requirement:

- The tag picker on a card must only show tags that belong to that card's board.
- Board filters should not show unrelated board tags unless the user is in a global cross-board view.
- Global tag views must show board context so users do not confuse tags with the same name.

## Short-Term Planning Option

Before the full database migration, there is a smaller possible improvement:

- Keep tags account-level for now.
- Change the card tag picker to show only tags already used by cards on the same board.
- Allow creating new tags from the current card as today.

This would immediately reduce confusion, because IT users would not see HR tags unless those tags are already used on IT cards.

However, this is only a UI-level fix. The tags would still technically be account-level, so this should be treated as temporary or partial.

Recommended use of this option:

- Use it only if we need a fast fix before true board-specific tags are implemented.
- Do not treat it as the final solution.

## Recommended Approach

Implement true board-specific tags instead of only hiding unrelated tags in the UI.

This is the cleanest long-term solution and best supports CEO-level project control.

## Planned Data Model Changes

- Add `board_id` to `tags`.
- Make `Tag` belong to `Board`.
- Keep `Tag` belonging to `Account` for tenant isolation.
- Add a unique index on `account_id`, `board_id`, and `title`.
- Update `Board` so it has direct tags.
- Keep `Card` using taggings.

## Migration Plan

Existing account-level tags must be split by board.

For each existing tag:

1. Find all boards with cards using that tag.
2. Create one replacement tag per board using the same title.
3. Move each tagging to the replacement tag for that card's board.
4. Remove old unused account-level tags after reassignment.

Example before migration:

- Account tag: `blocked`
- Used on cards from QLT DUAT and THL DUAT.

Example after migration:

- QLT DUAT tag: `blocked`
- THL DUAT tag: `blocked`

## Application Changes

### Card Tagging

- When adding a tag to a card, use `card.board.tags` instead of `account.tags`.
- The tag picker should only show tags from the card's board.
- Creating a new tag from a card should create it under that card's board.

### Filters

- Board-level filters should show only tags relevant to the selected board.
- Global filters need board context because the same tag title may exist on multiple boards.
- Saved filters using old tag IDs may need migration.

### Menus

- Global tag menus should either group tags by board or show the board name beside each tag.
- Avoid showing a flat account-wide tag list without board context.

### Special Tools And Integrations

Update code that currently creates account-level tags.

Known examples:

- Blocker tool should create or use the `blocked` tag from the card's board.
- GitHub issue sync should create labels as tags under the issue card's board.
- Any API endpoint that creates tags should be board-aware.

## Reporting Tag Structure

Recommended starting tags for each management board:

- `blocked`
- `decision-required`
- `quotation`
- `payment`
- `evidence-attached`
- `evidence-missing`
- `deadline-risk`
- `waiting-external-party`
- `management-review`

These tag names may repeat across boards, but each board owns its own copy.

## Testing Plan

Add or update tests to confirm:

- Same tag title can exist on different boards.
- Same tag title cannot be duplicated inside the same board.
- A card only sees tags from its own board.
- Adding a tag creates it under the card's board.
- Filters still work after tags become board-specific.
- Existing account-level tags migrate correctly.
- Blocker tools use board-specific tags.
- GitHub sync uses board-specific tags.
- No cross-account or cross-board tag leakage occurs.

## Risks

- Existing saved filters may reference old tag IDs.
- Global tag views may become confusing if board context is not shown.
- Migration must handle tags used across multiple boards.
- Integrations that assume account-level tags must be updated.

## Implementation Phases

### Phase 1: Data Model

- Add `board_id` to tags.
- Update model relationships and validations.
- Add indexes.

### Phase 2: Migration

- Split existing tags by board.
- Reassign taggings.
- Clean unused old tags.

### Phase 3: Card Tagging UI

- Restrict tag picker to the current board.
- Create tags under the current board.

### Phase 4: Filters And Menus

- Update filter tag lists.
- Add board context where needed.

### Phase 5: Tools And Integrations

- Update blocker tools.
- Update GitHub sync.
- Update APIs or MCP tools that create tags.

### Phase 6: Tests And Verification

- Run unit tests for tags, taggings, filters, and integrations.
- Run relevant system tests for card tagging.

## Decision

Recommended decision: move to true board-specific tags.

This is better than only hiding unrelated tags because it prevents tag mixing at the data level and supports clean project control for each board.
