from datetime import date


def _access_token(client) -> str:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "items@example.com",
            "display_name": "Items owner",
            "password": "correct-horse-battery-staple",
        },
    )
    return response.json()["access_token"]


def test_create_list_update_archive_and_restore_item(client):
    token = _access_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    created = client.post(
        "/api/v1/items",
        headers=headers,
        json={
            "name": "Washing machine",
            "category": "appliance",
            "location": "Bathroom",
            "warranty_expires_at": str(date.today()),
        },
    )
    assert created.status_code == 201
    item = created.json()
    assert item["name"] == "Washing machine"

    listed = client.get("/api/v1/items", headers=headers)
    assert listed.status_code == 200
    assert listed.json()["total"] == 1

    updated = client.patch(
        f"/api/v1/items/{item['id']}",
        headers=headers,
        json={"location": "Laundry room"},
    )
    assert updated.status_code == 200
    assert updated.json()["location"] == "Laundry room"

    archived = client.delete(f"/api/v1/items/{item['id']}", headers=headers)
    assert archived.status_code == 204

    listed_after_archive = client.get("/api/v1/items", headers=headers)
    assert listed_after_archive.json()["total"] == 0

    archived_items = client.get("/api/v1/items?archived=true", headers=headers)
    assert archived_items.status_code == 200
    assert archived_items.json()["total"] == 1
    assert archived_items.json()["items"][0]["id"] == item["id"]

    restored = client.post(f"/api/v1/items/{item['id']}/restore", headers=headers)
    assert restored.status_code == 200
    assert restored.json()["id"] == item["id"]

    listed_after_restore = client.get("/api/v1/items", headers=headers)
    assert listed_after_restore.json()["total"] == 1
    assert listed_after_restore.json()["items"][0]["location"] == "Laundry room"


def test_item_requires_authentication(client):
    response = client.get("/api/v1/items")
    assert response.status_code == 401
