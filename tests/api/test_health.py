"""
API contract tests — verify that key endpoints exist and respond with expected shapes.
Add a test here for each API endpoint that consuming projects depend on.

Target: staging Supabase only (API_URL env var).
"""

import os
import pytest
import requests


def test_supabase_health(client):
    """Verify the staging Supabase instance is reachable."""
    resp = requests.get(
        f"{os.environ['API_URL']}/rest/v1/",
        headers={"apikey": os.environ["SUPABASE_ANON_KEY"]},
        verify=os.environ.get("VERIFY_SSL", "false").lower() == "true",
    )
    # 200 = healthy, 404 = Supabase up but no tables yet — both are acceptable
    assert resp.status_code in [200, 404], f"Unexpected status: {resp.status_code}"


def test_auth_endpoint_reachable(client):
    """Verify GoTrue auth endpoint is reachable."""
    resp = requests.get(
        f"{os.environ['API_URL']}/auth/v1/settings",
        headers={"apikey": os.environ["SUPABASE_ANON_KEY"]},
        verify=os.environ.get("VERIFY_SSL", "false").lower() == "true",
    )
    assert resp.status_code == 200, f"GoTrue /settings unreachable: {resp.status_code}"
    assert "external" in resp.json() or "mailer_autoconfirm" in resp.json()
