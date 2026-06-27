def test_refresh_rejects_an_access_token(client):
    registration = client.post(
        '/api/v1/auth/register',
        json={
            'email': 'tokens@example.com',
            'display_name': 'Token owner',
            'password': 'correct-horse-battery-staple',
        },
    )
    assert registration.status_code == 201

    response = client.post(
        '/api/v1/auth/refresh',
        json={'refresh_token': registration.json()['access_token']},
    )

    assert response.status_code == 401
    assert response.json()['detail']['code'] == 'invalid_refresh_token'
