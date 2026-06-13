import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/piece_service.dart';
import '../../models/piece.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/shared_app_bar.dart';
import '../list_piece/list_piece_screen.dart';

class MyPiecesScreen extends StatefulWidget {
  const MyPiecesScreen({super.key});

  @override
  State<MyPiecesScreen> createState() => _MyPiecesScreenState();
}

class _MyPiecesScreenState extends State<MyPiecesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  Animation<double> _fade(double start, double end) => CurvedAnimation(
        parent: _anim,
        curve: Interval(
            start.clamp(0, 1), end.clamp(0, 1), curve: Curves.easeOut),
      );

  Animation<Offset> _slide(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _anim,
          curve: Interval(
              start.clamp(0, 1), end.clamp(0, 1), curve: Curves.easeOut),
        ),
      );

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    PieceService.instance.fetchMyPieces();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────

  Future<void> _toggleHidden(PieceListItem piece) async {
    try {
      await PieceService.instance.toggleHidden(piece.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update visibility',
                style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _deletePiece(PieceListItem piece) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete piece',
          style: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: AppColors.inkStrong,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${piece.title}"? This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await PieceService.instance.deletePiece(piece.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete piece',
                  style: GoogleFonts.inter(fontSize: 13)),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  void _editPiece(PieceListItem piece) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => ListPieceScreen(editPieceId: piece.id),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: const SharedAppBar(currentRoute: '/my-pieces'),
      drawer: const AppDrawer(currentRoute: '/my-pieces'),
      body: ListenableBuilder(
        listenable: PieceService.instance,
        builder: (context, _) {
          final service = PieceService.instance;

          if (service.loadingPieces && service.pieces.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          final pieces = service.pieces;

          if (pieces.isEmpty) {
            return _buildEmpty();
          }

          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () => PieceService.instance.fetchMyPieces(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              itemCount: pieces.length + 1, // +1 for header
              itemBuilder: (context, index) {
                if (index == 0) {
                  return FadeTransition(
                    opacity: _fade(0.0, 0.40),
                    child: SlideTransition(
                      position: _slide(0.0, 0.40),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'My pieces',
                              style: GoogleFonts.fraunces(
                                fontSize: 28,
                                fontWeight: FontWeight.w400,
                                color: AppColors.inkStrong,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${pieces.length} items',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final piece = pieces[index - 1];
                final animStart = 0.05 + (index - 1) * 0.04;
                return FadeTransition(
                  opacity: _fade(animStart, (animStart + 0.35).clamp(0, 1)),
                  child: SlideTransition(
                    position:
                        _slide(animStart, (animStart + 0.38).clamp(0, 1)),
                    child: _PieceRow(
                      piece: piece,
                      onToggleHidden: () => _toggleHidden(piece),
                      onDelete: () => _deletePiece(piece),
                      onEdit: () => _editPiece(piece),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.muted2),
          const SizedBox(height: 16),
          Text(
            'No pieces yet',
            style: GoogleFonts.fraunces(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'List your first piece to get started',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (_, _, _) => const ListPieceScreen(),
                  transitionsBuilder: (_, animation, _, child) =>
                      FadeTransition(opacity: animation, child: child),
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'List a piece',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.bone,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Piece row ────────────────────────────────────────────────

class _PieceRow extends StatelessWidget {
  final PieceListItem piece;
  final VoidCallback onToggleHidden;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _PieceRow({
    required this.piece,
    required this.onToggleHidden,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: piece.isHidden ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onEdit,
                splashColor: AppColors.ink.withValues(alpha: 0.05),
                highlightColor: AppColors.ink.withValues(alpha: 0.04),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      // Cover image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 56,
                          height: 56,
                          color: AppColors.muted2,
                          child: piece.coverImageBytes != null
                              ? Image.memory(
                                  piece.coverImageBytes!,
                                  fit: BoxFit.cover,
                                  width: 56,
                                  height: 56,
                                )
                              : const Icon(Icons.image_outlined,
                                  size: 24, color: AppColors.muted),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title + meta
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              piece.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.inkStrong,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  piece.priceFormatted,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                                if (piece.discipline != null &&
                                    piece.discipline!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: const BoxDecoration(
                                      color: AppColors.muted2,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      piece.discipline!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (piece.isHidden) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.muted2.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Hidden',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Actions menu
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded,
                            size: 20, color: AppColors.muted),
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 4,
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              onEdit();
                            case 'toggle':
                              onToggleHidden();
                            case 'delete':
                              onDelete();
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined,
                                    size: 18, color: AppColors.inkSoft),
                                const SizedBox(width: 10),
                                Text('Edit',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.inkSoft)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(
                                  piece.isHidden
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 18,
                                  color: AppColors.inkSoft,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  piece.isHidden ? 'Show' : 'Hide',
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: AppColors.inkSoft),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline_rounded,
                                    size: 18, color: AppColors.danger),
                                const SizedBox(width: 10),
                                Text('Delete',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.danger)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(color: AppColors.hairline, height: 1, thickness: 1),
          ],
        ),
      ),
    );
  }
}
