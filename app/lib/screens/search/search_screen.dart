import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../core/browse_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/shared_app_bar.dart';
import '../../core/collection_service.dart';
import '../../widgets/save_to_collection_modal.dart';
import '../product_detail/product_detail_screen.dart';
import '../profile/user_profile_screen.dart';

// ── Search Screen ──────────────────────────────────────────────

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  final _searchController = TextEditingController();
  bool _showUsers = false;
  Timer? _debounce;

  List<BrowsePiece> _pieces = [];
  List<BrowseUser> _users = [];
  bool _loadingPieces = false;
  bool _loadingUsers = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  static const _pageSize = 6;
  static const _maxPieces = 20;

  // ── Recent users ──
  List<BrowseUser> _recentUsers = [];
  static const _recentUsersKey = 'recent_searched_users';

  bool get _hasQuery => _searchController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loadRecentUsers();
    _resetAndSearch();
    BrowseService.instance.addListener(_onBrowseChanged);
  }

  @override
  void dispose() {
    BrowseService.instance.removeListener(_onBrowseChanged);
    _anim.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onBrowseChanged() {
    if (mounted && !_showUsers) {
      setState(() {
        _pieces = BrowseService.instance.pieces;
      });
    }
  }

  // ── Recent users persistence ──────────────────────────────

  Future<void> _loadRecentUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_recentUsersKey);
    if (jsonList != null && jsonList.isNotEmpty) {
      setState(() {
        _recentUsers = jsonList
            .map((s) => BrowseUser.fromJson(
                jsonDecode(s) as Map<String, dynamic>))
            .toList();
      });
    }
  }

  Future<void> _saveRecentUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _recentUsers
        .map((u) => jsonEncode(_browseUserToJson(u)))
        .toList();
    await prefs.setStringList(_recentUsersKey, jsonList);
  }

  Map<String, dynamic> _browseUserToJson(BrowseUser u) => {
        'id': u.id,
        'username': u.username,
        'studio_name': u.studioName,
        'discipline': u.discipline,
        'city': u.city,
        'country': u.country,
        'bio': u.bio,
        'avatar_type': u.avatarType,
        'avatar_color': u.avatarColor,
        'avatar_image_b64': u.avatarImageB64,
        'banner_type': u.bannerType,
        'banner_color': u.bannerColor,
        'banner_image_b64': u.bannerImageB64,
        'is_following': u.isFollowing,
        'followers_count': u.followersCount,
        'following_count': u.followingCount,
        'pieces_count': u.piecesCount,
      };

  void _addToRecent(BrowseUser user) {
    setState(() {
      _recentUsers.removeWhere((u) => u.id == user.id);
      _recentUsers.insert(0, user);
      // Keep max 20 recent users
      if (_recentUsers.length > 20) {
        _recentUsers = _recentUsers.sublist(0, 20);
      }
    });
    _saveRecentUsers();
  }

  void _removeFromRecent(int userId) {
    setState(() {
      _recentUsers.removeWhere((u) => u.id == userId);
    });
    _saveRecentUsers();
  }

  // ── Search logic ──────────────────────────────────────────

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _resetAndSearch();
      if (_hasQuery) {
        _searchUsers();
      } else {
        setState(() => _users = []);
      }
    });
  }

  void _resetAndSearch() {
    _offset = 0;
    _hasMore = true;
    _pieces = [];
    _searchPieces();
  }

  Future<void> _searchPieces() async {
    setState(() => _loadingPieces = _offset == 0);
    final query = _searchController.text.trim();
    await BrowseService.instance.fetchPieces(
      search: query.isEmpty ? null : query,
      sort: query.isEmpty ? 'random' : null,
      limit: _pageSize,
      offset: _offset,
    );
    if (!mounted) return;
    final allPieces = BrowseService.instance.pieces;
    final newCount = allPieces.length - _pieces.length;
    setState(() {
      _pieces = List.of(allPieces);
      _offset = _pieces.length;
      _hasMore = newCount >= _pageSize && _pieces.length < _maxPieces;
      _loadingPieces = false;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    await _searchPieces();
    if (mounted) setState(() => _loadingMore = false);
  }

  Future<void> _searchUsers() async {
    setState(() => _loadingUsers = true);
    final query = _searchController.text.trim();
    await BrowseService.instance.fetchUsers(
      search: query.isEmpty ? null : query,
      limit: 20,
    );
    if (!mounted) return;
    setState(() {
      _users = BrowseService.instance.users;
      _loadingUsers = false;
    });
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

  void _navigateToUser(BrowseUser user) {
    _addToRecent(user);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            UserProfileScreen(userId: user.id.toString()),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      drawer: const AppDrawer(currentRoute: '/search'),
      appBar: const SharedAppBar(
        currentRoute: '/search',
        hideSearchIcon: true,
      ),
      body: CustomScrollView(
        slivers: [
          // ── Search bar ──
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fade(0.0, 0.4),
              child: SlideTransition(
                position: _slide(0.0, 0.4),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      color: AppColors.inkStrong,
                    ),
                    decoration: InputDecoration(
                      hintText: _showUsers
                          ? 'Search users...'
                          : 'Search products...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14.5,
                        color: AppColors.muted,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 12, right: 8),
                        child: Icon(
                          Icons.search_outlined,
                          size: 20,
                          color: AppColors.muted,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(
                          color: AppColors.hairline,
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(
                          color: AppColors.ink,
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Toggle tabs + filters button ──
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fade(0.1, 0.5),
              child: SlideTransition(
                position: _slide(0.1, 0.5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _TabLabel(
                        label: 'Products',
                        active: !_showUsers,
                        onTap: () => setState(() => _showUsers = false),
                      ),
                      const SizedBox(width: 28),
                      _TabLabel(
                        label: 'Users',
                        active: _showUsers,
                        onTap: () => setState(() => _showUsers = true),
                      ),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SizeTransition(
                            sizeFactor: anim,
                            axis: Axis.horizontal,
                            axisAlignment: 1,
                            child: child,
                          ),
                        ),
                        child: !_showUsers
                            ? GestureDetector(
                                key: const ValueKey('filters-btn'),
                                onTap: () => showModalBottomSheet<void>(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (_) => const _FiltersModal(),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                        color: AppColors.hairline, width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.tune_rounded,
                                        size: 14,
                                        color: AppColors.inkSoft,
                                      ),
                                      const SizedBox(width: 5),
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
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('filters-empty')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── List content ──
          SliverToBoxAdapter(
            child: _showUsers
                ? _buildUsersContent()
                : (_loadingPieces
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 64),
                        child: Center(child: LoadingSpinner()),
                      )
                    : _ProductsGridBox(
                        pieces: _pieces,
                        hasMore: _hasMore,
                        loadingMore: _loadingMore,
                        onLoadMore: _loadMore,
                      )),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildUsersContent() {
    // If there's an active search query, show API results
    if (_hasQuery) {
      if (_loadingUsers) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: Center(child: LoadingSpinner()),
        );
      }
      return _UsersListBox(
        users: _users,
        onUserTap: _navigateToUser,
      );
    }

    // No query → show recent users
    if (_recentUsers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded,
                size: 36, color: AppColors.hairline2),
            const SizedBox(height: 12),
            Text('No recent searches',
                style:
                    GoogleFonts.inter(fontSize: 14, color: AppColors.muted)),
            const SizedBox(height: 4),
            Text('Users you visit will appear here',
                style:
                    GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted)),
          ],
        ),
      );
    }

    return _RecentUsersListBox(
      users: _recentUsers,
      onUserTap: _navigateToUser,
      onRemove: _removeFromRecent,
    );
  }
}

// ── Tab label (underlined editorial style) ─────────────────────

class _TabLabel extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabLabel({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: GoogleFonts.fraunces(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: active ? AppColors.inkStrong : AppColors.muted,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 1.5,
            width: active ? 32 : 0,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

// ── Products grid box ────────────────────────────────────────

class _ProductsGridBox extends StatefulWidget {
  final List<BrowsePiece> pieces;
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback onLoadMore;

  const _ProductsGridBox({
    required this.pieces,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
  });

  @override
  State<_ProductsGridBox> createState() => _ProductsGridBoxState();
}

class _ProductsGridBoxState extends State<_ProductsGridBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pieces = widget.pieces;
    if (pieces.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 36, color: AppColors.hairline2),
            const SizedBox(height: 12),
            Text('No products found',
                style:
                    GoogleFonts.inter(fontSize: 14, color: AppColors.muted)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pieces.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 24,
              childAspectRatio: 0.58,
            ),
            itemBuilder: (_, i) {
              final start = (i * 0.07).clamp(0.0, 0.55);
              final end = (start + 0.45).clamp(0.0, 1.0);
              final curve = CurvedAnimation(
                parent: _ctrl,
                curve: Interval(start, end, curve: Curves.easeOut),
              );
              return FadeTransition(
                opacity: curve,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(curve),
                  child: _ProductCard(piece: pieces[i]),
                ),
              );
            },
          ),
          if (widget.hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: GestureDetector(
                onTap: widget.loadingMore ? null : widget.onLoadMore,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.hairline, width: 1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: widget.loadingMore
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.inkSoft,
                          ),
                        )
                      : Text(
                          'Load more',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.inkSoft,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Recent users list (with X button) ────────────────────────

class _RecentUsersListBox extends StatelessWidget {
  final List<BrowseUser> users;
  final void Function(BrowseUser) onUserTap;
  final void Function(int userId) onRemove;

  const _RecentUsersListBox({
    required this.users,
    required this.onUserTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Recent',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...List.generate(users.length * 2 - 1, (index) {
            if (index.isOdd) {
              return const Divider(
                  color: AppColors.hairline, height: 1, thickness: 1);
            }
            final i = index ~/ 2;
            return _RecentUserRow(
              user: users[i],
              onTap: () => onUserTap(users[i]),
              onRemove: () => onRemove(users[i].id),
            );
          }),
        ],
      ),
    );
  }
}

// ── Recent user row (with X) ─────────────────────────────────

class _RecentUserRow extends StatelessWidget {
  final BrowseUser user;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentUserRow({
    required this.user,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final initials = user.studioName != null
        ? user.studioName!.split(' ').map((w) => w[0]).take(2).join()
        : user.username
            .split(' ')
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // ── Avatar ──
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _parseColor(user.avatarColor),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: user.avatarType == 'image' && user.avatarImageB64 != null
                  ? ClipOval(
                      child: Image.memory(
                        base64Decode(user.avatarImageB64!),
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      initials,
                      style: GoogleFonts.fraunces(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.studioName ?? user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fraunces(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),

            // ── Remove button ──
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}

// ── Users list box (search results) ──────────────────────────

class _UsersListBox extends StatefulWidget {
  final List<BrowseUser> users;
  final void Function(BrowseUser) onUserTap;

  const _UsersListBox({
    required this.users,
    required this.onUserTap,
  });

  @override
  State<_UsersListBox> createState() => _UsersListBoxState();
}

class _UsersListBoxState extends State<_UsersListBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = widget.users;
    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search_rounded,
                size: 36, color: AppColors.hairline2),
            const SizedBox(height: 12),
            Text('No users found',
                style:
                    GoogleFonts.inter(fontSize: 14, color: AppColors.muted)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(users.length * 2 - 1, (index) {
          if (index.isOdd) {
            return const Divider(
                color: AppColors.hairline, height: 1, thickness: 1);
          }
          final i = index ~/ 2;
          final start = (i * 0.07).clamp(0.0, 0.55);
          final end = (start + 0.45).clamp(0.0, 1.0);
          final curve = CurvedAnimation(
            parent: _ctrl,
            curve: Interval(start, end, curve: Curves.easeOut),
          );
          return FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(curve),
              child: _UserRow(
                user: users[i],
                onTap: () => widget.onUserTap(users[i]),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Product card ─────────────────────────────────────────────

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
        pageBuilder: (_, __, ___) =>
            ProductDetailScreen(pieceId: widget.piece.id),
        transitionsBuilder: (_, animation, __, child) =>
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
                      child: const Icon(Icons.image_outlined,
                          size: 32, color: AppColors.muted),
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                          color: saved ? AppColors.accent : AppColors.muted,
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

// ── User row (search results) ────────────────────────────────

class _UserRow extends StatelessWidget {
  final BrowseUser user;
  final VoidCallback onTap;

  const _UserRow({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = user.studioName != null
        ? user.studioName!.split(' ').map((w) => w[0]).take(2).join()
        : user.username
            .split(' ')
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _parseColor(user.avatarColor),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: GoogleFonts.fraunces(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.studioName ?? user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fraunces(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkStrong,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (user.discipline != null)
                  Text(
                    user.discipline!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkSoft,
                      letterSpacing: 0.1,
                    ),
                  ),
                if (user.city != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        user.city!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
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
      discipline = cats.first;
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

    // Type filter: 0=All, 1=Buy, 2=Rent, 3=Buy or Rent (both)
    String? pieceType;
    switch (_selectedType) {
      case 1:
        pieceType = 'buy';
        break;
      case 2:
        pieceType = 'rent';
        break;
      // 0 (All) and 3 (Buy or Rent) don't filter
    }

    BrowseService.instance.fetchPieces(
      discipline: discipline,
      sort: sort,
      pieceType: pieceType,
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
                child: const Icon(Icons.close_rounded,
                    size: 20, color: AppColors.muted),
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
                  const SizedBox(height: 20),
                  _sectionLabel('TYPE'),
                  const SizedBox(height: 12),
                  _chipRow(
                      _types,
                      (i) => _selectedType == i,
                      (i) => setState(() => _selectedType = i)),

                  const SizedBox(height: 24),
                  Row(children: [
                    _sectionLabel('PRICE RANGE'),
                    const Spacer(),
                    Text(
                      '€${_priceRange.start.round()} – €${_priceRange.end.round()}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.inkSoft),
                    ),
                  ]),
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

                  const SizedBox(height: 20),
                  _sectionLabel('SORT BY'),
                  const SizedBox(height: 12),
                  _chipRow(
                      _sortOptions,
                      (i) => _selectedSort == i,
                      (i) => setState(() => _selectedSort = i)),

                  const SizedBox(height: 24),
                  _sectionLabel('CATEGORY'),
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
                        child: _chip(_categories[i], active),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
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

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
          letterSpacing: 1.4,
        ),
      );

  Widget _chipRow(List<String> items, bool Function(int) isActive,
      void Function(int) onTap) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: List.generate(
          items.length,
          (i) => GestureDetector(
                onTap: () => onTap(i),
                child: _chip(items[i], isActive(i)),
              )),
    );
  }

  Widget _chip(String label, bool active) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: active ? AppColors.ink : AppColors.hairline, width: 1),
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
      );
}
