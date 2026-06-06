import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/address_service.dart';
import '../../core/app_colors.dart';
import '../../models/address.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/shared_app_bar.dart';

// ═════════════════════════════════════════════════════════════
// ── Addresses Screen ────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

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

    // Load addresses from backend
    AddressService.instance.loadFromBackend();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────

  void _setDefault(int index) {
    AddressService.instance.setDefaultByIndex(index);
  }

  void _removeAddress(int index) {
    final svc = AddressService.instance;
    final address = svc.addresses[index];

    showDialog(
      context: context,
      barrierColor: AppColors.ink.withValues(alpha: 0.3),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline_rounded,
                    size: 20, color: AppColors.danger),
              ),
              const SizedBox(height: 16),
              Text(
                'Remove address',
                style: GoogleFonts.fraunces(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: AppColors.inkStrong,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will permanently remove your "${address.label}" address.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.hairline, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        svc.deleteAddressByIndex(index);

                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${address.label} address removed',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.bone),
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: AppColors.ink,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            action: SnackBarAction(
                              label: 'Undo',
                              textColor: AppColors.gold,
                              onPressed: () => svc.reAddAddress(address),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            'Remove',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.surface,
                            ),
                          ),
                        ),
                      ),
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

  void _openAddressSheet({Address? existing}) {
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final streetCtrl = TextEditingController(text: existing?.street ?? '');
    final numberCtrl = TextEditingController(text: existing?.number ?? '');
    final detailsCtrl =
        TextEditingController(text: existing?.details ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? '');
    final postalCtrl =
        TextEditingController(text: existing?.postalCode ?? '');
    final countryCtrl = TextEditingController(text: existing?.country ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final isEdit = existing != null;

    var isDefault = existing?.isDefault ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit address' : 'New address',
                      style: GoogleFonts.fraunces(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: AppColors.inkStrong,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setSheetState(() => isDefault = !isDefault),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDefault
                            ? AppColors.sage.withValues(alpha: 0.12)
                            : AppColors.ink.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDefault
                              ? AppColors.sage.withValues(alpha: 0.3)
                              : AppColors.hairline,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDefault
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 14,
                            color: isDefault
                                ? AppColors.sage
                                : AppColors.muted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Default',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDefault
                                  ? AppColors.sage
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SheetField(
                  label: 'Label (e.g. Home, Studio)', controller: labelCtrl),
              const SizedBox(height: 14),
              _SheetField(label: 'Full name', controller: nameCtrl),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _SheetField(
                        label: 'Street', controller: streetCtrl),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: _SheetField(
                        label: 'Number', controller: numberCtrl),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SheetField(
                label: 'Floor, door, block...',
                controller: detailsCtrl,
                optional: true,
              ),
              const SizedBox(height: 14),
              _SheetField(label: 'City', controller: cityCtrl),
              const SizedBox(height: 14),
              _SheetField(label: 'Postal code', controller: postalCtrl),
              const SizedBox(height: 14),
              _SheetField(label: 'Country', controller: countryCtrl),
              const SizedBox(height: 14),
              _SheetField(label: 'Phone number', controller: phoneCtrl),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final allFilled = [
                      labelCtrl,
                      nameCtrl,
                      streetCtrl,
                      numberCtrl,
                      cityCtrl,
                      postalCtrl,
                      countryCtrl,
                      phoneCtrl,
                    ].every((c) => c.text.trim().isNotEmpty);

                    if (!allFilled) return;

                    final detailsTrimmed = detailsCtrl.text.trim();
                    final addr = Address(
                      id: existing?.id,
                      label: labelCtrl.text.trim(),
                      fullName: nameCtrl.text.trim(),
                      street: streetCtrl.text.trim(),
                      number: numberCtrl.text.trim(),
                      details: detailsTrimmed.isEmpty
                          ? null
                          : detailsTrimmed,
                      city: cityCtrl.text.trim(),
                      postalCode: postalCtrl.text.trim(),
                      country: countryCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      isDefault: isDefault,
                    );
                    final svc = AddressService.instance;
                    if (isEdit && existing.id != null) {
                      svc.updateAddress(existing.id!, addr);
                      if (isDefault) svc.setDefault(existing.id!);
                    } else {
                      svc.addAddress(addr);
                    }
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.bone,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                  child: Text(
                    isEdit ? 'Save' : 'Add',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: const SharedAppBar(currentRoute: '/addresses'),
      drawer: const AppDrawer(currentRoute: '/addresses'),
      body: ListenableBuilder(
        listenable: AddressService.instance,
        builder: (context, _) {
          final addresses = AddressService.instance.addresses;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header + Add button ──
                FadeTransition(
                  opacity: _fade(0.0, 0.45),
                  child: SlideTransition(
                    position: _slide(0.0, 0.45),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Addresses',
                              style: GoogleFonts.fraunces(
                                fontSize: 28,
                                fontWeight: FontWeight.w400,
                                color: AppColors.inkStrong,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _openAddressSheet(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.hairline, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_rounded,
                                      size: 16, color: AppColors.inkSoft),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Add new',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.inkSoft,
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

                const SizedBox(height: 24),

                // ── Address cards ──
                for (var i = 0; i < addresses.length; i++) ...[
                  FadeTransition(
                    opacity: _fade(0.06 + i * 0.10, 0.50 + i * 0.10),
                    child: SlideTransition(
                      position: _slide(0.06 + i * 0.10, 0.50 + i * 0.10),
                      child: _AddressCard(
                        address: addresses[i],
                        onSetDefault: () => _setDefault(i),
                        onEdit: () =>
                            _openAddressSheet(existing: addresses[i]),
                        onRemove: () => _removeAddress(i),
                      ),
                    ),
                  ),
                  if (i < addresses.length - 1) const SizedBox(height: 12),
                ],

                if (addresses.isEmpty)
                  FadeTransition(
                    opacity: _fade(0.06, 0.50),
                    child: SlideTransition(
                      position: _slide(0.06, 0.50),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 48),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.location_off_outlined,
                                  size: 36, color: AppColors.muted),
                              const SizedBox(height: 10),
                              Text(
                                'No addresses yet',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Address card ────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _AddressCard({
    required this.address,
    required this.onSetDefault,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  address.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (address.isDefault) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sage.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Default',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.sage,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // Name
          Text(
            address.fullName,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 4),

          // Street + number
          Text(
            '${address.street} ${address.number}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.inkSoft,
            ),
          ),

          // Details (floor, door, block...)
          if (address.details != null && address.details!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              address.details!,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
          ],
          const SizedBox(height: 2),

          // City, postal code, country
          Text(
            '${address.postalCode} ${address.city}, ${address.country}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 4),

          // Phone
          Text(
            address.phone,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.hairline, height: 1, thickness: 1),
          const SizedBox(height: 12),

          // Action row
          Row(
            children: [
              if (!address.isDefault) ...[
                GestureDetector(
                  onTap: onSetDefault,
                  child: Text(
                    'Set as default',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkSoft,
                      decoration: TextDecoration.underline,
                      decorationColor:
                          AppColors.inkSoft.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
              ],
              GestureDetector(
                onTap: onEdit,
                child: Text(
                  'Edit',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: onRemove,
                child: Text(
                  'Remove',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Sheet text field ────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _SheetField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool optional;

  const _SheetField({
    required this.label,
    required this.controller,
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
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 4),
              Text(
                '(optional)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.inkStrong,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bone,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
