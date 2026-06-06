import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

// ═════════════════════════════════════════════════════════════
// ── FollowService (singleton ChangeNotifier) ────────────────
// ═════════════════════════════════════════════════════════════

class FollowService extends ChangeNotifier {
  static final FollowService _instance = FollowService._();
  static FollowService get instance => _instance;

  FollowService._() {
    // Current user starts empty — real counts loaded from backend
    _followers['me'] = {};
    _following['me'] = {};

    // Seed some external users
    _followers['marta-sala'] = {'me', 'atelier-nm', 'clara-boj', 'studio-vera'};
    _following['marta-sala'] = {'me', 'clara-boj', 'teixidors'};

    _followers['studio-vera'] = {'me', 'marta-sala', 'laia-font', 'anna-riera', 'viabizzuno'};
    _following['studio-vera'] = {'me', 'marta-sala', 'viabizzuno'};

    _followers['teixidors'] = {'me', 'marta-sala', 'atelier-nm', 'laia-font', 'jordi-canudas', 'anna-riera'};
    _following['teixidors'] = {'atelier-nm', 'viabizzuno', 'jordi-canudas'};

    _followers['viabizzuno'] = {'me', 'studio-vera', 'anna-riera', 'laia-font'};
    _following['viabizzuno'] = {'studio-vera', 'anna-riera', 'teixidors'};

    _followers['clara-boj'] = {'me', 'marta-sala', 'elena-marti'};
    _following['clara-boj'] = {'marta-sala', 'me', 'elena-marti', 'apparatu'};

    _followers['atelier-nm'] = {'me', 'teixidors', 'jordi-canudas'};
    _following['atelier-nm'] = {'me', 'teixidors', 'marta-sala'};

    _followers['laia-font'] = {'me', 'anna-riera', 'nuria-coll'};
    _following['laia-font'] = {'studio-vera', 'teixidors', 'viabizzuno', 'anna-riera'};

    _followers['anna-riera'] = {'me', 'laia-font', 'viabizzuno'};
    _following['anna-riera'] = {'laia-font', 'viabizzuno', 'studio-vera'};
  }

  // userId → set of userIds who follow them
  final Map<String, Set<String>> _followers = {};
  // userId → set of userIds they follow
  final Map<String, Set<String>> _following = {};

  // ── Queries ─────────────────────────────────────────────────

  bool isFollowing(String targetUserId) =>
      _following['me']?.contains(targetUserId) ?? false;

  int followerCount(String userId) => _followers[userId]?.length ?? 0;
  int followingCount(String userId) => _following[userId]?.length ?? 0;

  int get myFollowerCount => followerCount('me');
  int get myFollowingCount => followingCount('me');

  List<UserProfile> getFollowers(String userId) {
    final ids = _followers[userId] ?? {};
    return ids
        .where((id) => id != 'me')
        .map((id) {
          try {
            return findProfileById(id);
          } catch (_) {
            return null;
          }
        })
        .whereType<UserProfile>()
        .toList();
  }

  List<UserProfile> getFollowing(String userId) {
    final ids = _following[userId] ?? {};
    return ids
        .where((id) => id != 'me')
        .map((id) {
          try {
            return findProfileById(id);
          } catch (_) {
            return null;
          }
        })
        .whereType<UserProfile>()
        .toList();
  }

  // ── Mutations ───────────────────────────────────────────────

  void follow(String targetUserId) {
    _following.putIfAbsent('me', () => {}).add(targetUserId);
    _followers.putIfAbsent(targetUserId, () => {}).add('me');
    notifyListeners();
  }

  void unfollow(String targetUserId) {
    _following['me']?.remove(targetUserId);
    _followers[targetUserId]?.remove('me');
    notifyListeners();
  }

  void toggleFollow(String targetUserId) {
    isFollowing(targetUserId) ? unfollow(targetUserId) : follow(targetUserId);
  }
}
