from datetime import date, timedelta


def _access_token(client) -> str:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "warranty@example.com",
            "display_name": "Warranty owner",
            "password": "correct-horse-battery-staple",
        },
    )
    assert response.status_code == 201
    return response.json()["access_token"]


def _create_item(client, headers: dict[str, str], name: str, warranty_expires_at: date | None = None) -> dict:
    payload = {"name": name, "category": "appliance"}
    if warranty_expires_at is not None:
        payload["warranty_expires_at"] = str(warranty_expires_at)
    response = client.post("/api/v1/items", headers=headers, json=payload)
    assert response.status_code == 201
    return response.json()


def test_list_items_can_filter_by_warranty_state(client):
    token = _access_token(client)
    headers = {"Authorization": f"Bearer {token}"}
    today = date.today()

    _create_item(client, headers, "Expired blender", today - timedelta(days=1))
    _create_item(client, headers, "Soon toaster", today + timedelta(days=2))
    _create_item(client, headers, "Later toaster", today + timedelta(days=15))
    _create_item(client, headers, "Protected washer", today + timedelta(days=46))
    _create_item(client, headers, "Paper towel holder")

    expired = client.get("/api/v1/items", headers=headers, params={"warranty_state": "expired"})
    assert expired.status_code == 200
    assert [item["name"] for item in expired.json()["items"]] == ["Expired blender"]

    expiring = client.get(
        "/api/v1/items",
        headers=headers,
        params={"warranty_state": "expiring", "warranty_window_days": 45},
    )
    assert expiring.status_code == 200
    assert [item["name"] for item in expiring.json()["items"]] == ["Soon toaster", "Later toaster"]

    valid = client.get("/api/v1/items", headers=headers, params={"warranty_state": "valid"})
    assert valid.status_code == 200
    assert [item["name"] for item in valid.json()["items"]] == ["Protected washer"]

    without_warranty = client.get("/api/v1/items", headers=headers, params={"warranty_state": "none"})
    assert without_warranty.status_code == 200
    assert [item["name"] for item in without_warranty.json()["items"]] == ["Paper towel holder"]
