import csv
from io import StringIO


def _register(client, *, email: str) -> str:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "display_name": email.split("@")[0],
            "password": "correct-horse-battery-staple",
        },
    )
    assert response.status_code == 201
    return response.json()["access_token"]


def _headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _csv_rows(response) -> list[list[str]]:
    return list(csv.reader(StringIO(response.text)))


def test_export_returns_only_active_household_items_and_neutralizes_formulas(client):
    owner_token = _register(client, email="export-owner@example.com")
    other_token = _register(client, email="export-other@example.com")
    owner_headers = _headers(owner_token)

    exported_item = client.post(
        "/api/v1/items",
        headers=owner_headers,
        json={
            "name": "=SUM(1,1)",
            "category": "appliance",
            "location": "Kitchen",
            "notes": "@spreadsheet-formula",
        },
    )
    assert exported_item.status_code == 201

    archived_item = client.post(
        "/api/v1/items",
        headers=owner_headers,
        json={"name": "Archived router", "category": "electronics"},
    )
    assert archived_item.status_code == 201
    archived = client.delete(f"/api/v1/items/{archived_item.json()['id']}", headers=owner_headers)
    assert archived.status_code == 204

    other_item = client.post(
        "/api/v1/items",
        headers=_headers(other_token),
        json={"name": "Other household item", "category": "other"},
    )
    assert other_item.status_code == 201

    exported = client.get("/api/v1/items/export", headers=owner_headers)
    assert exported.status_code == 200
    assert exported.headers["content-type"].startswith("text/csv")
    assert exported.headers["content-disposition"] == 'attachment; filename="homeledger-inventory.csv"'

    rows = _csv_rows(exported)
    assert rows[0] == [
        "name",
        "category",
        "location",
        "serial_number",
        "purchase_date",
        "warranty_expires_at",
        "notes",
        "archived",
    ]
    assert rows[1] == ["'=SUM(1,1)", "appliance", "Kitchen", "", "", "", "'@spreadsheet-formula", "no"]
    assert "Archived router" not in exported.text
    assert "Other household item" not in exported.text

    exported_with_archived = client.get("/api/v1/items/export?include_archived=true", headers=owner_headers)
    assert exported_with_archived.status_code == 200
    archived_rows = _csv_rows(exported_with_archived)
    assert [row[0] for row in archived_rows[1:]] == ["Archived router", "'=SUM(1,1)"]
    assert archived_rows[1][-1] == "yes"
