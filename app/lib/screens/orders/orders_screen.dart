import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/order_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/shared_app_bar.dart';
import '../product_detail/product_detail_screen.dart';

// ═════════════════════════════════════════════════════════════
// ── Orders Screen ───────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class OrdersScreen extends StatefulWidget {
  final bool canGoBack;

  const OrdersScreen({super.key, this.canGoBack = false});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  // 0 = Active, 1 = History
  int _tabIndex = 0;
  bool _loading = true;

  // ── Animation helpers ──────────────────────────────────────

  Animation<double> _fade(double start, double end) => CurvedAnimation(
        parent: _anim,
        curve: Interval(start.clamp(0, 1), end.clamp(0, 1),
            curve: Curves.easeOut),
      );

  Animation<Offset> _slide(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _anim,
          curve: Interval(start.clamp(0, 1), end.clamp(0, 1),
              curve: Curves.easeOut),
        ),
      );

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    await OrderService.instance.fetchOrders();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = OrderService.instance.orders;

    final activeOrders = orders
        .where((o) =>
            o.status == 'pending' ||
            o.status == 'confirmed' ||
            o.status == 'shipped')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final historyOrders = orders
        .where((o) => o.status == 'delivered' || o.status == 'cancelled')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: const SharedAppBar(currentRoute: '/orders'),
      drawer: const AppDrawer(currentRoute: '/orders'),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  FadeTransition(
                    opacity: _fade(0.0, 0.45),
                    child: SlideTransition(
                      position: _slide(0.0, 0.45),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: Row(
                          children: [
                            if (widget.canGoBack) ...[
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 20,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Text(
                              'Orders',
                              style: GoogleFonts.fraunces(
                                fontSize: 28,
                                fontWeight: FontWeight.w400,
                                color: AppColors.inkStrong,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Tabs ──
                  FadeTransition(
                    opacity: _fade(0.06, 0.50),
                    child: SlideTransition(
                      position: _slide(0.06, 0.50),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _TabLabel(
                              label: 'Active',
                              active: _tabIndex == 0,
                              onTap: () => setState(() => _tabIndex = 0),
                            ),
                            const SizedBox(width: 28),
                            _TabLabel(
                              label: 'History',
                              active: _tabIndex == 1,
                              onTap: () => setState(() => _tabIndex = 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Tab content ──
                  FadeTransition(
                    opacity: _fade(0.12, 0.55),
                    child: SlideTransition(
                      position: _slide(0.12, 0.55),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _tabIndex == 0
                            ? _OrdersList(
                                key: const ValueKey('active'),
                                orders: activeOrders,
                                emptyMessage: 'No active orders',
                              )
                            : _OrdersList(
                                key: const ValueKey('history'),
                                orders: historyOrders,
                                emptyMessage: 'No past orders',
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Tab label ───────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _TabLabel extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabLabel({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: GoogleFonts.fraunces(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: active ? AppColors.inkStrong : AppColors.muted,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 1.5,
            width: active ? 32 : 0,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Orders list ─────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _OrdersList extends StatelessWidget {
  final List<OrderData> orders;
  final String emptyMessage;

  const _OrdersList({
    super.key,
    required this.orders,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Center(
          child: Text(
            emptyMessage,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.muted,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: orders.map((order) => _OrderRow(order: order)).toList(),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Order row ───────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _OrderRow extends StatelessWidget {
  final OrderData order;

  const _OrderRow({required this.order});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${diff}d ago';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.gold;
      case 'confirmed':
        return AppColors.sage;
      case 'shipped':
        return AppColors.sage;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.muted;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  void _openDetail(BuildContext context) {
    // Navigate to the first item's piece detail if available
    if (order.items.isNotEmpty) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              ProductDetailScreen(pieceId: order.items.first.pieceId),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final title = firstItem?.pieceTitle ?? 'Order #${order.id}';
    final subtitle = order.sellerUsername ?? 'Seller';
    final color = _statusColor(order.status);

    return Column(
      children: [
        GestureDetector(
          onTap: () => _openDetail(context),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                // ── Product thumbnail ──
                _buildThumbnail(firstItem),

                const SizedBox(width: 14),

                // ── Name + seller ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkStrong,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // ── Price + status + date ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      order.totalFormatted,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusLabel(order.status),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(order.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(color: AppColors.hairline, height: 1, thickness: 1),
      ],
    );
  }

  Widget _buildThumbnail(OrderItemData? item) {
    if (item?.pieceCoverB64 != null && item!.pieceCoverB64!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          base64Decode(item.pieceCoverB64!),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.hairline2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, size: 20, color: AppColors.muted),
    );
  }
}
