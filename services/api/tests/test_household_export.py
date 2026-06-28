import json


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


def test_export_contains_only_the_active_household_snapshot(client):
    owner = _register(client, email="owner-export@example.com", display_name="Owner")
    member = _register(client, email="member-export@example.com", display_name="Member")
    owner_headers = _headers(owner)
    member_headers = _headers(member)

    shared_router = client.post(
        "/api/v1/items",
        headers=owner_headers,
        json={
            "name": "Shared router",
            "category": "electronics",
            "serial_number": "SHARED-42",
        },
    )
    assert shared_router.status_code == 201
    router_id = shared_router.json()["id"]

    archived_kettle = client.post(
        "/api/v1/items",
        headers=owner_headers,
        json={"name": "Archived kettle", "category": "appliance"},
    )
    assert archived_kettle.status_code == 201
    archived_id = archived_kettle.json()["id"]
    assert client.delete(f"/api/v1/items/{archived_id}", headers=owner_headers).status_code == 204

    task = client.post(
        "/api/v1/maintenance",
        headers=owner_headers,
        json={
            "item_id": router_id,
            "title": "Review router firmware",
            "frequency_days": 90,
            "next_due_date": "2026-07-15",
        },
    )
    assert task.status_code == 201
    assert client.post(
        f"/api/v1/maintenance/{task.json()['id']}/complete",
        headers=owner_headers,
    ).status_code == 200

    personal_item = client.post(
        "/api/v1/items",
        headers=member_headers,
        json={"name": "Member-only vacuum", "category": "appliance"},
    )
    assert personal_item.status_code == 201

    member_export_before_selection = client.get(
        "/api/v1/households/current/export",
        headers=member_headers,
    )
    assert member_export_before_selection.status_code == 200
    assert [item["name"] for item in member_export_before_selection.json()["items"]] == ["Member-only vacuum"]

    owner_household = client.get("/api/v1/households/current", headers=owner_headers)
    household_id = owner_household.json()["id"]
    shared_member = client.post(
        "/api/v1/households/current/members",
        headers=owner_headers,
        json={"email": "member-export@example.com"},
    )
    assert shared_member.status_code == 201
    assert client.post(
        f"/api/v1/households/{household_id}/select",
        headers=member_headers,
    ).status_code == 200

    exported = client.get("/api/v1/households/current/export", headers=member_headers)
    assert exported.status_code == 200
    payload = exported.json()

    assert payload["format_version"] == 1
    assert payload["household"]["id"] == household_id
    assert payload["household"]["name"] == "Owner's home"
    assert {item["name"] for item in payload["items"]} == {"Shared router", "Archived kettle"}
    assert next(item for item in payload["items"] if item["id"] == archived_id)["archived_at"] is not None
    assert [entry["title"] for entry in payload["maintenance_tasks"]] == ["Review router firmware"]
    assert [entry["task_title"] for entry in payload["maintenance_completions"]] == [
        "Review router firmware"
    ]
    assert "Member-only vacuum" not in json.dumps(payload)
    assert "password_hash" not in json.dumps(payload)
