import 'package:flutter/material.dart';

// ── SavedCollection model ────────────────────────────────────

class SavedCollection {
  final String id;
  String name;
  Color? coverColor;
  final List<String> productIds;
  final DateTime createdAt;

  SavedCollection({
    required this.id,
    required this.name,
    this.coverColor,
    List<String>? productIds,
    DateTime? createdAt,
  })  : productIds = productIds ?? [],
        createdAt = createdAt ?? DateTime.now();
}

// ── CollectionService (singleton ChangeNotifier) ─────────────

class CollectionService extends ChangeNotifier {
  // Singleton
  static final CollectionService _instance = CollectionService._();
  static CollectionService get instance => _instance;
  CollectionService._();

  final List<SavedCollection> _collections = [];
  List<SavedCollection> get collections => List.unmodifiable(_collections);

  /// Products saved without belonging to any specific collection.
  final Set<String> _savedProductIds = {};

  /// All unique saved product IDs (loose saves + all collections).
  Set<String> get allSavedProductIds =>
      {..._savedProductIds, ..._collections.expand((c) => c.productIds)};

  /// Whether the given product is saved (loose or in any collection).
  bool isProductSaved(String productId) =>
      _savedProductIds.contains(productId) ||
      _collections.any((c) => c.productIds.contains(productId));

  /// Quick toggle: save (loose) or unsave from everywhere.
  void toggleSaved(String productId) {
    if (isProductSaved(productId)) {
      // Unsave from loose set and all collections
      _savedProductIds.remove(productId);
      for (final col in _collections) {
        col.productIds.remove(productId);
      }
    } else {
      _savedProductIds.add(productId);
    }
    notifyListeners();
  }

  /// Which collections contain the given product.
  List<SavedCollection> collectionsForProduct(String productId) =>
      _collections.where((c) => c.productIds.contains(productId)).toList();

  /// Create a new collection, optionally adding an initial product.
  SavedCollection createCollection(
    String name, {
    Color? coverColor,
    String? initialProductId,
  }) {
    final id =
        '${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-')}-${DateTime.now().millisecondsSinceEpoch}';
    final collection = SavedCollection(
      id: id,
      name: name,
      coverColor: coverColor,
    );
    if (initialProductId != null) {
      collection.productIds.add(initialProductId);
    }
    _collections.add(collection);
    notifyListeners();
    return collection;
  }

  /// Toggle a product in/out of a specific collection.
  void toggleProductInCollection(String collectionId, String productId) {
    final col = _collections.firstWhere((c) => c.id == collectionId);
    if (col.productIds.contains(productId)) {
      col.productIds.remove(productId);
    } else {
      col.productIds.add(productId);
    }
    notifyListeners();
  }

  /// Remove a product from everywhere (loose set + all collections).
  void unsaveProduct(String productId) {
    _savedProductIds.remove(productId);
    for (final col in _collections) {
      col.productIds.remove(productId);
    }
    notifyListeners();
  }

  /// Delete a collection entirely.
  void deleteCollection(String collectionId) {
    _collections.removeWhere((c) => c.id == collectionId);
    notifyListeners();
  }

  /// Rename a collection.
  void renameCollection(String collectionId, String newName) {
    final col = _collections.firstWhere((c) => c.id == collectionId);
    col.name = newName;
    notifyListeners();
  }
}
