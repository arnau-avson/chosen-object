import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _searchActive = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  late final AnimationController _searchAnim;
  late final Animation<double> _titleFade;   // 1→0 as search opens
  late final Animation<double> _searchFade;  // 0→1 as search opens
  late final Animation<Offset> _searchSlide; // slides in from right

  @override
  void initState() {
    super.initState();
    _searchAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 230),
    );
    final curve = CurvedAnimation(parent: _searchAnim, curve: Curves.easeOut);
    _titleFade = Tween<double>(begin: 1.0, end: 0.0).animate(curve);
    _searchFade = curve;
    _searchSlide = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(curve);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchAnim.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searchActive = true);
    _searchAnim.forward();
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _searchFocusNode.unfocus();
    _searchAnim.reverse().then((_) {
      if (mounted) {
        _searchController.clear();
        setState(() => _searchActive = false);
      }
    });
  }

  void _showNotificationsModal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _NotificationsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      drawer: const AppDrawer(currentRoute: '/home'),
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Row(
            children: [
              // ── Expanded area: wordmark ↔ search field ──────────
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Wordmark fades out
                    IgnorePointer(
                      ignoring: _searchActive,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: const Text('Chosen Object'),
                      ),
                    ),
                    // Search field slides+fades in
                    IgnorePointer(
                      ignoring: !_searchActive,
                      child: FadeTransition(
                        opacity: _searchFade,
                        child: SlideTransition(
                          position: _searchSlide,
                          child: FractionallySizedBox(
                            widthFactor: 0.95,
                            alignment: Alignment.center,
                            child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            textInputAction: TextInputAction.search,
                            style: GoogleFonts.inter(
                                fontSize: 14.5, color: AppColors.inkStrong),
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: GoogleFonts.inter(
                                  fontSize: 14.5, color: AppColors.muted),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: const BorderSide(
                                    color: AppColors.ink, width: 1.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: const BorderSide(
                                    color: AppColors.ink, width: 1.0),
                              ),
                              suffixIcon: IconButton(
                                icon:
                                    const Icon(Icons.close_rounded, size: 18),
                                color: AppColors.muted,
                                onPressed: _closeSearch,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                            onSubmitted: (_) {},
                          ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Action icons collapse as search opens ────────────
              SizeTransition(
                sizeFactor: _titleFade,
                axis: Axis.horizontal,
                axisAlignment: 1,
                child: IgnorePointer(
                  ignoring: _searchActive,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search_outlined, size: 21),
                          tooltip: 'Search',
                          color: AppColors.inkSoft,
                          onPressed: _openSearch,
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.bookmark_border_rounded,
                              size: 21),
                          tooltip: 'Saved',
                          color: AppColors.inkSoft,
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.notifications_none_rounded,
                              size: 22),
                          tooltip: 'Notifications',
                          color: AppColors.inkSoft,
                          onPressed: () => _showNotificationsModal(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SeasonHeader(),
            const SizedBox(height: 28),
            const _FilterButton(),
            const SizedBox(height: 28),
            const _ProductGrid(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Notifications modal ──────────────────────────────────────

class _NotificationsModal extends StatelessWidget {
  const _NotificationsModal();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 480),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.hairline, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Text(
                      'Notifications',
                      style: GoogleFonts.fraunces(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: AppColors.inkStrong,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: AppColors.muted,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.hairline, height: 1, thickness: 1),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        size: 36,
                        color: AppColors.hairline2,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No notifications yet',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w400,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Nº04 left ──
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

// ── Filter button + modal ─────────────────────────────────────

class _FilterButton extends StatelessWidget {
  const _FilterButton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => const _FiltersModal(),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.hairline, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 16,
                color: AppColors.inkSoft,
              ),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkSoft,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltersModal extends StatefulWidget {
  const _FiltersModal();

  @override
  State<_FiltersModal> createState() => _FiltersModalState();
}

class _FiltersModalState extends State<_FiltersModal> {
  static const _filters = [
    'All',
    'Available to rent',
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

  final Set<int> _selected = {0};

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
          const SizedBox(height: 20),

          // Filter chips
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: List.generate(_filters.length, (i) {
              final active = _selected.contains(i);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (i == 0) {
                      _selected
                        ..clear()
                        ..add(0);
                    } else {
                      _selected.remove(0);
                      if (active) {
                        _selected.remove(i);
                        if (_selected.isEmpty) _selected.add(0);
                      } else {
                        _selected.add(i);
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
                    _filters[i],
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

// ── Mock product data ────────────────────────────────────────

class _Product {
  final String name;
  final String designer;
  final String price;
  final String tag; // 'Sell', 'Buy', 'Rent', 'Buy or Rent'
  final List<Color> images; // placeholder colors for mock images

  const _Product({
    required this.name,
    required this.designer,
    required this.price,
    required this.tag,
    required this.images,
  });
}

const _mockProducts = <_Product>[
  _Product(
    name: 'Curved Vessel',
    designer: 'Marta Sala',
    price: '€340',
    tag: 'Sell',
    images: [Color(0xFFBEB0A0), Color(0xFFA89888), Color(0xFFD4C8B8)],
  ),
  _Product(
    name: 'Linen Armchair',
    designer: 'Atelier NM',
    price: '€1,200',
    tag: 'Buy or Rent',
    images: [Color(0xFFCBC2B4), Color(0xFFB5A898)],
  ),
  _Product(
    name: 'Bronze Table Lamp',
    designer: 'Studio Vèra',
    price: '€480',
    tag: 'Sell',
    images: [Color(0xFFA8997E), Color(0xFFC2B5A2), Color(0xFF8A7D6A)],
  ),
  _Product(
    name: 'Walnut Side Table',
    designer: 'Jordi Canudas',
    price: '€720',
    tag: 'Rent',
    images: [Color(0xFF9A8C7B), Color(0xFFBAAD9A)],
  ),
  _Product(
    name: 'Stoneware Bowl',
    designer: 'Clara Boj',
    price: '€190',
    tag: 'Buy',
    images: [Color(0xFFD0C5B5), Color(0xFFB8AB99), Color(0xFFE0D6C4)],
  ),
  _Product(
    name: 'Woven Throw',
    designer: 'Teixidors',
    price: '€260',
    tag: 'Buy or Rent',
    images: [Color(0xFFC5B9A5), Color(0xFFAEA08C)],
  ),
  _Product(
    name: 'Glass Pendant',
    designer: 'Viabizzuno',
    price: '€560',
    tag: 'Sell',
    images: [Color(0xFFB3A594), Color(0xFFD6CCC0), Color(0xFF9E9080)],
  ),
  _Product(
    name: 'Ceramic Vase',
    designer: 'Apparatu',
    price: '€280',
    tag: 'Rent',
    images: [Color(0xFFCABEAE), Color(0xFFB0A492)],
  ),
];

// ── Product grid ─────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  const _ProductGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _mockProducts.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 24,
          childAspectRatio: 0.58,
        ),
        itemBuilder: (_, i) => _ProductCard(product: _mockProducts[i]),
      ),
    );
  }
}

// ── Product card with swipeable images ───────────────────────

class _ProductCard extends StatefulWidget {
  final _Product product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.product.images;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Image area with PageView ──
        Expanded(
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
                          margin: const EdgeInsets.symmetric(horizontal: 3),
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

        const SizedBox(height: 10),

        // ── Product info ──
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
          widget.product.designer,
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
    );
  }
}
