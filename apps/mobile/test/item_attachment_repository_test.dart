import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/features/attachments/data/item_attachment_repository.dart';

void main() {
  test('mock attachment repository uploads, downloads and deletes an item receipt', () async {
    final repository = MockItemAttachmentRepository();
    final bytes = Uint8List.fromList([1, 2, 3, 4]);

    final created = await repository.upload(
      'router',
      AttachmentUpload(
        filename: 'receipt.pdf',
        bytes: bytes,
        contentType: 'application/pdf',
      ),
    );

    expect((await repository.load('router')).single.id, created.id);
    expect(await repository.download('router', created.id), bytes);

    await repository.delete('router', created.id);
    expect(await repository.load('router'), isEmpty);
  });
}
