import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../data/item_attachment_repository.dart';
import '../domain/item_attachment.dart';
import 'attachment_localizations.dart';
import 'item_attachments_provider.dart';

class ItemAttachmentsSection extends ConsumerStatefulWidget {
  const ItemAttachmentsSection({required this.itemId, super.key});

  final String itemId;

  @override
  ConsumerState<ItemAttachmentsSection> createState() => _ItemAttachmentsSectionState();
}

class _ItemAttachmentsSectionState extends ConsumerState<ItemAttachmentsSection> {
  var _uploading = false;
  String? _pendingAttachmentId;

  Future<void> _pickAndUpload() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }

    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        _showError(context.l10n.attachmentPickerFailed);
      }
      return;
    }

    setState(() => _uploading = true);
    try {
      await ref.read(itemAttachmentRepositoryProvider).upload(
            widget.itemId,
            AttachmentUpload(
              filename: file.name,
              bytes: bytes,
              contentType: _contentTypeFor(file.name),
            ),
          );
      ref.invalidate(itemAttachmentsProvider(widget.itemId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.attachmentAdded)),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        _showError(error.message);
      }
    } on Object {
      if (mounted) {
        _showError(context.l10n.errorGeneric);
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _open(ItemAttachment attachment) async {
    setState(() => _pendingAttachmentId = attachment.id);
    try {
      final bytes = await ref
          .read(itemAttachmentRepositoryProvider)
          .download(widget.itemId, attachment.id);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${_downloadFilename(attachment)}');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFilex.open(file.path);
    } on ApiException catch (error) {
      if (mounted) {
        _showError(error.message);
      }
    } on Object {
      if (mounted) {
        _showError(context.l10n.attachmentOpenFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _pendingAttachmentId = null);
      }
    }
  }

  Future<void> _confirmDelete(ItemAttachment attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.deleteAttachmentTitle),
        content: Text(dialogContext.l10n.deleteAttachmentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.deleteAttachment),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _pendingAttachmentId = attachment.id);
    try {
      await ref
          .read(itemAttachmentRepositoryProvider)
          .delete(widget.itemId, attachment.id);
      ref.invalidate(itemAttachmentsProvider(widget.itemId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.attachmentDeleted)),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        _showError(error.message);
      }
    } on Object {
      if (mounted) {
        _showError(context.l10n.errorGeneric);
      }
    } finally {
      if (mounted) {
        setState(() => _pendingAttachmentId = null);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final attachments = ref.watch(itemAttachmentsProvider(widget.itemId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.attachments,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('item-attachment-upload-action'),
                  onPressed: _uploading ? null : _pickAndUpload,
                  icon: _uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file_outlined),
                  label: Text(l10n.addAttachment),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.attachmentTypesHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            attachments.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.errorGeneric),
                  TextButton(
                    onPressed: () => ref.invalidate(itemAttachmentsProvider(widget.itemId)),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
              data: (data) {
                if (data.isEmpty) {
                  return Text(l10n.noAttachments);
                }
                return Column(
                  children: [
                    for (final attachment in data)
                      _AttachmentTile(
                        attachment: attachment,
                        pending: _pendingAttachmentId == attachment.id,
                        onOpen: () => _open(attachment),
                        onDelete: () => _confirmDelete(attachment),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _contentTypeFor(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return switch (extension) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }

  String _downloadFilename(ItemAttachment attachment) {
    final safeName = attachment.originalFilename.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );
    return 'homeledger-${attachment.id}-$safeName';
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.pending,
    required this.onOpen,
    required this.onDelete,
  });

  final ItemAttachment attachment;
  final bool pending;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localizations = MaterialLocalizations.of(context);
    final metadata = '${_formatBytes(attachment.sizeBytes)} · '
        '${localizations.formatMediumDate(attachment.createdAt.toLocal())}';

    return ListTile(
      key: ValueKey('item-attachment-${attachment.id}'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        attachment.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
      ),
      title: Text(
        attachment.originalFilename,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(metadata),
      onTap: pending ? null : onOpen,
      trailing: pending
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.openAttachment,
                  icon: const Icon(Icons.open_in_new_outlined),
                  onPressed: onOpen,
                ),
                IconButton(
                  tooltip: l10n.deleteAttachment,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
