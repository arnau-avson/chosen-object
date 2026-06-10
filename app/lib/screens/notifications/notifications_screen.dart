import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/notification_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/shared_app_bar.dart';
import 'notification_settings_sheet.dart';

// ═════════════════════════════════════════════════════════════
// ── Notifications Screen ────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
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
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await NotificationService.instance.fetchNotifications();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────

  void _markRead(int id) {
    NotificationService.instance.markRead(id).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _markAllRead() {
    NotificationService.instance.markAllRead().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = NotificationService.instance.notifications;
    final unread = notifications.where((n) => !n.isRead).toList();
    final read = notifications.where((n) => n.isRead).toList();

    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: const SharedAppBar(currentRoute: '/notifications'),
      drawer: const AppDrawer(currentRoute: '/notifications'),
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
                            Expanded(
                              child: Text(
                                'Notifications',
                                style: GoogleFonts.fraunces(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.inkStrong,
                                ),
                              ),
                            ),
                            if (unread.isNotEmpty)
                              GestureDetector(
                                onTap: _markAllRead,
                                child: Text(
                                  'Mark all read',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () =>
                                  NotificationSettingsSheet.show(context),
                              child: const Icon(
                                Icons.tune_rounded,
                                size: 20,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Unread section ──
                  if (unread.isNotEmpty) ...[
                    FadeTransition(
                      opacity: _fade(0.06, 0.50),
                      child: SlideTransition(
                        position: _slide(0.06, 0.50),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'New',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.14 * 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _fade(0.08, 0.52),
                      child: SlideTransition(
                        position: _slide(0.08, 0.52),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: unread
                                .map((n) => _NotificationRow(
                                      key: ValueKey(n.id),
                                      notification: n,
                                      onMarkRead: () => _markRead(n.id),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Read section ──
                  if (read.isNotEmpty) ...[
                    FadeTransition(
                      opacity: _fade(0.10, 0.54),
                      child: SlideTransition(
                        position: _slide(0.10, 0.54),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Earlier',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.14 * 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _fade(0.12, 0.55),
                      child: SlideTransition(
                        position: _slide(0.12, 0.55),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: read
                                .map((n) => _NotificationRow(
                                      key: ValueKey(n.id),
                                      notification: n,
                                      onMarkRead: null,
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ── Empty state ──
                  if (unread.isEmpty && read.isEmpty)
                    FadeTransition(
                      opacity: _fade(0.06, 0.50),
                      child: SlideTransition(
                        position: _slide(0.06, 0.50),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 64),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 36,
                                  color: AppColors.hairline2,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No notifications yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Notification row (swipeable) ────────────────────────────
// ═════════════════════════════════════════════════════════════

class _NotificationRow extends StatefulWidget {
  final NotificationData notification;
  final VoidCallback? onMarkRead;

  const _NotificationRow({
    super.key,
    required this.notification,
    required this.onMarkRead,
  });

  @override
  State<_NotificationRow> createState() => _NotificationRowState();
}

class _NotificationRowState extends State<_NotificationRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _slideAnim;
  double _dragExtent = 0;

  static const double _actionW = 64;
  static const double _maxSlide = _actionW;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnim = const AlwaysStoppedAnimation(0);
    _ctrl.addListener(() {
      setState(() => _dragExtent = _slideAnim.value);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      _dragExtent = (_dragExtent + d.delta.dx).clamp(-_maxSlide, 0);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v < -300 || _dragExtent < -_maxSlide / 2) {
      _snapTo(-_maxSlide);
    } else {
      _snapTo(0);
    }
  }

  void _snapTo(double target) {
    _slideAnim = Tween<double>(begin: _dragExtent, end: target).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward(from: 0);
  }

  void _close() => _snapTo(0);

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'order_update':
        return Icons.local_shipping_outlined;
      case 'follow':
        return Icons.person_add_outlined;
      case 'price_drop':
        return Icons.trending_down_rounded;
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'item_sold':
        return Icons.sell_outlined;
      case 'new_piece':
        return Icons.auto_awesome_outlined;
      case 'piece_update':
        return Icons.edit_outlined;
      case 'rental':
        return Icons.calendar_today_outlined;
      case 'rental_status':
        return Icons.update_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'order_update':
        return AppColors.sage;
      case 'follow':
        return AppColors.accent;
      case 'price_drop':
        return AppColors.gold;
      case 'message':
        return AppColors.inkSoft;
      case 'item_sold':
        return AppColors.success;
      case 'new_piece':
        return AppColors.gold;
      case 'piece_update':
        return AppColors.sage;
      case 'rental':
        return AppColors.accent;
      case 'rental_status':
        return AppColors.sage;
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final isUnread = !n.isRead;
    final iconColor = _typeColor(n.type);

    return Column(
      children: [
        ClipRect(
          child: Stack(
            children: [
              // ── Action button (revealed on swipe) ──
              if (isUnread)
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _close();
                          widget.onMarkRead?.call();
                        },
                        child: Container(
                          width: _actionW,
                          color: AppColors.sage,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                color: AppColors.surface,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Read',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.surface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Sliding content ──
              GestureDetector(
                onHorizontalDragUpdate: isUnread ? _onDragUpdate : null,
                onHorizontalDragEnd: isUnread ? _onDragEnd : null,
                child: Transform.translate(
                  offset: Offset(_dragExtent, 0),
                  child: Container(
                    color: AppColors.bone,
                    padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Unread dot ──
                        if (isUnread)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, right: 10),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        if (!isUnread) const SizedBox(width: 16),

                        // ── Type icon ──
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _typeIcon(n.type),
                            size: 18,
                            color: iconColor,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // ── Title + body ──
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: isUnread
                                            ? FontWeight.w500
                                            : FontWeight.w400,
                                        color: AppColors.inkStrong,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(n.createdAt),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                              if (n.body != null && n.body!.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  n.body!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: isUnread
                                        ? AppColors.inkSoft
                                        : AppColors.muted,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.hairline, height: 1, thickness: 1),
      ],
    );
  }
}
