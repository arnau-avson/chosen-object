import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/piece_service.dart';
import '../../core/profile_service.dart';
import '../../models/piece.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/shared_app_bar.dart';
import '../list_piece/list_piece_screen.dart';
import 'edit_profile_screen.dart';
import 'followers_screen.dart';

// ── Helpers ──────────────────────────────────────────────────

String _formatNumber(int n) {
  if (n < 1000) return '$n';
  final thousands = n ~/ 1000;
  final remainder = (n % 1000) ~/ 100;
  return remainder == 0 ? '${thousands}k' : '$thousands.${remainder}k';
}

// ═════════════════════════════════════════════════════════════
// ── Profile Screen ──────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  bool _descExpanded = false;

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

  void _openFollowers(int tab) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            FollowersScreen(userId: ProfileService.instance.userId, initialTab: tab),
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

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // Fetch user's pieces from backend
    PieceService.instance.fetchMyPieces();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: const SharedAppBar(currentRoute: '/profile'),
      drawer: const AppDrawer(currentRoute: '/profile'),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          ProfileService.instance,
          PieceService.instance,
        ]),
        builder: (context, _) {
          final p = ProfileService.instance;
          final pieceService = PieceService.instance;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── A) Banner + Avatar + Edit overlays ──
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
                            child: p.bannerType == 'image' &&
                                    p.bannerImageBytes != null
                                ? Image.memory(
                                    p.bannerImageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 140,
                                  )
                                : Container(color: p.bannerColor),
                          ),

                          // Banner edit overlay
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: _openEditProfile,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.surface
                                      .withValues(alpha: 0.78),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 16,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ),

                          // Avatar
                          Positioned(
                            bottom: 0,
                            left: 24,
                            child: Stack(
                              children: [
                                p.avatarType == 'image' &&
                                        p.avatarImageBytes != null
                                    ? Container(
                                        width: 88,
                                        height: 88,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: AppColors.surface,
                                              width: 4),
                                          image: DecorationImage(
                                            image: MemoryImage(
                                                p.avatarImageBytes!),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 88,
                                        height: 88,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: p.avatarColor,
                                          border: Border.all(
                                              color: AppColors.surface,
                                              width: 4),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          p.initials,
                                          style: GoogleFonts.fraunces(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white
                                                .withValues(alpha: 0.85),
                                          ),
                                        ),
                                      ),

                                // Avatar edit overlay
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _openEditProfile,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.ink,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppColors.surface,
                                            width: 2),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.camera_alt_outlined,
                                        size: 13,
                                        color: AppColors.bone,
                                      ),
                                    ),
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

                const SizedBox(height: 14),

                // ── B) Name + handle + location ──
                FadeTransition(
                  opacity: _fade(0.07, 0.47),
                  child: SlideTransition(
                    position: _slide(0.07, 0.47),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                p.name,
                                style: GoogleFonts.fraunces(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.inkStrong,
                                ),
                              ),
                              if (p.verified) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.verified,
                                    size: 18, color: AppColors.sage),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.handle,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            [
                              p.location.split(',').first,
                              ...p.specialties,
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

                // ── C) Edit profile button ──
                FadeTransition(
                  opacity: _fade(0.14, 0.54),
                  child: SlideTransition(
                    position: _slide(0.14, 0.54),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: GestureDetector(
                        onTap: _openEditProfile,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppColors.hairline, width: 1),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.edit_outlined,
                                  size: 15, color: AppColors.inkSoft),
                              const SizedBox(width: 6),
                              Text(
                                'Edit profile',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
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
                                count: p.pieceCount,
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
                              child: _StatColumn(
                                count: p.soldCount,
                                label: 'Sold',
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
                                  count: p.followerCount,
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
                                  count: p.followingCount,
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
                  child:
                      Divider(color: AppColors.hairline, height: 1),
                ),

                // ── E) No 01 — About ──
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
                                  text: '\u2116 01',
                                  style: GoogleFonts.fraunces(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.gold,
                                    height: 1.3,
                                  ),
                                ),
                                TextSpan(
                                  text: ' \u2014 About',
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
                                    p.bio,
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
                                    p.bio,
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

                // ── F) No 02 — Pieces ──
                FadeTransition(
                  opacity: _fade(0.35, 0.75),
                  child: SlideTransition(
                    position: _slide(0.35, 0.75),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '\u2116 02',
                                  style: GoogleFonts.fraunces(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.gold,
                                    height: 1.3,
                                  ),
                                ),
                                TextSpan(
                                  text: ' \u2014 Pieces',
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

                        if (pieceService.loadingPieces)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: LoadingSpinner()),
                          )
                        else if (pieceService.pieces.isEmpty)
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
                          _PieceGrid(pieces: pieceService.pieces),
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
  final List<PieceListItem> pieces;
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
// ── Piece card with action icons ────────────────────────────
// ═════════════════════════════════════════════════════════════

class _PieceCard extends StatelessWidget {
  final PieceListItem piece;
  const _PieceCard({required this.piece});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: AppColors.ink.withValues(alpha: 0.3),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline_rounded,
                    size: 20, color: AppColors.danger),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete piece',
                style: GoogleFonts.fraunces(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: AppColors.inkStrong,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will permanently delete "${piece.title}". This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: AppColors.hairline, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        PieceService.instance.deletePiece(piece.id).then((_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '"${piece.title}" deleted',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.bone,
                                ),
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: AppColors.ink,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          );
                        }).catchError((_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to delete piece',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.bone,
                                ),
                              ),
                              backgroundColor: AppColors.danger,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          );
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            'Delete',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.surface,
                            ),
                          ),
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Image area ──
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (piece.coverImageBytes != null)
                  Image.memory(
                    piece.coverImageBytes!,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    color: AppColors.hairline,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_outlined,
                      size: 32,
                      color: AppColors.muted,
                    ),
                  ),

                // Tag badge
                if (piece.rental)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Rental',
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

        const SizedBox(height: 10),

        // ── Piece info + action icons ──
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
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (piece.discipline != null) piece.discipline!,
                      if (piece.year != null) piece.year!,
                    ].join(' \u00B7 '),
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

            // Action icons
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, _, _) =>
                            ListPieceScreen(editPieceId: piece.id),
                        transitionsBuilder: (_, animation, _, child) =>
                            FadeTransition(
                                opacity: animation, child: child),
                        transitionDuration:
                            const Duration(milliseconds: 300),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
