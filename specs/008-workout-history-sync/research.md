# Research: Workout History Sync

**Feature**: 008-workout-history-sync
**Date**: 2026-03-08

## Decision 1: MongoDB Collection Design

**Decision**: Use two collections — `exercises` and `workouts` — with workout exercises and sets embedded as subdocuments within the workout document.

**Rationale**:
- MongoDB's document model is ideal for embedding the workout → exercises → sets hierarchy since this data is always read/written together.
- Exercises are stored as a separate collection because they're shared across workouts and need deduplication by name per user.
- Embedding workout exercises and sets avoids the need for joins (which MongoDB doesn't natively support) and ensures atomic writes of a complete workout.
- The CSV data shows ~10 sets per workout on average (1735 rows / ~170 workouts = ~10 sets/workout). Well within MongoDB's 16MB document limit.

**Alternatives considered**:
- Fully normalized (3 collections for workouts, workout_exercises, workout_sets): Rejected — adds complexity with no benefit at this scale (2 users, <1000 workouts each).
- Single collection with everything embedded: Rejected — exercise definitions need to be referenced across workouts for consistency.

## Decision 2: Deduplication Strategy

**Decision**: Use the SwiftData `Workout.id` (UUID) as the `local_id` field in MongoDB, with a unique compound index on `(user_id, local_id)`.

**Rationale**:
- SwiftData generates UUIDs that are globally unique, making them safe deduplication keys.
- Compound index ensures no duplicate workouts per user even with retries or interrupted syncs.
- The server returns the saved workout's `local_id` on success, and the client marks it as synced locally.

**Alternatives considered**:
- Hash-based dedup (hash of workout date + name): Rejected — two workouts with the same name on the same day are valid.
- Server-generated IDs only: Rejected — requires round-trip before marking synced, more fragile with network issues.

## Decision 3: Sync State Tracking

**Decision**: Use a `syncedWorkoutIds` Set stored in UserDefaults (via App Group) to track which workout UUIDs have been synced.

**Rationale**:
- Simple and lightweight — just a set of UUID strings.
- UserDefaults is appropriate for small metadata (even 1000 UUIDs is ~40KB).
- Avoids adding a `syncStatus` field to the SwiftData model, which would require a schema migration.
- Pending count = total completed workouts - synced count.

**Alternatives considered**:
- Adding `isSynced` property to Workout SwiftData model: Rejected — requires schema migration and is more invasive.
- Separate SwiftData model for sync tracking: Rejected — over-engineered for a simple set membership check.

## Decision 4: Sync Trigger Points

**Decision**: Sync at two points: (1) on app launch after authentication succeeds, and (2) immediately after a workout is completed.

**Rationale**:
- App launch sync covers: initial bulk upload, retrying previously failed uploads, and catching workouts completed while offline.
- Post-completion sync provides immediate backup of fresh data.
- Both are fire-and-forget from the UI perspective — sync happens in the background.

**Alternatives considered**:
- Background app refresh (BGTaskScheduler): Rejected — unreliable timing, unnecessary complexity for a sync that only matters when the user is active.
- Manual sync button: Rejected — violates "Minimal Friction" principle.

## Decision 5: Bulk Upload Strategy

**Decision**: Upload workouts one at a time using the same single-workout endpoint, iterating through unsynced workouts sequentially.

**Rationale**:
- Simplifies the server — one endpoint handles both initial bulk sync and ongoing per-workout sync.
- Each workout upload is idempotent (upsert with unique compound index), so interrupted bulk syncs safely resume.
- At ~10 sets per workout and ~170 workouts, the total payload is small — sequential uploads complete in seconds.
- Avoids implementing a separate bulk endpoint.

**Alternatives considered**:
- Batch endpoint (POST array of workouts): Rejected — added complexity for minimal gain. Can be added later if performance becomes an issue.
- Single mega-upload of all data: Rejected — not resumable, harder to implement idempotently.

## Decision 6: Exercise Sync Strategy

**Decision**: Exercises are synced as part of the workout upload. The server upserts exercises referenced by each workout, using `(user_id, name)` as the unique key.

**Rationale**:
- Exercises don't need a separate sync lifecycle — they're always referenced from a workout.
- Upserting on each workout upload ensures the exercise catalog stays current without a separate sync mechanism.
- Body part and equipment type may be updated if the user modifies an exercise — upsert handles this naturally.

**Alternatives considered**:
- Separate exercise sync step before workout sync: Rejected — adds ordering complexity with no benefit.
- Embedding exercise details directly in workout documents: Rejected — duplicates data and makes exercise catalog queries impossible.
