import 'package:flutter/material.dart';
import '../core/app_colors.dart';

enum NotificationType {
  orderUpdate,
  newFollower,
  priceDrop,
  newMessage,
  itemSold,
  system;

  String get label => switch (this) {
        orderUpdate => 'Order',
        newFollower => 'Follower',
        priceDrop => 'Price drop',
        newMessage => 'Message',
        itemSold => 'Sold',
        system => 'System',
      };

  IconData get icon => switch (this) {
        orderUpdate => Icons.local_shipping_outlined,
        newFollower => Icons.person_add_outlined,
        priceDrop => Icons.trending_down_rounded,
        newMessage => Icons.chat_bubble_outline_rounded,
        itemSold => Icons.sell_outlined,
        system => Icons.info_outline_rounded,
      };

  Color get color => switch (this) {
        orderUpdate => AppColors.sage,
        newFollower => AppColors.accent,
        priceDrop => AppColors.gold,
        newMessage => AppColors.inkSoft,
        itemSold => AppColors.success,
        system => AppColors.muted,
      };
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime date;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.date,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        date: date,
        isRead: isRead ?? this.isRead,
      );
}

final mockNotifications = <AppNotification>[
  AppNotification(
    id: 'notif-001',
    type: NotificationType.orderUpdate,
    title: 'Order shipped',
    body: 'Your Curved Vessel by Marta Sala has been shipped.',
    date: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  AppNotification(
    id: 'notif-002',
    type: NotificationType.newFollower,
    title: 'New follower',
    body: 'Elena Torres started following you.',
    date: DateTime.now().subtract(const Duration(hours: 8)),
  ),
  AppNotification(
    id: 'notif-003',
    type: NotificationType.priceDrop,
    title: 'Price drop',
    body: 'Bronze Table Lamp is now €420 (was €480).',
    date: DateTime.now().subtract(const Duration(days: 1)),
    isRead: true,
  ),
  AppNotification(
    id: 'notif-004',
    type: NotificationType.newMessage,
    title: 'New message',
    body: 'Clara Fontaine sent you a message about Linen Armchair.',
    date: DateTime.now().subtract(const Duration(days: 1)),
    isRead: true,
  ),
  AppNotification(
    id: 'notif-005',
    type: NotificationType.itemSold,
    title: 'Item sold',
    body: 'Your Stoneware Bowl has been purchased.',
    date: DateTime.now().subtract(const Duration(days: 3)),
    isRead: true,
  ),
  AppNotification(
    id: 'notif-006',
    type: NotificationType.orderUpdate,
    title: 'Order delivered',
    body: 'Your Walnut Side Table has been delivered.',
    date: DateTime.now().subtract(const Duration(days: 5)),
    isRead: true,
  ),
  AppNotification(
    id: 'notif-007',
    type: NotificationType.system,
    title: 'Welcome to Chosen Object',
    body: 'Discover unique design pieces from independent studios.',
    date: DateTime.now().subtract(const Duration(days: 12)),
    isRead: true,
  ),
];
