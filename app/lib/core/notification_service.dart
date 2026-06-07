import 'package:flutter/foundation.dart';

import 'api_client.dart';

// ═════════════════════════════════════════════════════════════
// ── NotificationService (singleton ChangeNotifier) ────────────
// ═════════════════════════════════════════════════════════════

class NotificationData {
  final int id;
  final String type;
  final String title;
  final String? body;
  final bool isRead;
  final int? referenceId;
  final String? referenceType;
  final DateTime createdAt;

  NotificationData({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    required this.isRead,
    this.referenceId,
    this.referenceType,
    required this.createdAt,
  });

  factory NotificationData.fromJson(Map<String, dynamic> j) => NotificationData(
        id: j['id'] as int,
        type: j['type'] as String,
        title: j['title'] as String,
        body: j['body'] as String?,
        isRead: j['is_read'] as bool,
        referenceId: j['reference_id'] as int?,
        referenceType: j['reference_type'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  NotificationService._();

  List<NotificationData> _notifications = [];
  List<NotificationData> get notifications => _notifications;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _loading = false;
  bool get loading => _loading;

  /// Fetch notifications.
  Future<void> fetchNotifications({int offset = 0, int limit = 20}) async {
    _loading = true;
    notifyListeners();

    try {
      final data =
          await ApiClient.instance.get('/notifications?offset=$offset&limit=$limit');
      _notifications = (data as List)
          .map((j) => NotificationData.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // keep existing
    }

    _loading = false;
    notifyListeners();
  }

  /// Fetch unread count.
  Future<void> fetchUnreadCount() async {
    try {
      final data = await ApiClient.instance.get('/notifications/unread-count');
      _unreadCount = (data as Map<String, dynamic>)['unread_count'] as int;
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  /// Mark single notification as read.
  Future<void> markRead(int notificationId) async {
    try {
      await ApiClient.instance.patch('/notifications/$notificationId/read', {});
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        _notifications[idx] = NotificationData(
          id: _notifications[idx].id,
          type: _notifications[idx].type,
          title: _notifications[idx].title,
          body: _notifications[idx].body,
          isRead: true,
          referenceId: _notifications[idx].referenceId,
          referenceType: _notifications[idx].referenceType,
          createdAt: _notifications[idx].createdAt,
        );
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (_) {
      // ignore
    }
  }

  /// Mark all as read.
  Future<void> markAllRead() async {
    try {
      await ApiClient.instance.patch('/notifications/read-all', {});
      _notifications = _notifications
          .map((n) => NotificationData(
                id: n.id,
                type: n.type,
                title: n.title,
                body: n.body,
                isRead: true,
                referenceId: n.referenceId,
                referenceType: n.referenceType,
                createdAt: n.createdAt,
              ))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }
}
