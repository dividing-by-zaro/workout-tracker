# Quickstart: User Authentication & Profiles

**Feature**: 007-user-auth

## Prerequisites

- MongoDB running (Coolify one-click deploy, or local `mongod` / Docker `mongo:7`)
- Existing timer-backend environment (Python 3.12+, uv)
- Xcode 15+ with the Kiln project

## Backend Setup

1. **Add MongoDB to Coolify**: Deploy a MongoDB service, note the connection URL.

2. **Update `.env`**:
   ```
   MONGODB_URL=mongodb://user:pass@your-coolify-mongo:27017/kiln
   ```

3. **Install new dependency**:
   ```bash
   cd timer-backend
   uv add motor
   ```

4. **Run backend** (seeds 2 users on first start if `users` collection is empty):
   ```bash
   cd timer-backend
   uv run uvicorn main:app --reload
   ```

5. **Retrieve API keys** (check backend startup logs or query MongoDB directly):
   ```bash
   # The seed script prints keys to stdout on first run
   # Or query directly:
   uv run python -c "
   from pymongo import MongoClient
   db = MongoClient('mongodb://localhost:27017')['kiln']
   for u in db.users.find():
       print(f\"{u['name']}: {u['api_key']}\")
   "
   ```

## iOS Setup

1. **No changes to `Secrets.xcconfig`** needed for auth — the API key is now entered at runtime via the login screen, not at build time.

2. **`TIMER_BACKEND_URL` still comes from `Secrets.xcconfig`** — the backend URL is still a build-time config.

3. **Build in Xcode** (Cmd+R), launch app → login screen appears → paste API key → tap Connect.

## Verification

- **Backend health**: `curl http://localhost:8000/health`
- **Auth test**: `curl -H "Authorization: Bearer kiln_YOUR_KEY" http://localhost:8000/api/me`
- **Invalid key test**: `curl -H "Authorization: Bearer wrong" http://localhost:8000/api/me` → should return 401
- **iOS login**: Launch app, paste key, tap Connect → should see main tab view
- **iOS persistence**: Force-quit app, relaunch → should skip login screen
- **iOS logout**: Profile tab → Logout → should return to login screen
