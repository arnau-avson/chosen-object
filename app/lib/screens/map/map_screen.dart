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
    _selectedCluster = null;
    _loadPieces(search: value.isEmpty ? null : value);
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPanel = _selectedCluster != null;

    return Scaffold(
      backgroundColor: AppColors.bone,
      drawer: const AppDrawer(currentRoute: '/map'),
      appBar: const SharedAppBar(currentRoute: '/map'),
      body: Column(
        children: [
          // ── Map area ──────────────────────────────────────────
          Expanded(
            flex: bottomPanel ? 5 : 7,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: LatLng(41.3874, 2.1686),
                    initialZoom: 5.5,
                    minZoom: 3,
                    onTap: (_, __) {
                      setState(() => _selectedCluster = null);
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
                          width: 48,
                          height: 48,
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

                // ── Loading indicator ──
                if (_loading)
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Loading pieces...',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Center on me button ──
                Positioned(
                  bottom: 14,
                  right: 14,
                  child: GestureDetector(
                    onTap: _centerOnMe,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        size: 18,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Search bar ──────────────────────────────────────────
          Container(
            color: AppColors.bone,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.hairline, width: 1),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: _onSearch,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: AppColors.inkStrong,
                ),
                decoration: InputDecoration(
                  hintText: 'Search pieces by name, city...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: AppColors.muted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // ── Bottom panel: pieces from selected city ────────────
          if (bottomPanel)
            Expanded(
              flex: 4,
              child: _CityPiecesPanel(cluster: _selectedCluster!),
            )
          else
            // ── City list ──
            Expanded(
              flex: 3,
              child: _clusters.isEmpty && !_loading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_off_outlined,
                              size: 36, color: AppColors.muted),
                          const SizedBox(height: 8),
                          Text(
                            'No pieces with location found',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: _clusters.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final cluster = _clusters[index];
                        return _CityRow(
                          cluster: cluster,
                          onTap: () => _onClusterTap(cluster),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Cluster pin widget ──────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _ClusterPin extends StatelessWidget {
  final int count;
  final bool selected;

  const _ClusterPin({required this.count, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.accent : AppColors.inkStrong,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count.toString(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── City row in list ────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _CityRow extends StatelessWidget {
  final _CityCluster cluster;
  final VoidCallback onTap;

  const _CityRow({required this.cluster, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.hairline, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded,
                size: 18, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                cluster.city,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkStrong,
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${cluster.pieces.length} piece${cluster.pieces.length == 1 ? '' : 's'}',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── City pieces bottom panel ────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _CityPiecesPanel extends StatelessWidget {
  final _CityCluster cluster;

  const _CityPiecesPanel({required this.cluster});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  cluster.city,
                  style: GoogleFonts.fraunces(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkStrong,
                  ),
                ),
                const Spacer(),
                Text(
                  '${cluster.pieces.length} piece${cluster.pieces.length == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.hairline, height: 1),

          // ── Pieces list ──
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              scrollDirection: Axis.horizontal,
              itemCount: cluster.pieces.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                return _PieceCard(piece: cluster.pieces[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Piece card in bottom panel ──────────────────────────────
// ═════════════════════════════════════════════════════════════

class _PieceCard extends StatelessWidget {
  final BrowsePiece piece;

  const _PieceCard({required this.piece});

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
        width: 140,
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
                        width: 140,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppColors.hairline2,
                        child: const Center(
                          child: Icon(Icons.image_outlined,
                              size: 28, color: AppColors.muted),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    piece.priceFormatted,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                  if (piece.sellerUsername != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${piece.sellerUsername}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
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
    );
  }
}
