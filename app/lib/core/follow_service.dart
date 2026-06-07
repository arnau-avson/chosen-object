import 'package:flutter/foundation.dart';

import 'api_client.dart';

// ═════════════════════════════════════════════════════════════
// ── FollowService (singleton ChangeNotifier) ────────────────
// ═════════════════════════════════════════════════════════════

class FollowUser {
  final int id;
  final String username;
  final String? studioName;
  final String? discipline;
  final String avatarType;
  final String avatarColor;
  final String? avatarImageB64;
  final DateTime? followedAt;

  FollowUser({
    required this.id,
    required this.username,
    this.studioName,
    this.discipline,
    this.avatarType = 'color',
    this.avatarColor = '#2E2520',
    this.avatarImageB64,
    this.followedAt,
  });

  factory FollowUser.fromJson(Map<String, dynamic> j) => FollowUser(
        id: j['id'] as int,
        username: j['username'] as String,
        studioName: j['studio_name'] as String?,
        discipline: j['discipline'] as String?,
        avatarType: j['avatar_type'] as String? ?? 'color',
        avatarColor: j['avatar_color'] as String? ?? '#2E2520',
        avatarImageB64: j['avatar_image_b64'] as String?,
        followedAt: j['followed_at'] != null
            ? DateTime.parse(j['followed_at'] as String)
            : null,
      );
}

class FollowService extends ChangeNotifier {
  static final FollowService _instance = FollowService._();
  static FollowService get instance => _instance;
  FollowService._();

  // Cache follow state for current session
  final Set<int> _followingIds = {};

  int _myFollowersCount = 0;
  int _myFollowingCount = 0;

  int get myFollowerCount => _myFollowersCount;
  int get myFollowingCount => _myFollowingCount;

  bool isFollowing(int userId) => _followingIds.contains(userId);

  /// Seed the local cache (e.g. from browse API response).
  void markFollowing(int userId) {
    _followingIds.add(userId);
  }

  /// Fetch follow counts for a user.
  Future<Map<String, int>> fetchCounts(int userId) async {
    try {
      final data = await ApiClient.instance.get('/follows/$userId/counts');
      final map = data as Map<String, dynamic>;
      return {
        'followers': map['followers_count'] as int,
        'following': map['following_count'] as int,
      };
    } catch (_) {
      return {'followers': 0, 'following': 0};
    }
  }

  /// Load my counts and mark which users I'm following.
  Future<void> loadMyCounts(int myUserId) async {
    final counts = await fetchCounts(myUserId);
    _myFollowersCount = counts['followers'] ?? 0;
    _myFollowingCount = counts['following'] ?? 0;
    notifyListeners();
  }

  /// Follow a user.
  Future<bool> follow(int userId) async {
    try {
      await ApiClient.instance.post('/follows/$userId', {});
      _followingIds.add(userId);
      _myFollowingCount++;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Unfollow a user.
  Future<bool> unfollow(int userId) async {
    try {
      await ApiClient.instance.delete('/follows/$userId');
      _followingIds.remove(userId);
      _myFollowingCount--;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Toggle follow.
  Future<void> toggleFollow(int userId) async {
    if (isFollowing(userId)) {
      await unfollow(userId);
    } else {
      await follow(userId);
    }
  }

  /// Get followers list.
  Future<List<FollowUser>> getFollowers(int userId,
      {int offset = 0, int limit = 20}) async {
    try {
      final data = await ApiClient.instance
          .get('/follows/$userId/followers?offset=$offset&limit=$limit');
      return (data as List)
          .map((j) => FollowUser.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get following list.
  Future<List<FollowUser>> getFollowing(int userId,
      {int offset = 0, int limit = 20}) async {
    try {
      final data = await ApiClient.instance
          .get('/follows/$userId/following?offset=$offset&limit=$limit');
      final list = (data as List)
          .map((j) => FollowUser.fromJson(j as Map<String, dynamic>))
          .toList();
      // Update local cache
      for (final u in list) {
        _followingIds.add(u.id);
      }
      return list;
    } catch (_) {
      return [];
    }
  }
}
