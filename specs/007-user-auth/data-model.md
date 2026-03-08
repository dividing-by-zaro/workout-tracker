# Data Model: User Authentication & Profiles

**Feature**: 007-user-auth
**Date**: 2026-03-08

## Entities

### User (Backend — MongoDB `users` collection)

| Field        | Type     | Required | Description                                      |
|--------------|----------|----------|--------------------------------------------------|
| `_id`        | ObjectId | auto     | MongoDB auto-generated document ID                |
| `name`       | string   | yes      | Display name (e.g., "Isabel", "Neta")            |
| `api_key`    | string   | yes      | Unique authentication key, `kiln_` prefixed       |
| `created_at` | datetime | yes      | Document creation timestamp (UTC)                 |

**Indexes**: Unique index on `api_key` for O(1) lookup in auth middleware.

**Seed data**: 2 documents inserted on first backend startup if collection is empty.

**Schema flexibility**: Being a MongoDB document, additional fields (e.g., `preferences`, `avatar_url`, `last_seen`) can be added to individual documents at any time without migrations.

### Cached User Profile (iOS — UserDefaults)

| Key                    | Type   | Description                              |
|------------------------|--------|------------------------------------------|
| `cachedUserName`       | String | User's display name for offline display  |
| `cachedUserProfileAt`  | Date   | When the profile was last fetched        |

**Purpose**: Enables offline app launch after initial authentication. Updated on every successful profile fetch.

### Stored Credential (iOS — Keychain)

| Attribute       | Value                  |
|-----------------|------------------------|
| `kSecClass`     | `kSecClassGenericPassword` |
| `kSecAttrService` | `app.izaro.kiln`     |
| `kSecAttrAccount` | `api-key`            |
| `kSecValueData` | The API key string (UTF-8 encoded) |

**Purpose**: Secure, hardware-backed storage of the API key. Persists across app restarts and device reboots. Cleared on logout.

## Relationships

```text
Backend MongoDB:
  users (collection)
    └── 1 document per user (2 total)

iOS Device:
  Keychain: api-key → authenticates against → users.api_key
  UserDefaults: cachedUserName → mirrors → users.name
```

## State Transitions

### Auth State (iOS)

```text
                    ┌─────────────────┐
          launch    │                 │  valid key + profile
  ┌────────────────▶│   checking      │──────────────────────┐
  │                 │                 │                       │
  │                 └───────┬─────────┘                       ▼
  │                         │                          ┌──────────────┐
  │              no key or  │                          │              │
  │              invalid    │                          │ authenticated│
  │                         ▼                          │              │
  │                 ┌─────────────────┐                └──────┬───────┘
  │                 │                 │                       │
  │                 │ unauthenticated │    logout             │
  │                 │                 │◀──────────────────────┘
  │                 └───────┬─────────┘
  │                         │
  │              user enters│ valid key
  │              key        │
  │                         ▼
  │                 ┌─────────────────┐
  │                 │  authenticating  │──── success ──▶ authenticated
  │                 │                 │
  │                 └───────┬─────────┘
  │                         │ failure (invalid key / network error)
  │                         ▼
  │                 unauthenticated (with error message)
  └── app relaunch cycles back to checking
```

States:
- **checking**: App launched, reading Keychain and optionally verifying with backend
- **unauthenticated**: No valid key stored, show login screen
- **authenticating**: User submitted a key, validating against backend
- **authenticated**: Valid key stored, user profile loaded, show main app
