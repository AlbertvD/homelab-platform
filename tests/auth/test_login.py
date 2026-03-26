import uuid
import pytest
from lib.api_client import APIClient

def test_signup_returns_token(authenticated_client):
    assert authenticated_client.access_token is not None
    assert authenticated_client.user_id is not None
