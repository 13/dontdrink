# Supabase Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** planned, not started. Written 2026-09-12 against `main` at v1.3.0.

**Goal:** Let two devices share one history. Logged days and user-created modes replicate through a Supabase instance the user configures; everything keeps working offline, and an install that has not been configured contacts nothing new.

**Architecture:** Local-first. Every write still commits to SQLite first and is marked dirty. A transport-agnostic `SyncEngine` merges local and remote rows by last-write-wins; a `SupabaseSyncTransport` is the only part that knows about the network, so the merge rules are unit-testable against a fake with no server. Push is a single Postgres function so a stale device cannot overwrite newer data.

## Decisions already taken

These were settled with the user on 2026-09-12; do not re-open them without asking.

| Question | Decision |
| --- | --- |
| Instance | **Self-hosted, configured in Settings.** Server URL and anon key are entered by the user and stored on-device. Nothing is baked into the APK. |
| Auth | **Email + password** (Supabase email auth). No magic links, so no deep-link plumbing. |
| Scope | **Entries + custom modes.** Theme, language, reminder time and the enabled/active mode selection stay per-device. |
| Trigger | **Launch, resume, and after a local write (debounced), plus a manual "Sync now".** No realtime websocket. |
| Conflicts | Last-write-wins on the client `updated_at`; an exact tie goes to the remote row. A tombstone competes on its timestamp like any other row. |

## Global Constraints

- **Flutter runs through `fvm`**: `fvm flutter analyze`, `fvm flutter test`, `fvm flutter build apk`. The pinned local version is stable 3.44.6; CI pins 3.41.2 in `.github/workflows/release.yml`. That drift is known and unrelated to this work — do not "fix" it by upgrading the CI pin as part of this plan.
- **`fvm flutter analyze` must report "No issues found" at the end of every task**, and `fvm flutter test` must be green.
- **Release builds do work on this machine** and sign with the shared keystore via `android/key.properties` (gitignored). A local build writing migrator noise into `android/gradle.properties` or downgrading pins in `pubspec.lock` is drift: revert those two files rather than committing them.
- **An unconfigured install must open no new connection.** The Supabase client is constructed only once a URL and an anon key exist. This is what keeps the privacy claim true for anyone who never turns sync on.
- **Offline is the normal case, not the error case.** A failed sync is never a dialog and never blocks a write; it sets a status the Settings card shows.
- **Never let a sync failure lose a local row.** Clock skew may misorder a conflict; it must not drop data.
- **Ids are not copy.** `mode_id`, `date_key`, level integers and achievement thresholds are protocol, and the content translation layer already depends on that. Nothing in this plan may translate or renumber them.
- **The v2→v3 migration must be idempotent**, checked against the real table shape with `PRAGMA table_info`, exactly like the v1→v2 rebuild. `migration_test.dart` covers the downgrade-then-upgrade path; keep it passing.
- **One new runtime dependency: `supabase_flutter`**, plus `flutter_secure_storage` for the session and anon key. No others.

---

## Task 1 — Local schema v3 and soft deletes

- [ ] `app_database.dart`: bump `_dbVersion` to 3. Add `deleted INTEGER NOT NULL DEFAULT 0` and `dirty INTEGER NOT NULL DEFAULT 0` to `day_entries`; add `updated_at INTEGER`, `deleted`, `dirty` to `modes` (modes have only `created_at` today, so a rename currently has nothing to order by).
- [ ] Migrate with `ALTER TABLE ADD COLUMN` guarded by a `PRAGMA table_info` check — no table rebuild, and re-running on an already-v3 file is a no-op.
- [ ] Existing rows migrate as `deleted=0, dirty=1`, so the first sync uploads the whole history instead of assuming it is already remote.
- [ ] `entry_repository.dart`: `delete()` and `deleteAllForMode()` write tombstones (`deleted=1, updated_at=now, dirty=1`) instead of removing rows. Every read gains `deleted = 0`. `upsert()` sets `dirty=1`.
- [ ] `mode_repository.dart`: same for `deleteCustom()` and `updateCustom()`; `deleteCustom` keeps cascading to the mode's entries, as tombstones.
- [ ] Add `pendingChanges()`, `applyRemote(rows)`, `clearDirty(keys)` to both repositories, and a purge for tombstones that are confirmed pushed and older than 90 days.
- [ ] `export_import_service.dart`: exclude tombstones from the export payload; mark imported rows dirty so a restored backup propagates.
- [ ] Tests: migration idempotency and defaults; delete writes a tombstone; reads hide it; dirty flags set and cleared; export omits tombstones.

## Task 2 — Sync engine against a fake transport

- [ ] `SyncTransport` interface: `push(changes) → accepted`, `pull(since) → (rows, watermark)`.
- [ ] `SyncEngine`: pure merge, last-write-wins on client `updated_at`, remote wins an exact tie, tombstones compete on timestamp (a delete at 10:05 beats an edit at 10:03).
- [ ] The pull watermark is the **server's** clock (`server_updated_at`), stored locally. Device clock skew may misorder a conflict; it must never lose a row.
- [ ] Tests with a fake transport: local-newer, remote-newer, tie, tombstone-vs-edit in both directions, custom-mode rename collision, a pull arriving mid-write, and a two-fake-device round trip that converges regardless of push order.

## Task 3 — Supabase schema

- [ ] `supabase/migrations/0001_sync.sql`, committed so the server schema is reproducible.
- [ ] `day_entries` keyed `(user_id, mode_id, date_key)` and `modes` keyed `(user_id, id)`; `user_id uuid not null references auth.users on delete cascade`; `updated_at` client-supplied; `server_updated_at` maintained by a trigger; index on `(user_id, server_updated_at)`.
- [ ] RLS enabled on both, `auth.uid() = user_id` for select/insert/update/delete.
- [ ] `sync_push(entries jsonb, modes jsonb)` function: `on conflict … do update … where excluded.updated_at > existing.updated_at`. This is why push is an RPC and not `.upsert()` — a stale device must not be able to overwrite newer data, and the batch should be one atomic round-trip.

## Task 4 — Client, config, view model

- [ ] Add `supabase_flutter` and `flutter_secure_storage`.
- [ ] `SyncSettingsRepository`: server URL, anon key, session, pull watermark, last-sync result. **Session and anon key go to secure storage**, not SharedPreferences.
- [ ] `SupabaseSyncTransport` implementing `SyncTransport`; the client is constructed lazily, only when a URL and key exist.
- [ ] `SyncViewModel`: `unconfigured → signedOut → idle(lastSyncedAt) → syncing → error(kind)`. Error kinds are an enum translated in the UI, the way `ImportFailure` and `ModeRule` already are — no English sentences built below the widget layer.
- [ ] Triggers: launch, `AppLifecycleState.resumed` via a `WidgetsBindingObserver`, and after a local write debounced ~2 s. Plus manual "Sync now".
- [ ] After a successful pull, reload `TrackerViewModel` and `ModeViewModel` the way the import path already does.

## Task 5 — Settings UI and copy

- [ ] New Settings section: server URL, anon key, sign in / sign up (email + password), status row ("Last synced 12:04"), **Sync now**, sign out.
- [ ] ~35 new strings in `app_en.arb` / `app_de.arb` / `app_it.arb`.
- [ ] **Rewrite the About card's privacy copy in all three languages.** It currently promises "No account, no cloud sync", which stops being unconditionally true. It becomes conditional: local-only until sync is configured, and naming the configured server once it is.
- [ ] `AndroidManifest.xml`: `INTERNET` is already declared for the updater. Update the comment there — it currently asserts the only destinations are `api.github.com` and `objects.githubusercontent.com`.

## Open question to settle before Task 4

**Cleartext HTTP.** Android blocks it by default, so a `http://192.168.22.10:8000` instance will not connect. Shipping `cleartextTrafficPermitted` weakens every connection the app makes, the updater's included. Recommendation: require `https://` and terminate TLS in front of the instance (Caddy or Tailscale both do it for free). If plain HTTP on the LAN is wanted instead, scope it to a `network_security_config` entry for that host rather than opening cleartext app-wide, and say so in the About copy.

## Out of scope

- Realtime subscriptions (decided against: battery, long-lived connection, reconnect logic).
- Syncing settings — theme, language, reminder time, enabled/active modes stay per-device. Reminder time across timezones is its own problem.
- Sharing data between two *accounts*. One account, many devices.
- Any change to signing or the release workflow. The sync build still updates over v1.3.0 in place.
