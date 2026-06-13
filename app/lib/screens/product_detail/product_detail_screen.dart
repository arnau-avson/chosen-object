import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/browse_service.dart';
import '../../core/cart_service.dart';
import '../../core/collection_service.dart';
import '../../core/follow_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/save_to_collection_modal.dart';
import '../profile/user_profile_screen.dart';
import '../../widgets/fullscreen_image_viewer.dart';
import '../../widgets/shared_app_bar.dart';

class ProductDetailScreen extends StatefulWidget {
  final int pieceId;
  const ProductDetailScreen({super.key, required this.pieceId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentPage = 0;
  bool _descExpanded = false;
  final _pageCtrl = PageController();

  BrowsePiece? _piece;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPiece();
  }

  Future<void> _loadPiece() async {
    final piece = await BrowseService.instance.fetchPieceDetail(widget.pieceId);
    if (!mounted) return;
    setState(() {
      _piece = piece;
      _loading = false;
      if (piece == null) _error = 'Piece not found';
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  List<String> _getImageB64List() {
    final piece = _piece!;
    final list = <String>[];
    if (piece.images != null && piece.images!.isNotEmpty) {
      for (final img in piece.images!) {
        final b64 = img['image_b64'] as String?;
        if (b64 != null && b64.isNotEmpty) list.add(b64);
      }
    }
    if (list.isEmpty && piece.coverImageB64 != null) {
      list.add(piece.coverImageB64!);
    }
    return list;
  }

  void _openImageViewer(
      BuildContext context, List<String> imagesB64, int initialIndex) {
    FullscreenImageViewer.open(context, imagesB64, initialIndex: initialIndex);
  }

  String _getTag() {
    final piece = _piece!;
    if (piece.rental && piece.priceCents > 0) return 'Buy or Rent';
    if (piece.rental) return 'Rent';
    return 'Buy';
  }

  String _priceLabel(String tag) => switch (tag) {
        'Rent' => 'RENTAL PRICE',
        'Buy or Rent' => 'SALE PRICE',
        _ => 'SALE PRICE',
      };

  String _actionLabel(String tag) => switch (tag) {
        'Rent' => 'Request rental',
        'Buy or Rent' => 'Add to cart',
        _ => 'Add to cart',
      };

  Future<void> _handlePrimaryAction(String tag) async {
    if (tag == 'Rent') {
      // For rental-only pieces show a snackbar (rental request flow)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rental request feature coming soon')),
      );
    } else {
      // Add to cart
      final success = await CartService.instance.addToCart(widget.pieceId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Added to cart' : 'Failed to add to cart'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        drawer: const AppDrawer(currentRoute: '/product-detail'),
        appBar:
            const SharedAppBar(currentRoute: '/product-detail', showBack: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _piece == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        drawer: const AppDrawer(currentRoute: '/product-detail'),
        appBar:
            const SharedAppBar(currentRoute: '/product-detail', showBack: true),
        body: Center(
          child: Text(_error ?? 'Something went wrong',
              style: GoogleFonts.inter(color: AppColors.muted)),
        ),
      );
    }

    final piece = _piece!;
    final imagesB64 = _getImageB64List();
    final tag = _getTag();
    final w = MediaQuery.of(context).size.width;
    final designerName = piece.sellerStudioName ?? piece.sellerUsername ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: const AppDrawer(currentRoute: '/product-detail'),
      appBar:
          const SharedAppBar(currentRoute: '/product-detail', showBack: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ═══════════════════════════════════════════════════
            // ── 1. Image carousel ────────────────────────────
            // ═══════════════════════════════════════════════════
            SizedBox(
              height: w * 0.95,
              child: imagesB64.isEmpty
                  ? Container(
                      color: AppColors.hairline,
                      alignment: Alignment.center,
                      child: Icon(Icons.image_outlined,
                          size: 48, color: AppColors.muted),
                    )
                  : Stack(
                      children: [
                        PageView.builder(
                          controller: _pageCtrl,
                          itemCount: imagesB64.length,
                          onPageChanged: (p) =>
                              setState(() => _currentPage = p),
                          itemBuilder: (_, i) => GestureDetector(
                            onDoubleTap: () =>
                                _openImageViewer(context, imagesB64, i),
                            child: Image.memory(
                              base64Decode(imagesB64[i]),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
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
                              tag,
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
                        if (imagesB64.length > 1)
                          Positioned(
                            bottom: 14,
                            left: 16,
                            right: 16,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _currentPage > 0
                                      ? () => _pageCtrl.previousPage(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeOut,
                                          )
                                      : null,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: _currentPage > 0
                                          ? AppColors.ink
                                              .withValues(alpha: 0.5)
                                          : AppColors.ink
                                              .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.chevron_left_rounded,
                                      size: 18,
                                      color: _currentPage > 0
                                          ? Colors.white
                                          : Colors.white
                                              .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(imagesB64.length,
                                      (i) {
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
                                GestureDetector(
                                  onTap: _currentPage < imagesB64.length - 1
                                      ? () => _pageCtrl.nextPage(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeOut,
                                          )
                                      : null,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color:
                                          _currentPage < imagesB64.length - 1
                                              ? AppColors.ink
                                                  .withValues(alpha: 0.5)
                                              : AppColors.ink
                                                  .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color:
                                          _currentPage < imagesB64.length - 1
                                              ? Colors.white
                                              : Colors.white
                                                  .withValues(alpha: 0.4),
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
                  ListenableBuilder(
                    listenable: CollectionService.instance,
                    builder: (context, _) {
                      final saved = CollectionService.instance
                          .isProductSaved(widget.pieceId);
                      return GestureDetector(
                        onTap: () => CollectionService.instance
                            .toggleSaved(widget.pieceId),
                        onLongPress: () => SaveToCollectionModal.show(
                            context, widget.pieceId),
                        child: Icon(
                          saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 22,
                          color:
                              saved ? AppColors.inkStrong : AppColors.inkSoft,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════════════════
            // ── 3. Edition + Title + Year ─────────────────────
            // ═══════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (piece.edition != null)
                    Text(
                      'Edition ${piece.edition}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    piece.title,
                    style: GoogleFonts.fraunces(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  if (piece.year != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      piece.year!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ═══════════════════════════════════════════════════
            // ── 4. Designer / Seller ─────────────────────────
            // ═══════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, _, _) =>
                                UserProfileScreen(userId: piece.userId.toString()),
                            transitionsBuilder: (_, animation, _, child) =>
                                FadeTransition(
                                    opacity: animation, child: child),
                            transitionDuration:
                                const Duration(milliseconds: 300),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.hairline,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              designerName.isNotEmpty
                                  ? designerName[0].toUpperCase()
                                  : '?',
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
                                Text(
                                  designerName,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.inkStrong,
                                  ),
                                ),
                                if (piece.discipline != null) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    piece.discipline!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () async {
                      await FollowService.instance.follow(piece.userId);
                    },
                    child: Container(
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
            if (piece.description != null && piece.description!.isNotEmpty)
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
                              piece.description!,
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
                              piece.description!,
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
                  if (piece.year != null)
                    _SpecRow(label: 'Year', value: piece.year!),
                  if (piece.discipline != null)
                    _SpecRow(label: 'Discipline', value: piece.discipline!),
                  if (piece.packaging != null)
                    _SpecRow(label: 'Packaging', value: piece.packaging!),
                  _SpecRow(
                      label: 'Stock', value: piece.stock.toString()),
                  if (piece.shipsTo != null && piece.shipsTo!.isNotEmpty)
                    _SpecRow(
                        label: 'Ships to',
                        value: piece.shipsTo!.join(', ')),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: AppColors.hairline, height: 1),
            ),

            // ═══════════════════════════════════════════════════
            // ── 7. Price + Actions ───────────────────────────
            // ═══════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _priceLabel(tag),
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (piece.oldPriceCents != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '€${(piece.oldPriceCents! / 100).toStringAsFixed(2)}',
                          style: GoogleFonts.fraunces(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFB04A4A),
                            height: 1.1,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: const Color(0xFFB04A4A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          piece.priceFormatted,
                          style: GoogleFonts.fraunces(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            color: AppColors.inkStrong,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Text(
                      piece.priceFormatted,
                      style: GoogleFonts.fraunces(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        color: AppColors.inkStrong,
                        height: 1.1,
                      ),
                    ),
                  // Rental rate info
                  if (piece.rental && piece.rentalDailyRateCents != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Rental: €${(piece.rentalDailyRateCents! / 100).toStringAsFixed(2)}/day',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Action buttons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _handlePrimaryAction(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _actionLabel(tag),
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
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Make an offer = start conversation with seller
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Offer feature coming soon')),
                        );
                      },
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

