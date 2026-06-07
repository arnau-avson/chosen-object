import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/browse_service.dart';
import '../../core/follow_service.dart';
import '../../core/collection_service.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/save_to_collection_modal.dart';
import '../product_detail/product_detail_screen.dart';
import 'followers_screen.dart';

// ── Helpers ──────────────────────────────────────────────────

String _formatNumber(int n) {
  if (n < 1000) return '$n';
  final thousands = n ~/ 1000;
  final remainder = (n % 1000) ~/ 100;
  return remainder == 0 ? '${thousands}k' : '$thousands.${remainder}k';
}

Color _parseHex(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}

// ═════════════════════════════════════════════════════════════
// ── User Profile Screen ─────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  BrowseUser? _profile;
  List<BrowsePiece> _pieces = [];
  bool _loadingProfile = true;
  bool _descExpanded = false;

  int get _userId => int.tryParse(widget.userId) ?? 0;

  // ── Animation helpers ──────────────────────────────────────

  Animation<double> _fade(double start, double end) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start.clamp(0, 1), end.clamp(0, 1),
            curve: Curves.easeOut),
      );

  Animation<Offset> _slide(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start.clamp(0, 1), end.clamp(0, 1),
              curve: Curves.easeOut),
        ),
      );

  // ── Lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await BrowseService.instance.fetchUserProfile(_userId);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loadingProfile = false;
    });
    _ctrl.forward();
    // Also fetch pieces by this user (search by username)
    if (profile != null) {
      await BrowseService.instance.fetchPieces(
        search: profile.username,
        limit: 20,
      );
      if (!mounted) return;
      // Filter pieces that belong to this user
      setState(() {
        _pieces = BrowseService.instance.pieces
            .where((p) => p.userId == _userId)
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openFollowers(int tab) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            FollowersScreen(userId: _userId, initialTab: tab),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;

    if (_loadingProfile) {
      return Scaffold(
        backgroundColor: AppColors.bone,
        body: const Center(child: LoadingSpinner()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppColors.bone,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_off_outlined, size: 48, color: AppColors.muted),
              const SizedBox(height: 12),
              Text('User not found',
                  style: GoogleFonts.inter(color: AppColors.muted)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Text('Go back',
                    style: GoogleFonts.inter(
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile!;
    final displayName = profile.studioName ?? profile.username;
    final initials = displayName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.bone,
      body: ListenableBuilder(
        listenable: FollowService.instance,
        builder: (context, _) {
          final isFollowing = FollowService.instance.isFollowing(_userId);

          return Stack(
            children: [
              // ── Scrollable content ──
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── A) Banner + Avatar overlap ──
                    FadeTransition(
                      opacity: _fade(0.0, 0.40),
                      child: SlideTransition(
                        position: _slide(0.0, 0.40),
                        child: SizedBox(
                          height: 140 + 44,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Banner
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 140,
                                child: profile.bannerImageB64 != null
                                    ? Image.memory(
                                        base64Decode(profile.bannerImageB64!),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 140,
                                      )
                                    : Container(
                                        color: _parseHex(profile.bannerColor)),
                              ),
                              // Avatar
                              Positioned(
                                bottom: 0,
                                left: 24,
                                child: Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _parseHex(profile.avatarColor),
                                    border: Border.all(
                                        color: AppColors.surface, width: 4),
                                  ),
                                  alignment: Alignment.center,
                                  child: profile.avatarImageB64 != null
                                      ? ClipOval(
                                          child: Image.memory(
                                            base64Decode(
                                                profile.avatarImageB64!),
                                            fit: BoxFit.cover,
                                            width: 80,
                                            height: 80,
                                          ),
                                        )
                                      : Text(
                                          initials,
                                          style: GoogleFonts.fraunces(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white
                                                .withValues(alpha: 0.85),
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── B) Name + description ──
                    FadeTransition(
                      opacity: _fade(0.07, 0.47),
                      child: SlideTransition(
                        position: _slide(0.07, 0.47),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: GoogleFonts.fraunces(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.inkStrong,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                [
                                  if (profile.city != null) profile.city!,
                                  if (profile.discipline != null)
                                    profile.discipline!,
                                ].join(' · '),
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

                    // ── C) Action buttons ──
                    FadeTransition(
                      opacity: _fade(0.14, 0.54),
                      child: SlideTransition(
                        position: _slide(0.14, 0.54),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    if (isFollowing) {
                                      await FollowService.instance
                                          .unfollow(_userId);
                                    } else {
                                      await FollowService.instance
                                          .follow(_userId);
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 220),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 11),
                                    decoration: BoxDecoration(
                                      color: isFollowing
                                          ? Colors.transparent
                                          : AppColors.ink,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isFollowing
                                            ? AppColors.hairline
                                            : AppColors.ink,
                                        width: 1,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      isFollowing ? 'Following' : 'Follow',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isFollowing
                                            ? AppColors.inkSoft
                                            : AppColors.bone,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 11),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: AppColors.hairline, width: 1),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Message',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── D) Stats row ──
                    FadeTransition(
                      opacity: _fade(0.21, 0.61),
                      child: SlideTransition(
                        position: _slide(0.21, 0.61),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _StatColumn(
                                    count: profile.piecesCount,
                                    label: 'Pieces',
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  color: AppColors.hairline,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 4),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _openFollowers(0),
                                    behavior: HitTestBehavior.opaque,
                                    child: _StatColumn(
                                      count: profile.followersCount,
                                      label: 'Followers',
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  color: AppColors.hairline,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 4),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _openFollowers(1),
                                    behavior: HitTestBehavior.opaque,
                                    child: _StatColumn(
                                      count: profile.followingCount,
                                      label: 'Following',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(color: AppColors.hairline, height: 1),
                    ),

                    // ── E) Nº01 — About ──
                    if (profile.bio != null && profile.bio!.isNotEmpty)
                      FadeTransition(
                        opacity: _fade(0.28, 0.68),
                        child: SlideTransition(
                          position: _slide(0.28, 0.68),
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(24, 24, 24, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '№ 01',
                                        style: GoogleFonts.fraunces(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.gold,
                                          height: 1.3,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' — About',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.muted,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                GestureDetector(
                                  onTap: () => setState(
                                      () => _descExpanded = !_descExpanded),
                                  child: AnimatedCrossFade(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    crossFadeState: _descExpanded
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    firstChild: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profile.bio!,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.inkSoft,
                                            height: 1.7,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Read more',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.inkStrong,
                                          ),
                                        ),
                                      ],
                                    ),
                                    secondChild: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profile.bio!,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.inkSoft,
                                            height: 1.7,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Show less',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.inkStrong,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(color: AppColors.hairline, height: 1),
                    ),

                    // ── F) Nº02 — Pieces ──
                    FadeTransition(
                      opacity: _fade(0.35, 0.75),
                      child: SlideTransition(
                        position: _slide(0.35, 0.75),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 24, 24, 0),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '№ 02',
                                      style: GoogleFonts.fraunces(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.gold,
                                        height: 1.3,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' — Pieces',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.muted,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_pieces.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 32),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.inventory_2_outlined,
                                          size: 32, color: AppColors.muted),
                                      const SizedBox(height: 10),
                                      Text(
                                        'No pieces yet',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              _PieceGrid(pieces: _pieces),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // ── G) Back button overlay ──
              Positioned(
                top: safeTop + 12,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.78),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: AppColors.inkSoft,
                    ),
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
// ── Stat column ─────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _StatColumn extends StatelessWidget {
  final int count;
  final String label;
  const _StatColumn({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatNumber(count),
          style: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: AppColors.inkStrong,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.muted,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Piece grid ──────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _PieceGrid extends StatelessWidget {
  final List<BrowsePiece> pieces;
  const _PieceGrid({required this.pieces});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: pieces.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 24,
          childAspectRatio: 0.58,
        ),
        itemBuilder: (_, i) => _PieceCard(piece: pieces[i]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Piece card with cover image ─────────────────────────────
// ═════════════════════════════════════════════════════════════

class _PieceCard extends StatelessWidget {
  final BrowsePiece piece;
  const _PieceCard({required this.piece});

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            ProductDetailScreen(pieceId: piece.id),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  String _getTag() {
    if (piece.rental && piece.priceCents > 0) return 'Buy or Rent';
    if (piece.rental) return 'Rent';
    return 'Buy';
  }

  @override
  Widget build(BuildContext context) {
    final tag = _getTag();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _openDetail(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  if (piece.coverImageB64 != null)
                    Image.memory(
                      base64Decode(piece.coverImageB64!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  else
                    Container(
                      color: AppColors.hairline,
                      alignment: Alignment.center,
                      child: Icon(Icons.image_outlined,
                          size: 32, color: AppColors.muted),
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkSoft,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _openDetail(context),
          behavior: HitTestBehavior.opaque,
          child: Row(
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
                    const SizedBox(height: 2),
                    Text(
                      piece.year ?? '',
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
                      piece.priceFormatted,
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
                  final saved =
                      CollectionService.instance.isProductSaved(piece.id);
                  return GestureDetector(
                    onTap: () =>
                        CollectionService.instance.toggleSaved(piece.id),
                    onLongPress: () =>
                        SaveToCollectionModal.show(context, piece.id),
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
        ),
      ],
    );
  }
}
