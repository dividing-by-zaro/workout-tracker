from datetime import datetime

from pydantic import BaseModel


class WorkoutSetPayload(BaseModel):
    order: int
    weight: float | None = None
    reps: int | None = None
    distance: float | None = None
    seconds: float | None = None
    rpe: float | None = None
    completed_at: datetime | None = None


class WorkoutExercisePayload(BaseModel):
    order: int
    exercise_name: str
    exercise_type: str
    body_part: str | None = None
    equipment_type: str | None = None
    sets: list[WorkoutSetPayload]


class WorkoutPayload(BaseModel):
    local_id: str
    name: str
    started_at: datetime
    completed_at: datetime
    duration_seconds: int | None = None
    exercises: list[WorkoutExercisePayload]


class WorkoutResponse(BaseModel):
    status: str
    local_id: str


class SyncStatusResponse(BaseModel):
    synced_count: int
