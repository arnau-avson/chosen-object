import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../auth/login_screen.dart';
import '../auth/role_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _slides = [
    (
      title: 'Verified studios,\nevery piece.',
      body:
          'Only authenticated designers, ateliers and galleries. Every listing curated and signed off by a real person.',
    ),
    (
      title: 'Buy it.\nOr rent it.',
      body:
          'Own what you love, or borrow for a shoot. Flexible access to the most distinctive objects in Europe.',
    ),
    (
      title: 'Discover\nnear you.',
      body:
          'Find studios and collectors in your city. The best design lives closer than you think.',
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _skip() => _replace(const LoginScreen());

  void _continue() => _replace(const RoleSelectionScreen());

  void _replace(Widget screen) {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, _, _) => screen,
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 360),
    ));
  }

  void _prev() => _ctrl.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );

  void _next() => _ctrl.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );

  @override
  Widget build(BuildContext context) {
    final isFirst = _page == 0;
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.bone,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.07),
                  blurRadius: 32,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: PageView.builder(
                      controller: _ctrl,
                      itemCount: _slides.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
                    ),
                  ),
                ),
                _BottomBar(
                  page: _page,
                  total: _slides.length,
                  isFirst: isFirst,
                  isLast: isLast,
                  onPrev: _prev,
                  onNext: _next,
                  onSkip: _skip,
                  onContinue: _continue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Slide content ────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final ({String title, String body}) slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 44, 32, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slide.title,
            style: GoogleFonts.fraunces(
              fontSize: 30,
              fontWeight: FontWeight.w400,
              height: 1.22,
              color: AppColors.inkStrong,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            slide.body,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.muted,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom bar ───────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int page;
  final int total;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onContinue;

  const _BottomBar({
    required this.page,
    required this.total,
    required this.isFirst,
    required this.isLast,
    required this.onPrev,
    required this.onNext,
    required this.onSkip,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 20, 28),
      child: Row(
        children: [
          // ── Pill indicators ──────────────────────────────
          Row(
            children: List.generate(total, (i) {
              final active = i == page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                margin: const EdgeInsets.only(right: 6),
                width: active ? 26.0 : 7.0,
                height: 7,
                decoration: BoxDecoration(
                  color: active ? AppColors.ink : AppColors.hairline2,
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),

          const SizedBox(width: 14),

          // ── Prev / Next arrows ───────────────────────────
          _NavArrow(
            icon: Icons.chevron_left_rounded,
            visible: !isFirst,
            onTap: onPrev,
          ),
          const SizedBox(width: 6),
          _NavArrow(
            icon: Icons.chevron_right_rounded,
            visible: !isLast,
            onTap: onNext,
          ),

          const Spacer(),

          // ── Skip / Continue ──────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLast
                ? GestureDetector(
                    key: const ValueKey('continue'),
                    onTap: onContinue,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 11),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Continue →',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.bone,
                        ),
                      ),
                    ),
                  )
                : TextButton(
                    key: const ValueKey('skip'),
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.muted,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                    ),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(fontSize: 13.5),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Small inline arrow button ────────────────────────────────

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool visible;
  final VoidCallback onTap;

  const _NavArrow({
    required this.icon,
    required this.visible,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !visible,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.hairline, width: 1),
            ),
            child: Icon(icon, size: 17, color: AppColors.inkSoft),
          ),
        ),
      ),
    );
  }
}
