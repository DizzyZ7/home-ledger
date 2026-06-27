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


def test_complete_task_moves_next_due_date_by_frequency(client):
    token = _access_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    item_response = client.post(
        "/api/v1/items",
        headers=headers,
        json={"name": "Dishwasher", "category": "appliance"},
    )
    assert item_response.status_code == 201

    task_response = client.post(
        "/api/v1/maintenance",
        headers=headers,
        json={
            "item_id": item_response.json()["id"],
            "title": "Clean filter",
            "frequency_days": 90,
            "next_due_date": str(date.today()),
        },
    )
    assert task_response.status_code == 201

    completed_response = client.post(
        f"/api/v1/maintenance/{task_response.json()['id']}/complete",
        headers=headers,
    )

    assert completed_response.status_code == 200
    assert completed_response.json()["next_due_date"] == str(
        date.today() + timedelta(days=90)
    )
    assert completed_response.json()["completed_at"] is not None
