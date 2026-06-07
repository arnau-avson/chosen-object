import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../core/piece_service.dart';
import '../../core/profile_service.dart';
import '../../widgets/shared_app_bar.dart';
import '../home/home_screen.dart';

// ═════════════════════════════════════════════════════════════
// ── List a Piece Screen (5-step carousel) ───────────────────
// ═════════════════════════════════════════════════════════════

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

class ListPieceScreen extends StatefulWidget {
  final int? editPieceId;
  const ListPieceScreen({super.key, this.editPieceId});

  @override
  State<ListPieceScreen> createState() => _ListPieceScreenState();
}

class _ListPieceScreenState extends State<ListPieceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  final _pageCtrl = PageController();
  int _step = 0;
  bool _published = false;
  String _publishedTitle = '';

  // Edit mode
  bool get _isEditing => widget.editPieceId != null;
  bool _loadingPiece = false;
  final List<int?> _imageIds = []; // null = new image, int = existing server id
  final List<int> _removedImageIds = [];

  // Step 1 — Photos
  final _picker = ImagePicker();
  final List<Uint8List> _images = [];
  bool _isPublishing = false;

  // Step 2 — Details
  final _titleCtrl = TextEditingController();
  String? _discipline;
  final _yearCtrl = TextEditingController(text: '2025');
  final _editionCtrl = TextEditingController();

  // Step 3 — Pricing
  final _priceCtrl = TextEditingController();
  final _oldPriceCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();
  bool _rental = false;
  final _stockCtrl = TextEditingController(text: '1');

  // Step 4 — Shipping
  final Set<String> _shipsTo = {};
  String _packaging = 'Standard';


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
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    if (_isEditing) _loadExistingPiece();
  }

  Future<void> _loadExistingPiece() async {
    setState(() => _loadingPiece = true);
    try {
      final piece = await PieceService.instance.fetchPiece(widget.editPieceId!);

      _titleCtrl.text = piece.title;
      _discipline = piece.discipline;
      _yearCtrl.text = piece.year ?? '';
      _editionCtrl.text = piece.edition ?? '';
      _priceCtrl.text = (piece.priceCents ~/ 100).toString();
      if (piece.oldPriceCents != null) {
        _oldPriceCtrl.text = (piece.oldPriceCents! ~/ 100).toString();
      }
      if (piece.costPriceCents != null) {
        _costPriceCtrl.text = (piece.costPriceCents! ~/ 100).toString();
      }
      _rental = piece.rental;
      _stockCtrl.text = piece.stock.toString();
      if (piece.shipsTo != null) _shipsTo.addAll(piece.shipsTo!);
      _packaging = piece.packaging ?? 'Standard';

      for (final img in piece.images) {
        _images.add(img.bytes);
        _imageIds.add(img.id);
      }
    } catch (_) {
      // Failed to load — stay on empty form
    }
    if (!mounted) return;
    setState(() => _loadingPiece = false);
  }

  @override
  void dispose() {
    _anim.dispose();
    _pageCtrl.dispose();
    _titleCtrl.dispose();
    _yearCtrl.dispose();
    _editionCtrl.dispose();
    _priceCtrl.dispose();
    _oldPriceCtrl.dispose();
    _costPriceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────

  void _next() {
    if (_step < 4) {
      setState(() => _step++);
      _pageCtrl.animateToPage(_step,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.animateToPage(_step,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    }
  }

  Future<void> _publish() async {
    final price = int.tryParse(_priceCtrl.text.trim());
    if (price == null || _titleCtrl.text.trim().isEmpty || _images.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in title, at least one image, and price',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.bone),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final oldPrice = int.tryParse(_oldPriceCtrl.text.trim());
      final costPrice = int.tryParse(_costPriceCtrl.text.trim());
      final stock = int.tryParse(_stockCtrl.text.trim()) ?? 1;

      if (_isEditing) {
        final pieceId = widget.editPieceId!;

        // Update metadata
        await PieceService.instance.updatePiece(pieceId, {
          'title': _titleCtrl.text.trim(),
          'discipline': _discipline,
          'year': _yearCtrl.text.trim().isNotEmpty
              ? _yearCtrl.text.trim()
              : null,
          'edition': _editionCtrl.text.trim().isNotEmpty
              ? _editionCtrl.text.trim()
              : null,
          'price_cents': price * 100,
          'old_price_cents': oldPrice != null ? oldPrice * 100 : null,
          'cost_price_cents': costPrice != null ? costPrice * 100 : null,
          'rental': _rental,
          'stock': stock,
          'ships_to': _shipsTo.toList(),
          'packaging': _packaging,
        });

        // Delete removed images
        for (final imgId in _removedImageIds) {
          await PieceService.instance.deleteImage(pieceId, imgId);
        }

        // Upload new images (those without an existing id)
        final newImages = <Uint8List>[];
        for (var i = 0; i < _images.length; i++) {
          if (i >= _imageIds.length || _imageIds[i] == null) {
            newImages.add(_images[i]);
          }
        }
        await PieceService.instance.uploadImages(pieceId, newImages);

        // Refresh list in profile
        PieceService.instance.fetchMyPieces();
      } else {
        await PieceService.instance.publishPiece(
          title: _titleCtrl.text.trim(),
          discipline: _discipline,
          year:
              _yearCtrl.text.trim().isNotEmpty ? _yearCtrl.text.trim() : null,
          edition: _editionCtrl.text.trim().isNotEmpty
              ? _editionCtrl.text.trim()
              : null,
          priceCents: price * 100,
          oldPriceCents: oldPrice != null ? oldPrice * 100 : null,
          costPriceCents: costPrice != null ? costPrice * 100 : null,
          rental: _rental,
          stock: stock,
          shipsTo: _shipsTo.toList(),
          packaging: _packaging,
          images: _images,
        );
      }

      if (!mounted) return;
      setState(() {
        _isPublishing = false;
        _publishedTitle = _titleCtrl.text.trim();
        _published = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${_isEditing ? 'update' : 'publish'}: $e',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.bone),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }
  }

  // ── Pick image from gallery ────────────────────────────────

  Future<void> _pickImage() async {
    if (_images.length >= 8) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    // image_cropper not available on desktop — skip crop step
    if (Platform.isAndroid || Platform.isIOS) {
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressQuality: 80,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop photo',
            toolbarColor: const Color(0xFF2E2520),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.accent,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop photo',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
          ),
        ],
      );
      if (cropped == null) return;
      final bytes = await File(cropped.path).readAsBytes();
      setState(() {
        _images.add(bytes);
        _imageIds.add(null);
      });
    } else {
      final bytes = await File(picked.path).readAsBytes();
      setState(() {
        _images.add(bytes);
        _imageIds.add(null);
      });
    }
  }

  void _pickDiscipline() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Discipline',
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: AppColors.inkStrong,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _disciplines.map((d) => Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _discipline = d);
                          Navigator.pop(ctx);
                        },
                        splashColor: AppColors.ink.withValues(alpha: 0.05),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  d,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: _discipline == d
                                        ? AppColors.inkStrong
                                        : AppColors.inkSoft,
                                  ),
                                ),
                              ),
                              if (_discipline == d)
                                const Icon(Icons.check_rounded,
                                    size: 18, color: AppColors.sage),
                            ],
                          ),
                        ),
                      ),
                    )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_published) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: const SharedAppBar(currentRoute: '/list', showBack: true),
      body: _loadingPiece
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.ink),
            )
          : Column(
        children: [
          // ── Header + step indicator ──
          FadeTransition(
            opacity: _fade(0.0, 0.40),
            child: SlideTransition(
              position: _slide(0.0, 0.40),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Edit piece' : 'List a piece',
                      style: GoogleFonts.fraunces(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: AppColors.inkStrong,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Step ${_step + 1} of 5',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (_step + 1) / 5,
                        minHeight: 3,
                        backgroundColor: AppColors.hairline,
                        valueColor: const AlwaysStoppedAnimation(AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Pages ──
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
                _buildStep5(),
              ],
            ),
          ),

          // ── Footer nav buttons ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.hairline, width: 1),
              ),
            ),
            child: _step == 4
                ? SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _back,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.arrow_back_rounded,
                                    size: 16, color: AppColors.muted),
                                const SizedBox(width: 4),
                                Text(
                                  'Back',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isPublishing ? null : _publish,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: _isPublishing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.bone,
                                      ),
                                    )
                                  : Text(
                                      _isEditing ? 'Update' : 'Publish',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.bone,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      if (_step > 0)
                        GestureDetector(
                          onTap: _back,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.arrow_back_rounded,
                                    size: 16, color: AppColors.muted),
                                const SizedBox(width: 4),
                                Text(
                                  'Back',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _next,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Continue',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.bone,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 16, color: AppColors.bone),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ── Success screen ─────────────────────────────────────────
  // ═════════════════════════════════════════════════════════════

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AppColors.bone,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Checkmark
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.sage.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 36,
                  color: AppColors.sage,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                _isEditing
                    ? 'Piece updated'
                    : 'Piece listed successfully',
                style: GoogleFonts.fraunces(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: AppColors.inkStrong,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _isEditing
                    ? '"$_publishedTitle" has been updated.'
                    : '"$_publishedTitle" is now live and visible to buyers.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 4),

              // Action button
              GestureDetector(
                onTap: () {
                  if (_isEditing) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        pageBuilder: (_, _, _) => const HomeScreen(),
                        transitionsBuilder: (_, animation, _, child) =>
                            FadeTransition(opacity: animation, child: child),
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _isEditing ? 'Back to profile' : 'Go to Home',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.bone,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ── Step 1: Photos ────────────────────────────────────────
  // ═════════════════════════════════════════════════════════════

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload up to 8 photos. The first is the cover.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (_, i) {
              if (i < _images.length) {
                // Filled slot
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.memory(
                        _images[i],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    // Cover label
                    if (i == 0)
                      Positioned(
                        bottom: 4,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.surface.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Cover',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.inkSoft,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Remove button
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          if (i < _imageIds.length && _imageIds[i] != null) {
                            _removedImageIds.add(_imageIds[i]!);
                          }
                          _images.removeAt(i);
                          if (i < _imageIds.length) _imageIds.removeAt(i);
                        }),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.ink.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Empty slot
              return GestureDetector(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.hairline,
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.add_rounded,
                        size: 28, color: AppColors.muted),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ── Step 2: Details ───────────────────────────────────────
  // ═════════════════════════════════════════════════════════════

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormField(label: 'Title', controller: _titleCtrl),
          const SizedBox(height: 20),

          // Discipline selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discipline',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDiscipline,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: AppColors.hairline, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _discipline ?? 'Select discipline',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: _discipline != null
                                ? AppColors.inkStrong
                                : AppColors.muted,
                          ),
                        ),
                      ),
                      const Icon(Icons.expand_more_rounded,
                          size: 20, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _FormField(
            label: 'Year',
            controller: _yearCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          _FormField(
            label: 'Edition (optional)',
            controller: _editionCtrl,
            hint: 'e.g. 3 / 12',
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ── Step 3: Pricing ───────────────────────────────────────
  // ═════════════════════════════════════════════════════════════

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormField(
            label: 'Sale price (€)',
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          _FormField(
            label: 'Previous price (€)',
            controller: _oldPriceCtrl,
            keyboardType: TextInputType.number,
            hint: 'Leave empty if no discount',
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              'If set, buyers will see the old price crossed out.',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _FormField(
            label: 'Cost price (€)',
            controller: _costPriceCtrl,
            keyboardType: TextInputType.number,
            hint: 'Your acquisition cost',
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              'For internal use only — buyers will never see this.',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Rental toggle
          Text(
            'Available for rental',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Chip(
                label: 'No',
                selected: !_rental,
                onTap: () => setState(() => _rental = false),
              ),
              const SizedBox(width: 10),
              _Chip(
                label: 'Yes',
                selected: _rental,
                onTap: () => setState(() => _rental = true),
              ),
            ],
          ),

        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ── Step 4: Shipping ──────────────────────────────────────
  // ═════════════════════════════════════════════════════════════

  Widget _buildStep4() {
    const shipOptions = ['Spain', 'EU', 'UK + CH', 'Worldwide'];
    const packOptions = ['Standard', 'Crated', 'White-glove'];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ships to',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: shipOptions.map((o) {
              final sel = _shipsTo.contains(o);
              return _Chip(
                label: o,
                selected: sel,
                onTap: () => setState(() {
                  sel ? _shipsTo.remove(o) : _shipsTo.add(o);
                }),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          Text(
            'Packaging',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: packOptions.map((o) {
              return _Chip(
                label: o,
                selected: _packaging == o,
                onTap: () => setState(() => _packaging = o),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          _FormField(
            label: 'Stock',
            controller: _stockCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              'Stock is not shown to buyers.',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ── Step 5: Preview ───────────────────────────────────────
  // ═════════════════════════════════════════════════════════════

  Widget _buildStep5() {
    final title = _titleCtrl.text.trim().isNotEmpty
        ? _titleCtrl.text.trim()
        : 'Untitled';
    final price = _priceCtrl.text.trim().isNotEmpty
        ? '€${_priceCtrl.text.trim()}'
        : '€0';
    final oldPrice = _oldPriceCtrl.text.trim().isNotEmpty
        ? '€${_oldPriceCtrl.text.trim()}'
        : null;
    final designer = ProfileService.instance.name;
    final year = _yearCtrl.text.trim();
    final previewImages = _images;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Preview — this is how buyers will see your piece.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.90,
              heightFactor: 0.90,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bone,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.hairline, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _PreviewContent(
                  images: previewImages,
                  title: title,
                  designer: designer,
                  year: year,
                  price: price,
                  oldPrice: oldPrice,
                  discipline: _discipline,
                  edition: _editionCtrl.text.trim().isNotEmpty
                      ? _editionCtrl.text.trim()
                      : null,
                  rental: _rental,
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
// ── Form field ──────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? hint;

  const _FormField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.hint,
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
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.inkStrong,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.muted2,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: AppColors.hairline, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: AppColors.hairline, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.ink, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Chip (selectable) ───────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.hairline,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.bone : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Preview content (mini product detail) ───────────────────
// ═════════════════════════════════════════════════════════════

class _PreviewContent extends StatefulWidget {
  final List<Uint8List> images;
  final String title;
  final String designer;
  final String year;
  final String price;
  final String? oldPrice;
  final String? discipline;
  final String? edition;
  final bool rental;

  const _PreviewContent({
    required this.images,
    required this.title,
    required this.designer,
    required this.year,
    required this.price,
    this.oldPrice,
    this.discipline,
    this.edition,
    this.rental = false,
  });

  @override
  State<_PreviewContent> createState() => _PreviewContentState();
}

class _PreviewContentState extends State<_PreviewContent> {
  int _page = 0;
  final _previewPageCtrl = PageController();

  @override
  void dispose() {
    _previewPageCtrl.dispose();
    super.dispose();
  }

  String get _tag => widget.rental ? 'Buy or Rent' : 'Sell';

  String get _priceLabel => switch (_tag) {
        'Rent' => 'RENTAL PRICE',
        'Buy or Rent' => 'SALE PRICE',
        _ => 'SALE PRICE',
      };

  String get _actionLabel => switch (_tag) {
        'Sell' || 'Buy' => 'Buy now',
        'Rent' => 'Request rental',
        'Buy or Rent' => 'Buy or rent',
        _ => 'Contact seller',
      };

  @override
  Widget build(BuildContext context) {
    final location = ProfileService.instance.location;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ═══════════════════════════════════════════════════
          // ── 1. Image carousel ────────────────────────────
          // ═══════════════════════════════════════════════════
          AspectRatio(
            aspectRatio: 0.85,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _previewPageCtrl,
                  itemCount: widget.images.length,
                  onPageChanged: (p) => setState(() => _page = p),
                  itemBuilder: (_, i) => Image.memory(
                    widget.images[i],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                // Tag pill
                Positioned(
                  top: 14,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _tag,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                // Dots + arrow controls
                if (widget.images.length > 1)
                  Positioned(
                    bottom: 14,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Prev button
                        GestureDetector(
                          onTap: _page > 0
                              ? () => _previewPageCtrl.previousPage(
                                    duration:
                                        const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  )
                              : null,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _page > 0
                                  ? AppColors.ink.withValues(alpha: 0.5)
                                  : AppColors.ink.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 18,
                              color: _page > 0
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Dots
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children:
                              List.generate(widget.images.length, (i) {
                            final active = i == _page;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: active ? 7 : 5,
                              height: active ? 7 : 5,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: active
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.4),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(width: 12),
                        // Next button
                        GestureDetector(
                          onTap: _page < widget.images.length - 1
                              ? () => _previewPageCtrl.nextPage(
                                    duration:
                                        const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  )
                              : null,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _page < widget.images.length - 1
                                  ? AppColors.ink.withValues(alpha: 0.5)
                                  : AppColors.ink.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: _page < widget.images.length - 1
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════
          // ── 2. Authenticated badge ───────────────────────
          // ═══════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
            child: Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_outlined,
                        size: 14, color: AppColors.sage),
                    const SizedBox(width: 5),
                    Text(
                      'Authenticated by Chosen Object',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.sage,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.bookmark_border_rounded,
                    size: 22, color: AppColors.inkSoft),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════
          // ── 3. Edition + Year ────────────────────────────
          // ═══════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.edition != null)
                  Text(
                    'Edition ${widget.edition}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  widget.year,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════
          // ── 4. Designer + Location ───────────────────────
          // ═══════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.hairline,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.designer.isNotEmpty
                              ? widget.designer[0]
                              : '?',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.designer,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.inkStrong,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              [
                                if (location.isNotEmpty) location,
                                if (widget.discipline != null)
                                  widget.discipline!,
                              ].join(' · '),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: AppColors.hairline, width: 1),
                  ),
                  child: Text(
                    'Follow',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: AppColors.hairline, height: 1),
          ),

          // ═══════════════════════════════════════════════════
          // ── 5. № 02 — Specifications ─────────────────────
          // ═══════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '№ 01',
                        style: GoogleFonts.fraunces(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          color: AppColors.gold,
                          height: 1.3,
                        ),
                      ),
                      TextSpan(
                        text: ' — Specifications',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.muted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _PreviewSpecRow(label: 'Year', value: widget.year),
                if (widget.discipline != null)
                  _PreviewSpecRow(
                      label: 'Discipline', value: widget.discipline!),
                if (widget.edition != null)
                  _PreviewSpecRow(
                      label: 'Edition', value: widget.edition!),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: AppColors.hairline, height: 1),
          ),

          // ═══════════════════════════════════════════════════
          // ── 6. Price + Actions ───────────────────────────
          // ═══════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _priceLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                if (widget.oldPrice != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        widget.oldPrice!,
                        style: GoogleFonts.fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFB04A4A),
                          height: 1.1,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: const Color(0xFFB04A4A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.price,
                        style: GoogleFonts.fraunces(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: AppColors.inkStrong,
                          height: 1.1,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    widget.price,
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkStrong,
                      height: 1.1,
                    ),
                  ),
              ],
            ),
          ),

          // ── Action buttons (side by side) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _actionLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.bone,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: AppColors.hairline, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Make an offer',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Preview spec row ──────────────────────────────────────────

class _PreviewSpecRow extends StatelessWidget {
  final String label;
  final String value;
  const _PreviewSpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
