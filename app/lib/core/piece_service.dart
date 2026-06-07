import 'package:flutter/foundation.dart';

import '../models/piece.dart';
import 'api_client.dart';

// ═════════════════════════════════════════════════════════════
// ── PieceService (singleton ChangeNotifier) ──────────────────
// ═════════════════════════════════════════════════════════════

class PieceService extends ChangeNotifier {
  static final PieceService _instance = PieceService._();
  static PieceService get instance => _instance;
  PieceService._();

  bool _publishing = false;
  bool get publishing => _publishing;

  // ── My pieces list ─────────────────────────────────────────
  List<PieceListItem> _pieces = [];
  List<PieceListItem> get pieces => _pieces;

  bool _loadingPieces = false;
  bool get loadingPieces => _loadingPieces;

  /// Fetch the current user's pieces from the backend.
  Future<void> fetchMyPieces() async {
    _loadingPieces = true;
    notifyListeners();

    try {
      final data = await ApiClient.instance.get('/pieces');
      _pieces = (data as List)
          .map((j) => PieceListItem.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Silently keep existing list on failure
    }

    _loadingPieces = false;
    notifyListeners();
  }

  /// Fetch a single piece with all images.
  Future<Piece> fetchPiece(int pieceId) async {
    final data = await ApiClient.instance.get('/pieces/$pieceId');
    return Piece.fromJson(data as Map<String, dynamic>);
  }

  /// Update piece metadata (partial).
  Future<void> updatePiece(int pieceId, Map<String, dynamic> data) async {
    await ApiClient.instance.patch('/pieces/$pieceId', data);
  }

  /// Delete a single image from a piece.
  Future<void> deleteImage(int pieceId, int imageId) async {
    await ApiClient.instance.delete('/pieces/$pieceId/images/$imageId');
  }

  /// Upload new images to an existing piece.
  Future<void> uploadImages(int pieceId, List<Uint8List> files) async {
    if (files.isEmpty) return;
    await ApiClient.instance.postMultipartMultiFile(
      '/pieces/$pieceId/images',
      files: files,
      fileField: 'files',
    );
  }

  /// Delete a piece by ID.
  Future<void> deletePiece(int pieceId) async {
    await ApiClient.instance.delete('/pieces/$pieceId');
    _pieces.removeWhere((p) => p.id == pieceId);
    notifyListeners();
  }

  /// Create piece (metadata) + upload images.
  /// Returns the created piece ID, or null on failure.
  Future<int?> publishPiece({
    required String title,
    String? discipline,
    String? year,
    String? edition,
    required int priceCents,
    int? oldPriceCents,
    int? costPriceCents,
    required bool rental,
    required int stock,
    List<String>? shipsTo,
    String? packaging,
    required List<Uint8List> images,
  }) async {
    _publishing = true;
    notifyListeners();

    try {
      // Step 1: Create piece metadata via JSON POST
      final body = <String, dynamic>{
        'title': title,
        'price_cents': priceCents,
        'rental': rental,
        'stock': stock,
      };
      if (discipline != null) body['discipline'] = discipline;
      if (year != null && year.isNotEmpty) body['year'] = year;
      if (edition != null && edition.isNotEmpty) body['edition'] = edition;
      if (oldPriceCents != null) body['old_price_cents'] = oldPriceCents;
      if (costPriceCents != null) body['cost_price_cents'] = costPriceCents;
      if (shipsTo != null && shipsTo.isNotEmpty) body['ships_to'] = shipsTo;
      if (packaging != null) body['packaging'] = packaging;

      final pieceData = await ApiClient.instance.post('/pieces', body);
      final pieceId = pieceData['id'] as int;

      // Step 2: Upload images via multipart POST
      if (images.isNotEmpty) {
        await ApiClient.instance.postMultipartMultiFile(
          '/pieces/$pieceId/images',
          files: images,
          fileField: 'files',
        );
      }

      _publishing = false;
      notifyListeners();
      return pieceId;
    } catch (e) {
      _publishing = false;
      notifyListeners();
      rethrow;
    }
  }
}
