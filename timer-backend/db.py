import os
import secrets
from datetime import datetime, timezone

from motor.motor_asyncio import AsyncIOMotorClient

MONGODB_URL = os.environ.get("MONGODB_URL", "mongodb://localhost:27017/kiln")

# Names for seed users — change these to your own before first deploy.
# Each name gets a unique API key printed to stdout on first launch.
SEED_USER_NAMES = os.environ.get("SEED_USER_NAMES", "User1,User2").split(",")

_client: AsyncIOMotorClient | None = None


def get_db():
    global _client
    if _client is None:
        _client = AsyncIOMotorClient(MONGODB_URL)
    try:
        return _client.get_default_database()
    except Exception:
        return _client["kiln"]


async def ensure_indexes():
    db = get_db()

    await db["users"].create_index("api_key", unique=True)
    await db["exercises"].create_index(
        [("user_id", 1), ("name", 1)], unique=True
    )
    await db["workouts"].create_index(
        [("user_id", 1), ("local_id", 1)], unique=True
    )


async def seed_users():
    db = get_db()
    users = db["users"]

    await ensure_indexes()

    count = await users.count_documents({})
    if count > 0:
        return

    seed_data = []
    for name in SEED_USER_NAMES:
        api_key = f"kiln_{secrets.token_urlsafe(32)}"
        seed_data.append({
            "name": name,
            "api_key": api_key,
            "created_at": datetime.now(timezone.utc),
        })
        print(f"Seeded user: {name} -> {api_key}")

    await users.insert_many(seed_data)


def close_client():
    global _client
    if _client is not None:
        _client.close()
        _client = None
