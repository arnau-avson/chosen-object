import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../models/product.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/shared_app_bar.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentPage = 0;
  bool _saved = false;
  bool _descExpanded = false;
  final _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _openImageViewer(
      BuildContext context, List<Color> images, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, _, _) =>
            _FullScreenImageViewer(images: images, initialIndex: initialIndex),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = mockProducts.firstWhere((p) => p.id == widget.productId);
    final images = product.images;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: const AppDrawer(currentRoute: '/product-detail'),
      appBar: const SharedAppBar(currentRoute: '/product-detail'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ═══════════════════════════════════════════════════
            // ── 1. Image carousel ────────────────────────────
            // ═══════════════════════════════════════════════════
            SizedBox(
              height: w * 0.95,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageCtrl,
                    itemCount: images.length,
                    onPageChanged: (p) => setState(() => _currentPage = p),
                    itemBuilder: (_, i) => GestureDetector(
                      onDoubleTap: () => _openImageViewer(
                          context, images, i),
                      child: Container(color: images[i]),
                    ),
                  ),
                  // Tag pill
                  Positioned(
                    top: 14,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        product.tag,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkSoft,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  // Dots + arrow controls
                  if (images.length > 1)
                    Positioned(
                      bottom: 14,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Prev button
                          GestureDetector(
                            onTap: _currentPage > 0
                                ? () => _pageCtrl.previousPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    )
                                : null,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _currentPage > 0
                                    ? AppColors.ink.withValues(alpha: 0.5)
                                    : AppColors.ink.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.chevron_left_rounded,
                                size: 18,
                                color: _currentPage > 0
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Dots
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(images.length, (i) {
                              final active = i == _currentPage;
                              return AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                width: active ? 7 : 5,
                                height: active ? 7 : 5,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: active
                                      ? Colors.white
                                      : Colors.white
                                          .withValues(alpha: 0.4),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(width: 12),
                          // Next button
                          GestureDetector(
                            onTap: _currentPage < images.length - 1
                                ? () => _pageCtrl.nextPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    )
                                : null,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _currentPage < images.length - 1
                                    ? AppColors.ink.withValues(alpha: 0.5)
                                    : AppColors.ink.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: _currentPage < images.length - 1
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ═══════════════════════════════════════════════════
            // ── 2. Save / authenticated badge ────────────────
            // ═══════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: Row(
                children: [
                  // Authenticated badge
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_outlined,
                          size: 14, color: AppColors.sage),
                      const SizedBox(width: 5),
                      Text(
                        'Authenticated by Chosen Object',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.sage,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Save button
                  GestureDetector(
                    onTap: () => setState(() => _saved = !_saved),
                    child: Icon(
                      _saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 22,
                      color:
                          _saved ? AppColors.inkStrong : AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════════════════
            // ── 3. Edition + Suite + Year ────────────────────
            // ═══════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.edition != null)
                    Text(
                      'Edition ${product.edition}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  if (product.suite != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.suite!,
                      style: GoogleFonts.fraunces(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    product.year,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════════════════
            // ── 4. Designer + Location ───────────────────────
            // ═══════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  // Avatar placeholder
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.hairline,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      product.designer[0],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              product.designer,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.inkStrong,
                              ),
                            ),
                            if (product.verified) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.verified,
                                  size: 14, color: AppColors.sage),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          [
                            if (product.location != null) product.location!,
                            if (product.category != null) product.category!,
                          ].join(' · '),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Follow button
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: AppColors.hairline, width: 1),
                    ),
                    child: Text(
                      'Follow',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: AppColors.hairline, height: 1),
            ),

            // ═══════════════════════════════════════════════════
            // ── 5. № 01 — About ──────────────────────────────
            // ═══════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
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
                    onTap: () =>
                        setState(() => _descExpanded = !_descExpanded),
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState: _descExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.description,
                            maxLines: 2,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.description,
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

            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: AppColors.hairline, height: 1),
            ),

            // ═══════════════════════════════════════════════════
            // ── 6. № 02 — Specifications ─────────────────────
            // ═══════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
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
                          text: ' — Specifications',
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
                  const SizedBox(height: 16),
                  _SpecRow(label: 'Year', value: product.year),
                  if (product.materials != null)
                    _SpecRow(label: 'Materials', value: product.materials!),
                  if (product.dimensions != null)
                    _SpecRow(
                        label: 'Dimensions', value: product.dimensions!),
                  if (product.weight != null)
                    _SpecRow(label: 'Weight', value: product.weight!),
                  if (product.condition != null)
                    _SpecRow(label: 'Condition', value: product.condition!),
                ],
              ),
            ),

            // ═══════════════════════════════════════════════════
            // ── 7. Tags ──────────────────────────────────────
            // ═══════════════════════════════════════════════════
            if (product.tags.isNotEmpty) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: product.tags
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: AppColors.hairline, width: 1),
                          ),
                          child: Text(
                            t,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: AppColors.hairline, height: 1),
            ),

            // ═══════════════════════════════════════════════════
            // ── 8. Price + Actions ───────────────────────────
            // ═══════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _priceLabel(product.tag),
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.price,
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkStrong,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            // ── Action buttons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                children: [
                  // Primary button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _actionLabel(product.tag),
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.bone,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Secondary button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: AppColors.hairline, width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Make an offer',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.inkSoft,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _priceLabel(String tag) => switch (tag) {
        'Rent' => 'RENTAL PRICE',
        'Buy or Rent' => 'SALE PRICE',
        _ => 'SALE PRICE',
      };

  String _actionLabel(String tag) => switch (tag) {
        'Sell' => 'Buy now',
        'Buy' => 'Buy now',
        'Rent' => 'Request rental',
        'Buy or Rent' => 'Buy or rent',
        _ => 'Contact seller',
      };
}

// ── Specification row ────────────────────────────────────────

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fullscreen image viewer with zoom ────────────────────────

class _FullScreenImageViewer extends StatefulWidget {
  final List<Color> images;
  final int initialIndex;
  const _FullScreenImageViewer(
      {required this.images, required this.initialIndex});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Zoomable paged images
          PageView.builder(
            controller: _pageCtrl,
            itemCount: images.length,
            onPageChanged: (p) => setState(() => _current = p),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: images[i],
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Bottom: counter + arrows
          if (images.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Prev
                  GestureDetector(
                    onTap: _current > 0
                        ? () => _pageCtrl.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            )
                        : null,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 24,
                      color: _current > 0
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_current + 1} / ${images.length}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Next
                  GestureDetector(
                    onTap: _current < images.length - 1
                        ? () => _pageCtrl.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            )
                        : null,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 24,
                      color: _current < images.length - 1
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
