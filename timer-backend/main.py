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
