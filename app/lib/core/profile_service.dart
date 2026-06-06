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

  // ── Studio fields ───────────────────────────────────────

  String _studioName = 'Atelier Noire';
  String _discipline = 'Lighting';
  String _city = 'Paris';
  String _country = 'France';

  // ── Online presence ─────────────────────────────────────

  String _website = 'https://ateliernoire.fr';
  String _instagram = '@atelier.noire';
  String _portfolio = 'https://portfolio.com';

  // ── Invoicing ───────────────────────────────────────────

  String _legalEntity = 'Atelier Noire SARL';
  String _vatId = 'FR 12 345 678 901';
  String _iban = 'FR76 1234 5678 9012 3456 7890 123';
  final String _invoicePrefix = 'CO-ATELIERNOIRE-';

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

  String get studioName => _studioName;
  String get discipline => _discipline;
  String get city => _city;
  String get country => _country;

  String get website => _website;
  String get instagram => _instagram;
  String get portfolio => _portfolio;

  String get legalEntity => _legalEntity;
  String get vatId => _vatId;
  String get iban => _iban;
  String get invoicePrefix => _invoicePrefix;

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
    String? studioName,
    String? discipline,
    String? city,
    String? country,
    String? website,
    String? instagram,
    String? portfolio,
    String? legalEntity,
    String? vatId,
    String? iban,
  }) {
    if (name != null) _name = name;
    if (handle != null) _handle = handle;
    if (location != null) _location = location;
    if (role != null) _role = role;
    if (bio != null) _bio = bio;
    if (specialties != null) _specialties = specialties;
    if (studioName != null) _studioName = studioName;
    if (discipline != null) _discipline = discipline;
    if (city != null) _city = city;
    if (country != null) _country = country;
    if (website != null) _website = website;
    if (instagram != null) _instagram = instagram;
    if (portfolio != null) _portfolio = portfolio;
    if (legalEntity != null) _legalEntity = legalEntity;
    if (vatId != null) _vatId = vatId;
    if (iban != null) _iban = iban;
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
