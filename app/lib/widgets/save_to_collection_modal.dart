import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/collection_service.dart';

// ═════════════════════════════════════════════════════════════
// ── Save to Collection Modal ────────────────────────────────
// ═════════════════════════════════════════════════════════════

class SaveToCollectionModal extends StatefulWidget {
  final String productId;
  const SaveToCollectionModal({super.key, required this.productId});

  /// Show as a bottom sheet from anywhere.
  static Future<void> show(BuildContext context, String productId) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SaveToCollectionModal(productId: productId),
    );
  }

  @override
  State<SaveToCollectionModal> createState() => _SaveToCollectionModalState();
}

class _SaveToCollectionModalState extends State<SaveToCollectionModal> {
  bool _creating = false;
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitNew() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    CollectionService.instance.createCollection(
      name,
      initialProductId: widget.productId,
    );
    _nameController.clear();
    setState(() => _creating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: CollectionService.instance,
          builder: (context, _) {
            final service = CollectionService.instance;
            final collections = service.collections;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Handle bar ──
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.hairline,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                // ── Title row ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Save to collection',
                          style: GoogleFonts.fraunces(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: AppColors.inkStrong,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: AppColors.muted,
                        onPressed: () => Navigator.of(context).pop(),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: AppColors.hairline, height: 24),
                ),

                // ── Collection rows ──
                if (collections.isEmpty && !_creating)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      'Create your first collection',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.muted,
                      ),
                    ),
                  )
                else
                  ...collections.map((col) {
                    final contains =
                        col.productIds.contains(widget.productId);
                    return InkWell(
                      onTap: () => service.toggleProductInCollection(
                          col.id, widget.productId),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              contains
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 20,
                              color: contains
                                  ? AppColors.accent
                                  : AppColors.muted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                col.name,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                            Text(
                              '${col.productIds.length}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                // ── Create new collection ──
                if (_creating)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            focusNode: _focusNode,
                            autofocus: true,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.inkStrong,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Collection name',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.muted,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onSubmitted: (_) => _submitNew(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _submitNew,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Create',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.bone,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  InkWell(
                    onTap: () {
                      setState(() => _creating = true);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _focusNode.requestFocus();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded,
                              size: 20, color: AppColors.inkSoft),
                          const SizedBox(width: 12),
                          Text(
                            'Create new collection',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ),
    );
  }
}
