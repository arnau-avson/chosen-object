import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../models/product.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/shared_app_bar.dart';
import '../product_detail/product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  static const _pageSize = 4;
  int _displayedCount = _pageSize;
  bool _loading = false;

  bool get _hasMore => _displayedCount < mockProducts.length;

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _displayedCount =
          (_displayedCount + _pageSize).clamp(0, mockProducts.length);
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
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
      drawer: const AppDrawer(currentRoute: '/home'),
      appBar: const SharedAppBar(currentRoute: '/home'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _fade(0.0, 0.5),
              child: SlideTransition(
                position: _slide(0.0, 0.5),
                child: const _SeasonHeader(),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _fade(0.2, 0.7),
              child: SlideTransition(
                position: _slide(0.2, 0.7),
                child: _ProductGrid(
                  products: mockProducts.take(_displayedCount).toList(),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // ── Load more / spinner ──
            if (_hasMore)
              Center(
                child: _loading
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
  const _SeasonHeader();

  static const int _pieceCount = 19;

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
                    '$_pieceCount pieces curated',
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
  // ── Transaction type ──
  static const _types = ['All', 'Buy', 'Rent', 'Buy or Rent'];
  int _selectedType = 0;

  // ── Category ──
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

  // ── Sort ──
  static const _sortOptions = ['Relevance', 'Price ↑', 'Price ↓', 'Newest'];
  int _selectedSort = 0;

  // ── Price range ──
  RangeValues _priceRange = const RangeValues(0, 1500);

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
          // Handle bar
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

          // Header
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

          // ── Scrollable filter content ──
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
                      fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                      color: active ? AppColors.bone : AppColors.inkSoft,
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
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              rangeThumbShape:
                  const RoundRangeSliderThumbShape(enabledThumbRadius: 7),
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
                      fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                      color: active ? AppColors.bone : AppColors.inkSoft,
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
                      fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                      color: active ? AppColors.bone : AppColors.inkSoft,
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
            onTap: () => Navigator.of(context).pop(),
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

// ── Product card with swipeable images ───────────────────────

class _ProductCard extends StatefulWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  int _currentPage = 0;
  bool _saved = false;

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
        ),
      ],
    );
  }
}
