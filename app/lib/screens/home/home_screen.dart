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
      body: Center(
        child: Text(
          'Home',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: AppColors.inkStrong,
          ),
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
