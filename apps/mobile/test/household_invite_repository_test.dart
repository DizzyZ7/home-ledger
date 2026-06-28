import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/features/households/data/household_repository.dart';

void main() {
  test('remote household repository creates and lists invite codes', () async {
    final client = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
    final requestedPaths = <String>[];
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths.add(options.path);
          if (options.method == 'POST') {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'id': 'invite-1',
                  'code': 'HL-ABCD-EFGH-JKLM-NPQR-STUV',
                  'expires_at': '2026-06-29T12:00:00Z',
                  'created_at': '2026-06-28T12:00:00Z',
                },
              ),
            );
            return;
          }
          handler.resolve(
            Response<List<dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: [
                {
                  'id': 'invite-1',
                  'expires_at': '2026-06-29T12:00:00Z',
                  'created_at': '2026-06-28T12:00:00Z',
                },
              ],
            ),
          );
        },
      ),
    );

    final repository = RemoteHouseholdRepository(client);
    final created = await repository.createInvite(expiresInHours: 24);
    final invites = await repository.loadInvites();

    expect(created.code, 'HL-ABCD-EFGH-JKLM-NPQR-STUV');
    expect(invites.single.id, 'invite-1');
    expect(requestedPaths, [
      '/households/current/invites',
      '/households/current/invites',
    ]);
  });

  test('remote household repository accepts an invitation code', () async {
    final client = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
    RequestOptions? capturedRequest;
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 'shared-household',
                'name': 'Shared home',
                'owner_id': 'owner-1',
                'role': 'member',
                'is_active': true,
                'created_at': '2026-06-28T12:00:00Z',
              },
            ),
          );
        },
      ),
    );

    final joined = await RemoteHouseholdRepository(client).acceptInvite('HL-ABCD-EFGH-JKLM-NPQR-STUV');

    expect(capturedRequest?.path, '/households/invites/accept');
    expect(capturedRequest?.data, {'code': 'HL-ABCD-EFGH-JKLM-NPQR-STUV'});
    expect(joined.isActive, isTrue);
    expect(joined.id, 'shared-household');
  });
}
