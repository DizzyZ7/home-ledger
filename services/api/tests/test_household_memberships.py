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


def test_owner_can_share_a_household_and_member_can_switch_to_it(client):
    owner = _register(client, email="owner@example.com", display_name="Owner")
    member = _register(client, email="member@example.com", display_name="Member")
    owner_headers = _headers(owner)
    member_headers = _headers(member)

    shared_item = client.post(
        "/api/v1/items",
        headers=owner_headers,
        json={"name": "Shared kettle", "category": "appliance"},
    )
    assert shared_item.status_code == 201

    owner_household = client.get("/api/v1/households/current", headers=owner_headers)
    assert owner_household.status_code == 200
    household_id = owner_household.json()["id"]
    assert owner_household.json()["members"][0]["role"] == "owner"

    added_member = client.post(
        "/api/v1/households/current/members",
        headers=owner_headers,
        json={"email": "member@example.com"},
    )
    assert added_member.status_code == 201
    assert added_member.json()["user_id"] == member["user"]["id"]
    assert added_member.json()["role"] == "member"

    memberships = client.get("/api/v1/households", headers=member_headers)
    assert memberships.status_code == 200
    assert len(memberships.json()) == 2
    assert [household["id"] for household in memberships.json() if household["is_active"]] != [household_id]

    selected = client.post(f"/api/v1/households/{household_id}/select", headers=member_headers)
    assert selected.status_code == 200
    assert selected.json()["is_active"] is True
    assert selected.json()["role"] == "member"

    shared_inventory = client.get("/api/v1/items", headers=member_headers)
    assert shared_inventory.status_code == 200
    assert [item["name"] for item in shared_inventory.json()["items"]] == ["Shared kettle"]

    member_item = client.post(
        "/api/v1/items",
        headers=member_headers,
        json={"name": "Member vacuum", "category": "appliance"},
    )
    assert member_item.status_code == 201

    owner_inventory = client.get("/api/v1/items", headers=owner_headers)
    assert owner_inventory.status_code == 200
    assert {item["name"] for item in owner_inventory.json()["items"]} == {"Shared kettle", "Member vacuum"}

    forbidden_invite = client.post(
        "/api/v1/households/current/members",
        headers=member_headers,
        json={"email": "owner@example.com"},
    )
    assert forbidden_invite.status_code == 403
    assert forbidden_invite.json()["detail"]["code"] == "household_owner_required"

    removed_member = client.delete(
        f"/api/v1/households/current/members/{member['user']['id']}",
        headers=owner_headers,
    )
    assert removed_member.status_code == 204

    member_households_after_removal = client.get("/api/v1/households", headers=member_headers)
    assert member_households_after_removal.status_code == 200
    assert len(member_households_after_removal.json()) == 1
    assert member_households_after_removal.json()[0]["is_active"] is True


def test_user_can_create_and_rename_a_separate_household(client):
    user = _register(client, email="homes@example.com", display_name="Homes")
    headers = _headers(user)

    original_item = client.post(
        "/api/v1/items",
        headers=headers,
        json={"name": "Apartment kettle", "category": "appliance"},
    )
    assert original_item.status_code == 201

    created = client.post(
        "/api/v1/households",
        headers=headers,
        json={"name": "  Country house  "},
    )
    assert created.status_code == 201
    assert created.json()["name"] == "Country house"
    assert created.json()["role"] == "owner"
    assert created.json()["is_active"] is True
    country_house_id = created.json()["id"]

    homes = client.get("/api/v1/households", headers=headers)
    assert homes.status_code == 200
    assert len(homes.json()) == 2
    assert [home["id"] for home in homes.json() if home["is_active"]] == [country_house_id]

    country_house_inventory = client.get("/api/v1/items", headers=headers)
    assert country_house_inventory.status_code == 200
    assert country_house_inventory.json()["items"] == []

    renamed = client.patch(
        "/api/v1/households/current",
        headers=headers,
        json={"name": "Dacha"},
    )
    assert renamed.status_code == 200
    assert renamed.json()["id"] == country_house_id
    assert renamed.json()["name"] == "Dacha"
    assert renamed.json()["is_active"] is True

    switched_back = client.post(
        f"/api/v1/households/{homes.json()[0]['id']}/select",
        headers=headers,
    )
    assert switched_back.status_code == 200
    apartment_inventory = client.get("/api/v1/items", headers=headers)
    assert apartment_inventory.status_code == 200
    assert [item["name"] for item in apartment_inventory.json()["items"]] == ["Apartment kettle"]


def test_member_cannot_rename_shared_household(client):
    owner = _register(client, email="rename-owner@example.com", display_name="Owner")
    member = _register(client, email="rename-member@example.com", display_name="Member")
    owner_headers = _headers(owner)
    member_headers = _headers(member)

    shared_household = client.get("/api/v1/households/current", headers=owner_headers).json()
    invited = client.post(
        "/api/v1/households/current/members",
        headers=owner_headers,
        json={"email": "rename-member@example.com"},
    )
    assert invited.status_code == 201

    selected = client.post(
        f"/api/v1/households/{shared_household['id']}/select",
        headers=member_headers,
    )
    assert selected.status_code == 200

    forbidden = client.patch(
        "/api/v1/households/current",
        headers=member_headers,
        json={"name": "Not allowed"},
    )
    assert forbidden.status_code == 403
    assert forbidden.json()["detail"]["code"] == "household_owner_required"
