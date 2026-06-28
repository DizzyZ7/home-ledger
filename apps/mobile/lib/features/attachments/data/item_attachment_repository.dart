import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/item_attachment.dart';

class AttachmentUpload {
  const AttachmentUpload({
    required this.filename,
    required this.bytes,
    required this.contentType,
  });

  final String filename;
  final Uint8List bytes;
  final String contentType;
}

abstract interface class ItemAttachmentRepository {
  Future<List<ItemAttachment>> load(String itemId);
  Future<ItemAttachment> upload(String itemId, AttachmentUpload upload);
  Future<Uint8List> download(String itemId, String attachmentId);
  Future<void> delete(String itemId, String attachmentId);
}

class RemoteItemAttachmentRepository implements ItemAttachmentRepository {
  RemoteItemAttachmentRepository(this._client);

  final Dio _client;

  @override
  Future<List<ItemAttachment>> load(String itemId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/items/$itemId/attachments');
      final items = response.data?['items'];
      if (items is! List<dynamic>) {
        return const [];
      }
      return items
          .whereType<Map<String, dynamic>>()
          .map(ItemAttachment.fromJson)
          .toList(growable: false);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<ItemAttachment> upload(String itemId, AttachmentUpload upload) async {
    try {
      final body = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          upload.bytes,
          filename: upload.filename,
          contentType: MediaType.parse(upload.contentType),
        ),
      });
      final response = await _client.post<Map<String, dynamic>>(
        '/items/$itemId/attachments',
        data: body,
      );
      final payload = response.data;
      if (payload == null) {
        throw const ApiException('Empty attachment response.');
      }
      return ItemAttachment.fromJson(payload);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<Uint8List> download(String itemId, String attachmentId) async {
    try {
      final response = await _client.get<List<int>>(
        '/items/$itemId/attachments/$attachmentId/download',
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException('Empty attachment download response.');
      }
      return Uint8List.fromList(data);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<void> delete(String itemId, String attachmentId) async {
    try {
      await _client.delete<void>('/items/$itemId/attachments/$attachmentId');
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }
}

class MockItemAttachmentRepository implements ItemAttachmentRepository {
  final Map<String, List<_MockStoredAttachment>> _attachmentsByItem = {};
  var _nextId = 1;

  @override
  Future<List<ItemAttachment>> load(String itemId) async {
    final attachments = _attachmentsByItem[itemId] ?? const <_MockStoredAttachment>[];
    return attachments.map((stored) => stored.attachment).toList(growable: false);
  }

  @override
  Future<ItemAttachment> upload(String itemId, AttachmentUpload upload) async {
    final now = DateTime.now().toUtc();
    final attachment = ItemAttachment(
      id: 'demo-attachment-${_nextId++}',
      itemId: itemId,
      originalFilename: upload.filename,
      contentType: upload.contentType,
      sizeBytes: upload.bytes.lengthInBytes,
      createdAt: now,
      updatedAt: now,
    );
    _attachmentsByItem.putIfAbsent(itemId, () => []).insert(
          0,
          _MockStoredAttachment(attachment: attachment, bytes: upload.bytes),
        );
    return attachment;
  }

  @override
  Future<Uint8List> download(String itemId, String attachmentId) async {
    final attachment = _find(itemId, attachmentId);
    if (attachment == null) {
      throw const ApiException('Attachment was not found.');
    }
    return attachment.bytes;
  }

  @override
  Future<void> delete(String itemId, String attachmentId) async {
    final attachments = _attachmentsByItem[itemId];
    if (attachments == null) {
      throw const ApiException('Attachment was not found.');
    }
    final index = attachments.indexWhere((stored) => stored.attachment.id == attachmentId);
    if (index == -1) {
      throw const ApiException('Attachment was not found.');
    }
    attachments.removeAt(index);
  }

  _MockStoredAttachment? _find(String itemId, String attachmentId) {
    final attachments = _attachmentsByItem[itemId];
    if (attachments == null) {
      return null;
    }
    for (final attachment in attachments) {
      if (attachment.attachment.id == attachmentId) {
        return attachment;
      }
    }
    return null;
  }
}

class _MockStoredAttachment {
  const _MockStoredAttachment({required this.attachment, required this.bytes});

  final ItemAttachment attachment;
  final Uint8List bytes;
}

final itemAttachmentRepositoryProvider = Provider<ItemAttachmentRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockItemAttachmentRepository();
  }
  return RemoteItemAttachmentRepository(ref.watch(apiClientProvider));
});
