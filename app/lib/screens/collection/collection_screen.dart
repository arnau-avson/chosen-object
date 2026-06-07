import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/collection_service.dart';
import '../../core/follow_service.dart';
import '../../core/profile_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/save_to_collection_modal.dart';
import '../../widgets/shared_app_bar.dart';
import '../profile/user_profile_screen.dart';

// ═════════════════════════════════════════════════════════════
// ── Collection Screen ───────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  // 0 = Pieces, 1 = Collections, 2 = Studios
  int _tabIndex = 0;
  List<FollowUser> _followingUsers = [];
  bool _loadingStudios = false;

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
    // Fetch data from API
    CollectionService.instance.fetchSavedPieces();
    CollectionService.instance.fetchCollections();
    _fetchFollowingUsers();
  }

  Future<void> _fetchFollowingUsers() async {
    setState(() => _loadingStudios = true);
    final myId = ProfileService.instance.userId;
    if (myId > 0) {
      final users = await FollowService.instance.getFollowing(myId);
      if (mounted) {
        setState(() {
          _followingUsers = users;
          _loadingStudios = false;
        });
      }
    } else {
      if (mounted) setState(() => _loadingStudios = false);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _openCollection(SavedCollection col) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _CollectionDetailScreen(
          title: col.name,
          collectionId: col.id,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showCreateDialog() {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    'New collection',
                    style: GoogleFonts.fraunces(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkStrong,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: AppColors.hairline, height: 24),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.inkStrong,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Collection name',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.muted,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (_) {
                            final name = controller.text.trim();
                            if (name.isNotEmpty) {
                              CollectionService.instance
                                  .createCollection(name);
                              Navigator.of(ctx).pop();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final name = controller.text.trim();
                          if (name.isNotEmpty) {
                            CollectionService.instance
                                .createCollection(name);
                            Navigator.of(ctx).pop();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Create',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.bone,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: const SharedAppBar(currentRoute: '/collection'),
      drawer: const AppDrawer(currentRoute: '/collection'),
      body: ListenableBuilder(
        listenable: CollectionService.instance,
        builder: (context, _) {
          final service = CollectionService.instance;
          final savedPieces = service.savedPieces;
          final collections = service.collections;

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
                        'Collection',
                        style: GoogleFonts.fraunces(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: AppColors.inkStrong,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ── Tab switch ──
                FadeTransition(
                  opacity: _fade(0.06, 0.50),
                  child: SlideTransition(
                    position: _slide(0.06, 0.50),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _TabLabel(
                            label: 'Pieces',
                            active: _tabIndex == 0,
                            onTap: () => setState(() => _tabIndex = 0),
                          ),
                          const SizedBox(width: 28),
                          _TabLabel(
                            label: 'Collections',
                            active: _tabIndex == 1,
                            onTap: () => setState(() => _tabIndex = 1),
                          ),
                          const SizedBox(width: 28),
                          _TabLabel(
                            label: 'Studios',
                            active: _tabIndex == 2,
                            onTap: () => setState(() => _tabIndex = 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Tab content ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _tabIndex == 0
                      ? _PiecesTab(
                          key: const ValueKey('pieces'),
                          savedPieces: savedPieces,
                          fade: _fade,
                          slide: _slide,
                        )
                      : _tabIndex == 1
                          ? _CollectionsTab(
                              key: const ValueKey('collections'),
                              collections: collections,
                              onOpenCollection: _openCollection,
                              onCreateCollection: _showCreateDialog,
                              fade: _fade,
                              slide: _slide,
                            )
                          : _StudiosTab(
                              key: const ValueKey('studios'),
                              users: _followingUsers,
                              loading: _loadingStudios,
                              fade: _fade,
                              slide: _slide,
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Tab label (underlined editorial style) ──────────────────
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
// ── Pieces tab ──────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _PiecesTab extends StatelessWidget {
  final List<SavedPiece> savedPieces;
  final Animation<double> Function(double, double) fade;
  final Animation<Offset> Function(double, double) slide;

  const _PiecesTab({
    super.key,
    required this.savedPieces,
    required this.fade,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    if (savedPieces.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bookmark_border_rounded,
                  size: 36, color: AppColors.hairline2),
              const SizedBox(height: 12),
              Text(
                'No saved pieces yet',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap the bookmark icon on any piece\nto save it here',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted2,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: fade(0.12, 0.55),
      child: SlideTransition(
        position: slide(0.12, 0.55),
        child: _SavedPieceGrid(pieces: savedPieces),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Collections tab ─────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _CollectionsTab extends StatelessWidget {
  final List<SavedCollection> collections;
  final void Function(SavedCollection) onOpenCollection;
  final VoidCallback onCreateCollection;
  final Animation<double> Function(double, double) fade;
  final Animation<Offset> Function(double, double) slide;

  const _CollectionsTab({
    super.key,
    required this.collections,
    required this.onOpenCollection,
    required this.onCreateCollection,
    required this.fade,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (collections.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.folder_outlined,
                      size: 36, color: AppColors.hairline2),
                  const SizedBox(height: 12),
                  Text(
                    'No collections yet',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create a collection to organise\nyour saved pieces',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.muted2,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          FadeTransition(
            opacity: fade(0.12, 0.55),
            child: SlideTransition(
              position: slide(0.12, 0.55),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: collections
                      .map((col) => _CollectionRow(
                            collection: col,
                            onTap: () => onOpenCollection(col),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),

        const SizedBox(height: 20),

        // ── Create collection button ──
        FadeTransition(
          opacity: fade(0.30, 0.75),
          child: SlideTransition(
            position: slide(0.30, 0.75),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: GestureDetector(
                  onTap: onCreateCollection,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: AppColors.hairline, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            size: 16, color: AppColors.inkSoft),
                        const SizedBox(width: 6),
                        Text(
                          'Create collection',
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
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Studios tab (saved/followed studios) ────────────────────
// ═════════════════════════════════════════════════════════════

class _StudiosTab extends StatelessWidget {
  final List<FollowUser> users;
  final bool loading;
  final Animation<double> Function(double, double) fade;
  final Animation<Offset> Function(double, double) slide;

  const _StudiosTab({
    super.key,
    required this.users,
    required this.loading,
    required this.fade,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: LoadingSpinner()),
      );
    }

    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.storefront_outlined,
                  size: 36, color: AppColors.hairline2),
              const SizedBox(height: 12),
              Text(
                'No saved studios yet',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Follow studios to see them here',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted2,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: fade(0.12, 0.55),
      child: SlideTransition(
        position: slide(0.12, 0.55),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: users
                .map((user) => _SavedStudioRow(user: user))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Saved studio row ────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _SavedStudioRow extends StatelessWidget {
  final FollowUser user;
  const _SavedStudioRow({required this.user});

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
    final avatarColor = _parseColor(user.avatarColor);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, _, _) =>
                UserProfileScreen(userId: user.id.toString()),
            transitionsBuilder: (_, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColor,
              ),
              alignment: Alignment.center,
              child: user.avatarImageB64 != null
                  ? ClipOval(
                      child: Image.memory(
                        base64Decode(user.avatarImageB64!),
                        width: 48,
                        height: 48,
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

            // Name + info
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
                      color: AppColors.inkStrong,
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

            // Unfollow button
            ListenableBuilder(
              listenable: FollowService.instance,
              builder: (context, _) {
                final following =
                    FollowService.instance.isFollowing(user.id);
                return GestureDetector(
                  onTap: () =>
                      FollowService.instance.toggleFollow(user.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: following
                          ? Colors.transparent
                          : AppColors.ink,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: following
                            ? AppColors.hairline
                            : AppColors.ink,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      following ? 'Following' : 'Follow',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: following
                            ? AppColors.inkSoft
                            : AppColors.bone,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Collection Row (list item) ──────────────────────────────
// ═════════════════════════════════════════════════════════════

class _CollectionRow extends StatelessWidget {
  final SavedCollection collection;
  final VoidCallback onTap;
  const _CollectionRow({required this.collection, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 56,
                height: 56,
                color: AppColors.hairline2,
              ),
            ),
            const SizedBox(width: 14),
            // Name + count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
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
                    '${collection.pieceCount} pieces',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Collection Detail Screen ────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _CollectionDetailScreen extends StatefulWidget {
  final String title;
  final int collectionId;

  const _CollectionDetailScreen({
    required this.title,
    required this.collectionId,
  });

  @override
  State<_CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState
    extends State<_CollectionDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  static const _pageSize = 4;
  int _displayedCount = _pageSize;
  bool _loading = false;
  List<SavedPiece> _pieces = [];
  bool _fetching = true;

  Animation<double> _fade(double start, double end) => CurvedAnimation(
        parent: _anim,
        curve: Interval(start.clamp(0, 1), end.clamp(0, 1),
            curve: Curves.easeOut),
      );

  Animation<Offset> _slide(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
          .animate(
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
    _fetchPieces();
  }

  Future<void> _fetchPieces() async {
    final detail = await CollectionService.instance
        .fetchCollectionDetail(widget.collectionId);
    if (!mounted) return;
    setState(() {
      _pieces = detail?.pieces ?? [];
      _fetching = false;
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _loadMore(int total) async {
    if (_loading || _displayedCount >= total) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _displayedCount =
          (_displayedCount + _pageSize).clamp(0, total);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: const SharedAppBar(
        currentRoute: '/collection',
        showBack: true,
      ),
      body: ListenableBuilder(
        listenable: CollectionService.instance,
        builder: (context, _) {
          if (_fetching) {
            return const Center(child: LoadingSpinner());
          }

          final pieces = _pieces;
          final displayed =
              pieces.take(_displayedCount).toList();
          final hasMore = _displayedCount < pieces.length;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                FadeTransition(
                  opacity: _fade(0.0, 0.45),
                  child: SlideTransition(
                    position: _slide(0.0, 0.45),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.fraunces(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              color: AppColors.inkStrong,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pieces.length} pieces',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (pieces.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 48),
                    child: Center(
                      child: Text(
                        'No pieces in this collection',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  )
                else ...[
                  // Grid
                  FadeTransition(
                    opacity: _fade(0.10, 0.55),
                    child: SlideTransition(
                      position: _slide(0.10, 0.55),
                      child: _SavedPieceGrid(
                          pieces: displayed),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Load more / spinner
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 32),
                      child:
                          Center(child: LoadingSpinner()),
                    )
                  else if (hasMore)
                    Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.only(bottom: 32),
                        child: GestureDetector(
                          onTap: () =>
                              _loadMore(pieces.length),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(999),
                              border: Border.all(
                                  color: AppColors.hairline,
                                  width: 1),
                            ),
                            child: Text(
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
                ],

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
// ── SavedPiece grid ─────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _SavedPieceGrid extends StatelessWidget {
  final List<SavedPiece> pieces;
  const _SavedPieceGrid({required this.pieces});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: pieces.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 24,
          childAspectRatio: 0.58,
        ),
        itemBuilder: (_, i) =>
            _SavedPieceCard(piece: pieces[i]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── SavedPiece card ─────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _SavedPieceCard extends StatelessWidget {
  final SavedPiece piece;
  const _SavedPieceCard({required this.piece});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Image area ──
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: double.infinity,
              color: AppColors.hairline2,
              child: piece.coverImageB64 != null
                  ? Image.memory(
                      base64Decode(piece.coverImageB64!),
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 32,
                        color: AppColors.muted,
                      ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    piece.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkStrong,
                    ),
                  ),
                  if (piece.discipline != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      piece.discipline!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatPrice(piece.priceCents),
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            ListenableBuilder(
              listenable: CollectionService.instance,
              builder: (context, _) {
                final saved = CollectionService.instance
                    .isProductSaved(piece.id);
                return GestureDetector(
                  onTap: () => CollectionService.instance
                      .toggleSaved(piece.id),
                  onLongPress: () => SaveToCollectionModal.show(
                      context, piece.id),
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 4, top: 1),
                    child: AnimatedSwitcher(
                      duration:
                          const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(
                              scale: anim, child: child),
                      child: Icon(
                        saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        key: ValueKey(saved),
                        size: 18,
                        color: saved
                            ? AppColors.accent
                            : AppColors.muted,
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

  String _formatPrice(int cents) {
    final euros = cents ~/ 100;
    final remainder = cents % 100;
    if (remainder == 0) {
      return '\u20AC$euros';
    }
    return '\u20AC$euros.${remainder.toString().padLeft(2, '0')}';
  }
}
