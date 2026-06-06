import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'api_client.dart';
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
  final bool _verified = false;

  // ── Avatar / Banner ───────────────────────────────────────

  String _avatarType = 'color'; // 'color' or 'image'
  Color _avatarColor = const Color(0xFF2E2520);
  Uint8List? _avatarImageBytes;

  String _bannerType = 'color'; // 'color' or 'image'
  Color _bannerColor = const Color(0xFF4A3F35);
  Uint8List? _bannerImageBytes;

  // ── Studio fields ─────────────────────────────────────────

  String _studioName = 'Atelier Noire';
  String _discipline = 'Lighting';
  String _city = 'Paris';
  String _country = 'France';

  // ── Online presence ───────────────────────────────────────

  String _website = 'https://ateliernoire.fr';
  String _instagram = '@atelier.noire';
  String _portfolio = 'https://portfolio.com';

  // ── Invoicing ─────────────────────────────────────────────

  String _legalEntity = 'Atelier Noire SARL';
  String _vatId = 'FR 12 345 678 901';
  String _iban = 'FR76 1234 5678 9012 3456 7890 123';
  String _invoicePrefix = 'CO-ATELIERNOIRE-';

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

  String get avatarType => _avatarType;
  Color get avatarColor => _avatarColor;
  Uint8List? get avatarImageBytes => _avatarImageBytes;

  String get bannerType => _bannerType;
  Color get bannerColor => _bannerColor;
  Uint8List? get bannerImageBytes => _bannerImageBytes;

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

  // ── Local setters (offline / mock) ────────────────────────

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
    _avatarType = 'color';
    _avatarColor = color;
    _avatarImageBytes = null;
    notifyListeners();
  }

  void updateAvatarImage(Uint8List bytes) {
    _avatarType = 'image';
    _avatarImageBytes = bytes;
    notifyListeners();
  }

  void updateBannerColor(Color color) {
    _bannerType = 'color';
    _bannerColor = color;
    _bannerImageBytes = null;
    notifyListeners();
  }

  void updateBannerImage(Uint8List bytes) {
    _bannerType = 'image';
    _bannerImageBytes = bytes;
    notifyListeners();
  }

  // ═════════════════════════════════════════════════════════
  // ── Backend integration ─────────────────────────────────
  // ═════════════════════════════════════════════════════════

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  static String _colorToHex(Color c) {
    return '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Fetch the full profile from the backend and hydrate local state.
  Future<void> loadFromBackend() async {
    try {
      final data = await ApiClient.instance.get('/profile/me');
      _name =
          '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
      _handle = data['handle'] ?? _handle;
      _city = data['city'] ?? _city;
      _country = data['country'] ?? _country;
      _location = [_city, _country]
          .where((s) => s.isNotEmpty)
          .join(', ');
      _role = data['role'] ?? _role;
      _bio = data['bio'] ?? _bio;
      _studioName = data['studio_name'] ?? _studioName;
      _discipline = data['discipline'] ?? _discipline;
      _website = data['website'] ?? _website;
      _instagram = data['instagram'] ?? _instagram;
      _portfolio = data['portfolio'] ?? _portfolio;
      _legalEntity = data['legal_entity'] ?? _legalEntity;
      _vatId = data['vat_id'] ?? _vatId;
      _iban = data['iban'] ?? _iban;
      _invoicePrefix = data['invoice_prefix'] ?? _invoicePrefix;

      // Avatar
      _avatarType = data['avatar_type'] ?? 'color';
      _avatarColor = _hexToColor(data['avatar_color'] ?? '#2E2520');
      if (data['avatar_image_b64'] != null) {
        _avatarImageBytes = base64Decode(data['avatar_image_b64']);
      } else {
        _avatarImageBytes = null;
      }

      // Banner
      _bannerType = data['banner_type'] ?? 'color';
      _bannerColor = _hexToColor(data['banner_color'] ?? '#4A3F35');
      if (data['banner_image_b64'] != null) {
        _bannerImageBytes = base64Decode(data['banner_image_b64']);
      } else {
        _bannerImageBytes = null;
      }

      notifyListeners();
    } catch (_) {
      // Silently fail — keep mock data if backend unreachable
    }
  }

  /// Push text profile fields to the backend.
  Future<void> saveToBackend() async {
    final parts = _name.split(' ');
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    try {
      await ApiClient.instance.put('/profile/me', {
        'first_name': firstName,
        'last_name': lastName,
        'handle': _handle,
        'city': _city,
        'country': _country,
        'bio': _bio,
        'studio_name': _studioName,
        'discipline': _discipline,
        'website': _website,
        'instagram': _instagram,
        'portfolio': _portfolio,
        'legal_entity': _legalEntity,
        'vat_id': _vatId,
        'iban': _iban,
        'invoice_prefix': _invoicePrefix,
      });
    } catch (_) {
      // Offline — changes saved locally only
    }
  }

  /// Upload avatar to backend (color or image).
  Future<void> uploadAvatarToBackend() async {
    try {
      if (_avatarType == 'color') {
        await ApiClient.instance.postMultipart('/profile/me/avatar', fields: {
          'type': 'color',
          'color': _colorToHex(_avatarColor),
        });
      } else if (_avatarImageBytes != null) {
        await ApiClient.instance.postMultipart(
          '/profile/me/avatar',
          fields: {'type': 'image'},
          fileBytes: _avatarImageBytes,
        );
      }
    } catch (_) {
      // Offline
    }
  }

  /// Upload banner to backend (color or image).
  Future<void> uploadBannerToBackend() async {
    try {
      if (_bannerType == 'color') {
        await ApiClient.instance.postMultipart('/profile/me/banner', fields: {
          'type': 'color',
          'color': _colorToHex(_bannerColor),
        });
      } else if (_bannerImageBytes != null) {
        await ApiClient.instance.postMultipart(
          '/profile/me/banner',
          fields: {'type': 'image'},
          fileBytes: _bannerImageBytes,
        );
      }
    } catch (_) {
      // Offline
    }
  }
}
