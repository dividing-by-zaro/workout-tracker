# Quickstart: Hybrid Rest Timer with Backend

## Prerequisites

- Xcode with iOS 17+ SDK
- Apple Developer account with Push Notifications capability enabled for `app.izaro.kiln`
- APNS authentication key (.p8 file) from Apple Developer portal
- Coolify instance with Docker deployment capability
- Python 3.12+ and uv installed (for local backend development)

## Backend Setup (Local Development)

```bash
cd timer-backend/
uv init  # if pyproject.toml doesn't exist
uv add fastapi uvicorn httpx pyjwt cryptography

# Create .env file
cat > .env << 'EOF'
APNS_KEY_ID=YOUR_KEY_ID
APNS_TEAM_ID=85S8MAN3A4
APNS_KEY_PATH=./AuthKey.p8
API_KEY=your-secret-api-key
APNS_ENVIRONMENT=development
EOF

# Copy your .p8 key file
cp ~/path/to/AuthKey_XXXXXXXXXX.p8 ./AuthKey.p8

# Run
uv run uvicorn main:app --host 0.0.0.0 --port 8000
```

## Backend Deployment (Coolify)

1. Push timer-backend to a git repository
2. In Coolify: Create new application → select git repo → Dockerfile build pack
3. Set environment variables: `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_KEY_PATH`, `API_KEY`, `APNS_ENVIRONMENT=production`
4. Mount the .p8 key file as a secret file or embed it via environment variable
5. Deploy

## iOS Changes

1. **Enable Push Notifications capability** in Xcode → Signing & Capabilities
2. **Add `aps-environment` entitlement** (auto-added by Xcode when enabling Push Notifications)
3. **Add `remote-notification` to UIBackgroundModes** in project.yml
4. **Store API key and backend URL** in iOS Keychain or UserDefaults
5. Build and run in Xcode (Cmd+R)

## Testing Flow

1. Start a workout from a template
2. Complete a set → rest timer starts
3. Verify: local notification scheduled (check Settings → Notifications → Kiln)
4. Verify: backend receives POST /timer/schedule (check backend logs)
5. Lock the phone, wait for timer expiry
6. Verify: notification appears with sound on lock screen
7. Verify: Live Activity transitions from timer view to next set view
8. Test skip: complete another set, skip timer, verify notification cancelled
