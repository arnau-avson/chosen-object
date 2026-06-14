import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_colors.dart';
import '../../core/browse_service.dart';
import '../../core/geocoding_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/shared_app_bar.dart';

// ═════════════════════════════════════════════════════════════
// ── City cluster model ──────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _CityCluster {
  final String city;
  final LatLng position;
  final List<BrowsePiece> pieces;

  _CityCluster({
    required this.city,
    required this.position,
    required this.pieces,
  });
}

// ═════════════════════════════════════════════════════════════
// ── MapScreen ───────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin {
  final _mapCtrl = MapController();
  bool _loading = true;
  List<_CityCluster> _clusters = [];
  AnimationController? _moveAnim;

  // ── Persistent filter state ──
  int _filterType = 0;       // 0=All, 1=Buy, 2=Rent
  int _filterCategory = 0;   // 0=All, 1..N = category
  int _filterSort = 0;       // 0=Newest, 1=Price↑, 2=Price↓

  @override
  void initState() {
    super.initState();
    _loadPieces();
  }

  /// Smoothly animate the map to [dest] at [zoom].
  void _animatedMove(LatLng dest, double zoom) {
    _moveAnim?.dispose();
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _moveAnim = ctrl;

    final startLat = _mapCtrl.camera.center.latitude;
    final startLng = _mapCtrl.camera.center.longitude;
    final startZoom = _mapCtrl.camera.zoom;

    final latTween = Tween(begin: startLat, end: dest.latitude);
    final lngTween = Tween(begin: startLng, end: dest.longitude);
    final zoomTween = Tween(begin: startZoom, end: zoom);

    final curve = CurvedAnimation(parent: ctrl, curve: Curves.easeInOut);

    ctrl.addListener(() {
      _mapCtrl.move(
        LatLng(latTween.evaluate(curve), lngTween.evaluate(curve)),
        zoomTween.evaluate(curve),
      );
    });

    ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        ctrl.dispose();
        if (_moveAnim == ctrl) _moveAnim = null;
      }
    });

    ctrl.forward();
  }

  Future<void> _loadPieces() async {
    setState(() => _loading = true);

    String? discipline;
    if (_filterCategory > 0) {
      const categories = [
        'All', 'Ceramic', 'Furniture', 'Textiles', 'Lighting',
        'Sculpture', 'Decor', 'Watercolour', 'Painting',
      ];
      discipline = categories[_filterCategory];
    }

    String? sort;
    if (_filterSort == 1) sort = 'price_asc';
    if (_filterSort == 2) sort = 'price_desc';

    String? pieceType;
    if (_filterType == 1) pieceType = 'buy';
    if (_filterType == 2) pieceType = 'rent';

    await BrowseService.instance.fetchPieces(
      discipline: discipline,
      sort: sort,
      pieceType: pieceType,
      limit: 100,
    );
    await _buildClusters();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _buildClusters() async {
    final pieces = BrowseService.instance.pieces;

    // Collect unique city names and geocode them
    final cityNames = pieces
        .map((p) => p.sellerCity)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    final coords = await GeocodingService.instance.geocodeAll(cityNames);

    final Map<String, _CityCluster> map = {};
    for (final piece in pieces) {
      final city = piece.sellerCity;
      if (city == null || city.isEmpty) continue;

      final key = city.toLowerCase().trim();
      final position = coords[key];
      if (position == null) continue;

      if (map.containsKey(key)) {
        map[key]!.pieces.add(piece);
      } else {
        map[key] = _CityCluster(
          city: city,
          position: position,
          pieces: [piece],
        );
      }
    }

    _clusters = map.values.toList();
  }

  void _onClusterTap(_CityCluster cluster) {
    final currentZoom = _mapCtrl.camera.zoom;
    final nextZoom = (currentZoom + 2).clamp(3.0, 17.0);
    _animatedMove(cluster.position, nextZoom);
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

      _animatedMove(LatLng(pos.latitude, pos.longitude), 13);
    } catch (e) {
      showMsg('Could not get location: ${e.toString().split(':').last.trim()}');
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MapFiltersModal(
        initialType: _filterType,
        initialCategory: _filterCategory,
        initialSort: _filterSort,
        onApply: (type, category, sort) {
          setState(() {
            _filterType = type;
            _filterCategory = category;
            _filterSort = sort;
          });
          _loadPieces();
        },
      ),
    );
  }

  @override
  void dispose() {
    _moveAnim?.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.bone,
      drawer: const AppDrawer(currentRoute: '/map'),
      appBar: const SharedAppBar(currentRoute: '/map'),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // ── Map container ──────────────────────────────────────
          Expanded(
            child: Center(
              child: Container(
                width: screenWidth * 0.9,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.hairline, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapCtrl,
                        options: MapOptions(
                          initialCenter: LatLng(41.3874, 2.1686),
                          initialZoom: 5.5,
                          minZoom: 3,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName: 'com.chosenobject.app',
                            maxZoom: 19,
                            keepBuffer: 8,
                          ),
                          MarkerLayer(
                            markers: _clusters.map((cluster) {
                              return Marker(
                                point: cluster.position,
                                width: 42,
                                height: 42,
                                child: GestureDetector(
                                  onTap: () => _onClusterTap(cluster),
                                  child: _ClusterPin(
                                    count: cluster.pieces.length,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),

                      // ── Loading indicator ──────────────────────
                      if (_loading)
                        Positioned(
                          top: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Loading...',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Buttons row (below the map, centered) ──────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MapActionButton(
                  icon: Icons.my_location_rounded,
                  label: 'Center on me',
                  onTap: _centerOnMe,
                ),
                const SizedBox(width: 12),
                _MapActionButton(
                  icon: Icons.tune_rounded,
                  label: 'Filters',
                  onTap: _showFilterSheet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Map action button ───────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MapActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.hairline, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.inkSoft),
            const SizedBox(width: 7),
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
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Cluster map pin ─────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _ClusterPin extends StatelessWidget {
  final int count;

  const _ClusterPin({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inkStrong,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count.toString(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Map filters modal ───────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _MapFiltersModal extends StatefulWidget {
  final int initialType;
  final int initialCategory;
  final int initialSort;
  final void Function(int type, int category, int sort) onApply;

  const _MapFiltersModal({
    required this.initialType,
    required this.initialCategory,
    required this.initialSort,
    required this.onApply,
  });

  @override
  State<_MapFiltersModal> createState() => _MapFiltersModalState();
}

class _MapFiltersModalState extends State<_MapFiltersModal> {
  static const _types = ['All', 'Buy', 'Rent'];

  static const _categories = [
    'All',
    'Ceramic',
    'Furniture',
    'Textiles',
    'Lighting',
    'Sculpture',
    'Decor',
    'Watercolour',
    'Painting',
  ];

  static const _sortOptions = ['Newest', 'Price ↑', 'Price ↓'];

  late int _selectedType = widget.initialType;
  late int _selectedCategory = widget.initialCategory;
  late int _selectedSort = widget.initialSort;

  void _apply() {
    widget.onApply(_selectedType, _selectedCategory, _selectedSort);
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
                child: const Icon(Icons.close_rounded,
                    size: 20, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _sectionLabel('TYPE'),
          const SizedBox(height: 10),
          _chipRow(_types, _selectedType, (i) => setState(() => _selectedType = i)),

          const SizedBox(height: 20),
          _sectionLabel('CATEGORY'),
          const SizedBox(height: 10),
          _chipRow(_categories, _selectedCategory,
              (i) => setState(() => _selectedCategory = i)),

          const SizedBox(height: 20),
          _sectionLabel('SORT'),
          const SizedBox(height: 10),
          _chipRow(_sortOptions, _selectedSort,
              (i) => setState(() => _selectedSort = i)),

          const SizedBox(height: 28),
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

  Widget _chipRow(List<String> items, int selected, void Function(int) onTap) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: List.generate(items.length, (i) {
        final active = i == selected;
        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active ? AppColors.ink : AppColors.hairline,
                width: 1,
              ),
            ),
            child: Text(
              items[i],
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                color: active ? AppColors.bone : AppColors.inkSoft,
              ),
            ),
          ),
        );
      }),
    );
  }
}
