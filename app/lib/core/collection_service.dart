import 'package:flutter/foundation.dart';

import 'api_client.dart';

// ═════════════════════════════════════════════════════════════
// ── CollectionService (singleton ChangeNotifier) ──────────────
// ═════════════════════════════════════════════════════════════

class SavedPiece {
  final int id;
  final String title;
  final String? discipline;
  final int priceCents;
  final String? coverImageB64;
  final DateTime savedAt;

  SavedPiece({
    required this.id,
    required this.title,
    this.discipline,
    required this.priceCents,
    this.coverImageB64,
    required this.savedAt,
  });

  factory SavedPiece.fromJson(Map<String, dynamic> j) => SavedPiece(
        id: j['id'] as int,
        title: j['title'] as String,
        discipline: j['discipline'] as String?,
        priceCents: j['price_cents'] as int,
        coverImageB64: j['cover_image_b64'] as String?,
        savedAt: DateTime.parse(j['saved_at'] as String),
      );
}

class SavedCollection {
  final int id;
  final String name;
  final int pieceCount;
  final DateTime createdAt;
  final List<SavedPiece> pieces;

  SavedCollection({
    required this.id,
    required this.name,
    this.pieceCount = 0,
    required this.createdAt,
    this.pieces = const [],
  });

  factory SavedCollection.fromJson(Map<String, dynamic> j) => SavedCollection(
        id: j['id'] as int,
        name: j['name'] as String,
        pieceCount: j['piece_count'] as int? ?? 0,
        createdAt: DateTime.parse(j['created_at'] as String),
        pieces: (j['pieces'] as List?)
                ?.map((p) => SavedPiece.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class CollectionService extends ChangeNotifier {
  static final CollectionService _instance = CollectionService._();
  static CollectionService get instance => _instance;
  CollectionService._();

  List<SavedPiece> _savedPieces = [];
  List<SavedPiece> get savedPieces => _savedPieces;

  List<SavedCollection> _collections = [];
  List<SavedCollection> get collections => _collections;

  final Set<int> _savedPieceIds = {};

  bool isProductSaved(int pieceId) => _savedPieceIds.contains(pieceId);

  /// Toggle save for a piece.
  Future<bool> toggleSaved(int pieceId) async {
    try {
      final data = await ApiClient.instance.post('/saves/$pieceId', {});
      final saved = (data as Map<String, dynamic>)['saved'] as bool;
      if (saved) {
        _savedPieceIds.add(pieceId);
      } else {
        _savedPieceIds.remove(pieceId);
      }
      notifyListeners();
      return saved;
    } catch (_) {
      return false;
    }
  }

  /// Fetch saved pieces.
  Future<void> fetchSavedPieces({int offset = 0, int limit = 20}) async {
    try {
      final data =
          await ApiClient.instance.get('/saves?offset=$offset&limit=$limit');
      _savedPieces = (data as List)
          .map((j) => SavedPiece.fromJson(j as Map<String, dynamic>))
          .toList();
      _savedPieceIds.clear();
      for (final p in _savedPieces) {
        _savedPieceIds.add(p.id);
      }
      notifyListeners();
    } catch (_) {
      // keep existing
    }
  }

  /// Fetch collections.
  Future<void> fetchCollections() async {
    try {
      final data = await ApiClient.instance.get('/collections');
      _collections = (data as List)
          .map((j) => SavedCollection.fromJson(j as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {
      // keep existing
    }
  }

  /// Create a collection.
  Future<SavedCollection?> createCollection(String name) async {
    try {
      final data =
          await ApiClient.instance.post('/collections', {'name': name});
      final col =
          SavedCollection.fromJson(data as Map<String, dynamic>);
      _collections.insert(0, col);
      notifyListeners();
      return col;
    } catch (_) {
      return null;
    }
  }

  /// Get collection detail with pieces.
  Future<SavedCollection?> fetchCollectionDetail(int collectionId) async {
    try {
      final data =
          await ApiClient.instance.get('/collections/$collectionId');
      return SavedCollection.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Rename a collection.
  Future<void> renameCollection(int collectionId, String newName) async {
    try {
      await ApiClient.instance
          .patch('/collections/$collectionId', {'name': newName});
      final idx = _collections.indexWhere((c) => c.id == collectionId);
      if (idx != -1) {
        await fetchCollections();
      }
    } catch (_) {
      // ignore
    }
  }

  /// Delete a collection.
  Future<void> deleteCollection(int collectionId) async {
    try {
      await ApiClient.instance.delete('/collections/$collectionId');
      _collections.removeWhere((c) => c.id == collectionId);
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  /// Add piece to collection.
  Future<void> addPieceToCollection(int collectionId, int pieceId) async {
    try {
      await ApiClient.instance
          .post('/collections/$collectionId/pieces/$pieceId', {});
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  /// Remove piece from collection.
  Future<void> removePieceFromCollection(int collectionId, int pieceId) async {
    try {
      await ApiClient.instance
          .delete('/collections/$collectionId/pieces/$pieceId');
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }
}
