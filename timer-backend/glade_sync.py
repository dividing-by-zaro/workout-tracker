import logging
import os
import re
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

import httpx

from db import get_db

logger = logging.getLogger("glade_sync")

GLADE_API_URL = os.environ.get("GLADE_API_URL", "")
GLADE_API_KEY = os.environ.get("GLADE_API_KEY", "")
GLADE_CF_CLIENT_ID = os.environ.get("GLADE_CF_CLIENT_ID", "")
GLADE_CF_CLIENT_SECRET = os.environ.get("GLADE_CF_CLIENT_SECRET", "")
GLADE_SYNC_USER = os.environ.get("GLADE_SYNC_USER", "")

SYNC_CUTOFF = datetime(2026, 3, 16, tzinfo=timezone.utc)
PACIFIC = ZoneInfo("America/Los_Angeles")

_sync_user_id = None


def _enabled() -> bool:
    return bool(GLADE_API_URL and GLADE_API_KEY and GLADE_SYNC_USER)


def _headers() -> dict:
    h = {
        "Content-Type": "application/json",
        "X-API-Key": GLADE_API_KEY,
    }
    if GLADE_CF_CLIENT_ID:
        h["CF-Access-Client-Id"] = GLADE_CF_CLIENT_ID
    if GLADE_CF_CLIENT_SECRET:
        h["CF-Access-Client-Secret"] = GLADE_CF_CLIENT_SECRET
    return h


async def _get_sync_user_id():
    global _sync_user_id
    if _sync_user_id is not None:
        return _sync_user_id
    db = get_db()
    user = await db["users"].find_one(
        {"name": re.compile(f"^{re.escape(GLADE_SYNC_USER)}$", re.IGNORECASE)}
    )
    if user:
        _sync_user_id = user["_id"]
    return _sync_user_id


def _is_syncable(doc: dict) -> bool:
    return (
        doc.get("completed_at") is not None
        and doc.get("duration_seconds") is not None
        and doc.get("started_at") is not None
        and doc["started_at"] >= SYNC_CUTOFF
        and round(doc["duration_seconds"] / 60) >= 1
    )


def _build_payload(doc: dict) -> dict:
    return {
        "date": doc["started_at"].astimezone(PACIFIC).strftime("%Y-%m-%d"),
        "activity_type": "strength",
        "duration_minutes": round(doc["duration_seconds"] / 60),
        "source": "kiln",
        "source_id": f"kiln_{doc['local_id']}",
        "description": doc.get("name", ""),
    }


async def sync_workout_to_glade(doc: dict):
    """POST a single workout to Glade. Idempotent via source_id dedup."""
    if not _enabled() or not _is_syncable(doc):
        return
    payload = _build_payload(doc)
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{GLADE_API_URL}/api/exercise",
                json=payload,
                headers=_headers(),
                timeout=10,
            )
            logger.info("Glade POST %s -> %s", payload["source_id"], resp.status_code)
    except Exception as e:
        logger.warning("Glade POST failed for %s: %s", payload["source_id"], e)


async def update_workout_in_glade(doc: dict):
    """PUT updated workout fields to Glade. Falls back to POST if 404."""
    if not _enabled() or not _is_syncable(doc):
        return
    source_id = f"kiln_{doc['local_id']}"
    payload = {
        "date": doc["started_at"].astimezone(PACIFIC).strftime("%Y-%m-%d"),
        "duration_minutes": round(doc["duration_seconds"] / 60),
        "description": doc.get("name", ""),
    }
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.put(
                f"{GLADE_API_URL}/api/exercise/by-source/{source_id}",
                json=payload,
                headers=_headers(),
                timeout=10,
            )
            logger.info("Glade PUT %s -> %s", source_id, resp.status_code)
            if resp.status_code == 404:
                await sync_workout_to_glade(doc)
    except Exception as e:
        logger.warning("Glade PUT failed for %s: %s", source_id, e)


async def delete_workout_from_glade(local_id: str):
    """DELETE a workout from Glade by source_id. Ignores 404."""
    if not _enabled():
        return
    source_id = f"kiln_{local_id}"
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.delete(
                f"{GLADE_API_URL}/api/exercise/by-source/{source_id}",
                headers=_headers(),
                timeout=10,
            )
            logger.info("Glade DELETE %s -> %s", source_id, resp.status_code)
    except Exception as e:
        logger.warning("Glade DELETE failed for %s: %s", source_id, e)


async def backfill_to_glade():
    """POST all eligible workouts to Glade. Safe to run repeatedly (dedup)."""
    if not _enabled():
        logger.info("Glade sync disabled (no GLADE_API_URL/GLADE_API_KEY)")
        return

    user_id = await _get_sync_user_id()
    if user_id is None:
        logger.warning("Glade backfill: user '%s' not found, skipping", GLADE_SYNC_USER)
        return

    db = get_db()
    cursor = db["workouts"].find({
        "user_id": user_id,
        "completed_at": {"$ne": None},
        "duration_seconds": {"$ne": None},
        "started_at": {"$gte": SYNC_CUTOFF},
    })

    count = 0
    async for doc in cursor:
        if _is_syncable(doc):
            await sync_workout_to_glade(doc)
            count += 1

    logger.info("Glade backfill complete: %d workouts synced", count)


async def is_sync_user(user_id) -> bool:
    """Check if the given user_id is the Glade sync user."""
    sync_id = await _get_sync_user_id()
    return sync_id is not None and user_id == sync_id
