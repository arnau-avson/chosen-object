import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../models/app_notification.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/shared_app_bar.dart';

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
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────

  void _toggleRead(String id) {
    setState(() {
      final idx = mockNotifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        mockNotifications[idx] =
            mockNotifications[idx].copyWith(isRead: !mockNotifications[idx].isRead);
      }
    });
  }

  void _delete(String id) {
    setState(() {
      mockNotifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread =
        mockNotifications.where((n) => !n.isRead).toList();
    final read =
        mockNotifications.where((n) => n.isRead).toList();

    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: const SharedAppBar(currentRoute: '/notifications'),
      drawer: const AppDrawer(currentRoute: '/notifications'),
      body: SingleChildScrollView(
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
                  child: Text(
                    'Notifications',
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkStrong,
                    ),
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
                                onToggleRead: () => _toggleRead(n.id),
                                onDelete: () => _delete(n.id),
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
                                onToggleRead: () => _toggleRead(n.id),
                                onDelete: () => _delete(n.id),
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
  final AppNotification notification;
  final VoidCallback onToggleRead;
  final VoidCallback onDelete;

  const _NotificationRow({
    super.key,
    required this.notification,
    required this.onToggleRead,
    required this.onDelete,
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
  static const double _maxSlide = _actionW * 2;

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

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final isUnread = !n.isRead;

    return Column(
      children: [
        ClipRect(
          child: Stack(
            children: [
              // ── Action buttons (revealed on swipe) ──
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Mark as read / unread
                    GestureDetector(
                      onTap: () {
                        _close();
                        widget.onToggleRead();
                      },
                      child: Container(
                        width: _actionW,
                        color: AppColors.sage,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isUnread
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.surface,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isUnread ? 'Read' : 'Unread',
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

                    // Delete
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        width: _actionW,
                        color: AppColors.danger,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.surface,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Delete',
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
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
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
                            color: n.type.color.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            n.type.icon,
                            size: 18,
                            color: n.type.color,
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
                                    _formatDate(n.date),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                n.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color:
                                      isUnread ? AppColors.inkSoft : AppColors.muted,
                                  height: 1.4,
                                ),
                              ),
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
