import 'package:flutter/foundation.dart';

import 'api_client.dart';

// ═════════════════════════════════════════════════════════════
// ── BrowseService (singleton ChangeNotifier) ─────────────────
// ═════════════════════════════════════════════════════════════

class BrowsePiece {
  final int id;
  final int userId;
  final String title;
  final String? discipline;
  final String? year;
  final String? edition;
  final String? description;
  final int priceCents;
  final int? oldPriceCents;
  final bool rental;
  final int? rentalDailyRateCents;
  final int stock;
  final List<String>? shipsTo;
  final String? packaging;
  final String status;
  final String? coverImageB64;
  final DateTime createdAt;
  final bool isSaved;
  final String? sellerUsername;
  final String? sellerStudioName;
  final List<Map<String, dynamic>>? images;

  BrowsePiece({
    required this.id,
    required this.userId,
    required this.title,
    this.discipline,
    this.year,
    this.edition,
    this.description,
    required this.priceCents,
    this.oldPriceCents,
    required this.rental,
    this.rentalDailyRateCents,
    required this.stock,
    this.shipsTo,
    this.packaging,
    required this.status,
    this.coverImageB64,
    required this.createdAt,
    this.isSaved = false,
    this.sellerUsername,
    this.sellerStudioName,
    this.images,
  });

  String get priceFormatted => '€${(priceCents / 100).toStringAsFixed(2)}';

  factory BrowsePiece.fromJson(Map<String, dynamic> j) => BrowsePiece(
        id: j['id'] as int,
        userId: j['user_id'] as int,
        title: j['title'] as String,
        discipline: j['discipline'] as String?,
        year: j['year'] as String?,
        edition: j['edition'] as String?,
        description: j['description'] as String?,
        priceCents: j['price_cents'] as int,
        oldPriceCents: j['old_price_cents'] as int?,
        rental: j['rental'] as bool,
        rentalDailyRateCents: j['rental_daily_rate_cents'] as int?,
        stock: j['stock'] as int,
        shipsTo: (j['ships_to'] as List?)?.cast<String>(),
        packaging: j['packaging'] as String?,
        status: j['status'] as String,
        coverImageB64: j['cover_image_b64'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        isSaved: j['is_saved'] as bool? ?? false,
        sellerUsername: j['seller_username'] as String?,
        sellerStudioName: j['seller_studio_name'] as String?,
        images: (j['images'] as List?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList(),
      );
}

class BrowseUser {
  final int id;
  final String username;
  final String? studioName;
  final String? discipline;
  final String? city;
  final String? country;
  final String? bio;
  final String avatarType;
  final String avatarColor;
  final String? avatarImageB64;
  final String bannerType;
  final String bannerColor;
  final String? bannerImageB64;
  final bool isFollowing;
  final int followersCount;
  final int followingCount;
  final int piecesCount;

  BrowseUser({
    required this.id,
    required this.username,
    this.studioName,
    this.discipline,
    this.city,
    this.country,
    this.bio,
    this.avatarType = 'color',
    this.avatarColor = '#2E2520',
    this.avatarImageB64,
    this.bannerType = 'color',
    this.bannerColor = '#4A3F35',
    this.bannerImageB64,
    this.isFollowing = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.piecesCount = 0,
  });

  factory BrowseUser.fromJson(Map<String, dynamic> j) => BrowseUser(
        id: j['id'] as int,
        username: j['username'] as String,
        studioName: j['studio_name'] as String?,
        discipline: j['discipline'] as String?,
        city: j['city'] as String?,
        country: j['country'] as String?,
        bio: j['bio'] as String?,
        avatarType: j['avatar_type'] as String? ?? 'color',
        avatarColor: j['avatar_color'] as String? ?? '#2E2520',
        avatarImageB64: j['avatar_image_b64'] as String?,
        bannerType: j['banner_type'] as String? ?? 'color',
        bannerColor: j['banner_color'] as String? ?? '#4A3F35',
        bannerImageB64: j['banner_image_b64'] as String?,
        isFollowing: j['is_following'] as bool? ?? false,
        followersCount: j['followers_count'] as int? ?? 0,
        followingCount: j['following_count'] as int? ?? 0,
        piecesCount: j['pieces_count'] as int? ?? 0,
      );
}

class BrowseService extends ChangeNotifier {
  static final BrowseService _instance = BrowseService._();
  static BrowseService get instance => _instance;
  BrowseService._();

  List<BrowsePiece> _pieces = [];
  List<BrowsePiece> get pieces => _pieces;

  bool _loading = false;
  bool get loading => _loading;

  List<BrowseUser> _users = [];
  List<BrowseUser> get users => _users;

  /// Browse/search pieces from the backend.
  Future<void> fetchPieces({
    String? search,
    String? discipline,
    String? sort,
    int? minPrice,
    int? maxPrice,
    int offset = 0,
    int limit = 20,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (discipline != null) params['discipline'] = discipline;
      if (sort != null) params['sort'] = sort;
      if (minPrice != null) params['min_price'] = minPrice.toString();
      if (maxPrice != null) params['max_price'] = maxPrice.toString();
      params['offset'] = offset.toString();
      params['limit'] = limit.toString();

      final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final data = await ApiClient.instance.get('/browse/pieces?$query');
      _pieces = (data as List)
          .map((j) => BrowsePiece.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Keep existing list on failure
    }

    _loading = false;
    notifyListeners();
  }

  /// Get a single piece detail.
  Future<BrowsePiece?> fetchPieceDetail(int pieceId) async {
    try {
      final data = await ApiClient.instance.get('/browse/pieces/$pieceId');
      return BrowsePiece.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Search users.
  Future<void> fetchUsers({String? search, int offset = 0, int limit = 20}) async {
    try {
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      params['offset'] = offset.toString();
      params['limit'] = limit.toString();

      final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final data = await ApiClient.instance.get('/browse/users?$query');
      _users = (data as List)
          .map((j) => BrowseUser.fromJson(j as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {
      // Keep existing
    }
  }

  /// Get a single user profile.
  Future<BrowseUser?> fetchUserProfile(int userId) async {
    try {
      final data = await ApiClient.instance.get('/browse/users/$userId');
      return BrowseUser.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
