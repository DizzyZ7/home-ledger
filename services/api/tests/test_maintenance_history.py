from datetime import date


def _access_token(client) -> str:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "history@example.com",
            "display_name": "History owner",
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


def _complete_task(client, headers: dict[str, str], task_id: str) -> dict:
    response = client.post(f"/api/v1/maintenance/{task_id}/complete", headers=headers)
    assert response.status_code == 200
    return response.json()


def test_completion_history_records_each_finished_task_and_supports_item_filter(client):
    token = _access_token(client)
    headers = {"Authorization": f"Bearer {token}"}
    dishwasher = _create_item(client, headers, "Dishwasher")
    coffee_machine = _create_item(client, headers, "Coffee machine")
    dishwasher_task = _create_task(client, headers, dishwasher["id"], "Clean dishwasher filter")
    coffee_task = _create_task(client, headers, coffee_machine["id"], "Descale coffee machine")

    _complete_task(client, headers, dishwasher_task["id"])
    _complete_task(client, headers, coffee_task["id"])
    _complete_task(client, headers, dishwasher_task["id"])

    history_response = client.get("/api/v1/maintenance/history", headers=headers)
    assert history_response.status_code == 200
    history = history_response.json()
    assert history["total"] == 3
    assert {record["task_id"] for record in history["items"]} == {
        dishwasher_task["id"],
        coffee_task["id"],
    }
    assert sum(record["task_id"] == dishwasher_task["id"] for record in history["items"]) == 2
    assert all(record["completed_at"] is not None for record in history["items"])

    dishwasher_history = client.get(
        "/api/v1/maintenance/history",
        headers=headers,
        params={"item_id": dishwasher["id"]},
    )
    assert dishwasher_history.status_code == 200
    scoped = dishwasher_history.json()
    assert scoped["total"] == 2
    assert all(record["item_id"] == dishwasher["id"] for record in scoped["items"])
    assert all(record["item_name"] == "Dishwasher" for record in scoped["items"])
    assert all(record["task_title"] == "Clean dishwasher filter" for record in scoped["items"])
