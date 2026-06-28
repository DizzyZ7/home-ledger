import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/features/attachments/data/item_attachment_repository.dart';

void main() {
  test('remote repository loads typed attachment metadata from the item endpoint', () async {
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
                'items': [
                  {
                    'id': 'receipt-1',
                    'item_id': 'router-1',
                    'original_filename': 'receipt.pdf',
                    'content_type': 'application/pdf',
                    'size_bytes': 42,
                    'created_at': '2026-06-28T10:00:00Z',
                    'updated_at': '2026-06-28T10:00:00Z',
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final repository = RemoteItemAttachmentRepository(client);
    final attachments = await repository.load('router-1');

    expect(capturedRequest?.path, '/items/router-1/attachments');
    expect(attachments, hasLength(1));
    expect(attachments.single.originalFilename, 'receipt.pdf');
    expect(attachments.single.isPdf, isTrue);
  });

  test('remote repository uploads multipart bytes and downloads binary attachment data', () async {
    final client = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
    final requestedPaths = <String>[];
    var uploadWasMultipart = false;
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths.add(options.path);
          if (options.method == 'POST') {
            uploadWasMultipart = options.data is FormData;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'id': 'receipt-1',
                  'item_id': 'router-1',
                  'original_filename': 'receipt.pdf',
                  'content_type': 'application/pdf',
                  'size_bytes': 4,
                  'created_at': '2026-06-28T10:00:00Z',
                  'updated_at': '2026-06-28T10:00:00Z',
                },
              ),
            );
            return;
          }
          handler.resolve(
            Response<List<int>>(
              requestOptions: options,
              statusCode: 200,
              data: const [1, 2, 3, 4],
            ),
          );
        },
      ),
    );

    final repository = RemoteItemAttachmentRepository(client);
    final uploaded = await repository.upload(
      'router-1',
      AttachmentUpload(
        filename: 'receipt.pdf',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        contentType: 'application/pdf',
      ),
    );
    final downloaded = await repository.download('router-1', uploaded.id);

    expect(uploadWasMultipart, isTrue);
    expect(requestedPaths, [
      '/items/router-1/attachments',
      '/items/router-1/attachments/receipt-1/download',
    ]);
    expect(downloaded, orderedEquals([1, 2, 3, 4]));
  });
}
