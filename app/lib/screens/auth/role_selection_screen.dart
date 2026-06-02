import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import 'register_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _cardsFade;
  late final Animation<Offset> _cardsSlide;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _titleFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    _cardsFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );
    _cardsSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    ));
    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  void _select(String role) {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, _, _) => RegisterScreen(role: role),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              // ── Header ──────────────────────────────────────
              FadeTransition(
                opacity: _titleFade,
                child: SlideTransition(
                  position: _titleSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How will you use\nChosen Object?',
                        style: GoogleFonts.fraunces(
                          fontSize: 30,
                          fontWeight: FontWeight.w400,
                          color: AppColors.inkStrong,
                          height: 1.22,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You can always switch later from Settings.',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Role cards ───────────────────────────────────
              FadeTransition(
                opacity: _cardsFade,
                child: SlideTransition(
                  position: _cardsSlide,
                  child: Column(
                    children: [
                      _RoleCard(
                        icon: Icons.bookmark_border_rounded,
                        title: 'I collect',
                        description:
                            'Discover, save, buy and rent authenticated pieces.',
                        onTap: () => _select('collector'),
                      ),
                      const SizedBox(height: 14),
                      _RoleCard(
                        icon: Icons.grid_view_rounded,
                        title: 'I sell',
                        description:
                            "List your studio's work and reach collectors across Europe.",
                        onTap: () => _select('seller'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Role card ────────────────────────────────────────────────

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _pressed ? AppColors.inkSoft : AppColors.hairline,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: _pressed ? 0.04 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + Title
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.bone,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.hairline, width: 1),
                    ),
                    child:
                        Icon(widget.icon, size: 19, color: AppColors.inkSoft),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    widget.title,
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkStrong,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                widget.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
