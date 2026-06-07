import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_colors.dart';
import '../../core/browse_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/shared_app_bar.dart';
import '../product_detail/product_detail_screen.dart';

// ═════════════════════════════════════════════════════════════
// ── City → LatLng lookup ────────────────────────────────────
// ═════════════════════════════════════════════════════════════

const Map<String, LatLng> _cityCoords = {
  'barcelona': LatLng(41.3874, 2.1686),
  'girona': LatLng(41.9794, 2.8214),
  'valencia': LatLng(39.4699, -0.3763),
  'madrid': LatLng(40.4168, -3.7038),
  'seville': LatLng(37.3891, -5.9845),
  'sevilla': LatLng(37.3891, -5.9845),
  'terrassa': LatLng(41.5630, 2.0089),
  'palma': LatLng(39.5696, 2.6502),
  'palma de mallorca': LatLng(39.5696, 2.6502),
  'milan': LatLng(45.4642, 9.1900),
  'milano': LatLng(45.4642, 9.1900),
  'lisbon': LatLng(38.7223, -9.1393),
  'lisboa': LatLng(38.7223, -9.1393),
  'bilbao': LatLng(43.2630, -2.9350),
  'paris': LatLng(48.8566, 2.3522),
  'london': LatLng(51.5074, -0.1278),
  'berlin': LatLng(52.5200, 13.4050),
  'rome': LatLng(41.9028, 12.4964),
  'roma': LatLng(41.9028, 12.4964),
  'amsterdam': LatLng(52.3676, 4.9041),
  'porto': LatLng(41.1579, -8.6291),
  'marseille': LatLng(43.2965, 5.3698),
  'lyon': LatLng(45.7640, 4.8357),
  'florence': LatLng(43.7696, 11.2558),
  'firenze': LatLng(43.7696, 11.2558),
  'malaga': LatLng(36.7213, -4.4214),
  'zaragoza': LatLng(41.6488, -0.8891),
  'san sebastian': LatLng(43.3183, -1.9812),
  'donostia': LatLng(43.3183, -1.9812),
  'bruges': LatLng(51.2093, 3.2247),
  'antwerp': LatLng(51.2194, 4.4025),
  'vienna': LatLng(48.2082, 16.3738),
  'munich': LatLng(48.1351, 11.5820),
  'zurich': LatLng(47.3769, 8.5417),
  'copenhagen': LatLng(55.6761, 12.5683),
  'stockholm': LatLng(59.3293, 18.0686),
  'brussels': LatLng(50.8503, 4.3517),
  'athens': LatLng(37.9838, 23.7275),
  'prague': LatLng(50.0755, 14.4378),
  'budapest': LatLng(47.4979, 19.0402),
};

LatLng? _coordsForCity(String? city) {
  if (city == null || city.isEmpty) return null;
  return _cityCoords[city.toLowerCase().trim()];
}

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

class _MapScreenState extends State<MapScreen> {
  final _mapCtrl = MapController();
  final _searchController = TextEditingController();
  bool _loading = true;
  List<_CityCluster> _clusters = [];
  _CityCluster? _selectedCluster;

  @override
  void initState() {
    super.initState();
    _loadPieces();
  }

  Future<void> _loadPieces({String? search}) async {
    setState(() => _loading = true);
    await BrowseService.instance.fetchPieces(
      search: search,
      limit: 100,
    );
    _buildClusters();
    if (mounted) setState(() => _loading = false);
  }

  void _buildClusters() {
    final pieces = BrowseService.instance.pieces;
    final Map<String, _CityCluster> map = {};

    for (final piece in pieces) {
      final city = piece.sellerCity;
      if (city == null || city.isEmpty) continue;
      final coords = _coordsForCity(city);
      if (coords == null) continue;

      final key = city.toLowerCase().trim();
      if (map.containsKey(key)) {
        map[key]!.pieces.add(piece);
      } else {
        map[key] = _CityCluster(
          city: city,
          position: coords,
          pieces: [piece],
        );
      }
    }

    _clusters = map.values.toList();
  }

  void _onClusterTap(_CityCluster cluster) {
    setState(() => _selectedCluster = cluster);
    _mapCtrl.move(cluster.position, 10);
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

  void _onSearch(String value) {
    setState(() => _selectedCluster = null);
    _loadPieces(search: value.isEmpty ? null : value);
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MapFiltersModal(
        onApply: (discipline, sort, pieceType) {
          BrowseService.instance.fetchPieces(
            discipline: discipline,
            sort: sort,
            pieceType: pieceType,
            limit: 100,
          ).then((_) {
            _buildClusters();
            if (mounted) setState(() {});
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        kToolbarHeight;

    return Scaffold(
      backgroundColor: AppColors.bone,
      drawer: const AppDrawer(currentRoute: '/map'),
      appBar: const SharedAppBar(currentRoute: '/map'),
      body: Column(
        children: [
          const SizedBox(height: 14),

          // ── Search input (above the map) ───────────────────────
          SizedBox(
            width: screenWidth * 0.9,
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearch,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                color: AppColors.inkStrong,
              ),
              decoration: InputDecoration(
                hintText: 'Search pieces or cities...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: AppColors.muted,
                ),
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
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 8),
                  child: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Map container (90% width, 80% height) ──────────────
          Expanded(
            child: Center(
              child: Container(
                width: screenWidth * 0.9,
                height: screenHeight * 0.8,
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
                          onTap: (_, __) {
                            if (_selectedCluster != null) {
                              setState(() => _selectedCluster = null);
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName: 'com.chosenobject.app',
                            maxZoom: 19,
                          ),
                          MarkerLayer(
                            markers: _clusters.map((cluster) {
                              final isSelected = cluster == _selectedCluster;
                              return Marker(
                                point: cluster.position,
                                width: 42,
                                height: 42,
                                child: GestureDetector(
                                  onTap: () => _onClusterTap(cluster),
                                  child: _ClusterPin(
                                    count: cluster.pieces.length,
                                    selected: isSelected,
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

                      // ── Carousel (selected city pieces) ────────
                      if (_selectedCluster != null)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: SizedBox(
                            height: 170,
                            child: _PiecesCarousel(
                              cluster: _selectedCluster!,
                              onClose: () =>
                                  setState(() => _selectedCluster = null),
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
  final bool selected;

  const _ClusterPin({required this.count, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? AppColors.accent : AppColors.inkStrong,
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
// ── Pieces carousel (selected city) ─────────────────────────
// ═════════════════════════════════════════════════════════════

class _PiecesCarousel extends StatelessWidget {
  final _CityCluster cluster;
  final VoidCallback onClose;

  const _PiecesCarousel({required this.cluster, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 8),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 14, color: AppColors.accent),
                const SizedBox(width: 5),
                Text(
                  cluster.city,
                  style: GoogleFonts.fraunces(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkStrong,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '· ${cluster.pieces.length} piece${cluster.pieces.length == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.muted,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),

          // ── Horizontal list ──
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              scrollDirection: Axis.horizontal,
              itemCount: cluster.pieces.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                return _PieceChip(piece: cluster.pieces[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Piece chip in carousel ──────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _PieceChip extends StatelessWidget {
  final BrowsePiece piece;

  const _PieceChip({required this.piece});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                ProductDetailScreen(pieceId: piece.id),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: AppColors.bone,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.hairline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(9)),
                child: piece.coverImageB64 != null
                    ? Image.memory(
                        base64Decode(piece.coverImageB64!),
                        width: 120,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppColors.hairline2,
                        child: const Center(
                          child: Icon(Icons.image_outlined,
                              size: 22, color: AppColors.muted),
                        ),
                      ),
              ),
            ),
            // ── Info ──
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    piece.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    piece.priceFormatted,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Map filters modal ───────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _MapFiltersModal extends StatefulWidget {
  final void Function(String? discipline, String? sort, String? pieceType)
      onApply;

  const _MapFiltersModal({required this.onApply});

  @override
  State<_MapFiltersModal> createState() => _MapFiltersModalState();
}

class _MapFiltersModalState extends State<_MapFiltersModal> {
  static const _types = ['All', 'Buy', 'Rent'];
  int _selectedType = 0;

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
  int _selectedCategory = 0;

  static const _sortOptions = ['Newest', 'Price ↑', 'Price ↓'];
  int _selectedSort = 0;

  void _apply() {
    String? discipline;
    if (_selectedCategory > 0) {
      discipline = _categories[_selectedCategory];
    }

    String? sort;
    switch (_selectedSort) {
      case 1:
        sort = 'price_asc';
        break;
      case 2:
        sort = 'price_desc';
        break;
    }

    String? pieceType;
    switch (_selectedType) {
      case 1:
        pieceType = 'buy';
        break;
      case 2:
        pieceType = 'rent';
        break;
    }

    widget.onApply(discipline, sort, pieceType);
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
