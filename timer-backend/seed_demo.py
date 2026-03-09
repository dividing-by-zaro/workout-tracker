"""Seed a Demo user (Jane Doe) with sample workouts.

Usage:
    uv run seed_demo.py                          # local: http://localhost:8000
    uv run seed_demo.py https://your-server.com  # remote
"""

import asyncio
import sys
import secrets
from datetime import datetime, timezone, timedelta

from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv
import httpx

load_dotenv()

from db import get_db, ensure_indexes


async def main():
    base_url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000"

    # --- Step 1: Create user directly in MongoDB ---
    db = get_db()
    await ensure_indexes()

    existing = await db["users"].find_one({"name": "Jane Doe"})
    if existing:
        api_key = existing["api_key"]
        print(f"Demo user already exists: {api_key}")
    else:
        api_key = f"kiln_{secrets.token_urlsafe(32)}"
        await db["users"].insert_one({
            "name": "Jane Doe",
            "api_key": api_key,
            "created_at": datetime.now(timezone.utc),
        })
        print(f"Created demo user: Jane Doe -> {api_key}")

    # --- Step 2: Seed workouts via API ---
    headers = {"Authorization": f"Bearer {api_key}"}

    workouts = [
        {
            "local_id": "demo-workout-001",
            "name": "Upper Body Push",
            "started_at": (datetime.now(timezone.utc) - timedelta(days=3, hours=1)).isoformat(),
            "completed_at": (datetime.now(timezone.utc) - timedelta(days=3)).isoformat(),
            "duration_seconds": 3600,
            "exercises": [
                {
                    "order": 0,
                    "exercise_name": "Bench Press (Barbell)",
                    "exercise_type": "strength",
                    "body_part": "chest",
                    "equipment_type": "barbell",
                    "sets": [
                        {"order": 0, "weight": 135.0, "reps": 10},
                        {"order": 1, "weight": 155.0, "reps": 8},
                        {"order": 2, "weight": 175.0, "reps": 6},
                        {"order": 3, "weight": 175.0, "reps": 5},
                    ],
                },
                {
                    "order": 1,
                    "exercise_name": "Overhead Press (Barbell)",
                    "exercise_type": "strength",
                    "body_part": "shoulders",
                    "equipment_type": "barbell",
                    "sets": [
                        {"order": 0, "weight": 65.0, "reps": 10},
                        {"order": 1, "weight": 75.0, "reps": 8},
                        {"order": 2, "weight": 85.0, "reps": 6},
                    ],
                },
                {
                    "order": 2,
                    "exercise_name": "Incline Dumbbell Press",
                    "exercise_type": "strength",
                    "body_part": "chest",
                    "equipment_type": "dumbbell",
                    "sets": [
                        {"order": 0, "weight": 40.0, "reps": 12},
                        {"order": 1, "weight": 45.0, "reps": 10},
                        {"order": 2, "weight": 45.0, "reps": 9},
                    ],
                },
                {
                    "order": 3,
                    "exercise_name": "Tricep Pushdown (Cable)",
                    "exercise_type": "strength",
                    "body_part": "arms",
                    "equipment_type": "cable",
                    "sets": [
                        {"order": 0, "weight": 30.0, "reps": 15},
                        {"order": 1, "weight": 35.0, "reps": 12},
                        {"order": 2, "weight": 35.0, "reps": 10},
                    ],
                },
            ],
        },
        {
            "local_id": "demo-workout-002",
            "name": "Lower Body",
            "started_at": (datetime.now(timezone.utc) - timedelta(days=1, hours=1, minutes=15)).isoformat(),
            "completed_at": (datetime.now(timezone.utc) - timedelta(days=1)).isoformat(),
            "duration_seconds": 4500,
            "exercises": [
                {
                    "order": 0,
                    "exercise_name": "Squat (Barbell)",
                    "exercise_type": "strength",
                    "body_part": "legs",
                    "equipment_type": "barbell",
                    "sets": [
                        {"order": 0, "weight": 135.0, "reps": 10},
                        {"order": 1, "weight": 185.0, "reps": 8},
                        {"order": 2, "weight": 205.0, "reps": 6},
                        {"order": 3, "weight": 225.0, "reps": 4},
                    ],
                },
                {
                    "order": 1,
                    "exercise_name": "Romanian Deadlift (Barbell)",
                    "exercise_type": "strength",
                    "body_part": "legs",
                    "equipment_type": "barbell",
                    "sets": [
                        {"order": 0, "weight": 135.0, "reps": 10},
                        {"order": 1, "weight": 155.0, "reps": 8},
                        {"order": 2, "weight": 155.0, "reps": 8},
                    ],
                },
                {
                    "order": 2,
                    "exercise_name": "Leg Press (Machine)",
                    "exercise_type": "strength",
                    "body_part": "legs",
                    "equipment_type": "machine",
                    "sets": [
                        {"order": 0, "weight": 270.0, "reps": 12},
                        {"order": 1, "weight": 360.0, "reps": 10},
                        {"order": 2, "weight": 360.0, "reps": 8},
                    ],
                },
                {
                    "order": 3,
                    "exercise_name": "Walking Lunge (Dumbbell)",
                    "exercise_type": "strength",
                    "body_part": "legs",
                    "equipment_type": "dumbbell",
                    "sets": [
                        {"order": 0, "weight": 30.0, "reps": 12},
                        {"order": 1, "weight": 35.0, "reps": 10},
                        {"order": 2, "weight": 35.0, "reps": 10},
                    ],
                },
                {
                    "order": 4,
                    "exercise_name": "Calf Raise (Machine)",
                    "exercise_type": "strength",
                    "body_part": "legs",
                    "equipment_type": "machine",
                    "sets": [
                        {"order": 0, "weight": 90.0, "reps": 15},
                        {"order": 1, "weight": 110.0, "reps": 12},
                        {"order": 2, "weight": 110.0, "reps": 12},
                    ],
                },
            ],
        },
    ]

    async with httpx.AsyncClient(base_url=base_url, timeout=30) as client:
        for w in workouts:
            resp = await client.post("/api/workouts", json=w, headers=headers)
            print(f"  {w['name']}: {resp.status_code} - {resp.json()}")

    print("\nDone! API key for Jane Doe:")
    print(f"  {api_key}")


if __name__ == "__main__":
    asyncio.run(main())
