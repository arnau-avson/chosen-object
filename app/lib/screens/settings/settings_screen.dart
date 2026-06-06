import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/settings_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/shared_app_bar.dart';
import '../addresses/addresses_screen.dart';
import '../payments/payments_screen.dart';
import '../profile/edit_profile_screen.dart';

// ═════════════════════════════════════════════════════════════
// ── Settings Screen ─────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
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

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label — coming soon',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.bone,
          ),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _openAddresses() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const AddressesScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _openPayments() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const PaymentsScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _openEditProfile() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const EditProfileScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _pickAccountRole() {
    final s = SettingsService.instance;
    const roles = ['Buyer', 'Seller', 'Both'];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Account type',
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: AppColors.inkStrong,
              ),
            ),
            const SizedBox(height: 16),
            ...roles.map((role) {
              final selected = role == s.accountRole;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: AppColors.ink.withValues(alpha: 0.05),
                  onTap: () {
                    s.setAccountRole(role);
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 13, horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  color: selected
                                      ? AppColors.inkStrong
                                      : AppColors.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                role == 'Buyer'
                                    ? 'Browse, collect and purchase pieces'
                                    : role == 'Seller'
                                        ? 'List and sell your own pieces'
                                        : 'Buy and sell on the platform',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_rounded,
                              size: 16, color: AppColors.accent),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = SettingsService.instance;

    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: const SharedAppBar(currentRoute: '/settings'),
      drawer: const AppDrawer(currentRoute: '/settings'),
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) {
          return SingleChildScrollView(
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
                        'Settings',
                        style: GoogleFonts.fraunces(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: AppColors.inkStrong,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Section 1: Account ──
                FadeTransition(
                  opacity: _fade(0.06, 0.50),
                  child: SlideTransition(
                    position: _slide(0.06, 0.50),
                    child: _SettingsSection(
                      title: 'Account',
                      children: [
                        _NavigationRow(
                          label: 'Edit profile',
                          onTap: _openEditProfile,
                        ),
                        const Divider(
                            color: AppColors.hairline,
                            height: 1,
                            thickness: 1),
                        _TapRow(
                          label: 'Account type',
                          value: s.accountRole,
                          onTap: _pickAccountRole,
                        ),
                        const Divider(
                            color: AppColors.hairline,
                            height: 1,
                            thickness: 1),
                        _NavigationRow(
                          label: 'Addresses',
                          onTap: _openAddresses,
                        ),
                        const Divider(
                            color: AppColors.hairline,
                            height: 1,
                            thickness: 1),
                        _NavigationRow(
                          label: 'Payments',
                          onTap: _openPayments,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Section 2: Notifications ──
                FadeTransition(
                  opacity: _fade(0.12, 0.55),
                  child: SlideTransition(
                    position: _slide(0.12, 0.55),
                    child: _SettingsSection(
                      title: 'Notifications',
                      children: [
                        _ToggleRow(
                          label: 'Push notifications',
                          value: s.pushNotifications,
                          onChanged: s.setPushNotifications,
                        ),
                        const Divider(
                            color: AppColors.hairline,
                            height: 1,
                            thickness: 1),
                        _ToggleRow(
                          label: 'Email notifications',
                          value: s.emailNotifications,
                          onChanged: s.setEmailNotifications,
                        ),
                        const Divider(
                            color: AppColors.hairline,
                            height: 1,
                            thickness: 1),
                        _ToggleRow(
                          label: 'Order updates',
                          value: s.orderUpdates,
                          onChanged: s.setOrderUpdates,
                        ),
                        const Divider(
                            color: AppColors.hairline,
                            height: 1,
                            thickness: 1),
                        _ToggleRow(
                          label: 'Price drops',
                          value: s.priceDrops,
                          onChanged: s.setPriceDrops,
                        ),
                        const Divider(
                            color: AppColors.hairline,
                            height: 1,
                            thickness: 1),
                        _ToggleRow(
                          label: 'New followers',
                          value: s.newFollowers,
                          onChanged: s.setNewFollowers,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Section 3: Privacy ──
                FadeTransition(
                  opacity: _fade(0.18, 0.60),
                  child: SlideTransition(
                    position: _slide(0.18, 0.60),
                    child: _SettingsSection(
                      title: 'Privacy',
                      children: [
                        _ToggleRow(
                          label: 'Show profile publicly',
                          value: s.showProfilePublicly,
                          onChanged: s.setShowProfilePublicly,
                        ),
                        const Divider(
                            color: AppColors.hairline,
                            height: 1,
                            thickness: 1),
                        _ToggleRow(
                          label: 'Allow messages from anyone',
                          value: s.allowMessagesFromAnyone,
                          onChanged: s.setAllowMessagesFromAnyone,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Section 4: Appearance ──
                FadeTransition(
                  opacity: _fade(0.24, 0.65),
                  child: SlideTransition(
                    position: _slide(0.24, 0.65),
                    child: _SettingsSection(
                      title: 'Appearance',
                      children: [
                        _InfoRow(label: 'Language', value: s.language),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Section 5: Support ──
                FadeTransition(
                  opacity: _fade(0.30, 0.70),
                  child: SlideTransition(
                    position: _slide(0.30, 0.70),
                    child: _SettingsSection(
                      title: 'Support',
                      children: [
                        _NavigationRow(
                          label: 'Help',
                          onTap: () => _showComingSoon('Help'),
                        ),
                        const Divider(
                            color: AppColors.hairline,
                            height: 1,
                            thickness: 1),
                        const _InfoRow(label: 'About', value: 'v1.0.0'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Settings section ────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.muted2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.hairline, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Navigation row ──────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _NavigationRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavigationRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.ink.withValues(alpha: 0.05),
        highlightColor: AppColors.ink.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Toggle row ──────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          SizedBox(
            height: 32,
            child: FittedBox(
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.ink,
                activeTrackColor: AppColors.ink.withValues(alpha: 0.35),
                inactiveThumbColor: AppColors.muted,
                inactiveTrackColor: AppColors.hairline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Info row ────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

// ═════════════════════════════════════════════════════════════
// ── Tap row (label + value + chevron) ───────────────────────
// ═════════════════════════════════════════════════════════════

class _TapRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TapRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.ink.withValues(alpha: 0.05),
        highlightColor: AppColors.ink.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
