import 'package:flutter/material.dart';
import '../core/app_colors.dart';

enum OrderStatus {
  pending,
  shipped,
  delivered,
  cancelled;

  String get label => switch (this) {
        pending => 'Pending',
        shipped => 'Shipped',
        delivered => 'Delivered',
        cancelled => 'Cancelled',
      };

  Color get color => switch (this) {
        pending => AppColors.gold,
        shipped => AppColors.sage,
        delivered => AppColors.success,
        cancelled => AppColors.danger,
      };
}

class Order {
  final String id;
  final String productId;
  final String productName;
  final String designerName;
  final String price;
  final OrderStatus status;
  final DateTime date;
  final Color imageColor;
  final String? trackingNumber;

  const Order({
    required this.id,
    required this.productId,
    required this.productName,
    required this.designerName,
    required this.price,
    required this.status,
    required this.date,
    required this.imageColor,
    this.trackingNumber,
  });
}

final mockOrders = <Order>[
  Order(
    id: 'ord-001',
    productId: 'curved-vessel',
    productName: 'Curved Vessel',
    designerName: 'Marta Sala',
    price: '€340',
    status: OrderStatus.shipped,
    date: DateTime.now().subtract(const Duration(days: 2)),
    imageColor: const Color(0xFFBEB0A0),
    trackingNumber: 'ES29384710',
  ),
  Order(
    id: 'ord-002',
    productId: 'linen-armchair',
    productName: 'Linen Armchair',
    designerName: 'Atelier NM',
    price: '€1,200',
    status: OrderStatus.pending,
    date: DateTime.now().subtract(const Duration(days: 1)),
    imageColor: const Color(0xFFCBC2B4),
  ),
  Order(
    id: 'ord-003',
    productId: 'bronze-table-lamp',
    productName: 'Bronze Table Lamp',
    designerName: 'Studio Vèra',
    price: '€480',
    status: OrderStatus.delivered,
    date: DateTime.now().subtract(const Duration(days: 14)),
    imageColor: const Color(0xFFA8997E),
    trackingNumber: 'ES10293847',
  ),
  Order(
    id: 'ord-004',
    productId: 'walnut-side-table',
    productName: 'Walnut Side Table',
    designerName: 'Jordi Canudas',
    price: '€720',
    status: OrderStatus.delivered,
    date: DateTime.now().subtract(const Duration(days: 30)),
    imageColor: const Color(0xFF9A8C7B),
    trackingNumber: 'ES55938271',
  ),
  Order(
    id: 'ord-005',
    productId: 'stoneware-bowl',
    productName: 'Terracotta Planter',
    designerName: 'Laia Clos',
    price: '€90',
    status: OrderStatus.cancelled,
    date: DateTime.now().subtract(const Duration(days: 21)),
    imageColor: const Color(0xFFC4A882),
  ),
  Order(
    id: 'ord-006',
    productId: 'woven-throw',
    productName: 'Silk Cushion Set',
    designerName: 'Casa Textil',
    price: '€260',
    status: OrderStatus.shipped,
    date: DateTime.now().subtract(const Duration(days: 3)),
    imageColor: const Color(0xFFD4C8B8),
    trackingNumber: 'ES77281940',
  ),
];
