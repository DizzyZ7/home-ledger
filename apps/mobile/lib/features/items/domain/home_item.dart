import 'package:flutter/foundation.dart';

@immutable
class HomeItem {
  const HomeItem({
    required this.id,
    required this.name,
    required this.category,
    this.location,
    this.serialNumber,
    this.purchaseDate,
    this.warrantyExpiresAt,
    this.notes,
  });

  final String id;
  final String name;
  final String category;
  final String? location;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final DateTime? warrantyExpiresAt;
  final String? notes;

  factory HomeItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? value) => value is String ? DateTime.tryParse(value) : null;

    return HomeItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'other',
      location: json['location'] as String?,
      serialNumber: json['serial_number'] as String?,
      purchaseDate: parseDate(json['purchase_date']),
      warrantyExpiresAt: parseDate(json['warranty_expires_at']),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'location': location,
        'serial_number': serialNumber,
        'purchase_date': purchaseDate?.toIso8601String(),
        'warranty_expires_at': warrantyExpiresAt?.toIso8601String(),
        'notes': notes,
      };

  Map<String, dynamic> toCreatePayload() => {
        'name': name,
        'category': category,
        'location': location,
        'serial_number': serialNumber,
        'purchase_date': _dateOnly(purchaseDate),
        'warranty_expires_at': _dateOnly(warrantyExpiresAt),
        'notes': notes,
      };

  Map<String, dynamic> toUpdatePayload() => toCreatePayload();

  static String? _dateOnly(DateTime? value) {
    if (value == null) {
      return null;
    }
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  HomeItem copyWith({
    String? id,
    String? name,
    String? category,
    String? location,
    String? serialNumber,
    DateTime? purchaseDate,
    DateTime? warrantyExpiresAt,
    String? notes,
  }) {
    return HomeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      serialNumber: serialNumber ?? this.serialNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyExpiresAt: warrantyExpiresAt ?? this.warrantyExpiresAt,
      notes: notes ?? this.notes,
    );
  }
}
