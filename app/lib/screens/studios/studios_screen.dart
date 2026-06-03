import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../models/user_profile.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/shared_app_bar.dart';
import '../profile/user_profile_screen.dart';

// ── Mock studio data ──────────────────────────────────────────

class _MockStudio {
  final String name;
  final String location;
  final List<String> specialties;
  final int pieceCount;
  final int followerCount;
  final bool verified;
  final Color avatarColor;

  const _MockStudio({
    required this.name,
    required this.location,
    required this.specialties,
    required this.pieceCount,
    required this.followerCount,
    required this.verified,
    required this.avatarColor,
  });
}

const _mockStudios = <_MockStudio>[
  _MockStudio(
    name: 'Marta Sala',
    location: 'Barcelona',
    specialties: ['Ceramic', 'Sculpture'],
    pieceCount: 19,
    followerCount: 1640,
    verified: true,
    avatarColor: Color(0xFFBEB0A0),
  ),
  _MockStudio(
    name: 'Atelier NM',
    location: 'Madrid',
    specialties: ['Furniture', 'Textiles'],
    pieceCount: 12,
    followerCount: 980,
    verified: true,
    avatarColor: Color(0xFFCBC2B4),
  ),
  _MockStudio(
    name: 'Studio Vèra',
    location: 'Valencia',
    specialties: ['Lighting', 'Decor'],
    pieceCount: 8,
    followerCount: 2310,
    verified: true,
    avatarColor: Color(0xFFA8997E),
  ),
  _MockStudio(
    name: 'Jordi Canudas',
    location: 'Girona',
    specialties: ['Furniture', 'Sculpture'],
    pieceCount: 6,
    followerCount: 540,
    verified: false,
    avatarColor: Color(0xFF9A8C7B),
  ),
  _MockStudio(
    name: 'Clara Boj',
    location: 'Barcelona',
    specialties: ['Ceramic', 'Painting'],
    pieceCount: 14,
    followerCount: 1120,
    verified: true,
    avatarColor: Color(0xFFD0C5B5),
  ),
  _MockStudio(
    name: 'Teixidors',
    location: 'Terrassa',
    specialties: ['Textiles', 'Decor', 'Furniture'],
    pieceCount: 22,
    followerCount: 3480,
    verified: true,
    avatarColor: Color(0xFFC5B9A5),
  ),
  _MockStudio(
    name: 'Viabizzuno',
    location: 'Milan',
    specialties: ['Lighting', 'Sculpture'],
    pieceCount: 31,
    followerCount: 5720,
    verified: true,
    avatarColor: Color(0xFFB3A594),
  ),
  _MockStudio(
    name: 'Apparatu',
    location: 'Seville',
    specialties: ['Ceramic', 'Decor'],
    pieceCount: 9,
    followerCount: 870,
    verified: false,
    avatarColor: Color(0xFFCABEAE),
  ),
  _MockStudio(
    name: 'Laia Font',
    location: 'Madrid',
    specialties: ['Furniture', 'Lighting', 'Decor'],
    pieceCount: 15,
    followerCount: 2050,
    verified: true,
    avatarColor: Color(0xFF8A7D6A),
  ),
  _MockStudio(
    name: 'Pau Vives',
    location: 'Valencia',
    specialties: ['Textiles', 'Painting'],
    pieceCount: 7,
    followerCount: 430,
    verified: false,
    avatarColor: Color(0xFFB5A898),
  ),
];

String _formatNumber(int n) {
  if (n < 1000) return '$n';
  final s = n.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

// ── Studios Screen ────────────────────────────────────────────

class StudiosScreen extends StatefulWidget {
  const StudiosScreen({super.key});

  @override
  State<StudiosScreen> createState() => _StudiosScreenState();
}

class _StudiosScreenState extends State<StudiosScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  static const _pageSize = 4;
  int _displayedCount = _pageSize;
  bool _loading = false;

  bool get _hasMore => _displayedCount < _mockStudios.length;

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _displayedCount =
          (_displayedCount + _pageSize).clamp(0, _mockStudios.length);
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
      drawer: const AppDrawer(currentRoute: '/studios'),
      appBar: const SharedAppBar(currentRoute: '/studios'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _fade(0.0, 0.5),
              child: SlideTransition(
                position: _slide(0.0, 0.5),
                child: const _StudiosHeader(),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _fade(0.2, 0.7),
              child: SlideTransition(
                position: _slide(0.2, 0.7),
                child: _StudioGrid(
                  studios: _mockStudios.take(_displayedCount).toList(),
                ),
              ),
            ),
            const SizedBox(height: 28),
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

// ── Studios header ────────────────────────────────────────────

class _StudiosHeader extends StatelessWidget {
  const _StudiosHeader();

  @override
  Widget build(BuildContext context) {
    final verifiedCount = _mockStudios.where((s) => s.verified).length;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Center(
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left: Nº number ──
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Nº',
                    style: GoogleFonts.fraunces(
                      fontSize: 42,
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                      color: AppColors.gold,
                      height: 1.0,
                    ),
                  ),
                ],
              ),

              // ── Vertical divider ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Container(width: 1, color: AppColors.hairline),
              ),

              // ── Right: info lines ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$verifiedCount verified studios',
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
                          text: 'The studios behind\nevery ',
                          style: GoogleFonts.fraunces(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w400,
                            color: AppColors.inkSoft,
                            height: 1.4,
                          ),
                        ),
                        TextSpan(
                          text: 'piece.',
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

// ── Studio grid ───────────────────────────────────────────────

class _StudioGrid extends StatelessWidget {
  final List<_MockStudio> studios;
  const _StudioGrid({required this.studios});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: studios.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 24,
          childAspectRatio: 0.58,
        ),
        itemBuilder: (_, i) => _StudioCard(studio: studios[i]),
      ),
    );
  }
}

// ── Studio card ───────────────────────────────────────────────

class _StudioCard extends StatefulWidget {
  final _MockStudio studio;
  const _StudioCard({required this.studio});

  @override
  State<_StudioCard> createState() => _StudioCardState();
}

class _StudioCardState extends State<_StudioCard> {
  bool _saved = false;

  void _openProfile() {
    final profile = findProfileByName(widget.studio.name);
    if (profile != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, _, _) =>
              UserProfileScreen(userId: profile.id),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.studio;
    final description = [s.location, ...s.specialties].join(' · ');
    final stats =
        '${s.pieceCount} pieces · ${_formatNumber(s.followerCount)} followers';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Image placeholder ──
        Expanded(
          child: GestureDetector(
            onTap: _openProfile,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                color: s.avatarColor,
                width: double.infinity,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Info + save icon ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _openProfile,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + verified badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkStrong,
                            ),
                          ),
                        ),
                        if (s.verified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: AppColors.sage,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Location · Specialties
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Stats
                    Text(
                      stats,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
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
      ],
    );
  }
}
