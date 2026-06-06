import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/collection_service.dart';
import '../../core/profile_service.dart';
import '../../models/product.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/save_to_collection_modal.dart';
import '../../widgets/shared_app_bar.dart';
import '../product_detail/product_detail_screen.dart';
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

  // Pagination
  static const _pageSize = 4;
  int _displayedCount = _pageSize;
  bool _loading = false;

  late final List<Product> _userProducts;

  bool get _hasMore => _displayedCount < _userProducts.length;

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
            FollowersScreen(userId: 'me', initialTab: tab),
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
    _userProducts = mockProducts
        .where((p) => p.designer == ProfileService.instance.name)
        .toList();
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

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _displayedCount =
          (_displayedCount + _pageSize).clamp(0, _userProducts.length);
      _loading = false;
    });
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final displayed = _userProducts.take(_displayedCount).toList();

    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: const SharedAppBar(currentRoute: '/profile'),
      drawer: const AppDrawer(currentRoute: '/profile'),
      body: ListenableBuilder(
        listenable: ProfileService.instance,
        builder: (context, _) {
          final p = ProfileService.instance;

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

                // ── E) Nº01 — About ──
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

                // ── F) Nº02 — Pieces ──
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

                        if (_userProducts.isEmpty)
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
                        else ...[
                          _ProductGrid(products: displayed),
                          const SizedBox(height: 28),

                          if (_loading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 32),
                              child: Center(child: LoadingSpinner()),
                            )
                          else if (_hasMore)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 32),
                                child: GestureDetector(
                                  onTap: _loadMore,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 22, vertical: 10),
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
// ── Product grid ────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _ProductGrid extends StatelessWidget {
  final List<Product> products;
  const _ProductGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 24,
          childAspectRatio: 0.58,
        ),
        itemBuilder: (_, i) => _ProductCard(product: products[i]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Product card with swipeable images ──────────────────────
// ═════════════════════════════════════════════════════════════

class _ProductCard extends StatefulWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  int _currentPage = 0;

  void _openDetail() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            ProductDetailScreen(productId: widget.product.id),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product.images;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Image area with PageView ──
        Expanded(
          child: GestureDetector(
            onTap: _openDetail,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (p) => setState(() => _currentPage = p),
                    itemBuilder: (_, i) => Container(color: images[i]),
                  ),

                  // Tag badge
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
                        widget.product.tag,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkSoft,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  // Dot indicators
                  if (images.length > 1)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (i) {
                          final active = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: active ? 6 : 5,
                            height: active ? 6 : 5,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.45),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Product info + save icon ──
        GestureDetector(
          onTap: _openDetail,
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
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
                      '${widget.product.designer} · ${widget.product.year}',
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
                      widget.product.price,
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
                      .isProductSaved(widget.product.id);
                  return GestureDetector(
                    onTap: () => CollectionService.instance
                        .toggleSaved(widget.product.id),
                    onLongPress: () => SaveToCollectionModal.show(
                        context, widget.product.id),
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
                          color:
                              saved ? AppColors.accent : AppColors.muted,
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
