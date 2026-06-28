import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/core/storage/token_storage.dart';

class InMemorySecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}

void main() {
  test('persists and restores tokens with the current user session', () async {
    final store = InMemorySecureKeyValueStore();
    final storage = TokenStorage(store);
    const session = StoredSession(
      userId: 'user-1',
      email: 'owner@example.test',
      displayName: 'Owner',
    );

    await storage.save(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      session: session,
    );

    expect(await storage.readAccessToken(), 'access-token');
    expect(await storage.readRefreshToken(), 'refresh-token');
    expect(await storage.readSession(), isA<StoredSession>());
    final restored = await storage.readSession();
    expect(restored?.userId, session.userId);
    expect(restored?.email, session.email);
    expect(restored?.displayName, session.displayName);
  });

  test('drops an invalid stored session instead of restoring partial data', () async {
    final store = InMemorySecureKeyValueStore()
      ..values['homeledger_session_v1'] = '{"user_id": 42}';
    final storage = TokenStorage(store);

    expect(await storage.readSession(), isNull);
    expect(store.values, isNot(contains('homeledger_session_v1')));
  });

  test('clears access, refresh and session data together', () async {
    final store = InMemorySecureKeyValueStore();
    final storage = TokenStorage(store);

    await storage.save(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      session: const StoredSession(
        userId: 'user-1',
        email: 'owner@example.test',
        displayName: 'Owner',
      ),
    );
    await storage.clear();

    expect(store.values, isEmpty);
  });
}
