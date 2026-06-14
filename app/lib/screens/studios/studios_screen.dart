import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/browse_service.dart';
import '../../core/follow_service.dart';
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
  final _searchController = TextEditingController();
  Timer? _debounce;

  bool _initialLoading = true;
  List<BrowseUser> _studios = [];
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  static const _pageSize = 6;
  static const _maxStudios = 20;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resetAndFetch();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _resetAndFetch);
  }

  void _resetAndFetch() {
    _offset = 0;
    _hasMore = true;
    _studios = [];
    _fetchStudios();
  }

  Future<void> _fetchStudios() async {
    if (_offset == 0) setState(() => _initialLoading = true);
    final query = _searchController.text.trim();
    await BrowseService.instance.fetchUsers(
      search: query.isEmpty ? null : query,
      offset: _offset,
      limit: _pageSize,
    );
    if (!mounted) return;
    final allUsers = BrowseService.instance.users;
    // Seed follow state from API response
    for (final u in allUsers) {
      if (u.isFollowing) {
        FollowService.instance.markFollowing(u.id);
      }
    }
    final newCount = allUsers.length - _studios.length;
    setState(() {
      _studios = List.of(allUsers);
      _offset = _studios.length;
      _hasMore = newCount >= _pageSize && _studios.length < _maxStudios;
      _initialLoading = false;
    });
    _anim.forward();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    await _fetchStudios();
    if (mounted) setState(() => _loadingMore = false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
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
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: _fade(0.0, 0.5),
                    child: SlideTransition(
                      position: _slide(0.0, 0.5),
                      child: _StudiosHeader(userCount: _studios.length),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Search input ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        color: AppColors.inkStrong,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search studios...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14.5,
                          color: AppColors.muted,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(
                              color: AppColors.hairline, width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(
                              color: AppColors.ink, width: 1.0),
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 14, right: 8),
                          child: Icon(Icons.search_rounded,
                              size: 18, color: AppColors.muted),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 0, minHeight: 0),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  FadeTransition(
                    opacity: _fade(0.2, 0.7),
                    child: SlideTransition(
                      position: _slide(0.2, 0.7),
                      child: _StudioGrid(users: _studios),
                    ),
                  ),

                  // ── Load more ──
                  if (_hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Center(
                        child: GestureDetector(
                          onTap: _loadingMore ? null : _loadMore,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 11),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.hairline, width: 1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: _loadingMore
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppColors.inkSoft,
                                    ),
                                  )
                                : Text(
                                    'Load more',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.inkSoft,
                                    ),
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
      child: Wrap(
        spacing: 14,
        runSpacing: 24,
        children: users.map((u) {
          final cardWidth =
              (MediaQuery.of(context).size.width - 16 * 2 - 14) / 2;
          return SizedBox(
            width: cardWidth,
            child: _StudioCard(user: u),
          );
        }).toList(),
      ),
    );
  }
}

// ── Studio card ───────────────────────────────────────────────

class _StudioCard extends StatelessWidget {
  final BrowseUser user;
  const _StudioCard({required this.user});

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            UserProfileScreen(userId: user.id.toString()),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = user;
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
        // ── Image / avatar area (fixed aspect ratio) ──
        AspectRatio(
          aspectRatio: 0.75,
          child: GestureDetector(
            onTap: () => _openProfile(context),
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
                onTap: () => _openProfile(context),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkStrong,
                      ),
                    ),
                    const SizedBox(height: 2),
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
            ListenableBuilder(
              listenable: FollowService.instance,
              builder: (context, _) {
                final saved = FollowService.instance.isFollowing(u.id);
                return GestureDetector(
                  onTap: () => FollowService.instance.toggleFollow(u.id),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, top: 1),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        key: ValueKey(saved),
                        size: 18,
                        color: saved ? AppColors.accent : AppColors.muted,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
