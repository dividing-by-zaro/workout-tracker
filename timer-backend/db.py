import os
import secrets
from datetime import datetime, timezone

from motor.motor_asyncio import AsyncIOMotorClient

MONGODB_URL = os.environ.get("MONGODB_URL", "mongodb://localhost:27017/kiln")

_client: AsyncIOMotorClient | None = None


def get_db():
    global _client
    if _client is None:
        _client = AsyncIOMotorClient(MONGODB_URL)
    try:
        return _client.get_default_database()
    except Exception:
        return _client["kiln"]


async def seed_users():
    db = get_db()
    users = db["users"]

    # Create unique index on api_key
    await users.create_index("api_key", unique=True)

    count = await users.count_documents({})
    if count > 0:
        return

    seed_data = []
    for name in ("Isabel", "Lakzhmy"):
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
