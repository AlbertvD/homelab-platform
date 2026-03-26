import os

def test_user_can_see_own_profile(authenticated_client):
    table = os.environ.get("RLS_PROFILE_TABLE", "profiles")
    resp = authenticated_client.get(f"/rest/v1/{table}?select=*")
    assert resp.status_code == 200
    profiles = resp.json()
    assert len(profiles) > 0
