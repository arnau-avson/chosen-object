import 'package:flutter/foundation.dart';

import 'api_client.dart';

// ═════════════════════════════════════════════════════════════
// ── RentalService (singleton ChangeNotifier) ──────────────────
// ═════════════════════════════════════════════════════════════

class RentalData {
  final int id;
  final int pieceId;
  final String? pieceTitle;
  final int renterId;
  final String? renterUsername;
  final int ownerId;
  final String? ownerUsername;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final int dailyRateCents;
  final int totalCents;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  RentalData({
    required this.id,
    required this.pieceId,
    this.pieceTitle,
    required this.renterId,
    this.renterUsername,
    required this.ownerId,
    this.ownerUsername,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.dailyRateCents,
    required this.totalCents,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  String get totalFormatted => '€${(totalCents / 100).toStringAsFixed(2)}';
  int get days => endDate.difference(startDate).inDays;

  factory RentalData.fromJson(Map<String, dynamic> j) => RentalData(
        id: j['id'] as int,
        pieceId: j['piece_id'] as int,
        pieceTitle: j['piece_title'] as String?,
        renterId: j['renter_id'] as int,
        renterUsername: j['renter_username'] as String?,
        ownerId: j['owner_id'] as int,
        ownerUsername: j['owner_username'] as String?,
        status: j['status'] as String,
        startDate: DateTime.parse(j['start_date'] as String),
        endDate: DateTime.parse(j['end_date'] as String),
        dailyRateCents: j['daily_rate_cents'] as int,
        totalCents: j['total_cents'] as int,
        notes: j['notes'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );
}

class BlockedDateRange {
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  BlockedDateRange({
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory BlockedDateRange.fromJson(Map<String, dynamic> j) => BlockedDateRange(
        startDate: DateTime.parse(j['start_date'] as String),
        endDate: DateTime.parse(j['end_date'] as String),
        status: j['status'] as String,
      );
}

class RentalService extends ChangeNotifier {
  static final RentalService _instance = RentalService._();
  static RentalService get instance => _instance;
  RentalService._();

  List<RentalData> _rentals = [];
  List<RentalData> get rentals => _rentals;

  bool _loading = false;
  bool get loading => _loading;

  /// Request a rental.
  Future<RentalData?> requestRental({
    required int pieceId,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'piece_id': pieceId,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
      };
      if (notes != null) body['notes'] = notes;

      final data = await ApiClient.instance.post('/rentals', body);
      return RentalData.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Fetch rentals.
  Future<void> fetchRentals({
    String role = 'renter',
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
      final data = await ApiClient.instance.get('/rentals?$query');
      _rentals = (data as List)
          .map((j) => RentalData.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // keep existing
    }

    _loading = false;
    notifyListeners();
  }

  /// Get rental detail.
  Future<RentalData?> fetchRental(int rentalId) async {
    try {
      final data = await ApiClient.instance.get('/rentals/$rentalId');
      return RentalData.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Owner respond to rental request.
  Future<RentalData?> respondToRental(int rentalId, {required bool accept}) async {
    try {
      final data = await ApiClient.instance
          .patch('/rentals/$rentalId/respond', {'accept': accept});
      return RentalData.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Owner update rental status.
  Future<RentalData?> updateRentalStatus(
    int rentalId, {
    required String status,
  }) async {
    try {
      final data = await ApiClient.instance
          .patch('/rentals/$rentalId/status', {'status': status});
      return RentalData.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Get blocked dates for a piece in a given month.
  Future<List<BlockedDateRange>> fetchCalendar(
    int pieceId, {
    required int year,
    required int month,
  }) async {
    try {
      final data = await ApiClient.instance
          .get('/rentals/calendar/$pieceId?year=$year&month=$month');
      final map = data as Map<String, dynamic>;
      return (map['blocked_dates'] as List)
          .map((j) => BlockedDateRange.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
