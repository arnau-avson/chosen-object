import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/browse_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/shared_app_bar.dart';
import '../profile/user_profile_screen.dart';

// ── Helpers ────────────────────────────────────────────────────

String _formatNumber(int n) {
  if (n < 1000) return '$n';
  final s = n.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

Color _parseHexColor(String hex) {
  return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
}

// ── Studios Screen ────────────────────────────────────────────

class StudiosScreen extends StatefulWidget {
  const StudiosScreen({super.key});

  @override
  State<StudiosScreen> createState() => _StudiosScreenState();
}

class _StudiosScreenState extends State<StudiosScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fetchStudios();
  }

  Future<void> _fetchStudios() async {
    await BrowseService.instance.fetchUsers();
    if (!mounted) return;
    setState(() => _initialLoading = false);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      drawer: const AppDrawer(currentRoute: '/studios'),
      appBar: const SharedAppBar(currentRoute: '/studios'),
      body: _initialLoading
          ? const Center(child: LoadingSpinner())
          : ListenableBuilder(
              listenable: BrowseService.instance,
              builder: (context, _) {
                final users = BrowseService.instance.users;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeTransition(
                        opacity: _fade(0.0, 0.5),
                        child: SlideTransition(
                          position: _slide(0.0, 0.5),
                          child: _StudiosHeader(userCount: users.length),
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeTransition(
                        opacity: _fade(0.2, 0.7),
                        child: SlideTransition(
                          position: _slide(0.2, 0.7),
                          child: _StudioGrid(users: users),
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

// ── Studios header ────────────────────────────────────────────

class _StudiosHeader extends StatelessWidget {
  final int userCount;
  const _StudiosHeader({required this.userCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Center(
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left: No number ──
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'N\u00ba',
                    style: GoogleFonts.fraunces(
                      fontSize: 42,
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                      color: AppColors.gold,
                      height: 1.0,
                    ),
                  ),
                ],
              ),

              // ── Vertical divider ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Container(width: 1, color: AppColors.hairline),
              ),

              // ── Right: info lines ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$userCount studios',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.muted,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'The studios behind\nevery ',
                          style: GoogleFonts.fraunces(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w400,
                            color: AppColors.inkSoft,
                            height: 1.4,
                          ),
                        ),
                        TextSpan(
                          text: 'piece.',
                          style: GoogleFonts.fraunces(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            color: AppColors.inkSoft,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Studio grid ───────────────────────────────────────────────

class _StudioGrid extends StatelessWidget {
  final List<BrowseUser> users;
  const _StudioGrid({required this.users});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: users.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 24,
          childAspectRatio: 0.58,
        ),
        itemBuilder: (_, i) => _StudioCard(user: users[i]),
      ),
    );
  }
}

// ── Studio card ───────────────────────────────────────────────

class _StudioCard extends StatefulWidget {
  final BrowseUser user;
  const _StudioCard({required this.user});

  @override
  State<_StudioCard> createState() => _StudioCardState();
}

class _StudioCardState extends State<_StudioCard> {
  bool _saved = false;

  void _openProfile() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            UserProfileScreen(userId: widget.user.id.toString()),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final displayName = u.studioName ?? u.username;
    final locationParts = <String>[
      if (u.city != null) u.city!,
      if (u.discipline != null) u.discipline!,
    ];
    final description = locationParts.join(' \u00b7 ');
    final stats =
        '${u.piecesCount} pieces \u00b7 ${_formatNumber(u.followersCount)} followers';

    final avatarColor = _parseHexColor(u.avatarColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Image / avatar area ──
        Expanded(
          child: GestureDetector(
            onTap: _openProfile,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: u.avatarImageB64 != null
                  ? Image.memory(
                      base64Decode(u.avatarImageB64!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: avatarColor,
                      width: double.infinity,
                    ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Info + save icon ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _openProfile,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkStrong,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Location / discipline
                    if (description.isNotEmpty)
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.muted,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Stats
                    Text(
                      stats,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _saved = !_saved),
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 1),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    _saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    key: ValueKey(_saved),
                    size: 18,
                    color: _saved ? AppColors.accent : AppColors.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
