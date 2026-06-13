import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/browse_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/save_to_collection_modal.dart';
import '../../widgets/shared_app_bar.dart';
import '../../core/collection_service.dart';
import '../product_detail/product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  bool _loadingMore = false;
  int _offset = 0;
  static const _pageSize = 20;
  bool _hasMore = true;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    await BrowseService.instance.fetchPieces(offset: 0, limit: _pageSize);
    if (!mounted) return;
    setState(() {
      _offset = BrowseService.instance.pieces.length;
      _hasMore = BrowseService.instance.pieces.length >= _pageSize;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    await BrowseService.instance.fetchPieces(offset: _offset, limit: _pageSize);
    if (!mounted) return;
    setState(() {
      _offset = BrowseService.instance.pieces.length;
      _hasMore = BrowseService.instance.pieces.length >= _offset;
      _loadingMore = false;
    });
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPress = now;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Press back again to exit',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.bone),
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.ink,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
      },
      child: Scaffold(
      backgroundColor: AppColors.bone,
      drawer: const AppDrawer(currentRoute: '/home'),
      appBar: const SharedAppBar(currentRoute: '/home'),
      body: ListenableBuilder(
        listenable: BrowseService.instance,
        builder: (context, _) {
          final pieces = BrowseService.instance.pieces;
          final loading = BrowseService.instance.loading && pieces.isEmpty;

          if (loading) {
            return const Center(child: LoadingSpinner());
          }

          if (pieces.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 48,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No pieces available',
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkStrong,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'There are no pieces listed yet. Check back later or explore studios.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _fade(0.0, 0.5),
                  child: SlideTransition(
                    position: _slide(0.0, 0.5),
                    child: _SeasonHeader(pieceCount: pieces.length),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _fade(0.2, 0.7),
                  child: SlideTransition(
                    position: _slide(0.2, 0.7),
                    child: _ProductGrid(pieces: pieces),
                  ),
                ),
                const SizedBox(height: 28),
                if (_hasMore)
                  Center(
                    child: _loadingMore
                        ? const Padding(
                            padding: EdgeInsets.only(bottom: 32),
                            child: LoadingSpinner(),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: GestureDetector(
                              onTap: _loadMore,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 11),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: AppColors.hairline, width: 1),
                                ),
                                child: Text(
                                  'Load more',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.inkSoft,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  )
                else
                  const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    ),
    );
  }
}

// ── Season header ─────────────────────────────────────────────

String _currentSeason() {
  final now = DateTime.now();
  final m = now.month;
  final d = now.day;
  if ((m == 12 && d >= 21) || m <= 2 || (m == 3 && d <= 19)) return 'Winter';
  if ((m == 3 && d >= 20) || m == 4 || m == 5 || (m == 6 && d <= 20)) return 'Spring';
  if ((m == 6 && d >= 21) || m == 7 || m == 8 || (m == 9 && d <= 22)) return 'Summer';
  return 'Autumn';
}

class _SeasonHeader extends StatelessWidget {
  final int pieceCount;
  const _SeasonHeader({required this.pieceCount});

  @override
  Widget build(BuildContext context) {
    final season = _currentSeason();
    final year = DateTime.now().year;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Center(
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left: Nº04 + Filters button stacked ──
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Nº',
                          style: GoogleFonts.fraunces(
                            fontSize: 42,
                            fontWeight: FontWeight.w300,
                            fontStyle: FontStyle.italic,
                            color: AppColors.gold,
                            height: 1.0,
                          ),
                        ),
                        TextSpan(
                          text: '04',
                          style: GoogleFonts.fraunces(
                            fontSize: 42,
                            fontWeight: FontWeight.w300,
                            fontStyle: FontStyle.italic,
                            color: AppColors.inkStrong,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => const _FiltersModal(),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: AppColors.hairline, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: AppColors.inkSoft,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Filters',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkSoft,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Vertical divider ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Container(width: 1, color: AppColors.hairline),
              ),

              // ── Right: stacked lines ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Edit  ·  $season $year',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.muted,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$pieceCount pieces curated',
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
                          text: 'A small, ',
                          style: GoogleFonts.fraunces(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w400,
                            color: AppColors.inkSoft,
                            height: 1.4,
                          ),
                        ),
                        TextSpan(
                          text: 'careful selection.',
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

// ── Filters modal ─────────────────────────────────────────────

class _FiltersModal extends StatefulWidget {
  const _FiltersModal();

  @override
  State<_FiltersModal> createState() => _FiltersModalState();
}

class _FiltersModalState extends State<_FiltersModal> {
  static const _types = ['All', 'Buy', 'Rent', 'Buy or Rent'];
  int _selectedType = 0;

  static const _categories = [
    'All',
    'Painting',
    'Sculpture',
    'Furniture',
    'Lighting',
    'Watercolour',
    'Ceramic',
    'Decor',
    'Textiles',
    'Mixed media',
  ];
  final Set<int> _selectedCategories = {0};

  static const _sortOptions = ['Relevance', 'Price ↑', 'Price ↓', 'Newest'];
  int _selectedSort = 0;

  RangeValues _priceRange = const RangeValues(0, 1500);

  void _apply() {
    String? discipline;
    if (!_selectedCategories.contains(0)) {
      final cats = _selectedCategories.map((i) => _categories[i]).toList();
      discipline = cats.first; // simplified: use first selected
    }

    String? sort;
    switch (_selectedSort) {
      case 1:
        sort = 'price_asc';
        break;
      case 2:
        sort = 'price_desc';
        break;
      case 3:
        sort = 'newest';
        break;
    }

    BrowseService.instance.fetchPieces(
      discipline: discipline,
      sort: sort,
      minPrice: _priceRange.start.round() * 100,
      maxPrice: _priceRange.end.round() * 100,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Filters',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: AppColors.inkStrong,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: AppColors.hairline),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Type section ──
                  const SizedBox(height: 20),
                  Text(
                    'TYPE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: List.generate(_types.length, (i) {
                      final active = _selectedType == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedType = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: active ? AppColors.ink : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: active ? AppColors.ink : AppColors.hairline,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _types[i],
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight:
                                  active ? FontWeight.w500 : FontWeight.w400,
                              color:
                                  active ? AppColors.bone : AppColors.inkSoft,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  // ── Price range section ──
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'PRICE RANGE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '€${_priceRange.start.round()} – €${_priceRange.end.round()}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.ink,
                      inactiveTrackColor: AppColors.hairline,
                      thumbColor: AppColors.ink,
                      overlayColor: AppColors.ink.withValues(alpha: 0.08),
                      trackHeight: 2,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                      rangeThumbShape: const RoundRangeSliderThumbShape(
                          enabledThumbRadius: 7),
                    ),
                    child: RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 3000,
                      divisions: 60,
                      onChanged: (v) => setState(() => _priceRange = v),
                    ),
                  ),

                  // ── Sort section ──
                  const SizedBox(height: 20),
                  Text(
                    'SORT BY',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: List.generate(_sortOptions.length, (i) {
                      final active = _selectedSort == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSort = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: active ? AppColors.ink : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: active ? AppColors.ink : AppColors.hairline,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _sortOptions[i],
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight:
                                  active ? FontWeight.w500 : FontWeight.w400,
                              color:
                                  active ? AppColors.bone : AppColors.inkSoft,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  // ── Category section ──
                  const SizedBox(height: 24),
                  Text(
                    'CATEGORY',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: List.generate(_categories.length, (i) {
                      final active = _selectedCategories.contains(i);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (i == 0) {
                              _selectedCategories
                                ..clear()
                                ..add(0);
                            } else {
                              _selectedCategories.remove(0);
                              if (active) {
                                _selectedCategories.remove(i);
                                if (_selectedCategories.isEmpty) {
                                  _selectedCategories.add(0);
                                }
                              } else {
                                _selectedCategories.add(i);
                              }
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: active ? AppColors.ink : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: active ? AppColors.ink : AppColors.hairline,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _categories[i],
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight:
                                  active ? FontWeight.w500 : FontWeight.w400,
                              color:
                                  active ? AppColors.bone : AppColors.inkSoft,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // Apply button
          GestureDetector(
            onTap: _apply,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                'Apply filters',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.bone,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product grid ─────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  final List<BrowsePiece> pieces;
  const _ProductGrid({required this.pieces});

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
        itemBuilder: (_, i) => _ProductCard(piece: pieces[i]),
      ),
    );
  }
}

// ── Product card with swipeable images ───────────────────────

class _ProductCard extends StatefulWidget {
  final BrowsePiece piece;
  const _ProductCard({required this.piece});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  int _currentPage = 0;

  void _openDetail() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            ProductDetailScreen(pieceId: widget.piece.id),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  List<String> _getImageList() {
    final piece = widget.piece;
    final list = <String>[];
    if (piece.images != null) {
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

  String _getTag() {
    final piece = widget.piece;
    if (piece.rental && piece.priceCents > 0) return 'Buy or Rent';
    if (piece.rental) return 'Rent';
    return 'Buy';
  }

  @override
  Widget build(BuildContext context) {
    final images = _getImageList();
    final tag = _getTag();
    final piece = widget.piece;
    final designerName = piece.sellerStudioName ?? piece.sellerUsername ?? '';

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
                  if (images.isNotEmpty)
                    PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (p) => setState(() => _currentPage = p),
                      itemBuilder: (_, i) => Image.memory(
                        base64Decode(images[i]),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  else
                    Container(
                      color: AppColors.hairline,
                      alignment: Alignment.center,
                      child: Icon(Icons.image_outlined,
                          size: 32, color: AppColors.muted),
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
                      '$designerName${piece.year != null ? ' · ${piece.year}' : ''}',
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
