def _register(client, email: str) -> str:
    response = client.post(
        '/api/v1/auth/register',
        json={
            'email': email,
            'display_name': email.split('@')[0],
            'password': 'correct-horse-battery-staple',
        },
    )
    assert response.status_code == 201
    return response.json()['access_token']


def test_user_cannot_read_another_users_item(client):
    owner_token = _register(client, 'owner@example.com')
    other_token = _register(client, 'other@example.com')

    created = client.post(
        '/api/v1/items',
        headers={'Authorization': f'Bearer {owner_token}'},
        json={'name': 'Private router', 'category': 'electronics'},
    )
    assert created.status_code == 201

    item_id = created.json()['id']
    response = client.get(
        f'/api/v1/items/{item_id}',
        headers={'Authorization': f'Bearer {other_token}'},
    )

    assert response.status_code == 404
    assert response.json()['detail']['code'] == 'item_not_found'
