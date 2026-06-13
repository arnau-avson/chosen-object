import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/cart_service.dart';
import '../core/message_service.dart';
import '../core/notification_service.dart';
import '../screens/collection/collection_screen.dart';
import '../screens/home/home_screen.dart';

class SharedAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? currentRoute;
  final bool hideSearchIcon;
  final bool showBack;
  final String? title;

  const SharedAppBar({super.key, this.currentRoute, this.hideSearchIcon = false, this.showBack = false, this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<SharedAppBar> createState() => _SharedAppBarState();
}

class _SharedAppBarState extends State<SharedAppBar>
    with SingleTickerProviderStateMixin {
  bool _searchActive = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  late final AnimationController _searchAnim;
  late final Animation<double> _titleFade;
  late final Animation<double> _searchFade;
  late final Animation<Offset> _searchSlide;

  @override
  void initState() {
    super.initState();
    _searchAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 230),
    );
    final curve = CurvedAnimation(parent: _searchAnim, curve: Curves.easeOut);
    _titleFade = Tween<double>(begin: 1.0, end: 0.0).animate(curve);
    _searchFade = curve;
    _searchSlide = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(curve);

    // Fetch badge counts
    NotificationService.instance.fetchUnreadCount();
    MessageService.instance.fetchUnreadCount();
    MessageService.instance.fetchRequests();
    CartService.instance.fetchCart();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchAnim.dispose();
    super.dispose();
  }

  void _closeSearch() {
    _searchFocusNode.unfocus();
    _searchAnim.reverse().then((_) {
      if (mounted) {
        _searchController.clear();
        setState(() => _searchActive = false);
      }
    });
  }

  void _showNotificationsModal(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (_, anim, _, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curve),
          child: FadeTransition(opacity: curve, child: child),
        );
      },
      pageBuilder: (_, _, _) => const _NotificationsModal(),
    );
  }

  void _showCartModal(BuildContext context) {
    CartService.instance.fetchCart();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _CartModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: widget.showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 21),
              color: AppColors.inkSoft,
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (_, _, _) => const HomeScreen(),
                      transitionsBuilder: (_, animation, _, child) =>
                          FadeTransition(opacity: animation, child: child),
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                }
              },
              tooltip: 'Back',
            )
          : ListenableBuilder(
              listenable: Listenable.merge([
                MessageService.instance,
                NotificationService.instance,
                CartService.instance,
              ]),
              builder: (context, _) {
                final total = MessageService.instance.unreadCount +
                    MessageService.instance.requestCount +
                    NotificationService.instance.unreadCount +
                    CartService.instance.itemCount;
                return IconButton(
                  icon: Badge(
                    isLabelVisible: total > 0,
                    label: Text(
                      total.toString(),
                      style: const TextStyle(fontSize: 9),
                    ),
                    backgroundColor: const Color(0xFFCC3333),
                    child: const Icon(Icons.menu_rounded, size: 22),
                  ),
                  color: AppColors.inkSoft,
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Menu',
                );
              },
            ),
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Row(
          children: [
            // ── Expanded area: wordmark <-> search field ──
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Wordmark or custom title fades out
                  IgnorePointer(
                    ignoring: _searchActive,
                    child: FadeTransition(
                      opacity: _titleFade,
                      child: widget.title != null
                          ? Text(
                              widget.title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : const Text('Chosen Object'),
                    ),
                  ),
                  // Search field slides+fades in
                  IgnorePointer(
                    ignoring: !_searchActive,
                    child: FadeTransition(
                      opacity: _searchFade,
                      child: SlideTransition(
                        position: _searchSlide,
                        child: FractionallySizedBox(
                          widthFactor: 0.95,
                          alignment: Alignment.center,
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            textInputAction: TextInputAction.search,
                            style: GoogleFonts.inter(
                                fontSize: 14.5, color: AppColors.inkStrong),
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: GoogleFonts.inter(
                                  fontSize: 14.5, color: AppColors.muted),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: const BorderSide(
                                    color: AppColors.ink, width: 1.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: const BorderSide(
                                    color: AppColors.ink, width: 1.0),
                              ),
                              suffixIcon: IconButton(
                                icon:
                                    const Icon(Icons.close_rounded, size: 18),
                                color: AppColors.muted,
                                onPressed: _closeSearch,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                            onSubmitted: (_) {},
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Action icons collapse as search opens ──
            SizeTransition(
              sizeFactor: _titleFade,
              axis: Axis.horizontal,
              axisAlignment: 1,
              child: IgnorePointer(
                ignoring: _searchActive,
                child: FadeTransition(
                  opacity: _titleFade,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!widget.hideSearchIcon)
                        ListenableBuilder(
                          listenable: CartService.instance,
                          builder: (context, _) {
                            final count = CartService.instance.itemCount;
                            return IconButton(
                              icon: Badge(
                                isLabelVisible: count > 0,
                                label: Text(
                                  count.toString(),
                                  style: const TextStyle(fontSize: 9),
                                ),
                                backgroundColor: AppColors.accent,
                                child: const Icon(
                                    Icons.shopping_bag_outlined, size: 21),
                              ),
                              tooltip: 'Cart',
                              color: AppColors.inkSoft,
                              onPressed: () => _showCartModal(context),
                            );
                          },
                        ),
                      IconButton(
                        icon: const Icon(
                            Icons.bookmark_border_rounded,
                            size: 21),
                        tooltip: 'Saved',
                        color: AppColors.inkSoft,
                        onPressed: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, _, _) =>
                                  const CollectionScreen(),
                              transitionsBuilder:
                                  (_, animation, _, child) =>
                                      FadeTransition(
                                          opacity: animation,
                                          child: child),
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                            Icons.notifications_none_rounded,
                            size: 22),
                        tooltip: 'Notifications',
                        color: AppColors.inkSoft,
                        onPressed: () => _showNotificationsModal(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: const [],
    );
  }
}

// ── Notifications modal ──────────────────────────────────────

class _NotificationsModal extends StatefulWidget {
  const _NotificationsModal();

  @override
  State<_NotificationsModal> createState() => _NotificationsModalState();
}

class _NotificationsModalState extends State<_NotificationsModal> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await NotificationService.instance.fetchNotifications();
    if (mounted) setState(() => _loading = false);
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
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
      case 'order_update': return Icons.local_shipping_outlined;
      case 'follow': return Icons.person_add_outlined;
      case 'price_drop': return Icons.trending_down_rounded;
      case 'message': return Icons.chat_bubble_outline_rounded;
      case 'item_sold': return Icons.sell_outlined;
      case 'new_piece': return Icons.auto_awesome_outlined;
      case 'piece_update': return Icons.edit_outlined;
      case 'rental': return Icons.calendar_today_outlined;
      case 'rental_status': return Icons.update_rounded;
      default: return Icons.info_outline_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'order_update': return AppColors.sage;
      case 'follow': return AppColors.accent;
      case 'price_drop': return AppColors.gold;
      case 'message': return AppColors.inkSoft;
      case 'item_sold': return AppColors.success;
      case 'new_piece': return AppColors.gold;
      case 'piece_update': return AppColors.sage;
      case 'rental': return AppColors.accent;
      case 'rental_status': return AppColors.sage;
      default: return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 480),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.hairline, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Text(
                      'Notifications',
                      style: GoogleFonts.fraunces(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: AppColors.inkStrong,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: AppColors.muted,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.hairline, height: 1, thickness: 1),

              // ── Content ──
              Flexible(
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      )
                    : ListenableBuilder(
                        listenable: NotificationService.instance,
                        builder: (context, _) {
                          final notifications =
                              NotificationService.instance.notifications;

                          if (notifications.isEmpty) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 48),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
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
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Show up to 10 recent notifications
                          final items = notifications.take(10).toList();
                          final hasUnread =
                              items.any((n) => !n.isRead);

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasUnread)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 12, 20, 0),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () {
                                        NotificationService.instance
                                            .markAllRead();
                                      },
                                      child: Text(
                                        'Mark all read',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Flexible(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4),
                                  itemCount: items.length,
                                  itemBuilder: (_, i) {
                                    final n = items[i];
                                    final isUnread = !n.isRead;
                                    final iconColor =
                                        _typeColor(n.type);

                                    return GestureDetector(
                                      onTap: isUnread
                                          ? () => NotificationService
                                              .instance
                                              .markRead(n.id)
                                          : null,
                                      behavior:
                                          HitTestBehavior.opaque,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 10),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            if (isUnread)
                                              Padding(
                                                padding:
                                                    const EdgeInsets
                                                        .only(
                                                        top: 6,
                                                        right: 8),
                                                child: Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: AppColors
                                                        .accent,
                                                    shape: BoxShape
                                                        .circle,
                                                  ),
                                                ),
                                              ),
                                            if (!isUnread)
                                              const SizedBox(
                                                  width: 13),
                                            Container(
                                              width: 30,
                                              height: 30,
                                              decoration:
                                                  BoxDecoration(
                                                color: iconColor
                                                    .withValues(
                                                        alpha:
                                                            0.10),
                                                shape:
                                                    BoxShape.circle,
                                              ),
                                              alignment:
                                                  Alignment.center,
                                              child: Icon(
                                                _typeIcon(n.type),
                                                size: 14,
                                                color: iconColor,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          n.title,
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                          style:
                                                              GoogleFonts
                                                                  .inter(
                                                            fontSize:
                                                                12,
                                                            fontWeight: isUnread
                                                                ? FontWeight
                                                                    .w500
                                                                : FontWeight
                                                                    .w400,
                                                            color: AppColors
                                                                .inkStrong,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          width: 6),
                                                      Text(
                                                        _formatDate(
                                                            n.createdAt),
                                                        style:
                                                            GoogleFonts
                                                                .inter(
                                                          fontSize:
                                                              10,
                                                          color:
                                                              AppColors
                                                                  .muted,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (n.body !=
                                                          null &&
                                                      n.body!
                                                          .isNotEmpty) ...[
                                                    const SizedBox(
                                                        height: 2),
                                                    Text(
                                                      n.body!,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow
                                                              .ellipsis,
                                                      style:
                                                          GoogleFonts
                                                              .inter(
                                                        fontSize: 11,
                                                        color: isUnread
                                                            ? AppColors
                                                                .inkSoft
                                                            : AppColors
                                                                .muted,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cart modal ─────────────────────────────────────────────────

class _CartModal extends StatelessWidget {
  const _CartModal();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListenableBuilder(
            listenable: CartService.instance,
            builder: (context, _) {
              final cart = CartService.instance;
              final items = cart.items;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Handle ──
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.hairline,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),

                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 14, 0),
                    child: Row(
                      children: [
                        Text(
                          'Cart',
                          style: GoogleFonts.fraunces(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: AppColors.inkStrong,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (items.isNotEmpty)
                          Text(
                            '${items.length} item${items.length == 1 ? '' : 's'}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: AppColors.muted,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child:
                        Divider(color: AppColors.hairline, height: 20),
                  ),

                  // ── Content ──
                  if (cart.loading)
                    const Expanded(
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    )
                  else if (items.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shopping_bag_outlined,
                              size: 36,
                              color: AppColors.hairline2,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your cart is empty',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Browse pieces and add them\nto your cart',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.muted2,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // ── Items list ──
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(
                            color: AppColors.hairline, height: 1),
                        itemBuilder: (_, i) {
                          final item = items[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            child: Row(
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(6),
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    color: AppColors.hairline2,
                                    child: item.coverImageB64 != null
                                        ? Image.memory(
                                            base64Decode(
                                                item.coverImageB64!),
                                            fit: BoxFit.cover,
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons.image_outlined,
                                              size: 20,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.inkStrong,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        item.priceFormatted,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.inkSoft,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Remove
                                GestureDetector(
                                  onTap: () => CartService.instance
                                      .removeFromCart(item.pieceId),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // ── Footer: total + checkout ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: AppColors.hairline, width: 1),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Total',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.inkStrong,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  cart.totalFormatted,
                                  style: GoogleFonts.fraunces(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.inkStrong,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Checkout coming soon'),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.ink,
                                  borderRadius:
                                      BorderRadius.circular(4),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Proceed to checkout',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.bone,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}
