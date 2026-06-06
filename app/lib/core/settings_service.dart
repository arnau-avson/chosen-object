import 'package:flutter/material.dart';

// ═════════════════════════════════════════════════════════════
// ── SettingsService (singleton ChangeNotifier) ──────────────
// ═════════════════════════════════════════════════════════════

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._();
  static SettingsService get instance => _instance;
  SettingsService._();

  // ── Notifications ─────────────────────────────────────────

  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _orderUpdates = true;
  bool _priceDrops = false;
  bool _newFollowers = true;

  bool get pushNotifications => _pushNotifications;
  bool get emailNotifications => _emailNotifications;
  bool get orderUpdates => _orderUpdates;
  bool get priceDrops => _priceDrops;
  bool get newFollowers => _newFollowers;

  // ── Privacy ───────────────────────────────────────────────

  bool _showProfilePublicly = true;
  bool _allowMessagesFromAnyone = false;

  bool get showProfilePublicly => _showProfilePublicly;
  bool get allowMessagesFromAnyone => _allowMessagesFromAnyone;

  // ── Appearance ────────────────────────────────────────────

  String _language = 'English';

  String get language => _language;

  // ── Setters ───────────────────────────────────────────────

  void setPushNotifications(bool v) {
    _pushNotifications = v;
    notifyListeners();
  }

  void setEmailNotifications(bool v) {
    _emailNotifications = v;
    notifyListeners();
  }

  void setOrderUpdates(bool v) {
    _orderUpdates = v;
    notifyListeners();
  }

  void setPriceDrops(bool v) {
    _priceDrops = v;
    notifyListeners();
  }

  void setNewFollowers(bool v) {
    _newFollowers = v;
    notifyListeners();
  }

  void setShowProfilePublicly(bool v) {
    _showProfilePublicly = v;
    notifyListeners();
  }

  void setAllowMessagesFromAnyone(bool v) {
    _allowMessagesFromAnyone = v;
    notifyListeners();
  }

  void setLanguage(String v) {
    _language = v;
    notifyListeners();
  }
}
