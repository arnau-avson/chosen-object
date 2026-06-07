import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/follow_service.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/shared_app_bar.dart';
import 'user_profile_screen.dart';

// ═════════════════════════════════════════════════════════════
// ── Followers Screen ────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class FollowersScreen extends StatefulWidget {
  final int userId;
  final int initialTab;

  const FollowersScreen({
    super.key,
    required this.userId,
    this.initialTab = 0,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late int _activeTab;

  List<FollowUser> _followers = [];
  List<FollowUser> _following = [];
  bool _loadingFollowers = true;
  bool _loadingFollowing = true;

  int _followerCount = 0;
  int _followingCount = 0;

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
    _activeTab = widget.initialTab;
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loadData();
  }

  Future<void> _loadData() async {
    final fs = FollowService.instance;

    // Load counts
    final counts = await fs.fetchCounts(widget.userId);
    if (!mounted) return;
    setState(() {
      _followerCount = counts['followers'] ?? 0;
      _followingCount = counts['following'] ?? 0;
    });

    // Load followers
    final followers = await fs.getFollowers(widget.userId);
    if (!mounted) return;
    setState(() {
      _followers = followers;
      _loadingFollowers = false;
    });

    // Load following
    final following = await fs.getFollowing(widget.userId);
    if (!mounted) return;
    setState(() {
      _following = following;
      _loadingFollowing = false;
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _openProfile(int userId) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => UserProfileScreen(userId: userId.toString()),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: const SharedAppBar(currentRoute: '/followers', showBack: true),
      body: ListenableBuilder(
        listenable: FollowService.instance,
        builder: (context, _) {
          return Column(
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
                      'Connections',
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
                          label: 'Followers',
                          count: _followerCount,
                          active: _activeTab == 0,
                          onTap: () => setState(() => _activeTab = 0),
                        ),
                        const SizedBox(width: 24),
                        _TabLabel(
                          label: 'Following',
                          count: _followingCount,
                          active: _activeTab == 1,
                          onTap: () => setState(() => _activeTab = 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: AppColors.hairline, height: 1),
              ),

              // ── User list ──
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _activeTab == 0
                      ? _loadingFollowers
                          ? const Center(
                              key: ValueKey('loading-followers'),
                              child: LoadingSpinner(),
                            )
                          : _UserList(
                              key: const ValueKey('followers'),
                              users: _followers,
                              onTapUser: _openProfile,
                              fade: _fade,
                              slide: _slide,
                            )
                      : _loadingFollowing
                          ? const Center(
                              key: ValueKey('loading-following'),
                              child: LoadingSpinner(),
                            )
                          : _UserList(
                              key: const ValueKey('following'),
                              users: _following,
                              onTapUser: _openProfile,
                              fade: _fade,
                              slide: _slide,
                            ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Tab label ───────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _TabLabel extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _TabLabel({
    required this.label,
    required this.count,
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
              '$label  $count',
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
// ── User list ───────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _UserList extends StatelessWidget {
  final List<FollowUser> users;
  final void Function(int userId) onTapUser;
  final Animation<double> Function(double, double) fade;
  final Animation<Offset> Function(double, double) slide;

  const _UserList({
    super.key,
    required this.users,
    required this.onTapUser,
    required this.fade,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded, size: 36, color: AppColors.muted),
            const SizedBox(height: 10),
            Text(
              'No one yet',
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      separatorBuilder: (_, _) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(color: AppColors.hairline, height: 1),
      ),
      itemBuilder: (_, i) {
        final step = 0.04;
        final start = 0.12 + (i * step);
        return FadeTransition(
          opacity: fade(start, (start + 0.40).clamp(0, 1)),
          child: SlideTransition(
            position: slide(start, (start + 0.40).clamp(0, 1)),
            child: _UserRow(
              user: users[i],
              onTap: () => onTapUser(users[i].id),
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── User row ────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _UserRow extends StatelessWidget {
  final FollowUser user;
  final VoidCallback onTap;

  const _UserRow({required this.user, required this.onTap});

  Color _parseColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16) ?? 0x2E2520;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = user.studioName ?? user.username;
    final initials = displayName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join();
    final isFollowing = FollowService.instance.isFollowing(user.id);
    final avatarColor = _parseColor(user.avatarColor);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColor,
              ),
              alignment: Alignment.center,
              child: user.avatarImageB64 != null
                  ? ClipOval(
                      child: Image.memory(
                        base64Decode(user.avatarImageB64!),
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      initials,
                      style: GoogleFonts.fraunces(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
            ),
            const SizedBox(width: 14),

            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      '@${user.username}',
                      if (user.discipline != null) user.discipline!,
                    ].join(' · '),
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

            // Follow / Following button
            GestureDetector(
              onTap: () => FollowService.instance.toggleFollow(user.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isFollowing ? Colors.transparent : AppColors.ink,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isFollowing ? AppColors.hairline : AppColors.ink,
                    width: 1,
                  ),
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isFollowing ? AppColors.inkSoft : AppColors.bone,
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
