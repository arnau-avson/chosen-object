import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/profile_service.dart';
import '../../widgets/shared_app_bar.dart';

// ── Palette for avatar / banner colour picker ────────────────

const _palette = <Color>[
  Color(0xFF2E2520),
  Color(0xFF4A3F35),
  Color(0xFF6B5B4E),
  Color(0xFF8A7D6A),
  Color(0xFF9A8C7B),
  Color(0xFFBEB0A0),
  Color(0xFFCBC2B4),
  Color(0xFFD4C8B8),
  Color(0xFFB8543C),
  Color(0xFFA04530),
  Color(0xFFA8893E),
  Color(0xFF6B7A5A),
  Color(0xFF4A7A4D),
  Color(0xFF3A6A7A),
  Color(0xFF5A5A8A),
  Color(0xFF7A5A6A),
];

// ═════════════════════════════════════════════════════════════
// ── Edit Profile Screen ─────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _handleCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _bioCtrl;

  late Color _avatarColor;
  late Color _bannerColor;

  // ── Animation helpers ──────────────────────────────────────

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
  void initState() {
    super.initState();
    final p = ProfileService.instance;
    _nameCtrl = TextEditingController(text: p.name);
    _handleCtrl = TextEditingController(text: p.handle);
    _locationCtrl = TextEditingController(text: p.location);
    _bioCtrl = TextEditingController(text: p.bio);
    _avatarColor = p.avatarColor;
    _bannerColor = p.bannerColor;

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _handleCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  // ── Save ───────────────────────────────────────────────────

  void _save() {
    final p = ProfileService.instance;
    p.updateProfile(
      name: _nameCtrl.text.trim(),
      handle: _handleCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
    );
    p.updateAvatarColor(_avatarColor);
    p.updateBannerColor(_bannerColor);
    Navigator.of(context).pop();
  }

  // ── Colour picker bottom sheet ─────────────────────────────

  void _pickColor({
    required String title,
    required Color current,
    required ValueChanged<Color> onPick,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: AppColors.inkStrong,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _palette.map((color) {
                final selected = color == current;
                return GestureDetector(
                  onTap: () {
                    onPick(color);
                    Navigator.of(context).pop();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: AppColors.accent, width: 3)
                          : Border.all(
                              color: AppColors.hairline, width: 1),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            size: 18, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final initials = _nameCtrl.text
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join();

    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: SharedAppBar(
        currentRoute: '/edit-profile',
        showBack: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            FadeTransition(
              opacity: _fade(0.0, 0.45),
              child: SlideTransition(
                position: _slide(0.0, 0.45),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Text(
                    'Edit profile',
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkStrong,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Banner + Avatar ──
            FadeTransition(
              opacity: _fade(0.06, 0.50),
              child: SlideTransition(
                position: _slide(0.06, 0.50),
                child: SizedBox(
                  height: 140 + 44,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Banner
                      Positioned(
                        top: 0,
                        left: 16,
                        right: 16,
                        height: 140,
                        child: GestureDetector(
                          onTap: () => _pickColor(
                            title: 'Banner colour',
                            current: _bannerColor,
                            onPick: (c) =>
                                setState(() => _bannerColor = c),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              color: _bannerColor,
                              alignment: Alignment.center,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.surface
                                      .withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 20,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Avatar
                      Positioned(
                        bottom: 0,
                        left: 36,
                        child: GestureDetector(
                          onTap: () => _pickColor(
                            title: 'Avatar colour',
                            current: _avatarColor,
                            onPick: (c) =>
                                setState(() => _avatarColor = c),
                          ),
                          child: Stack(
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _avatarColor,
                                  border: Border.all(
                                      color: AppColors.surface, width: 4),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  initials,
                                  style: GoogleFonts.fraunces(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white
                                        .withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.ink,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.surface,
                                        width: 2),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 13,
                                    color: AppColors.bone,
                                  ),
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
            ),

            const SizedBox(height: 28),

            // ── Form fields ──
            FadeTransition(
              opacity: _fade(0.12, 0.55),
              child: SlideTransition(
                position: _slide(0.12, 0.55),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _Field(label: 'Name', controller: _nameCtrl),
                      const SizedBox(height: 16),
                      _Field(label: 'Handle', controller: _handleCtrl),
                      const SizedBox(height: 16),
                      _Field(label: 'Location', controller: _locationCtrl),
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Bio',
                        controller: _bioCtrl,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Save button ──
            FadeTransition(
              opacity: _fade(0.18, 0.60),
              child: SlideTransition(
                position: _slide(0.18, 0.60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Save changes',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.bone,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Text field ──────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.muted2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.hairline, width: 1),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.inkStrong,
            ),
            cursorColor: AppColors.ink,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              border: InputBorder.none,
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
