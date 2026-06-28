from pathlib import Path

import pytest

from app.core.config import get_settings


def _access_token(client, *, email: str) -> str:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "display_name": "Attachment owner",
            "password": "correct-horse-battery-staple",
        },
    )
    assert response.status_code == 201
    return response.json()["access_token"]


def _create_item(client, headers: dict[str, str]) -> dict:
    response = client.post(
        "/api/v1/items",
        headers=headers,
        json={"name": "Air purifier", "category": "appliance"},
    )
    assert response.status_code == 201
    return response.json()


@pytest.fixture
def attachment_directory(monkeypatch, tmp_path: Path):
    monkeypatch.setenv("ATTACHMENT_STORAGE_PATH", str(tmp_path))
    monkeypatch.setenv("ATTACHMENT_MAX_BYTES", "10485760")
    get_settings.cache_clear()
    yield tmp_path
    get_settings.cache_clear()


def test_upload_list_download_and_delete_item_attachment(client, attachment_directory):
    token = _access_token(client, email="attachment-owner@example.com")
    headers = {"Authorization": f"Bearer {token}"}
    item = _create_item(client, headers)
    receipt_bytes = b"%PDF-1.7\nHomeLedger receipt\n"

    uploaded = client.post(
        f"/api/v1/items/{item['id']}/attachments",
        headers=headers,
        files={"file": ("receipt.pdf", receipt_bytes, "application/pdf")},
    )

    assert uploaded.status_code == 201
    attachment = uploaded.json()
    assert attachment["item_id"] == item["id"]
    assert attachment["original_filename"] == "receipt.pdf"
    assert attachment["content_type"] == "application/pdf"
    assert attachment["size_bytes"] == len(receipt_bytes)
    assert len(list(attachment_directory.iterdir())) == 1

    listed = client.get(f"/api/v1/items/{item['id']}/attachments", headers=headers)
    assert listed.status_code == 200
    assert listed.json()["total"] == 1
    assert listed.json()["items"][0]["id"] == attachment["id"]

    downloaded = client.get(
        f"/api/v1/items/{item['id']}/attachments/{attachment['id']}/download",
        headers=headers,
    )
    assert downloaded.status_code == 200
    assert downloaded.content == receipt_bytes
    assert downloaded.headers["content-type"].startswith("application/pdf")
    assert "receipt.pdf" in downloaded.headers["content-disposition"]

    deleted = client.delete(
        f"/api/v1/items/{item['id']}/attachments/{attachment['id']}",
        headers=headers,
    )
    assert deleted.status_code == 204
    assert list(attachment_directory.iterdir()) == []
    assert client.get(f"/api/v1/items/{item['id']}/attachments", headers=headers).json()["total"] == 0


def test_attachment_endpoints_hide_other_households_data(client, attachment_directory):
    owner_token = _access_token(client, email="attachment-owner@example.com")
    owner_headers = {"Authorization": f"Bearer {owner_token}"}
    item = _create_item(client, owner_headers)
    uploaded = client.post(
        f"/api/v1/items/{item['id']}/attachments",
        headers=owner_headers,
        files={"file": ("receipt.pdf", b"%PDF-1.7", "application/pdf")},
    )
    assert uploaded.status_code == 201

    other_token = _access_token(client, email="another-owner@example.com")
    other_headers = {"Authorization": f"Bearer {other_token}"}

    assert client.get(f"/api/v1/items/{item['id']}/attachments", headers=other_headers).status_code == 404
    assert (
        client.get(
            f"/api/v1/items/{item['id']}/attachments/{uploaded.json()['id']}/download",
            headers=other_headers,
        ).status_code
        == 404
    )


def test_attachment_upload_rejects_unsupported_type_and_oversized_file(
    client,
    attachment_directory,
    monkeypatch,
):
    token = _access_token(client, email="attachment-owner@example.com")
    headers = {"Authorization": f"Bearer {token}"}
    item = _create_item(client, headers)

    unsupported = client.post(
        f"/api/v1/items/{item['id']}/attachments",
        headers=headers,
        files={"file": ("receipt.txt", b"not a receipt", "text/plain")},
    )
    assert unsupported.status_code == 415

    monkeypatch.setenv("ATTACHMENT_MAX_BYTES", "5")
    get_settings.cache_clear()
    too_large = client.post(
        f"/api/v1/items/{item['id']}/attachments",
        headers=headers,
        files={"file": ("receipt.pdf", b"123456", "application/pdf")},
    )
    assert too_large.status_code == 413
    assert list(attachment_directory.iterdir()) == []
