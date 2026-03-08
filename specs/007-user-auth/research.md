# Research: User Authentication & Profiles

**Feature**: 007-user-auth
**Date**: 2026-03-08

## R1: MongoDB for 2-User Document Store

**Decision**: Use MongoDB via `motor` (async Python driver) with the existing FastAPI backend.

**Rationale**: The user explicitly requested a document-based DB to avoid schema migrations. MongoDB is the most mature document DB, `motor` integrates natively with asyncio/FastAPI, and Coolify supports one-click MongoDB deployment. For 2 users with minimal data, MongoDB is zero-overhead — no schema design, no migrations, just insert documents.

**Alternatives considered**:
- **PostgreSQL + JSONB columns**: Provides document flexibility within a relational DB. Rejected because the user explicitly wants to avoid schema management, and Postgres still requires table definitions.
- **SQLite**: Lightweight but still requires schema. Not a document store.
- **TinyDB / flat-file JSON**: Too fragile for a Docker deployment. No query language, no concurrent access safety.

## R2: API Key Generation & Storage Strategy

**Decision**: Generate 32-character URL-safe random tokens (Python `secrets.token_urlsafe(32)`) prefixed with `kiln_` for identifiability. Store the key as a plain string in the MongoDB `users` document (not hashed) since this is a 2-user private system with no risk of database breach at scale.

**Rationale**: For 2 users on a private server, the threat model doesn't justify bcrypt-hashing API keys (which would prevent key display/recovery). The `kiln_` prefix helps users identify which credential they're pasting. 32 bytes of randomness (256 bits) makes brute force infeasible even without rate limiting.

**Alternatives considered**:
- **Hashed keys (bcrypt/argon2)**: Industry best practice for production systems. Rejected because it prevents the developer from viewing/recovering keys, and the threat model (2 users, private server, no public signup) doesn't warrant it.
- **UUID4**: Less entropy density per character than `token_urlsafe`. No prefix support.
- **JWT tokens**: Overkill — no expiry, no claims needed, no token refresh. A static key is simpler.

## R3: iOS Keychain Access Pattern

**Decision**: Use the Security framework directly (`SecItemAdd`/`SecItemCopyMatching`/`SecItemDelete`) wrapped in a small `KeychainService` helper. Store the API key as a `kSecClassGenericPassword` item with service name `app.izaro.kiln` and account `api-key`.

**Rationale**: The Security framework is the standard iOS approach for credential storage. A thin wrapper (not a third-party library) keeps dependencies minimal. `kSecClassGenericPassword` is the correct class for API key storage.

**Alternatives considered**:
- **KeychainAccess (third-party library)**: Cleaner API but adds a dependency for ~30 lines of code. Rejected.
- **UserDefaults**: Insecure — stored in plain-text plist. Rejected per spec requirements.
- **SwiftData model**: Tied to the app's data container, not encrypted at rest with hardware-backed key. Rejected.

## R4: Auth Flow Architecture (iOS)

**Decision**: Add an `@Observable AuthService` class that owns the auth state (`.unauthenticated`, `.authenticated(UserProfile)`). Inject via `.environment()` at the app root. `KilnApp` conditionally renders `LoginView` or `ContentView` based on auth state. On launch, `AuthService` checks Keychain for stored key → if found, silently validates against backend → if valid, fetches profile and transitions to `.authenticated`.

**Rationale**: Matches the existing pattern (`WorkoutSessionManager` is `@Observable` + `.environment()`). Conditional root view rendering is the simplest auth gate — no navigation stack complexity, no sheet dismissal race conditions.

**Alternatives considered**:
- **NavigationStack with auth guard**: More complex, introduces navigation state management for a binary authenticated/not decision. Rejected.
- **Sheet presentation for login**: Can be dismissed accidentally, doesn't feel like a proper gate. Rejected.

## R5: Backend Auth Middleware Migration

**Decision**: Replace the single `API_KEY` env var with MongoDB-backed per-user key lookup. The middleware queries `users` collection by API key, attaches the user document to `request.state.user`. Existing timer endpoints continue working — they just now have a user context attached.

**Rationale**: Minimal change to existing middleware pattern. The timer endpoints don't need to use the user context yet (no per-user timer isolation needed for 2 users), but the middleware resolves the user for any endpoint that needs it (like `GET /api/me`).

**Alternatives considered**:
- **Keep single API_KEY + separate user lookup on specific endpoints**: Means some endpoints bypass user resolution. Inconsistent. Rejected.
- **JWT-based auth**: Adds token generation, expiry, refresh. Overkill for 2 static users. Rejected.

## R6: Offline Tolerance & Cached Profile

**Decision**: Cache the user profile (name) in UserDefaults after successful login. On subsequent launches, if the backend is unreachable, use the cached profile and proceed to the main app. The Keychain-stored API key is the source of truth for "is logged in" — the backend check is best-effort.

**Rationale**: The app's primary functionality is local (SwiftData workouts). Blocking the entire app on backend availability for a profile fetch would be a bad experience, especially in gyms with poor connectivity.

**Alternatives considered**:
- **Always require backend validation on launch**: Would block app usage when offline. Rejected — violates the local-first principle.
- **Cache in SwiftData**: Adds a User model to the workout data store. Unnecessary coupling. UserDefaults is fine for a single name string.

## R7: Constitution Principle VI Amendment

**Decision**: Amend Principle VI from "Single-User Simplicity" to "Household Simplicity" — exactly 2 users (developer + wife), API key auth only, no general multi-tenancy.

**Rationale**: The user (constitution author) explicitly requested 2-user support. The amendment preserves the spirit of the principle (no auth complexity, no RBAC, no user management UI) while expanding from 1 to 2 users. The backend adds a `users` collection but no signup, no roles, no sessions — just key lookup.

**Action required**: Update `.specify/memory/constitution.md` Principle VI during implementation.
