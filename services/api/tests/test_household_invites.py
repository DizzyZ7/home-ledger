def _register(client, email: str) -> dict:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "display_name": email.split("@")[0],
            "password": "correct-horse-battery-staple",
        },
    )
    assert response.status_code == 201
    return response.json()


def _headers(auth: dict) -> dict[str, str]:
    return {"Authorization": f"Bearer {auth['access_token']}"}


def test_owner_creates_and_member_accepts_one_time_invite(client):
    owner = _register(client, "owner@example.com")
    member = _register(client, "member@example.com")
    owner_headers = _headers(owner)
    member_headers = _headers(member)

    owner_household = client.get("/api/v1/households/current", headers=owner_headers).json()
    created = client.post(
        "/api/v1/households/current/invites",
        headers=owner_headers,
        json={"expires_in_hours": 24},
    )
    assert created.status_code == 201
    invite = created.json()
    assert invite["code"].startswith("HL-")

    listed = client.get("/api/v1/households/current/invites", headers=owner_headers)
    assert listed.status_code == 200
    assert "code" not in listed.json()[0]

    accepted = client.post(
        "/api/v1/households/invites/accept",
        headers=member_headers,
        json={"code": invite["code"].lower().replace("-", " ")},
    )
    assert accepted.status_code == 200
    assert accepted.json()["id"] == owner_household["id"]
    assert accepted.json()["role"] == "member"
    assert accepted.json()["is_active"] is True

    reused = client.post(
        "/api/v1/households/invites/accept",
        headers=member_headers,
        json={"code": invite["code"]},
    )
    assert reused.status_code == 404
    assert reused.json()["detail"]["code"] == "invite_invalid"


def test_owner_can_revoke_and_member_cannot_manage_invites(client):
    owner = _register(client, "owner@example.com")
    member = _register(client, "member@example.com")
    owner_headers = _headers(owner)
    member_headers = _headers(member)

    household = client.get("/api/v1/households/current", headers=owner_headers).json()
    added = client.post(
        "/api/v1/households/current/members",
        headers=owner_headers,
        json={"email": "member@example.com"},
    )
    assert added.status_code == 201
    selected = client.post(
        f"/api/v1/households/{household['id']}/select",
        headers=member_headers,
    )
    assert selected.status_code == 200

    forbidden = client.post(
        "/api/v1/households/current/invites",
        headers=member_headers,
        json={},
    )
    assert forbidden.status_code == 403

    invite = client.post(
        "/api/v1/households/current/invites",
        headers=owner_headers,
        json={},
    ).json()
    revoked = client.delete(
        f"/api/v1/households/current/invites/{invite['id']}",
        headers=owner_headers,
    )
    assert revoked.status_code == 204

    accepted = client.post(
        "/api/v1/households/invites/accept",
        headers=member_headers,
        json={"code": invite["code"]},
    )
    assert accepted.status_code == 404
