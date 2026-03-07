# Timer API Contract

Base URL: `https://<coolify-domain>/api`

Authentication: `Authorization: Bearer <API_KEY>` on all requests

## POST /timer/schedule

Schedule a delayed APNS push to update a Live Activity when the rest timer expires.

### Request

```json
{
  "push_token": "a1b2c3d4e5f6...",
  "duration_seconds": 120,
  "content_state": {
    "exerciseName": "Bench Press",
    "setNumber": 3,
    "totalSetsInExercise": 4,
    "previousSetLabel": "135 lbs x 8",
    "weight": 135.0,
    "reps": 8,
    "duration": null,
    "distance": null,
    "equipmentCategory": "weightReps",
    "isRestTimerActive": false,
    "restTimerEndDate": "1970-01-01T00:00:00Z",
    "restTotalSeconds": 0,
    "isWorkoutComplete": false,
    "exerciseIndex": 1,
    "totalExercises": 3
  },
  "device_id": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
}
```

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| push_token | string | yes | Hex-encoded Live Activity push token |
| duration_seconds | integer | yes | Seconds from now until push fires |
| content_state | object | yes | ContentState JSON to include in APNS payload |
| device_id | string | yes | Stable device identifier for cancellation |

### Response

**200 OK**
```json
{
  "status": "scheduled",
  "fire_at": "2026-03-07T15:32:00Z"
}
```

**400 Bad Request**
```json
{
  "error": "Invalid push token format"
}
```

**401 Unauthorized**
```json
{
  "error": "Invalid API key"
}
```

### Behavior

- If a pending timer already exists for the given `device_id`, it is cancelled and replaced
- The backend schedules an asyncio task that sleeps for `duration_seconds`, then sends an APNS push
- The APNS push uses the `content_state` as the Live Activity `content-state` payload

---

## POST /timer/cancel

Cancel a pending timer for a device.

### Request

```json
{
  "device_id": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
}
```

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| device_id | string | yes | Device whose pending timer should be cancelled |

### Response

**200 OK**
```json
{
  "status": "cancelled"
}
```

**200 OK** (no pending timer)
```json
{
  "status": "no_pending_timer"
}
```

**401 Unauthorized**
```json
{
  "error": "Invalid API key"
}
```

---

## APNS Push Payload (sent by backend)

The backend constructs and sends this payload to APNS when the timer expires.

### Headers

```
:method: POST
:path: /3/device/<push_token>
apns-push-type: liveactivity
apns-topic: app.izaro.kiln.push-type.liveactivity
apns-priority: 10
authorization: bearer <JWT>
```

### Body

```json
{
  "aps": {
    "timestamp": 1709827920,
    "event": "update",
    "content-state": {
      "exerciseName": "Bench Press",
      "setNumber": 3,
      "totalSetsInExercise": 4,
      "previousSetLabel": "135 lbs x 8",
      "weight": 135.0,
      "reps": 8,
      "duration": null,
      "distance": null,
      "equipmentCategory": "weightReps",
      "isRestTimerActive": false,
      "restTimerEndDate": "1970-01-01T00:00:00Z",
      "restTotalSeconds": 0,
      "isWorkoutComplete": false,
      "exerciseIndex": 1,
      "totalExercises": 3
    },
    "alert": {
      "title": "Rest Complete",
      "body": "Time for your next set!",
      "sound": "alert_tone.caf"
    }
  }
}
```

### APNS JWT Token

```
Algorithm: ES256
Header: { "alg": "ES256", "kid": "<KEY_ID>", "typ": "JWT" }
Payload: { "iss": "<TEAM_ID>", "iat": <unix_timestamp> }
```

- Token valid for 1 hour from `iat`
- Endpoint: `https://api.push.apple.com` (production)
