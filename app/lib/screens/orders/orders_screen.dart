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

  // 0 = My Purchases, 1 = My Sales
  int _roleIndex = 0;
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
    setState(() => _loading = true);
    final role = _roleIndex == 0 ? 'buyer' : 'seller';
    await OrderService.instance.fetchOrders(role: role);
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _switchRole(int index) {
    if (index == _roleIndex) return;
    setState(() {
      _roleIndex = index;
      _tabIndex = 0;
    });
    _loadOrders();
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

                  const SizedBox(height: 14),

                  // ── Role toggle (Purchases / Sales) ──
                  FadeTransition(
                    opacity: _fade(0.03, 0.47),
                    child: SlideTransition(
                      position: _slide(0.03, 0.47),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.hairline2,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              _RoleChip(
                                label: 'My Purchases',
                                active: _roleIndex == 0,
                                onTap: () => _switchRole(0),
                              ),
                              _RoleChip(
                                label: 'My Sales',
                                active: _roleIndex == 1,
                                onTap: () => _switchRole(1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Tabs (Active / History) ──
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
                                isSeller: _roleIndex == 1,
                                onStatusChanged: _loadOrders,
                              )
                            : _OrdersList(
                                key: const ValueKey('history'),
                                orders: historyOrders,
                                emptyMessage: 'No past orders',
                                isSeller: _roleIndex == 1,
                                onStatusChanged: _loadOrders,
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
// ── Role chip ───────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _RoleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: active ? FontWeight.w500 : FontWeight.w400,
              color: active ? AppColors.inkStrong : AppColors.muted,
            ),
          ),
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
  final bool isSeller;
  final VoidCallback onStatusChanged;

  const _OrdersList({
    super.key,
    required this.orders,
    required this.emptyMessage,
    required this.isSeller,
    required this.onStatusChanged,
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
        children: orders
            .map((order) => _OrderRow(
                  order: order,
                  isSeller: isSeller,
                  onStatusChanged: onStatusChanged,
                ))
            .toList(),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Order row ───────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _OrderRow extends StatefulWidget {
  final OrderData order;
  final bool isSeller;
  final VoidCallback onStatusChanged;

  const _OrderRow({
    required this.order,
    required this.isSeller,
    required this.onStatusChanged,
  });

  @override
  State<_OrderRow> createState() => _OrderRowState();
}

class _OrderRowState extends State<_OrderRow> {
  bool _actionLoading = false;

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
        return widget.isSeller ? 'Awaiting approval' : 'Pending';
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
    if (widget.order.items.isNotEmpty) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              ProductDetailScreen(pieceId: widget.order.items.first.pieceId),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  Future<void> _acceptOrder() async {
    setState(() => _actionLoading = true);
    await OrderService.instance.updateStatus(
      widget.order.id,
      status: 'confirmed',
    );
    setState(() => _actionLoading = false);
    widget.onStatusChanged();
  }

  Future<void> _rejectOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Decline order?',
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.inkStrong,
          ),
        ),
        content: Text(
          'This will cancel the order and restore stock. This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: AppColors.inkSoft,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Keep',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Decline',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _actionLoading = true);
    await OrderService.instance.updateStatus(
      widget.order.id,
      status: 'cancelled',
    );
    setState(() => _actionLoading = false);
    widget.onStatusChanged();
  }

  Future<void> _markShipped() async {
    final trackingCtrl = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Mark as shipped',
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.inkStrong,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Optionally add a tracking number:',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: trackingCtrl,
              decoration: InputDecoration(
                hintText: 'Tracking number (optional)',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.muted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.hairline),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.inkStrong),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(trackingCtrl.text),
            child: Text(
              'Confirm',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() => _actionLoading = true);
    await OrderService.instance.updateStatus(
      widget.order.id,
      status: 'shipped',
      trackingNumber: result.isEmpty ? null : result,
    );
    setState(() => _actionLoading = false);
    widget.onStatusChanged();
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Cancel order?',
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.inkStrong,
          ),
        ),
        content: Text(
          'This will cancel your order. This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: AppColors.inkSoft,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Keep',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Cancel order',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _actionLoading = true);
    await OrderService.instance.cancelOrder(widget.order.id);
    setState(() => _actionLoading = false);
    widget.onStatusChanged();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final title = firstItem?.pieceTitle ?? 'Order #${order.id}';
    final subtitle = widget.isSeller
        ? order.buyerUsername ?? 'Buyer'
        : order.sellerUsername ?? 'Seller';
    final color = _statusColor(order.status);

    return Column(
      children: [
        GestureDetector(
          onTap: () => _openDetail(context),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    // ── Product thumbnail ──
                    _buildThumbnail(firstItem),

                    const SizedBox(width: 14),

                    // ── Name + seller/buyer ──
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

                // ── Action buttons ──
                if (_actionLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                  )
                else
                  _buildActions(order),
              ],
            ),
          ),
        ),
        const Divider(color: AppColors.hairline, height: 1, thickness: 1),
      ],
    );
  }

  Widget _buildActions(OrderData order) {
    // Seller actions
    if (widget.isSeller) {
      if (order.status == 'pending') {
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Accept',
                  color: AppColors.success,
                  onTap: _acceptOrder,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'Decline',
                  color: AppColors.danger,
                  outlined: true,
                  onTap: _rejectOrder,
                ),
              ),
            ],
          ),
        );
      }
      if (order.status == 'confirmed') {
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Mark shipped',
                  color: AppColors.accent,
                  onTap: _markShipped,
                ),
              ),
            ],
          ),
        );
      }
    }

    // Buyer actions
    if (!widget.isSeller && order.status == 'pending') {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _ActionButton(
              label: 'Cancel',
              color: AppColors.danger,
              outlined: true,
              onTap: _cancelOrder,
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
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

// ═════════════════════════════════════════════════════════════
// ── Action button ───────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    this.outlined = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: outlined ? color : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
