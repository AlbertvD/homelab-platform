"""
Shared pytest fixtures for homelab-platform tests.
"""

import pytest
import uuid
import os
from lib.api_client import APIClient


@pytest.fixture(scope="session")
def service_key():
    """Supabase service role key — used only for test user cleanup."""
    key = os.environ.get("SUPABASE_SERVICE_KEY")
    if not key:
        pytest.skip("SUPABASE_SERVICE_KEY not set — skipping tests that require cleanup")
    return key


@pytest.fixture
def client():
    """Unauthenticated API client targeting staging Supabase."""
    return APIClient()


@pytest.fixture
def authenticated_client(service_key):
    """
    Authenticated client with a fresh test user.
    Cleans up the user after the test completes.
    """
    c = APIClient()
    email = f"test-{uuid.uuid4().hex[:8]}@test.duin.home"
    password = f"TestPass{uuid.uuid4().hex[:8]}!"
    c.signup(email, password)

    yield c

    # Cleanup: delete the test user via admin API
    c.delete_user(service_key)
