import 'dart:convert';
import 'dart:typed_data';

class Piece {
  final int id;
  final int userId;
  final String title;
  final String? discipline;
  final String? year;
  final String? edition;
  final int priceCents;
  final int? oldPriceCents;
  final int? costPriceCents;
  final bool rental;
  final int stock;
  final List<String>? shipsTo;
  final String? packaging;
  final String status;
  final List<PieceImageData> images;
  final DateTime createdAt;

  const Piece({
    required this.id,
    required this.userId,
    required this.title,
    this.discipline,
    this.year,
    this.edition,
    required this.priceCents,
    this.oldPriceCents,
    this.costPriceCents,
    required this.rental,
    required this.stock,
    this.shipsTo,
    this.packaging,
    required this.status,
    this.images = const [],
    required this.createdAt,
  });

  factory Piece.fromJson(Map<String, dynamic> json) => Piece(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        title: json['title'] as String,
        discipline: json['discipline'] as String?,
        year: json['year'] as String?,
        edition: json['edition'] as String?,
        priceCents: json['price_cents'] as int,
        oldPriceCents: json['old_price_cents'] as int?,
        costPriceCents: json['cost_price_cents'] as int?,
        rental: json['rental'] as bool? ?? false,
        stock: json['stock'] as int? ?? 1,
        shipsTo: (json['ships_to'] as List?)?.cast<String>(),
        packaging: json['packaging'] as String?,
        status: json['status'] as String? ?? 'active',
        images: (json['images'] as List?)
                ?.map(
                    (i) => PieceImageData.fromJson(i as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  String get priceFormatted {
    final euros = priceCents ~/ 100;
    return '\u20AC$euros';
  }
}

/// Lightweight model for list views (maps to PieceListOut).
class PieceListItem {
  final int id;
  final String title;
  final String? discipline;
  final String? year;
  final int priceCents;
  final bool rental;
  final String status;
  final Uint8List? coverImageBytes;
  final DateTime createdAt;

  const PieceListItem({
    required this.id,
    required this.title,
    this.discipline,
    this.year,
    required this.priceCents,
    required this.rental,
    required this.status,
    this.coverImageBytes,
    required this.createdAt,
  });

  factory PieceListItem.fromJson(Map<String, dynamic> json) => PieceListItem(
        id: json['id'] as int,
        title: json['title'] as String,
        discipline: json['discipline'] as String?,
        year: json['year'] as String?,
        priceCents: json['price_cents'] as int,
        rental: json['rental'] as bool? ?? false,
        status: json['status'] as String? ?? 'active',
        coverImageBytes: json['cover_image_b64'] != null
            ? base64Decode(json['cover_image_b64'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  String get priceFormatted {
    final euros = priceCents ~/ 100;
    return '\u20AC$euros';
  }
}

class PieceImageData {
  final int id;
  final int position;
  final Uint8List bytes;

  const PieceImageData({
    required this.id,
    required this.position,
    required this.bytes,
  });

  factory PieceImageData.fromJson(Map<String, dynamic> json) => PieceImageData(
        id: json['id'] as int,
        position: json['position'] as int,
        bytes: base64Decode(json['image_b64'] as String),
      );
}
