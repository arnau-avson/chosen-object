import 'package:flutter/foundation.dart';

import 'api_client.dart';

// ═════════════════════════════════════════════════════════════
// ── CartService (singleton ChangeNotifier) ────────────────────
// ═════════════════════════════════════════════════════════════

class CartItem {
  final int pieceId;
  final String title;
  final String? discipline;
  final int priceCents;
  final String? coverImageB64;
  final int sellerId;
  final String? sellerUsername;
  final DateTime addedAt;

  CartItem({
    required this.pieceId,
    required this.title,
    this.discipline,
    required this.priceCents,
    this.coverImageB64,
    required this.sellerId,
    this.sellerUsername,
    required this.addedAt,
  });

  String get priceFormatted => '€${(priceCents / 100).toStringAsFixed(2)}';

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        pieceId: j['piece_id'] as int,
        title: j['title'] as String,
        discipline: j['discipline'] as String?,
        priceCents: j['price_cents'] as int,
        coverImageB64: j['cover_image_b64'] as String?,
        sellerId: j['seller_id'] as int,
        sellerUsername: j['seller_username'] as String?,
        addedAt: DateTime.parse(j['added_at'] as String),
      );
}

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._();
  static CartService get instance => _instance;
  CartService._();

  List<CartItem> _items = [];
  List<CartItem> get items => _items;

  int _totalCents = 0;
  int get totalCents => _totalCents;

  int get itemCount => _items.length;
  String get totalFormatted => '€${(_totalCents / 100).toStringAsFixed(2)}';

  bool _loading = false;
  bool get loading => _loading;

  /// Fetch current cart from backend.
  Future<void> fetchCart() async {
    _loading = true;
    notifyListeners();

    try {
      final data = await ApiClient.instance.get('/cart');
      final map = data as Map<String, dynamic>;
      _items = (map['items'] as List)
          .map((j) => CartItem.fromJson(j as Map<String, dynamic>))
          .toList();
      _totalCents = map['total_cents'] as int;
    } catch (_) {
      // Keep existing
    }

    _loading = false;
    notifyListeners();
  }

  /// Add piece to cart.
  Future<bool> addToCart(int pieceId) async {
    try {
      await ApiClient.instance.post('/cart/$pieceId', {});
      await fetchCart();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Remove piece from cart.
  Future<bool> removeFromCart(int pieceId) async {
    try {
      await ApiClient.instance.delete('/cart/$pieceId');
      await fetchCart();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clear entire cart.
  Future<void> clearCart() async {
    try {
      await ApiClient.instance.delete('/cart');
      _items = [];
      _totalCents = 0;
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }
}
