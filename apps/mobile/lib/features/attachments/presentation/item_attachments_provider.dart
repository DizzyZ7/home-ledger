import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/item_attachment_repository.dart';
import '../domain/item_attachment.dart';

final itemAttachmentsProvider =
    FutureProvider.autoDispose.family<List<ItemAttachment>, String>((ref, itemId) {
  return ref.watch(itemAttachmentRepositoryProvider).load(itemId);
});
