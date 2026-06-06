import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
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

  final List<_Address> _addresses = [
    _Address(
      label: 'Home',
      name: 'Carlos García López',
      street: 'Calle Velázquez 21',
      city: '28001 Madrid, Spain',
      phone: '+34 600 000 000',
      isDefault: true,
    ),
    _Address(
      label: 'Studio',
      name: 'Carlos García López',
      street: 'Carrer del Born 14',
      city: '08003 Barcelona, Spain',
      phone: '+34 600 111 222',
      isDefault: false,
    ),
  ];

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
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────

  void _setDefault(int index) {
    setState(() {
      for (var i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(isDefault: i == index);
      }
    });
  }

  void _removeAddress(int index) {
    final addr = _addresses[index];
    setState(() => _addresses.removeAt(index));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${addr.label} address removed',
          style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.bone),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.gold,
          onPressed: () => setState(() => _addresses.insert(index, addr)),
        ),
      ),
    );
  }

  void _openAddressSheet({_Address? existing, int? editIndex}) {
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final streetCtrl = TextEditingController(text: existing?.street ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Padding(
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
              Text(
                editIndex != null ? 'Edit address' : 'New address',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: AppColors.inkStrong,
                ),
              ),
              const SizedBox(height: 20),
              _SheetField(label: 'Label (e.g. Home, Studio)', controller: labelCtrl),
              const SizedBox(height: 14),
              _SheetField(label: 'Full name', controller: nameCtrl),
              const SizedBox(height: 14),
              _SheetField(label: 'Street address', controller: streetCtrl),
              const SizedBox(height: 14),
              _SheetField(label: 'City, postal code, country', controller: cityCtrl),
              const SizedBox(height: 14),
              _SheetField(label: 'Phone number', controller: phoneCtrl),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (labelCtrl.text.trim().isEmpty ||
                        nameCtrl.text.trim().isEmpty) {
                      Navigator.pop(ctx);
                      return;
                    }
                    final addr = _Address(
                      label: labelCtrl.text.trim(),
                      name: nameCtrl.text.trim(),
                      street: streetCtrl.text.trim(),
                      city: cityCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      isDefault: existing?.isDefault ?? false,
                    );
                    setState(() {
                      if (editIndex != null) {
                        _addresses[editIndex] = addr;
                      } else {
                        _addresses.add(addr);
                      }
                    });
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
                    editIndex != null ? 'Save' : 'Add',
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
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: const SharedAppBar(currentRoute: '/addresses'),
      drawer: const AppDrawer(currentRoute: '/addresses'),
      body: SingleChildScrollView(
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
            for (var i = 0; i < _addresses.length; i++) ...[
              FadeTransition(
                opacity: _fade(0.06 + i * 0.10, 0.50 + i * 0.10),
                child: SlideTransition(
                  position: _slide(0.06 + i * 0.10, 0.50 + i * 0.10),
                  child: _AddressCard(
                    address: _addresses[i],
                    onSetDefault: () => _setDefault(i),
                    onEdit: () =>
                        _openAddressSheet(existing: _addresses[i], editIndex: i),
                    onRemove: () => _removeAddress(i),
                  ),
                ),
              ),
              if (i < _addresses.length - 1) const SizedBox(height: 12),
            ],

            if (_addresses.isEmpty)
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
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Address model ───────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _Address {
  final String label;
  final String name;
  final String street;
  final String city;
  final String phone;
  final bool isDefault;

  const _Address({
    required this.label,
    required this.name,
    required this.street,
    required this.city,
    required this.phone,
    required this.isDefault,
  });

  _Address copyWith({bool? isDefault}) => _Address(
        label: label,
        name: name,
        street: street,
        city: city,
        phone: phone,
        isDefault: isDefault ?? this.isDefault,
      );
}

// ═════════════════════════════════════════════════════════════
// ── Address card ────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _AddressCard extends StatelessWidget {
  final _Address address;
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
            address.name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 4),

          // Street
          Text(
            address.street,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 2),

          // City
          Text(
            address.city,
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

  const _SheetField({required this.label, required this.controller});

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
