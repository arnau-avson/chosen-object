import 'package:flutter/foundation.dart';

import 'api_client.dart';

// ═════════════════════════════════════════════════════════════
// ── OrderService (singleton ChangeNotifier) ───────────────────
// ═════════════════════════════════════════════════════════════

class OrderItemData {
  final int id;
  final int pieceId;
  final String? pieceTitle;
  final String? pieceCoverB64;
  final int priceCents;
  final int quantity;

  OrderItemData({
    required this.id,
    required this.pieceId,
    this.pieceTitle,
    this.pieceCoverB64,
    required this.priceCents,
    required this.quantity,
  });

  factory OrderItemData.fromJson(Map<String, dynamic> j) => OrderItemData(
        id: j['id'] as int,
        pieceId: j['piece_id'] as int,
        pieceTitle: j['piece_title'] as String?,
        pieceCoverB64: j['piece_cover_b64'] as String?,
        priceCents: j['price_cents'] as int,
        quantity: j['quantity'] as int,
      );
}

class OrderData {
  final int id;
  final int buyerId;
  final int sellerId;
  final String status;
  final int totalCents;
  final int? shippingAddressId;
  final String? trackingNumber;
  final String? notes;
  final List<OrderItemData> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? buyerUsername;
  final String? sellerUsername;

  OrderData({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.status,
    required this.totalCents,
    this.shippingAddressId,
    this.trackingNumber,
    this.notes,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.buyerUsername,
    this.sellerUsername,
  });

  String get totalFormatted => '€${(totalCents / 100).toStringAsFixed(2)}';

  factory OrderData.fromJson(Map<String, dynamic> j) => OrderData(
        id: j['id'] as int,
        buyerId: j['buyer_id'] as int,
        sellerId: j['seller_id'] as int,
        status: j['status'] as String,
        totalCents: j['total_cents'] as int,
        shippingAddressId: j['shipping_address_id'] as int?,
        trackingNumber: j['tracking_number'] as String?,
        notes: j['notes'] as String?,
        items: (j['items'] as List)
            .map((i) => OrderItemData.fromJson(i as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        buyerUsername: j['buyer_username'] as String?,
        sellerUsername: j['seller_username'] as String?,
      );
}

class OrderService extends ChangeNotifier {
  static final OrderService _instance = OrderService._();
  static OrderService get instance => _instance;
  OrderService._();

  List<OrderData> _orders = [];
  List<OrderData> get orders => _orders;

  bool _loading = false;
  bool get loading => _loading;

  /// Create orders from cart.
  Future<List<OrderData>> checkout({
    int? shippingAddressId,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (shippingAddressId != null) {
      body['shipping_address_id'] = shippingAddressId;
    }
    if (notes != null) body['notes'] = notes;

    final data = await ApiClient.instance.post('/orders', body);
    final results = (data as List)
        .map((j) => OrderData.fromJson(j as Map<String, dynamic>))
        .toList();
    return results;
  }

  /// Fetch orders for the current user.
  Future<void> fetchOrders({
    String role = 'buyer',
    String? status,
    int offset = 0,
    int limit = 20,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final params = <String, String>{
        'role': role,
        'offset': offset.toString(),
        'limit': limit.toString(),
      };
      if (status != null) params['status'] = status;

      final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final data = await ApiClient.instance.get('/orders?$query');
      _orders = (data as List)
          .map((j) => OrderData.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // keep existing
    }

    _loading = false;
    notifyListeners();
  }

  /// Get order detail.
  Future<OrderData?> fetchOrder(int orderId) async {
    try {
      final data = await ApiClient.instance.get('/orders/$orderId');
      return OrderData.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Update order status (seller).
  Future<OrderData?> updateStatus(
    int orderId, {
    required String status,
    String? trackingNumber,
  }) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (trackingNumber != null) body['tracking_number'] = trackingNumber;
      final data = await ApiClient.instance.patch('/orders/$orderId/status', body);
      return OrderData.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Cancel order (buyer).
  Future<OrderData?> cancelOrder(int orderId) async {
    try {
      final data = await ApiClient.instance.post('/orders/$orderId/cancel', {});
      return OrderData.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
