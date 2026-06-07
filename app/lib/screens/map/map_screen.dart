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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapCtrl = MapController();
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    await BrowseService.instance.fetchUsers(
      search: _searchQuery,
      limit: 50,
    );
    if (mounted) setState(() => _loading = false);
  }

  List<BrowseUser> get _users => BrowseService.instance.users;

  List<BrowseUser> get _usersWithLocation =>
      _users.where((u) => u.city != null || u.country != null).toList();

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
    _searchQuery = value.isEmpty ? null : value;
    _loadUsers();
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final mapHeight = size.height * 0.35;

    return Scaffold(
      backgroundColor: AppColors.bone,
      drawer: const AppDrawer(currentRoute: '/map'),
      appBar: const SharedAppBar(currentRoute: '/map'),
      body: Column(
        children: [
          // ── Map area with "coming soon" overlay ──────────────────
          SizedBox(
            height: mapHeight,
            child: Stack(
              children: [
                ClipRRect(
                  child: FlutterMap(
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
                      ),
                    ],
                  ),
                ),
                // Overlay
                Positioned.fill(
                  child: Container(
                    color: AppColors.bone.withValues(alpha: 0.55),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.hairline, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 28,
                              color: AppColors.muted,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Map pins coming soon',
                              style: GoogleFonts.fraunces(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.inkStrong,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Studio locations will appear here',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Center button ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _FloatingButton(
              icon: Icons.my_location_rounded,
              label: 'Center on me',
              onTap: _centerOnMe,
            ),
          ),

          // ── Search bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  hintText: 'Search studios by name or city...',
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

          const SizedBox(height: 16),

          // ── Studios list ────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.ink,
                      strokeWidth: 2,
                    ),
                  )
                : _usersWithLocation.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _usersWithLocation.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          return _StudioCard(user: _usersWithLocation[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.storefront_outlined,
            size: 40,
            color: AppColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            'No studios found',
            style: GoogleFonts.fraunces(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.inkStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating action button ──────────────────────────────────────

class _FloatingButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FloatingButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
    );
  }
}

// ── Studio card ─────────────────────────────────────────────────

class _StudioCard extends StatelessWidget {
  final BrowseUser user;

  const _StudioCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final location = [user.city, user.country]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Row(
        children: [
          // ── Avatar ──
          _buildAvatar(),
          const SizedBox(width: 14),

          // ── Info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.studioName ?? user.username,
                  style: GoogleFonts.fraunces(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkStrong,
                  ),
                ),
                if (user.studioName != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    '@${user.username}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (location.isNotEmpty) ...[
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          location,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.inkSoft,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (user.discipline != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    user.discipline!,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Pieces count badge ──
          Column(
            children: [
              Text(
                user.piecesCount.toString(),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkStrong,
                ),
              ),
              Text(
                'pieces',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (user.avatarType == 'image' && user.avatarImageB64 != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Image.memory(
          base64Decode(user.avatarImageB64!),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      );
    }

    // Color avatar with initial
    Color avatarColor;
    try {
      avatarColor = Color(
        int.parse(user.avatarColor.replaceFirst('#', '0xFF')),
      );
    } catch (_) {
      avatarColor = AppColors.ink;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: avatarColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          (user.studioName ?? user.username).substring(0, 1).toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.bone,
          ),
        ),
      ),
    );
  }
}
