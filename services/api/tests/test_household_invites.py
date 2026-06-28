def _register(client, *, email: str, display_name: str) -> dict:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "display_name": display_name,
            "password": "correct-horse-battery-staple",
        },
    )
    assert response.status_code == 201
    return response.json()


def _headers(auth_response: dict) -> dict[str, str]:
    return {"Authorization": f"Bearer {auth_response['access_token']}"}


def test_owner_can_create_and_member_can_accept_one_time_invitation(client):
    owner = _register(client, email="owner@example.com", display_name="Owner")
    member = _register(client, email="member@example.com", display_name="Member")
    owner_headers = _headers(owner)
    member_headers = _headers(member)

    household = client.get("/api/v1/households/current", headers=owner_headers).json()
    created = client.post(
        "/api/v1/households/current/invites",
        headers=owner_headers,
        json={"expires_in_hours": 24},
    )

    assert created.status_code == 201
    invite = created.json()
    assert invite["code"].startswith("HL-")
    assert invite["expires_at"]

    listed = client.get("/api/v1/households/current/invites", headers=owner_headers)
    assert listed.status_code == 200
    assert listed.json() == [
        {
            "id": invite["id"],
            "expires_at": invite["expires_at"],
            "created_at": invite["created_at"],
        }
    ]

    accepted = client.post(
        "/api/v1/households/invites/accept",
        headers=member_headers,
        json={"code": invite["code"].lower().replace("-", " ")},
    )
    assert accepted.status_code == 200
    assert accepted.json()["id"] == household["id"]
    assert accepted.json()["role"] == "member"
    assert accepted.json()["is_active"] is True

    owner_members = client.get("/api/v1/households/current", headers=owner_headers).json()["members"]
    assert {entry["email"] for entry in owner_members} == {"owner@example.com", "member@example.com"}

    reused = client.post(
        "/api/v1/households/invites/accept",
        headers=member_headers,
        json={"code": invite["code"]},
    )
    assert reused.status_code == 404
    assert reused.json()["detail"]["code"] == "invite_invalid"


def test_owner_can_revoke_invitation_and_member_cannot_manage_invites(client):
    owner = _register(client, email="owner@example.com", display_name="Owner")
    member = _register(client, email="member@example.com", display_name="Member")
    owner_headers = _headers(owner)
    member_headers = _headers(member)

    owner_household = client.get("/api/v1/households/current", headers=owner_headers).json()
    added = client.post(
        "/api/v1/households/current/members",
        headers=owner_headers,
        json={"email": "member@example.com"},
    )
    assert added.status_code == 201
    selected = client.post(
        f"/api/v1/households/{owner_household['id']}/select",
        headers=member_headers,
    )
    assert selected.status_code == 200
    assert selected.json()["role"] == "member"

    invite = client.post(
        "/api/v1/households/current/invites",
        headers=owner_headers,
        json={},
    ).json()

    member_create = client.post(
        "/api/v1/households/current/invites",
        headers=member_headers,
        json={},
    )
    assert member_create.status_code == 403
    assert member_create.json()["detail"]["code"] == "household_owner_required"

    revoked = client.delete(
        f"/api/v1/households/current/invites/{invite['id']}",
        headers=owner_headers,
    )
    assert revoked.status_code == 204

    listed = client.get("/api/v1/households/current/invites", headers=owner_headers)
    assert listed.status_code == 200
    assert listed.json() == []

    accepted = client.post(
        "/api/v1/households/invites/accept",
        headers=member_headers,
        json={"code": invite["code"]},
    )
    assert accepted.status_code == 404
    assert accepted.json()["detail"]["code"] == "invite_invalid"


def test_invite_rejects_invalid_code_and_existing_member(client):
    owner = _register(client, email="owner@example.com", display_name="Owner")
    owner_headers = _headers(owner)

    invalid = client.post(
        "/api/v1/households/invites/accept",
        headers=owner_headers,
        json={"code": "HL-not-a-real-code"},
    )
    assert invalid.status_code == 404
    assert invalid.json()["detail"]["code"] == "invite_invalid"

    invite = client.post(
        "/api/v1/households/current/invites",
        headers=owner_headers,
        json={},
    ).json()
    existing_member = client.post(
        "/api/v1/households/invites/accept",
        headers=owner_headers,
        json={"code": invite["code"]},
    )
    assert existing_member.status_code == 409
    assert existing_member.json()["detail"]["code"] == "member_exists"
