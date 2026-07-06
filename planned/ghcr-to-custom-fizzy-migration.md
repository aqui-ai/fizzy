# GHCR To Custom Fizzy Migration Plan

## Context

Production currently runs the GHCR-packaged Fizzy image. That deployment could not be modified directly, which is why `aqui-fizzy-bridge` was created to integrate GitHub and other workflows externally.

This local Fizzy repo is intended to replace the GHCR version with a custom build that can be changed, extended, and integrated natively.

The migration must avoid:

- Data loss.
- User recreation.
- Account recreation.
- Card number changes.
- Broken GitHub bridge mappings.
- Broken uploads or attachments.
- Broken login/session/token behavior where avoidable.

## Core Principle

Do an in-place application replacement, not a fresh installation.

The new custom Fizzy image should run against the existing production data volume and environment configuration after a full backup and staging rehearsal.

Current GHCR Docker deployments persist Fizzy data under:

```text
/rails/storage
```

That storage may include:

- Production SQLite database, commonly `production.sqlite3`.
- Active Storage files when using local disk storage.
- Generated exports/imports and other persisted runtime files.

To avoid user recreation, preserve the existing database and storage files.

## What Must Be Preserved

Preserve these exactly where possible:

- Production database.
- Active Storage files.
- `SECRET_KEY_BASE`.
- `BASE_URL`.
- SMTP settings.
- VAPID keys.
- `MULTI_TENANT` setting.
- `ACTIVE_STORAGE_SERVICE` and storage settings.
- Account IDs.
- `accounts.external_account_id` values.
- User IDs.
- Identity IDs.
- Board IDs.
- Card IDs.
- Card numbers.
- Access tokens.
- Existing bridge mapping database.

Do not seed or create a new account during migration.

## Why Account And Card Identity Matter

Fizzy URLs are account-prefixed using the account external ID.

Changing `accounts.external_account_id` would change account URLs and break existing links.

Changing card numbers would break:

- Existing Fizzy links.
- GitHub references.
- Bridge mappings.
- Any branch or PR references that use card numbers.

Changing user IDs would break:

- Assignments.
- Comments.
- Closures.
- Notifications.
- Bridge user mappings.
- Access tokens or attribution flows.

## Migration Strategy

Use this target flow:

```text
Before:
GHCR Fizzy image + existing /rails/storage volume + existing env

After:
Custom Fizzy image + same /rails/storage volume + same env
```

The image changes. The persistent data does not get recreated.

## Phase 1: Production Inventory

Before making changes, record the current production state.

Collect:

- GHCR image tag or digest.
- Docker Compose or deployment config.
- Container names.
- Volume names.
- Host paths if bind mounts are used.
- Environment variables.
- Current public URL.
- Current account slug.
- Current bridge deployment config.
- Current bridge mapping database path or Docker volume.

Record counts:

- Accounts.
- Users.
- Identities.
- Boards.
- Cards.
- Comments.
- Attachments.
- Webhooks.
- Access tokens.

Suggested Rails console checks on the current production data:

```ruby
Account.count
User.count
Identity.count
Board.count
Card.count
Comment.count
ActiveStorage::Attachment.count
Webhook.count
```

Also record:

```ruby
Account.pluck(:id, :external_account_id, :name)
Account.first.slug
Card.maximum(:number)
```

## Phase 2: Backups

Take backups before any migration attempt.

Required backups:

- Fizzy production storage volume.
- Fizzy production database file if SQLite is used.
- Active Storage files.
- Bridge mapping database.
- Production environment variable file or secret inventory.
- Current Docker Compose or deployment config.

The Fizzy account export feature is useful, but it should not be the primary rollback mechanism. For this migration, the primary backup is the full production storage volume.

Backup rules:

- Back up while the app is stopped or in a write-quiet window if possible.
- Verify the backup can be restored.
- Keep the pre-migration backup untouched until the new deployment is proven stable.
- Keep the old GHCR image digest so rollback can use the exact old version.

## Phase 3: Staging Rehearsal

Never run the first migration attempt directly on production.

Create a staging environment using copied production data:

```text
production storage backup -> staging storage volume
production env copy -> staging env
custom Fizzy image -> staging service
```

Staging validation:

- App boots.
- Login works.
- Existing users appear.
- Existing account slug works.
- Boards load.
- Cards load.
- Comments load.
- Attachments render.
- Notifications page loads.
- Search works or can be rebuilt.
- Background jobs boot.
- Webhooks do not crash.
- API tokens still work if token secrets are preserved.
- Bridge can still call Fizzy if needed.

Run migrations on staging first.

After migrations, compare counts with the inventory from Phase 1.

Validate that these did not change unexpectedly:

- Account IDs.
- Account external IDs.
- User IDs.
- Board IDs.
- Card IDs.
- Card numbers.

## Phase 4: Schema Compatibility Review

Before production cutover, review all migrations added in the custom Fizzy version.

Classify migrations:

- Additive and safe: new tables, nullable columns, indexes.
- Risky: column renames, deletes, type changes, data rewrites.
- Irreversible: destructive changes that prevent rollback to GHCR.

Prefer additive migrations for the first replacement deploy.

Avoid destructive schema changes until after the custom version has been running successfully.

If a migration is irreversible, rollback requires restoring the full pre-migration backup.

## Phase 5: Bridge Cutover Planning

`aqui-fizzy-bridge` currently depends on existing Fizzy card numbers and user mappings.

Before cutover:

- Back up the bridge mapping database.
- Record bridge environment variables.
- Pause bridge mutation paths during final cutover.
- Confirm whether the bridge will point to the new custom Fizzy after cutover.

During migration:

- Do not allow both old GHCR Fizzy and new custom Fizzy to receive writes.
- Do not run bridge mutation paths while the database is being backed up or migrated.
- Do not enable native GitHub sync and bridge GitHub sync mutations at the same time.

After cutover:

- Restart bridge only if still needed.
- Verify that mapped GitHub issues still point to the same Fizzy card numbers.
- Later, import bridge mappings into native GitHub integration tables.

## Phase 6: Final Production Cutover

Use a maintenance window.

Recommended cutover sequence:

1. Announce maintenance window.
2. Pause `aqui-fizzy-bridge` mutation processing.
3. Stop background jobs if they run separately.
4. Stop the GHCR Fizzy container.
5. Take a final production storage backup.
6. Take a final bridge mapping backup.
7. Start the custom Fizzy container with the same production storage volume.
8. Use the same production environment values.
9. Run database migrations.
10. Start web and job processes.
11. Smoke test the app.
12. Restart bridge only if needed.
13. Monitor logs and jobs.
14. End maintenance window only after validation passes.

## Phase 7: Post-Cutover Validation

Immediately validate:

- Public URL loads.
- Existing account slug loads.
- Existing users can sign in.
- Boards load.
- Cards load.
- Card detail pages load.
- Comments display.
- Attachments display and download.
- Creating a test card works.
- Commenting works.
- Assignment works.
- Closing/reopening works.
- Notifications work.
- Background jobs process.
- Webhooks process.
- Bridge smoke test passes if bridge remains active.

Run count comparisons again:

```ruby
Account.count
User.count
Identity.count
Board.count
Card.count
Comment.count
ActiveStorage::Attachment.count
Webhook.count
Account.pluck(:id, :external_account_id, :name)
Card.maximum(:number)
```

Expected result:

- Counts should match pre-cutover, except for explicitly expected records created during smoke testing.
- Account slug should match pre-cutover.
- Card numbers should continue from the old maximum.

## Phase 8: Rollback Plan

Rollback must remain simple.

Rollback sequence:

1. Stop custom Fizzy.
2. Stop bridge if it was restarted.
3. Restore the pre-cutover storage volume backup if migrations or writes occurred.
4. Start the old GHCR image using the old environment configuration.
5. Restart bridge with the old configuration.
6. Validate login, boards, cards, attachments, and bridge sync.

Important:

- Do not run the old GHCR image against a database that has been changed by irreversible custom migrations.
- If custom migrations ran, rollback should use the full pre-cutover backup.
- Keep the old GHCR image digest and old env values until rollback is no longer needed.

## Phase 9: After Stable Cutover

After the custom Fizzy version has run successfully:

- Keep backups for the agreed retention period.
- Document the new deployment process.
- Update bridge configuration if bridge remains temporarily active.
- Plan bridge mapping import into native GitHub tables.
- Gradually disable bridge mutation paths as native integrations replace them.
- Add migration-specific monitoring or admin checks if needed.

## Do Not Do These

- Do not create a fresh Fizzy account for production migration.
- Do not manually recreate users.
- Do not rely only on account export/import for this cutover.
- Do not change `SECRET_KEY_BASE` during migration.
- Do not change `accounts.external_account_id`.
- Do not reset `accounts.cards_count`.
- Do not run old and new Fizzy containers writing to the same data at the same time.
- Do not run bridge mutation and native GitHub mutation at the same time.
- Do not run first-time migrations directly on production without staging rehearsal.

## Recommended First Migration Test

Before touching production, perform this rehearsal:

1. Copy the production Fizzy storage volume to a staging volume.
2. Copy production env values to staging, changing only public URL-related values as needed.
3. Boot the custom Fizzy image against the staging volume.
4. Run migrations.
5. Compare counts and IDs.
6. Log in as an existing user.
7. Open existing boards/cards/comments/attachments.
8. Create a test card.
9. Run a bridge smoke test against staging if needed.
10. Document every command and result for the production runbook.

## Open Questions

- What is the exact production Docker volume name for `/rails/storage`?
- Is production using SQLite or MySQL right now?
- Is Active Storage local disk or S3?
- What is the exact GHCR image digest currently running?
- Where is the bridge mapping database stored?
- Is the bridge running in the same Docker Compose project or separately?
- What is the acceptable maintenance window?
- Who will verify login and business-critical workflows after cutover?
- Which migrations will exist in the first custom Fizzy deploy?
- Should bridge remain active immediately after cutover, or should native integration replace it at the same time?

## Success Criteria

Migration is successful when:

- Existing users can log in without recreation.
- Existing account URL still works.
- Existing boards, cards, comments, tags, assignments, closures, and files are present.
- Existing card numbers are preserved.
- Existing GitHub bridge mappings still reference valid Fizzy cards.
- Background jobs run successfully.
- No unexpected data count changes are found.
- Rollback backup remains available until the deployment is proven stable.
