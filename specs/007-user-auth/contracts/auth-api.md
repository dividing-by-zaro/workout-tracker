# API Contract: User Authentication

**Feature**: 007-user-auth
**Base URL**: `{TIMER_BACKEND_URL}` (same backend as timer endpoints)

## Authentication

All endpoints (except `/health`) require:
```
Authorization: Bearer kiln_<random_token>
```

Returns `401` with `{"error": "Invalid API key"}` if the key is missing, malformed, or not found in the database.

---

## Endpoints

### GET /api/me

Retrieve the authenticated user's profile.

**Request**:
```
GET /api/me
Authorization: Bearer kiln_abc123...
```

**Response (200)**:
```json
{
  "name": "Isabel",
  "created_at": "2026-03-08T00:00:00Z"
}
```

**Response (401)**:
```json
{
  "error": "Invalid API key"
}
```

**Notes**:
- This is the endpoint used by the iOS app to validate an API key on login and fetch the user profile.
- The response intentionally excludes the `api_key` and `_id` fields.

---

### GET /health

Health check (no authentication required).

**Request**:
```
GET /health
```

**Response (200)**:
```json
{
  "status": "ok"
}
```

---

### POST /api/timer/schedule (existing, unchanged)

Schedule a timer. Now requires per-user API key instead of shared API key.

**Request**: Same as before.

**Response**: Same as before.

---

### POST /api/timer/cancel (existing, unchanged)

Cancel a timer. Now requires per-user API key instead of shared API key.

**Request**: Same as before.

**Response**: Same as before.

---

## Migration Notes

- The existing single `API_KEY` environment variable is replaced by per-user keys stored in MongoDB.
- The `MONGODB_URL` environment variable must be added to the backend configuration.
- The auth middleware changes from env-var comparison to MongoDB lookup, but the `Authorization: Bearer <key>` header format remains identical.
- iOS `TimerBackendService` must switch from reading the API key from `Info.plist` to reading from Keychain (same key used for both auth and timer requests).
