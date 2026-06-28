class ItemAttachment {
  const ItemAttachment({
    required this.id,
    required this.itemId,
    required this.originalFilename,
    required this.contentType,
    required this.sizeBytes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String itemId;
  final String originalFilename;
  final String contentType;
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPdf => contentType == 'application/pdf';

  bool get isImage => contentType.startsWith('image/');

  factory ItemAttachment.fromJson(Map<String, dynamic> json) {
    return ItemAttachment(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      originalFilename: json['original_filename'] as String,
      contentType: json['content_type'] as String,
      sizeBytes: json['size_bytes'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
