from datetime import date


def _access_token(client) -> str:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "archive-maintenance@example.com",
            "display_name": "Archive maintenance owner",
            "password": "correct-horse-battery-staple",
        },
    )
    assert response.status_code == 201
    return response.json()["access_token"]


def _create_item(client, headers: dict[str, str]) -> dict:
    response = client.post(
        "/api/v1/items",
        headers=headers,
        json={"name": "Archived dishwasher", "category": "appliance"},
    )
    assert response.status_code == 201
    return response.json()


def _create_task(client, headers: dict[str, str], item_id: str) -> dict:
    response = client.post(
        "/api/v1/maintenance",
        headers=headers,
        json={
            "item_id": item_id,
            "title": "Clean dishwasher filter",
            "frequency_days": 90,
            "next_due_date": str(date.today()),
        },
    )
    assert response.status_code == 201
    return response.json()


def test_archived_items_hide_tasks_until_restored(client):
    token = _access_token(client)
    headers = {"Authorization": f"Bearer {token}"}
    item = _create_item(client, headers)
    task = _create_task(client, headers, item["id"])

    archive_response = client.delete(f"/api/v1/items/{item['id']}", headers=headers)
    assert archive_response.status_code == 204

    active_tasks = client.get("/api/v1/maintenance", headers=headers)
    assert active_tasks.status_code == 200
    assert active_tasks.json()["total"] == 0

    scoped_tasks = client.get(
        "/api/v1/maintenance",
        headers=headers,
        params={"item_id": item["id"]},
    )
    assert scoped_tasks.status_code == 200
    assert scoped_tasks.json()["total"] == 0

    create_for_archived = client.post(
        "/api/v1/maintenance",
        headers=headers,
        json={
            "item_id": item["id"],
            "title": "Should not be added",
            "frequency_days": 90,
            "next_due_date": str(date.today()),
        },
    )
    assert create_for_archived.status_code == 409
    assert create_for_archived.json()["detail"]["code"] == "item_archived"

    complete_archived_task = client.post(
        f"/api/v1/maintenance/{task['id']}/complete",
        headers=headers,
    )
    assert complete_archived_task.status_code == 409
    assert complete_archived_task.json()["detail"]["code"] == "item_archived"

    restore_response = client.post(f"/api/v1/items/{item['id']}/restore", headers=headers)
    assert restore_response.status_code == 200

    restored_tasks = client.get("/api/v1/maintenance", headers=headers)
    assert restored_tasks.status_code == 200
    assert restored_tasks.json()["total"] == 1
    assert restored_tasks.json()["items"][0]["id"] == task["id"]
