import 'package:flutter/material.dart';
import 'follow_service.dart';

// ═════════════════════════════════════════════════════════════
// ── ProfileService (singleton ChangeNotifier) ───────────────
// ═════════════════════════════════════════════════════════════

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._();
  static ProfileService get instance => _instance;
  ProfileService._() {
    FollowService.instance.addListener(notifyListeners);
  }

  // ── Profile fields ────────────────────────────────────────

  String _name = 'Borja Arrero';
  String _handle = '@baarrero';
  String _location = 'Barcelona, ES';
  String _role = 'Collector & Designer';
  String _bio =
      'Design enthusiast and collector based in Barcelona. '
      'Passionate about Mediterranean craft, honest materials, '
      'and objects made to last. Always looking for the next '
      'conversation piece.';
  List<String> _specialties = ['Furniture', 'Ceramic'];
  final int _pieceCount = 7;
  final int _soldCount = 3;
  // followerCount and followingCount are computed from FollowService
  final bool _verified = false;
  Color _avatarColor = const Color(0xFF2E2520);
  Color _bannerColor = const Color(0xFF4A3F35);

  // ── Getters ───────────────────────────────────────────────

  String get name => _name;
  String get handle => _handle;
  String get location => _location;
  String get role => _role;
  String get bio => _bio;
  List<String> get specialties => List.unmodifiable(_specialties);
  int get pieceCount => _pieceCount;
  int get soldCount => _soldCount;
  int get followerCount => FollowService.instance.myFollowerCount;
  int get followingCount => FollowService.instance.myFollowingCount;
  bool get verified => _verified;
  Color get avatarColor => _avatarColor;
  Color get bannerColor => _bannerColor;

  String get initials => _name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0])
      .take(2)
      .join();

  // ── Setters ───────────────────────────────────────────────

  void updateProfile({
    String? name,
    String? handle,
    String? location,
    String? role,
    String? bio,
    List<String>? specialties,
  }) {
    if (name != null) _name = name;
    if (handle != null) _handle = handle;
    if (location != null) _location = location;
    if (role != null) _role = role;
    if (bio != null) _bio = bio;
    if (specialties != null) _specialties = specialties;
    notifyListeners();
  }

  void updateAvatarColor(Color color) {
    _avatarColor = color;
    notifyListeners();
  }

  void updateBannerColor(Color color) {
    _bannerColor = color;
    notifyListeners();
  }
}
