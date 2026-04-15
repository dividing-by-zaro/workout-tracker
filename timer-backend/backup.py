"""Google Drive backup for the Kiln MongoDB database.

Dumps every collection in the configured database(s) to gzipped JSON and
uploads to Google Drive. Designed to be called from an async context — the
synchronous Google API client calls are offloaded via asyncio.to_thread.

Env vars required:
  GOOGLE_CLIENT_ID      — OAuth 2.0 client ID
  GOOGLE_CLIENT_SECRET  — OAuth 2.0 client secret
  GOOGLE_REFRESH_TOKEN  — OAuth 2.0 refresh token (from scripts/setup_google_auth.py)

Optional:
  BACKUP_DATABASES      — comma-separated DB names (default: "kiln")
  BACKUP_DRIVE_FOLDER   — Google Drive folder name (default: "kiln-backups")
  BACKUP_RETENTION_DAYS — days to keep old backups (default: 30)
"""

import asyncio
import gzip
import io
import json
import os
from datetime import datetime, timedelta, timezone

from bson import ObjectId
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseUpload

from db import get_db

GOOGLE_TOKEN_URI = "https://oauth2.googleapis.com/token"


def _json_serializer(obj):
    if isinstance(obj, ObjectId):
        return str(obj)
    if isinstance(obj, datetime):
        return obj.isoformat()
    raise TypeError(f"Object of type {type(obj)} is not JSON serializable")


async def _dump_database(db_name: str) -> bytes:
    client = get_db().client
    db = client[db_name]
    collection_names = await db.list_collection_names()
    dump = {}
    for coll_name in collection_names:
        docs = await db[coll_name].find().to_list(length=None)
        dump[coll_name] = docs

    json_bytes = json.dumps(dump, default=_json_serializer).encode()
    buf = io.BytesIO()
    with gzip.GzipFile(fileobj=buf, mode="wb") as gz:
        gz.write(json_bytes)
    return buf.getvalue()


def _get_credentials() -> Credentials | None:
    client_id = os.environ.get("GOOGLE_CLIENT_ID")
    client_secret = os.environ.get("GOOGLE_CLIENT_SECRET")
    refresh_token = os.environ.get("GOOGLE_REFRESH_TOKEN")
    if not all([client_id, client_secret, refresh_token]):
        return None
    return Credentials(
        token=None,
        refresh_token=refresh_token,
        client_id=client_id,
        client_secret=client_secret,
        token_uri=GOOGLE_TOKEN_URI,
    )


def _get_or_create_folder(service, folder_name: str) -> str:
    query = (
        f"name='{folder_name}' and mimeType='application/vnd.google-apps.folder' "
        f"and trashed=false"
    )
    results = service.files().list(q=query, fields="files(id)").execute()
    files = results.get("files", [])
    if files:
        return files[0]["id"]
    metadata = {
        "name": folder_name,
        "mimeType": "application/vnd.google-apps.folder",
    }
    folder = service.files().create(body=metadata, fields="id").execute()
    return folder["id"]


def _prune_old_backups(service, folder_id: str, retention_days: int):
    cutoff = datetime.now(timezone.utc) - timedelta(days=retention_days)
    cutoff_str = cutoff.isoformat()
    query = (
        f"'{folder_id}' in parents and trashed=false "
        f"and createdTime < '{cutoff_str}'"
    )
    results = service.files().list(q=query, fields="files(id, name)").execute()
    for f in results.get("files", []):
        service.files().delete(fileId=f["id"]).execute()
        print(f"  Pruned old backup: {f['name']}")


def _upload_to_drive(folder_name: str, retention_days: int, dumps: dict[str, bytes]) -> list[str]:
    service = build("drive", "v3", credentials=_get_credentials())
    folder_id = _get_or_create_folder(service, folder_name)

    uploaded = []
    for filename, data in dumps.items():
        media = MediaIoBaseUpload(
            io.BytesIO(data),
            mimetype="application/gzip",
            resumable=True,
        )
        file_metadata = {"name": filename, "parents": [folder_id]}
        service.files().create(body=file_metadata, media_body=media).execute()
        size_kb = len(data) / 1024
        uploaded.append(f"{filename} ({size_kb:.0f} KB)")
        print(f"  Uploaded {filename} ({size_kb:.0f} KB)")

    _prune_old_backups(service, folder_id, retention_days)
    return uploaded


async def run_backup() -> str:
    """Dump MongoDB databases and upload to Google Drive. Returns status message."""
    if _get_credentials() is None:
        return "Backup skipped: Google credentials not configured"

    databases = os.environ.get("BACKUP_DATABASES", "kiln").split(",")
    folder_name = os.environ.get("BACKUP_DRIVE_FOLDER", "kiln-backups")
    retention_days = int(os.environ.get("BACKUP_RETENTION_DAYS", "30"))
    date_str = datetime.now(timezone.utc).strftime("%Y-%m-%d_%H%M")

    dumps: dict[str, bytes] = {}
    for db_name in databases:
        db_name = db_name.strip()
        try:
            dumps[f"{db_name}-{date_str}.json.gz"] = await _dump_database(db_name)
        except Exception as e:
            print(f"  Dump failed for {db_name}: {e}")

    if not dumps:
        return "Backup failed: no databases dumped"

    uploaded = await asyncio.to_thread(
        _upload_to_drive, folder_name, retention_days, dumps
    )
    return f"Backed up: {', '.join(uploaded)}" if uploaded else "Backup failed: upload returned nothing"
