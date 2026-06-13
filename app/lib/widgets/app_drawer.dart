import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/auth_service.dart';
import '../core/cart_service.dart';
import '../core/message_service.dart';
import '../core/notification_service.dart';
import '../core/profile_service.dart';
import '../core/push_notification_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/collection/collection_screen.dart';
import '../screens/studios/studios_screen.dart';
import '../screens/messages/messages_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/payments/payments_screen.dart';
import '../screens/addresses/addresses_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/list_piece/list_piece_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/rental_calendar/rental_calendar_screen.dart';
import '../screens/my_pieces/my_pieces_screen.dart';

class AppDrawer extends StatefulWidget {
  final String? currentRoute;

  const AppDrawer({super.key, this.currentRoute});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // ── Secciones ──────────────────────────────────────────────

  List<_Section> _buildSections() {
    final msgCount = MessageService.instance.unreadCount + MessageService.instance.requestCount;
    final notifCount = NotificationService.instance.unreadCount;
    final cartCount = CartService.instance.itemCount;
    final role = ProfileService.instance.role.toLowerCase();
    final isSeller = role == 'seller' || role == 'both';

    return [
      _Section('Discover', [
        _Item('Home',            Icons.home_outlined,                 '/home'),
        _Item('Search',          Icons.search_outlined,               '/search'),
        _Item('Map',             Icons.map_outlined,                  '/map'),
        _Item('Studios',         Icons.storefront_outlined,           '/studios'),
      ]),
      _Section('Activity', [
        _Item('Collection',      Icons.bookmark_border_rounded,       '/collection'),
        _Item('Messages',        Icons.chat_bubble_outline_rounded,   '/messages',      badge: msgCount),
        _Item('Orders',          Icons.receipt_long_outlined,         '/orders',        badge: cartCount),
        _Item('Notifications',   Icons.notifications_none_rounded,    '/notifications', badge: notifCount),
      ]),
      _Section('Account', [
        _Item('Profile',         Icons.person_outline_rounded,        '/profile'),
        _Item('Settings',        Icons.tune_rounded,                  '/settings'),
        _Item('Addresses',       Icons.location_on_outlined,          '/addresses'),
        _Item('Payments',        Icons.credit_card_outlined,          '/payments'),
        _Item('Help',            Icons.help_outline_rounded,          '/help'),
      ]),
      if (isSeller) _Section('Sell', [
        _Item('List a piece',    Icons.add_photo_alternate_outlined,  '/list'),
        _Item('My pieces',       Icons.inventory_2_outlined,          '/my-pieces'),
        _Item('Dashboard',       Icons.bar_chart_rounded,             '/dashboard'),
        _Item('Rental calendar', Icons.calendar_today_outlined,       '/rental-calendar'),
      ]),
      _Section('Editorial', [
        _Item('Get the look',    Icons.auto_awesome_outlined,         '/get-the-look'),
        _Item('Themed week',     Icons.auto_stories_outlined,         '/themed-week'),
      ]),
      _Section('Trust console', [
        _Item('Admin console',   Icons.admin_panel_settings_outlined, '/admin'),
      ]),
    ];
  }


  // ── Animation helpers ───────────────────────────────────────

  Animation<double> _fade(double start, double end) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start.clamp(0, 1), end.clamp(0, 1),
            curve: Curves.easeOut),
      );

  Animation<Offset> _slide(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start.clamp(0, 1), end.clamp(0, 1),
              curve: Curves.easeOut),
        ),
      );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 305,
      backgroundColor: AppColors.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: Column(
        children: [
          // Header animado
          FadeTransition(
            opacity: _fade(0.0, 0.30),
            child: SlideTransition(
              position: _slide(0.0, 0.30),
              child: _buildHeader(context),
            ),
          ),

          const Divider(color: AppColors.hairline, height: 1, thickness: 1),

          // Lista de secciones
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                MessageService.instance,
                NotificationService.instance,
                CartService.instance,
                ProfileService.instance,
              ]),
              builder: (context, _) {
                final sections = _buildSections();
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 6, bottom: 16),
                  itemCount: sections.length,
                  itemBuilder: (_, i) {
                    final start = 0.08 + i * 0.09;
                    return FadeTransition(
                      opacity: _fade(start, start + 0.35),
                      child: SlideTransition(
                        position: _slide(start, start + 0.38),
                        child: _SectionWidget(
                          section: sections[i],
                          currentRoute: widget.currentRoute,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Footer con Sign out
          const Divider(color: AppColors.hairline, height: 1, thickness: 1),
          FadeTransition(
            opacity: _fade(0.65, 1.0),
            child: _buildFooter(context),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final p = ProfileService.instance;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: p,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 16, 18),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.avatarType == 'image' ? null : p.avatarColor,
                    image: p.avatarType == 'image' &&
                            p.avatarImageBytes != null
                        ? DecorationImage(
                            image: MemoryImage(p.avatarImageBytes!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: p.avatarType == 'image' &&
                          p.avatarImageBytes != null
                      ? null
                      : Text(
                          p.initials.isNotEmpty ? p.initials : '?',
                          style: GoogleFonts.fraunces(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                ),

                const SizedBox(width: 14),

                // Nombre y etiqueta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'My account',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.handle.isNotEmpty
                            ? p.handle
                            : p.name.isNotEmpty
                                ? p.name
                                : p.username,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkStrong,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botón cerrar
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.muted,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Close',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Footer ──────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: AppColors.ink.withValues(alpha: 0.05),
          highlightColor: AppColors.ink.withValues(alpha: 0.04),
          onTap: () async {
            Navigator.of(context).pop();
            await PushNotificationService.instance.unregisterToken();
            await AuthService.clearToken();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (_, _, _) => const LoginScreen(),
                  transitionsBuilder: (_, animation, _, child) =>
                      FadeTransition(opacity: animation, child: child),
                  transitionDuration: const Duration(milliseconds: 300),
                ),
                (_) => false,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.logout_outlined,
                  size: 18,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 13),
                Text(
                  'Sign out',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section ─────────────────────────────────────────────────

class _SectionWidget extends StatelessWidget {
  final _Section section;
  final String? currentRoute;
  const _SectionWidget({required this.section, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 5),
          child: Text(
            section.title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.muted2,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ...section.items.map(
          (item) => _ItemWidget(
            item: item,
            isActive: currentRoute == item.route,
          ),
        ),
      ],
    );
  }
}

// ── Item ────────────────────────────────────────────────────

class _ItemWidget extends StatelessWidget {
  final _Item item;
  final bool isActive;
  const _ItemWidget({required this.item, required this.isActive});

  void _navigateTo(BuildContext context, String route) {
    if (isActive) return;

    Widget? screen;
    switch (route) {
      case '/home':
        screen = const HomeScreen();
      case '/map':
        screen = const MapScreen();
      case '/search':
        screen = const SearchScreen();
      case '/studios':
        screen = const StudiosScreen();
      case '/collection':
        screen = const CollectionScreen();
      case '/messages':
        screen = const MessagesScreen();
      case '/orders':
        screen = const OrdersScreen();
      case '/notifications':
        screen = const NotificationsScreen();
      case '/profile':
        screen = const ProfileScreen();
      case '/settings':
        screen = const SettingsScreen();
      case '/edit-profile':
        screen = const EditProfileScreen();
      case '/payments':
        screen = const PaymentsScreen();
      case '/addresses':
        screen = const AddressesScreen();
      case '/list':
        screen = const ListPieceScreen();
      case '/my-pieces':
        screen = const MyPiecesScreen();
      case '/dashboard':
        screen = const DashboardScreen();
      case '/rental-calendar':
        screen = const RentalCalendarScreen();
    }

    if (screen != null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => screen!,
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: AppColors.ink.withValues(alpha: 0.05),
        highlightColor: AppColors.ink.withValues(alpha: 0.04),
        onTap: () {
          Navigator.of(context).pop();
          _navigateTo(context, item.route);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: isActive
              ? const BoxDecoration(
                  color: Color(0x0B2E2520),
                  border: Border(
                    left: BorderSide(color: AppColors.accent, width: 2.5),
                  ),
                )
              : const BoxDecoration(),
          padding: EdgeInsets.only(
            left: isActive ? 19.5 : 22,
            right: 22,
            top: 13,
            bottom: 13,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 18,
                color: isActive ? AppColors.accent : AppColors.inkSoft,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isActive ? AppColors.accent : AppColors.inkSoft,
                    fontWeight:
                        isActive ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
              if (item.badge != null) _Badge(count: item.badge!),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge ───────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.bone,
        ),
      ),
    );
  }
}

// ── Data models ─────────────────────────────────────────────

class _Section {
  final String title;
  final List<_Item> items;
  const _Section(this.title, this.items);
}

class _Item {
  final String label;
  final IconData icon;
  final String route;
  final int? badge;
  const _Item(this.label, this.icon, this.route, {this.badge});
}
