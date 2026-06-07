import 'package:flutter/foundation.dart';

import 'api_client.dart';

// ═════════════════════════════════════════════════════════════
// ── SettingsService (singleton ChangeNotifier) ────────────────
// ═════════════════════════════════════════════════════════════

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._();
  static SettingsService get instance => _instance;
  SettingsService._();

  // ── Account role (local only, derived from user profile) ───
  String _accountRole = 'Both';
  String get accountRole => _accountRole;

  void setAccountRole(String v) {
    _accountRole = v;
    notifyListeners();
  }

  // ── Notification settings ──────────────────────────────────
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

  // ── Privacy ────────────────────────────────────────────────
  bool _showProfilePublicly = true;
  bool _allowMessagesFromAnyone = false;

  bool get showProfilePublicly => _showProfilePublicly;
  bool get allowMessagesFromAnyone => _allowMessagesFromAnyone;

  // ── Appearance ─────────────────────────────────────────────
  String _language = 'en';
  String get language => _language;

  bool _loading = false;
  bool get loading => _loading;

  /// Load settings from backend.
  Future<void> loadSettings() async {
    _loading = true;
    notifyListeners();

    try {
      final data = await ApiClient.instance.get('/settings');
      final map = data as Map<String, dynamic>;
      _pushNotifications = map['push_notifications'] as bool? ?? true;
      _emailNotifications = map['email_notifications'] as bool? ?? true;
      _orderUpdates = map['order_updates'] as bool? ?? true;
      _priceDrops = map['price_drops'] as bool? ?? false;
      _newFollowers = map['new_followers'] as bool? ?? true;
      _showProfilePublicly = map['show_profile_publicly'] as bool? ?? true;
      _allowMessagesFromAnyone =
          map['allow_messages_from_anyone'] as bool? ?? false;
      _language = map['language'] as String? ?? 'en';
    } catch (_) {
      // Use defaults on failure
    }

    _loading = false;
    notifyListeners();
  }

  /// Update a single setting.
  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await ApiClient.instance.patch('/settings', {key: value});
    } catch (_) {
      // ignore, local state already updated
    }
  }

  void setPushNotifications(bool v) {
    _pushNotifications = v;
    notifyListeners();
    _updateSetting('push_notifications', v);
  }

  void setEmailNotifications(bool v) {
    _emailNotifications = v;
    notifyListeners();
    _updateSetting('email_notifications', v);
  }

  void setOrderUpdates(bool v) {
    _orderUpdates = v;
    notifyListeners();
    _updateSetting('order_updates', v);
  }

  void setPriceDrops(bool v) {
    _priceDrops = v;
    notifyListeners();
    _updateSetting('price_drops', v);
  }

  void setNewFollowers(bool v) {
    _newFollowers = v;
    notifyListeners();
    _updateSetting('new_followers', v);
  }

  void setShowProfilePublicly(bool v) {
    _showProfilePublicly = v;
    notifyListeners();
    _updateSetting('show_profile_publicly', v);
  }

  void setAllowMessagesFromAnyone(bool v) {
    _allowMessagesFromAnyone = v;
    notifyListeners();
    _updateSetting('allow_messages_from_anyone', v);
  }

  void setLanguage(String v) {
    _language = v;
    notifyListeners();
    _updateSetting('language', v);
  }
}
