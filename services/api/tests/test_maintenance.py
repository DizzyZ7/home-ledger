from datetime import date, timedelta


def _access_token(client) -> str:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "maintenance@example.com",
            "display_name": "Maintenance owner",
            "password": "correct-horse-battery-staple",
        },
    )
    assert response.status_code == 201
    return response.json()["access_token"]


def _create_item(client, headers: dict[str, str], name: str) -> dict:
    response = client.post(
        "/api/v1/items",
        headers=headers,
        json={"name": name, "category": "appliance"},
    )
    assert response.status_code == 201
    return response.json()


def _create_task(client, headers: dict[str, str], item_id: str, title: str) -> dict:
    response = client.post(
        "/api/v1/maintenance",
        headers=headers,
        json={
            "item_id": item_id,
            "title": title,
            "frequency_days": 90,
            "next_due_date": str(date.today()),
        },
    )
    assert response.status_code == 201
    return response.json()


def test_complete_task_moves_next_due_date_by_frequency(client):
    token = _access_token(client)
    headers = {"Authorization": f"Bearer {token}"}
    item = _create_item(client, headers, "Dishwasher")
    task = _create_task(client, headers, item["id"], "Clean filter")

    assert task["item_name"] == "Dishwasher"

    listed_response = client.get("/api/v1/maintenance", headers=headers)
    assert listed_response.status_code == 200
    assert listed_response.json()["items"][0]["item_name"] == "Dishwasher"

    completed_response = client.post(
        f"/api/v1/maintenance/{task['id']}/complete",
        headers=headers,
    )

    assert completed_response.status_code == 200
    assert completed_response.json()["item_name"] == "Dishwasher"
    assert completed_response.json()["next_due_date"] == str(date.today() + timedelta(days=90))
    assert completed_response.json()["completed_at"] is not None


def test_list_tasks_can_filter_by_linked_item(client):
    token = _access_token(client)
    headers = {"Authorization": f"Bearer {token}"}
    dishwasher = _create_item(client, headers, "Dishwasher")
    coffee_machine = _create_item(client, headers, "Coffee machine")
    dishwasher_task = _create_task(client, headers, dishwasher["id"], "Clean dishwasher filter")
    _create_task(client, headers, coffee_machine["id"], "Descale coffee machine")

    response = client.get(
        "/api/v1/maintenance",
        headers=headers,
        params={"item_id": dishwasher["id"]},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["total"] == 1
    assert payload["items"][0]["id"] == dishwasher_task["id"]
    assert payload["items"][0]["item_name"] == "Dishwasher"
