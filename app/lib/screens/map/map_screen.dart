import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_colors.dart';
import '../../models/product.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/shared_app_bar.dart';
import '../product_detail/product_detail_screen.dart';

// ── Coordinates for mock locations ──────────────────────────
final _cityCoords = <String, LatLng>{
  'Barcelona, ES': LatLng(41.3874, 2.1686),
  'Madrid, ES': LatLng(40.4168, -3.7038),
  'Valencia, ES': LatLng(39.4699, -0.3763),
  'Girona, ES': LatLng(41.9794, 2.8214),
  'Seville, ES': LatLng(37.3891, -5.9845),
  'Terrassa, ES': LatLng(41.5630, 2.0089),
  'Milan, IT': LatLng(45.4642, 9.1900),
};

// ── Product ↔ Marker key (we store the product id in Marker.key) ──
final _markerProducts = <Key, Product>{};

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapCtrl = MapController();
  Product? _selected;

  // ── Filter state ──
  int _selectedType = 0;
  final Set<int> _selectedCategories = {0};
  int _selectedSort = 0;
  RangeValues _priceRange = const RangeValues(0, 1500);

  List<Product> get _filteredProducts {
    return mockProducts.where((p) {
      // Type filter
      if (_selectedType == 1 && p.tag != 'Buy' && p.tag != 'Sell') {
        return false;
      }
      if (_selectedType == 2 && p.tag != 'Rent') return false;
      if (_selectedType == 3 && p.tag != 'Buy or Rent') return false;

      // Category filter
      if (!_selectedCategories.contains(0)) {
        final cats = _MapFiltersModal._categories;
        final selected =
            _selectedCategories.map((i) => cats[i].toLowerCase()).toSet();
        if (p.category != null && !selected.contains(p.category!.toLowerCase())) {
          return false;
        }
      }

      // Price filter
      final numPrice = double.tryParse(
              p.price.replaceAll('€', '').replaceAll(',', '').trim()) ??
          0;
      if (numPrice < _priceRange.start || numPrice > _priceRange.end) {
        return false;
      }

      return true;
    }).toList();
  }

  List<Marker> _buildMarkers() {
    _markerProducts.clear();
    final markers = <Marker>[];
    for (final product in _filteredProducts) {
      final coords = _cityCoords[product.location];
      if (coords == null) continue;

      final key = ValueKey(product.id);
      _markerProducts[key] = product;

      markers.add(
        Marker(
          key: key,
          point: coords,
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => setState(() => _selected = product),
            child: Container(
              decoration: BoxDecoration(
                color: product.verified ? AppColors.ink : AppColors.muted,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.diamond_outlined,
                size: 15,
                color: AppColors.bone,
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  void _navigateToProduct(Product product) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            ProductDetailScreen(productId: product.id),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _centerOnMe() async {
    void showMsg(String msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showMsg('Enable location services in system settings');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          showMsg('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        showMsg('Location permission permanently denied — update in settings');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      _mapCtrl.move(LatLng(pos.latitude, pos.longitude), 13);
    } catch (e) {
      showMsg('Could not get location: ${e.toString().split(':').last.trim()}');
    }
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MapFiltersModal(
        selectedType: _selectedType,
        selectedCategories: Set.of(_selectedCategories),
        selectedSort: _selectedSort,
        priceRange: _priceRange,
        onApply: (type, categories, sort, range) {
          setState(() {
            _selectedType = type;
            _selectedCategories
              ..clear()
              ..addAll(categories);
            _selectedSort = sort;
            _priceRange = range;
            // Deselect marker if it's filtered out
            if (_selected != null && !_filteredProducts.contains(_selected)) {
              _selected = null;
            }
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = _buildMarkers();
    final size = MediaQuery.of(context).size;
    final mapWidth = size.width * 0.90;
    final mapHeight =
        (size.height - MediaQuery.of(context).padding.top - kToolbarHeight) *
            0.85;

    return Scaffold(
      backgroundColor: AppColors.bone,
      drawer: const AppDrawer(currentRoute: '/map'),
      appBar: const SharedAppBar(currentRoute: '/map'),
      body: Stack(
        children: [
          // ── Full layout: map + buttons ──────────────────────────
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: mapWidth,
                    height: mapHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.hairline, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FlutterMap(
                        mapController: _mapCtrl,
                        options: MapOptions(
                          initialCenter: LatLng(40.4, -1.5),
                          initialZoom: 5.8,
                          onTap: (_, _) =>
                              setState(() => _selected = null),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName: 'com.chosenobject.app',
                            maxZoom: 19,
                          ),
                          MarkerClusterLayerWidget(
                            options: MarkerClusterLayerOptions(
                              maxClusterRadius: 60,
                              size: const Size(44, 44),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(50),
                              maxZoom: 15,
                              markers: markers,
                              builder: (context, clusterMarkers) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.ink,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.surface,
                                        width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.20),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      clusterMarkers.length.toString(),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.bone,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Buttons ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FloatingButton(
                      icon: Icons.my_location_rounded,
                      label: 'Center',
                      onTap: _centerOnMe,
                    ),
                    const SizedBox(width: 12),
                    _FloatingButton(
                      icon: Icons.tune_rounded,
                      label: 'Filters',
                      onTap: _openFilters,
                      badge: _hasActiveFilters ? '' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Product preview (fixed overlay at bottom, animated) ──
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(
                  position: slide,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _selected != null
                  ? _ProductPreviewCard(
                      key: ValueKey(_selected!.id),
                      product: _selected!,
                      onView: () => _navigateToProduct(_selected!),
                      onClose: () => setState(() => _selected = null),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters =>
      _selectedType != 0 ||
      !_selectedCategories.contains(0) ||
      _selectedCategories.length > 1 ||
      _priceRange.start > 0 ||
      _priceRange.end < 1500;
}

// ── Floating action button ──────────────────────────────────────

class _FloatingButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  const _FloatingButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.hairline, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: AppColors.inkSoft),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Product preview card ────────────────────────────────────────

class _ProductPreviewCard extends StatelessWidget {
  final Product product;
  final VoidCallback onView;
  final VoidCallback onClose;

  const _ProductPreviewCard({
    super.key,
    required this.product,
    required this.onView,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Thumbnail ──
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: product.images.first,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 14),

                // ── Info ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.fraunces(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkStrong,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${product.designer} · ${product.year}',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            product.price,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkStrong,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.ink.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              product.tag,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.bone,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Close ──
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: AppColors.muted,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // ── View button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: SizedBox(
              width: double.infinity,
              height: 42,
              child: FilledButton(
                onPressed: onView,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.bone,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text('View product'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map filters modal ───────────────────────────────────────────

class _MapFiltersModal extends StatefulWidget {
  final int selectedType;
  final Set<int> selectedCategories;
  final int selectedSort;
  final RangeValues priceRange;
  final void Function(int type, Set<int> categories, int sort, RangeValues range)
      onApply;

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

  const _MapFiltersModal({
    required this.selectedType,
    required this.selectedCategories,
    required this.selectedSort,
    required this.priceRange,
    required this.onApply,
  });

  @override
  State<_MapFiltersModal> createState() => _MapFiltersModalState();
}

class _MapFiltersModalState extends State<_MapFiltersModal> {
  static const _types = ['All', 'Buy', 'Rent', 'Buy or Rent'];
  static const _sortOptions = ['Relevance', 'Price ↑', 'Price ↓', 'Newest'];

  late int _selectedType = widget.selectedType;
  late final Set<int> _selectedCategories = Set.of(widget.selectedCategories);
  late int _selectedSort = widget.selectedSort;
  late RangeValues _priceRange = widget.priceRange;

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
                  _sectionLabel('TYPE'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: List.generate(_types.length, (i) {
                      return _chip(
                        label: _types[i],
                        active: _selectedType == i,
                        onTap: () => setState(() => _selectedType = i),
                      );
                    }),
                  ),

                  // ── Price range section ──
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _sectionLabel('PRICE RANGE'),
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
                  _sectionLabel('SORT BY'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: List.generate(_sortOptions.length, (i) {
                      return _chip(
                        label: _sortOptions[i],
                        active: _selectedSort == i,
                        onTap: () => setState(() => _selectedSort = i),
                      );
                    }),
                  ),

                  // ── Category section ──
                  const SizedBox(height: 24),
                  _sectionLabel('CATEGORY'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: List.generate(
                        _MapFiltersModal._categories.length, (i) {
                      final active = _selectedCategories.contains(i);
                      return _chip(
                        label: _MapFiltersModal._categories[i],
                        active: active,
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
            onTap: () {
              widget.onApply(
                _selectedType,
                _selectedCategories,
                _selectedSort,
                _priceRange,
              );
              Navigator.of(context).pop();
            },
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

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
          letterSpacing: 1.4,
        ),
      );

  Widget _chip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.ink : AppColors.hairline,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w500 : FontWeight.w400,
            color: active ? AppColors.bone : AppColors.inkSoft,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}
