"""
Shared API test client for homelab-platform.
Provides authenticated HTTP calls against Supabase-based services.

All tests must target STAGING Supabase (API_URL env var).
Never point at production. Cleanup fixture uses SUPABASE_SERVICE_KEY.
"""

import requests
import uuid
import urllib3
import os

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class APIClient:
    def __init__(self, base_url: str = None, anon_key: str = None):
        self.base_url = base_url or os.environ["API_URL"]  # fail loudly if not set
        self.anon_key = anon_key or os.environ["SUPABASE_ANON_KEY"]
        self.access_token = None
        self.user_id = None
        self.verify_ssl = os.environ.get("VERIFY_SSL", "false").lower() == "true"

    def _headers(self, authenticated: bool = True) -> dict:
        headers = {
            "apikey": self.anon_key,
            "Content-Type": "application/json",
        }
        if authenticated and self.access_token:
            headers["Authorization"] = f"Bearer {self.access_token}"
        return headers

    def signup(self, email: str = None, password: str = None) -> dict:
        email = email or f"test-{uuid.uuid4().hex[:6]}@test.duin.home"
        password = password or f"TestPass{uuid.uuid4().hex[:8]}!"
        resp = requests.post(
            f"{self.base_url}/auth/v1/signup",
            headers=self._headers(authenticated=False),
            json={"email": email, "password": password},
            verify=self.verify_ssl,
        )
        resp.raise_for_status()
        data = resp.json()
        self.access_token = data.get("access_token")
        self.user_id = data.get("user", {}).get("id")
        return data

    def login(self, email: str, password: str) -> dict:
        resp = requests.post(
            f"{self.base_url}/auth/v1/token?grant_type=password",
            headers=self._headers(authenticated=False),
            json={"email": email, "password": password},
            verify=self.verify_ssl,
        )
        resp.raise_for_status()
        data = resp.json()
        self.access_token = data.get("access_token")
        self.user_id = data.get("user", {}).get("id")
        return data

    def get(self, path: str, params: dict = None) -> requests.Response:
        return requests.get(
            f"{self.base_url}{path}",
            headers=self._headers(),
            params=params,
            verify=self.verify_ssl,
        )

    def post(self, path: str, json: dict = None) -> requests.Response:
        return requests.post(
            f"{self.base_url}{path}",
            headers=self._headers(),
            json=json,
            verify=self.verify_ssl,
        )

    def delete_user(self, service_key: str) -> None:
        """Delete this user via admin API. Used by cleanup fixture only."""
        if not self.user_id:
            return
        requests.delete(
            f"{self.base_url}/auth/v1/admin/users/{self.user_id}",
            headers={
                "apikey": service_key,
                "Authorization": f"Bearer {service_key}",
            },
            verify=self.verify_ssl,
        )
