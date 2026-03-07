import time
import jwt
import httpx


class APNSClient:
    """Sends push-to-update notifications to Apple's APNS for Live Activities."""

    APNS_PRODUCTION = "https://api.push.apple.com"
    APNS_DEVELOPMENT = "https://api.development.push.apple.com"
    TOKEN_TTL = 3000  # Refresh JWT every 50 minutes (valid for 1 hour)

    def __init__(self, key_path: str, key_id: str, team_id: str, environment: str = "development"):
        with open(key_path) as f:
            self._signing_key = f.read()
        self._key_id = key_id
        self._team_id = team_id
        self._base_url = self.APNS_PRODUCTION if environment == "production" else self.APNS_DEVELOPMENT
        self._cached_token: str | None = None
        self._token_issued_at: float = 0
        self._client = httpx.AsyncClient(http2=True)

    def generate_jwt(self) -> str:
        now = time.time()
        if self._cached_token and (now - self._token_issued_at) < self.TOKEN_TTL:
            return self._cached_token

        payload = {"iss": self._team_id, "iat": int(now)}
        headers = {"alg": "ES256", "kid": self._key_id}
        self._cached_token = jwt.encode(payload, self._signing_key, algorithm="ES256", headers=headers)
        self._token_issued_at = now
        return self._cached_token

    async def send_live_activity_update(
        self, push_token: str, content_state: dict, alert: dict | None = None
    ) -> httpx.Response:
        token = self.generate_jwt()
        apns_payload: dict = {
            "aps": {
                "timestamp": int(time.time()),
                "event": "update",
                "content-state": content_state,
            }
        }
        if alert:
            apns_payload["aps"]["alert"] = alert

        url = f"{self._base_url}/3/device/{push_token}"
        headers = {
            "authorization": f"bearer {token}",
            "apns-push-type": "liveactivity",
            "apns-topic": "app.izaro.kiln.push-type.liveactivity",
            "apns-priority": "10",
        }

        response = await self._client.post(url, json=apns_payload, headers=headers)
        return response

    async def close(self):
        await self._client.aclose()
