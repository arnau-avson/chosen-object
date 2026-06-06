import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../core/profile_service.dart';
import '../../widgets/shared_app_bar.dart';

// ── Palette for colour picker ──────────────────────────────────

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

const _disciplines = [
  'Painting',
  'Ceramic',
  'Furniture',
  'Sculpture',
  'Lighting',
  'Textiles',
  'Photography',
  'Mixed Media',
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
  final _picker = ImagePicker();

  // Personal
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _handleCtrl;
  late final TextEditingController _locationCtrl;

  // Username validation
  Timer? _usernameDebounce;
  String? _usernameError;   // null = valid or not checked yet
  bool _usernameChecking = false;

  // Avatar state
  late String _avatarType;
  late Color _avatarColor;
  Uint8List? _avatarImageBytes;

  // Banner state
  late String _bannerType;
  late Color _bannerColor;
  Uint8List? _bannerImageBytes;

  // Studio
  late final TextEditingController _studioNameCtrl;
  late String _discipline;
  late final TextEditingController _studioBioCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _countryCtrl;

  // Online
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _instagramCtrl;
  late final TextEditingController _portfolioCtrl;

  // Invoicing
  late final TextEditingController _legalCtrl;
  late final TextEditingController _vatCtrl;
  late final TextEditingController _ibanCtrl;

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
    _usernameCtrl = TextEditingController(text: p.username);
    _nameCtrl = TextEditingController(text: p.name);
    _handleCtrl = TextEditingController(text: p.handle);
    _locationCtrl = TextEditingController(text: p.location);

    _avatarType = p.avatarType;
    _avatarColor = p.avatarColor;
    _avatarImageBytes = p.avatarImageBytes;

    _bannerType = p.bannerType;
    _bannerColor = p.bannerColor;
    _bannerImageBytes = p.bannerImageBytes;

    _studioNameCtrl = TextEditingController(text: p.studioName);
    _discipline = p.discipline;
    _studioBioCtrl = TextEditingController(text: p.bio);
    _cityCtrl = TextEditingController(text: p.city);
    _countryCtrl = TextEditingController(text: p.country);

    _websiteCtrl = TextEditingController(text: p.website);
    _instagramCtrl = TextEditingController(text: p.instagram);
    _portfolioCtrl = TextEditingController(text: p.portfolio);

    _legalCtrl = TextEditingController(text: p.legalEntity);
    _vatCtrl = TextEditingController(text: p.vatId);
    _ibanCtrl = TextEditingController(text: p.iban);

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _handleCtrl.dispose();
    _locationCtrl.dispose();
    _studioNameCtrl.dispose();
    _studioBioCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _websiteCtrl.dispose();
    _instagramCtrl.dispose();
    _portfolioCtrl.dispose();
    _legalCtrl.dispose();
    _vatCtrl.dispose();
    _ibanCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  // ── Username validation ──────────────────────────────────────

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    final trimmed = value.trim().toLowerCase();

    if (trimmed.length < 6) {
      setState(() {
        _usernameError = 'Must be at least 6 characters';
        _usernameChecking = false;
      });
      return;
    }

    // Same as current → no need to check
    if (trimmed == ProfileService.instance.username) {
      setState(() {
        _usernameError = null;
        _usernameChecking = false;
      });
      return;
    }

    setState(() => _usernameChecking = true);

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final error = await ProfileService.instance.checkUsername(trimmed);
      if (!mounted) return;
      setState(() {
        _usernameError = error;
        _usernameChecking = false;
      });
    });
  }

  // ── Save ───────────────────────────────────────────────────

  void _save() {
    // Block save if username is invalid
    final uname = _usernameCtrl.text.trim().toLowerCase();
    if (uname.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Username must be at least 6 characters.',
            style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.bone),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
      return;
    }
    if (_usernameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _usernameError!,
            style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.bone),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
      return;
    }

    final p = ProfileService.instance;
    p.updateProfile(
      username: uname,
      name: _nameCtrl.text.trim(),
      handle: _handleCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      bio: _studioBioCtrl.text.trim(),
      studioName: _studioNameCtrl.text.trim(),
      discipline: _discipline,
      city: _cityCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      website: _websiteCtrl.text.trim(),
      instagram: _instagramCtrl.text.trim(),
      portfolio: _portfolioCtrl.text.trim(),
      legalEntity: _legalCtrl.text.trim(),
      vatId: _vatCtrl.text.trim(),
      iban: _ibanCtrl.text.trim(),
    );

    // Avatar
    if (_avatarType == 'image' && _avatarImageBytes != null) {
      p.updateAvatarImage(_avatarImageBytes!);
    } else {
      p.updateAvatarColor(_avatarColor);
    }

    // Banner
    if (_bannerType == 'image' && _bannerImageBytes != null) {
      p.updateBannerImage(_bannerImageBytes!);
    } else {
      p.updateBannerColor(_bannerColor);
    }

    // Push to backend (fire-and-forget)
    p.saveToBackend();
    p.uploadAvatarToBackend();
    p.uploadBannerToBackend();

    Navigator.of(context).pop();
  }

  // ── Image picker + cropper ─────────────────────────────────

  Future<Uint8List?> _pickAndCrop({
    required double ratioX,
    required double ratioY,
  }) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: CropAspectRatio(ratioX: ratioX, ratioY: ratioY),
      compressQuality: 80,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: ratioX == ratioY ? 'Crop avatar' : 'Crop banner',
          toolbarColor: const Color(0xFF2E2520),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.accent,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: ratioX == ratioY ? 'Crop avatar' : 'Crop banner',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    if (cropped == null) return null;
    return File(cropped.path).readAsBytes();
  }

  // ── Colour-or-image chooser bottom sheet ───────────────────

  void _showAvatarOptions() {
    _showImageOrColorSheet(
      title: 'Avatar',
      currentColor: _avatarColor,
      ratioX: 1,
      ratioY: 1,
      onColor: (c) => setState(() {
        _avatarType = 'color';
        _avatarColor = c;
        _avatarImageBytes = null;
      }),
      onImage: (bytes) => setState(() {
        _avatarType = 'image';
        _avatarImageBytes = bytes;
      }),
    );
  }

  void _showBannerOptions() {
    _showImageOrColorSheet(
      title: 'Banner',
      currentColor: _bannerColor,
      ratioX: 3,
      ratioY: 1,
      onColor: (c) => setState(() {
        _bannerType = 'color';
        _bannerColor = c;
        _bannerImageBytes = null;
      }),
      onImage: (bytes) => setState(() {
        _bannerType = 'image';
        _bannerImageBytes = bytes;
      }),
    );
  }

  void _showImageOrColorSheet({
    required String title,
    required Color currentColor,
    required double ratioX,
    required double ratioY,
    required ValueChanged<Color> onColor,
    required ValueChanged<Uint8List> onImage,
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

            // Option 1: Choose from gallery
            Material(
              color: Colors.transparent,
              child: InkWell(
                splashColor: AppColors.ink.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndCrop(ratioX: ratioX, ratioY: ratioY).then((bytes) {
                    if (bytes != null) onImage(bytes);
                  });
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_library_outlined,
                          size: 20, color: AppColors.inkSoft),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Choose from gallery',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(
                color: AppColors.hairline, height: 1, thickness: 1),

            // Option 2: Choose colour
            Material(
              color: Colors.transparent,
              child: InkWell(
                splashColor: AppColors.ink.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickColor(
                    title: '$title colour',
                    current: currentColor,
                    onPick: onColor,
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.palette_outlined,
                          size: 20, color: AppColors.inkSoft),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Choose colour',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                          : Border.all(color: AppColors.hairline, width: 1),
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

  // ── Discipline picker ──────────────────────────────────────

  void _pickDiscipline() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  children: [
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
                      'Discipline',
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: AppColors.inkStrong,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  children: _disciplines.map((d) {
                    final selected = d == _discipline;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        splashColor: AppColors.ink.withValues(alpha: 0.05),
                        onTap: () {
                          setState(() => _discipline = d);
                          Navigator.of(context).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 13, horizontal: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  d,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: selected
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                    color: selected
                                        ? AppColors.inkStrong
                                        : AppColors.inkSoft,
                                  ),
                                ),
                              ),
                              if (selected)
                                const Icon(Icons.check_rounded,
                                    size: 16, color: AppColors.accent),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 14),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppColors.muted2,
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
      appBar: const SharedAppBar(
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
              opacity: _fade(0.04, 0.48),
              child: SlideTransition(
                position: _slide(0.04, 0.48),
                child: _buildCoverSection(initials),
              ),
            ),

            // ── ACCOUNT ──
            FadeTransition(
              opacity: _fade(0.06, 0.50),
              child: SlideTransition(
                position: _slide(0.06, 0.50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Account'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _UsernameField(
                        controller: _usernameCtrl,
                        error: _usernameError,
                        checking: _usernameChecking,
                        onChanged: _onUsernameChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── STUDIO INFO ──
            FadeTransition(
              opacity: _fade(0.10, 0.54),
              child: SlideTransition(
                position: _slide(0.10, 0.54),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Studio Info'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _Field(
                              label: 'Studio name',
                              controller: _studioNameCtrl),
                          const SizedBox(height: 16),
                          _TapField(
                            label: 'Discipline',
                            value: _discipline,
                            onTap: _pickDiscipline,
                          ),
                          const SizedBox(height: 16),
                          _Field(
                            label: 'Bio',
                            controller: _studioBioCtrl,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 16),
                          _Field(label: 'City', controller: _cityCtrl),
                          const SizedBox(height: 16),
                          _Field(label: 'Country', controller: _countryCtrl),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── ONLINE PRESENCE ──
            FadeTransition(
              opacity: _fade(0.14, 0.58),
              child: SlideTransition(
                position: _slide(0.14, 0.58),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Online Presence'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _Field(
                              label: 'Website', controller: _websiteCtrl),
                          const SizedBox(height: 16),
                          _Field(
                              label: 'Instagram',
                              controller: _instagramCtrl),
                          const SizedBox(height: 16),
                          _Field(
                              label: 'Portfolio link',
                              controller: _portfolioCtrl),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── INVOICING ──
            FadeTransition(
              opacity: _fade(0.18, 0.62),
              child: SlideTransition(
                position: _slide(0.18, 0.62),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Invoicing'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _Field(
                              label: 'Legal entity name',
                              controller: _legalCtrl,
                              optional: true),
                          const SizedBox(height: 16),
                          _Field(
                              label: 'VAT / Tax ID',
                              controller: _vatCtrl,
                              optional: true),
                          const SizedBox(height: 16),
                          _Field(
                              label: 'IBAN',
                              controller: _ibanCtrl,
                              optional: true),
                          const SizedBox(height: 16),
                          _ReadOnlyField(
                            label: 'Invoice prefix',
                            value: ProfileService.instance.invoicePrefix,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── COMMISSION INFO ──
            FadeTransition(
              opacity: _fade(0.22, 0.66),
              child: SlideTransition(
                position: _slide(0.22, 0.66),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Commission Info'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.hairline, width: 1),
                        ),
                        child: Text(
                          'Chosen Object fee: 18% of sale price + Stripe '
                          'processing (~2.9% + €0.30). Payouts processed '
                          'within 2 business days of buyer confirmation.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.muted,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Save button ──
            FadeTransition(
              opacity: _fade(0.26, 0.70),
              child: SlideTransition(
                position: _slide(0.26, 0.70),
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

  // ── Cover section (banner + avatar) ────────────────────────

  Widget _buildCoverSection(String initials) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
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
                  onTap: _showBannerOptions,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _bannerType == 'image' && _bannerImageBytes != null
                        ? Image.memory(
                            _bannerImageBytes!,
                            width: double.infinity,
                            height: 140,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: _bannerColor,
                            alignment: Alignment.center,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.surface.withValues(alpha: 0.55),
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
                  onTap: _showAvatarOptions,
                  child: Stack(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _avatarType == 'image'
                              ? Colors.transparent
                              : _avatarColor,
                          border:
                              Border.all(color: AppColors.surface, width: 4),
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: _avatarType == 'image' &&
                                _avatarImageBytes != null
                            ? Image.memory(
                                _avatarImageBytes!,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                              )
                            : Text(
                                initials,
                                style: GoogleFonts.fraunces(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w400,
                                  color:
                                      Colors.white.withValues(alpha: 0.85),
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
                                color: AppColors.surface, width: 2),
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

        // "Change cover" label
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _showBannerOptions,
              child: Text(
                'Change cover',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        ),
      ],
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
  final bool optional;

  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              Text(
                'Optional',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: AppColors.muted2,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
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
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Tappable field (opens picker) ───────────────────────────
// ═════════════════════════════════════════════════════════════

class _TapField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TapField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.hairline, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkStrong,
                    ),
                  ),
                ),
                const Icon(Icons.expand_more_rounded,
                    size: 18, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Read-only field ─────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(read-only)',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: AppColors.muted2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.hairline2.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.hairline, width: 1),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Username field with live validation ──────────────────────
// ═════════════════════════════════════════════════════════════

class _UsernameField extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final bool checking;
  final ValueChanged<String> onChanged;

  const _UsernameField({
    required this.controller,
    required this.error,
    required this.checking,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    final isValid = hasText && error == null && !checking;
    final isError = hasText && error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isError
                  ? AppColors.danger.withValues(alpha: 0.5)
                  : isValid
                      ? AppColors.success.withValues(alpha: 0.5)
                      : AppColors.hairline,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.inkStrong,
            ),
            cursorColor: AppColors.ink,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: InputBorder.none,
              suffixIcon: !hasText
                  ? null
                  : checking
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.muted,
                            ),
                          ),
                        )
                      : Icon(
                          isValid
                              ? Icons.check_circle_outline_rounded
                              : Icons.cancel_outlined,
                          size: 18,
                          color: isValid ? AppColors.success : AppColors.danger,
                        ),
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 42, minHeight: 0),
            ),
          ),
        ),
        if (isError) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.danger,
            ),
          ),
        ],
      ],
    );
  }
}
