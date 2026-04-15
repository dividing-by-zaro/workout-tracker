"""One-time script to obtain a Google OAuth refresh token for Drive backups.

Run locally (not on server):
    uv run timer-backend/scripts/setup_google_auth.py

It will open a browser for OAuth consent, then print the refresh token.
Set these env vars on the Coolify deployment:
    GOOGLE_CLIENT_ID
    GOOGLE_CLIENT_SECRET
    GOOGLE_REFRESH_TOKEN

Note: the OAuth client can be shared with other projects (e.g. Glade) —
the drive.file scope only exposes files this app creates, so a single
client credential can safely back up multiple apps into different folders.
"""

import os
import sys

from google_auth_oauthlib.flow import InstalledAppFlow

SCOPES = ["https://www.googleapis.com/auth/drive.file"]


def main():
    client_id = os.environ.get("GOOGLE_CLIENT_ID")
    client_secret = os.environ.get("GOOGLE_CLIENT_SECRET")

    if not client_id or not client_secret:
        print("Set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET env vars first.")
        print("  export GOOGLE_CLIENT_ID=your-client-id")
        print("  export GOOGLE_CLIENT_SECRET=your-client-secret")
        sys.exit(1)

    flow = InstalledAppFlow.from_client_config(
        {
            "installed": {
                "client_id": client_id,
                "client_secret": client_secret,
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
                "redirect_uris": ["urn:ietf:wg:oauth:2.0:oob", "http://localhost"],
            }
        },
        scopes=SCOPES,
    )

    creds = flow.run_local_server(port=8090)

    print("\n--- Save these as Coolify env vars ---")
    print(f"GOOGLE_CLIENT_ID={client_id}")
    print(f"GOOGLE_CLIENT_SECRET={client_secret}")
    print(f"GOOGLE_REFRESH_TOKEN={creds.refresh_token}")
    print("--------------------------------------")


if __name__ == "__main__":
    main()
