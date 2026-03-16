import asyncio
import os
from contextlib import asynccontextmanager

from dotenv import load_dotenv
load_dotenv()
from datetime import datetime, timezone, timedelta

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from apns import APNSClient
from db import get_db, seed_users, close_client
from glade_sync import (
    backfill_to_glade,
    delete_workout_from_glade,
    is_sync_user,
    sync_workout_to_glade,
    update_workout_in_glade,
)
from models import WorkoutPayload


# --- Models ---

class ScheduleRequest(BaseModel):
    push_token: str
    duration_seconds: int
    content_state: dict
    device_id: str


class CancelRequest(BaseModel):
    device_id: str


class PendingTimer:
    def __init__(self, task: asyncio.Task, fire_at: datetime):
        self.task = task
        self.fire_at = fire_at


# --- App ---

pending_timers: dict[str, PendingTimer] = {}
apns_client: APNSClient | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global apns_client
    apns_client = APNSClient(
        key_id=os.environ["APNS_KEY_ID"],
        team_id=os.environ["APNS_TEAM_ID"],
        environment=os.environ.get("APNS_ENVIRONMENT", "development"),
        key_path=os.environ.get("APNS_KEY_PATH"),
        key_base64=os.environ.get("APNS_KEY_BASE64"),
    )
    await seed_users()
    asyncio.create_task(backfill_to_glade())
    yield
    await apns_client.close()
    close_client()


app = FastAPI(lifespan=lifespan)


# --- Middleware ---

@app.middleware("http")
async def verify_api_key(request: Request, call_next):
    if request.url.path == "/health":
        return await call_next(request)

    auth_header = request.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        return JSONResponse(status_code=401, content={"error": "Invalid API key"})

    key = auth_header[7:]
    db = get_db()
    user = await db["users"].find_one({"api_key": key})
    if user is None:
        return JSONResponse(status_code=401, content={"error": "Invalid API key"})

    request.state.user = user
    return await call_next(request)


# --- Endpoints ---

@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/api/me")
async def get_me(request: Request):
    user = request.state.user
    return {
        "name": user["name"],
        "created_at": user["created_at"].isoformat() if hasattr(user["created_at"], "isoformat") else str(user["created_at"]),
    }


async def _upsert_exercises(db, user_id, exercises, now):
    for ex in exercises:
        await db["exercises"].update_one(
            {"user_id": user_id, "name": ex.exercise_name},
            {
                "$set": {
                    "exercise_type": ex.exercise_type,
                    "body_part": ex.body_part,
                    "equipment_type": ex.equipment_type,
                    "updated_at": now,
                },
                "$setOnInsert": {
                    "user_id": user_id,
                    "name": ex.exercise_name,
                    "created_at": now,
                },
            },
            upsert=True,
        )


def _build_exercises_doc(exercises):
    return [
        {
            "order": ex.order,
            "exercise_name": ex.exercise_name,
            "sets": [
                {
                    "order": s.order,
                    "weight": s.weight,
                    "reps": s.reps,
                    "distance": s.distance,
                    "seconds": s.seconds,
                    "rpe": s.rpe,
                    "completed_at": s.completed_at,
                }
                for s in ex.sets
            ],
        }
        for ex in exercises
    ]


@app.post("/api/workouts", status_code=201)
async def create_workout(req: WorkoutPayload, request: Request):
    user = request.state.user
    user_id = user["_id"]
    db = get_db()
    now = datetime.now(timezone.utc)

    await _upsert_exercises(db, user_id, req.exercises, now)

    workout_doc = {
        "user_id": user_id,
        "local_id": req.local_id,
        "name": req.name,
        "started_at": req.started_at,
        "completed_at": req.completed_at,
        "duration_seconds": req.duration_seconds,
        "exercises": _build_exercises_doc(req.exercises),
        "synced_at": now,
    }

    # Try insert; if duplicate (user_id + local_id), return 200 exists
    try:
        await db["workouts"].insert_one(workout_doc)
        if await is_sync_user(user_id):
            asyncio.create_task(sync_workout_to_glade(workout_doc))
        return JSONResponse(
            status_code=201,
            content={"status": "created", "local_id": req.local_id},
        )
    except Exception as e:
        if "duplicate key" in str(e).lower() or "E11000" in str(e):
            return JSONResponse(
                status_code=200,
                content={"status": "exists", "local_id": req.local_id},
            )
        raise


@app.put("/api/workouts/{local_id}")
async def update_workout(local_id: str, req: WorkoutPayload, request: Request):
    user = request.state.user
    user_id = user["_id"]
    db = get_db()
    now = datetime.now(timezone.utc)

    await _upsert_exercises(db, user_id, req.exercises, now)

    result = await db["workouts"].update_one(
        {"user_id": user_id, "local_id": local_id},
        {
            "$set": {
                "name": req.name,
                "started_at": req.started_at,
                "completed_at": req.completed_at,
                "duration_seconds": req.duration_seconds,
                "exercises": _build_exercises_doc(req.exercises),
                "synced_at": now,
            }
        },
    )

    if result.matched_count == 0:
        return JSONResponse(
            status_code=404,
            content={"error": "Workout not found"},
        )

    if await is_sync_user(user_id):
        updated_doc = await db["workouts"].find_one(
            {"user_id": user_id, "local_id": local_id}
        )
        if updated_doc:
            asyncio.create_task(update_workout_in_glade(updated_doc))

    return {"status": "updated", "local_id": local_id}


@app.delete("/api/workouts/{local_id}")
async def delete_workout(local_id: str, request: Request):
    user = request.state.user
    db = get_db()

    result = await db["workouts"].delete_one(
        {"user_id": user["_id"], "local_id": local_id}
    )

    if result.deleted_count == 0:
        return JSONResponse(
            status_code=404,
            content={"error": "Workout not found"},
        )

    if await is_sync_user(user["_id"]):
        asyncio.create_task(delete_workout_from_glade(local_id))

    return {"status": "deleted", "local_id": local_id}


@app.get("/api/workouts/status")
async def get_sync_status(request: Request):
    user = request.state.user
    db = get_db()
    count = await db["workouts"].count_documents({"user_id": user["_id"]})
    return {"synced_count": count}


@app.get("/api/workouts/ids")
async def get_workout_ids(request: Request):
    user = request.state.user
    db = get_db()
    cursor = db["workouts"].find(
        {"user_id": user["_id"]},
        {"local_id": 1, "_id": 0},
    )
    ids = [doc["local_id"] async for doc in cursor]
    return {"local_ids": ids}


@app.post("/api/sync-glade")
async def trigger_glade_sync():
    asyncio.create_task(backfill_to_glade())
    return {"status": "sync_started"}


@app.post("/api/timer/schedule")
async def schedule_timer(req: ScheduleRequest):
    # Cancel existing timer for this device
    existing = pending_timers.pop(req.device_id, None)
    if existing and not existing.task.done():
        existing.task.cancel()

    fire_at = datetime.now(timezone.utc) + timedelta(seconds=req.duration_seconds)

    async def _fire():
        await asyncio.sleep(req.duration_seconds)
        try:
            response = await apns_client.send_live_activity_update(
                push_token=req.push_token,
                content_state=req.content_state,
            )
            if response.status_code != 200:
                print(f"APNS error {response.status_code}: {response.text}")
        except Exception as e:
            print(f"APNS send failed: {e}")
        finally:
            pending_timers.pop(req.device_id, None)

    task = asyncio.create_task(_fire())
    pending_timers[req.device_id] = PendingTimer(task=task, fire_at=fire_at)

    return {"status": "scheduled", "fire_at": fire_at.isoformat()}


@app.post("/api/timer/cancel")
async def cancel_timer(req: CancelRequest):
    existing = pending_timers.pop(req.device_id, None)
    if existing and not existing.task.done():
        existing.task.cancel()
        return {"status": "cancelled"}
    return {"status": "no_pending_timer"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
