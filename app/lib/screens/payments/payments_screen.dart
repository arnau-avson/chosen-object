import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/shared_app_bar.dart';

// ═════════════════════════════════════════════════════════════
// ── Payments Screen ─────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  // ── Mock data ──────────────────────────────────────────────

  final List<_SavedCard> _cards = [
    _SavedCard(
      brand: CardBrand.visa,
      last4: '4231',
      expires: '08/28',
      isDefault: true,
    ),
    _SavedCard(
      brand: CardBrand.mastercard,
      last4: '7811',
      expires: '03/26',
      isDefault: false,
    ),
  ];

  String _iban = '•••• •••• •••• 4231';
  String _ibanBank = 'Caixabank';

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
      for (var i = 0; i < _cards.length; i++) {
        _cards[i] = _cards[i].copyWith(isDefault: i == index);
      }
    });
  }

  void _removeCard(int index) {
    final card = _cards[index];
    setState(() => _cards.removeAt(index));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${card.brand.label} •••• ${card.last4} removed',
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
          onPressed: () {
            setState(() => _cards.insert(index, card));
          },
        ),
      ),
    );
  }

  void _updateIban() {
    final ibanCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
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
              'Update IBAN',
              style: GoogleFonts.fraunces(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: AppColors.inkStrong,
              ),
            ),
            const SizedBox(height: 20),
            _SheetField(label: 'IBAN', controller: ibanCtrl),
            const SizedBox(height: 14),
            _SheetField(label: 'Bank name', controller: bankCtrl),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (ibanCtrl.text.trim().isNotEmpty) {
                    final raw = ibanCtrl.text.trim();
                    final masked = raw.length > 4
                        ? '•••• •••• •••• ${raw.substring(raw.length - 4)}'
                        : raw;
                    setState(() {
                      _iban = masked;
                      if (bankCtrl.text.trim().isNotEmpty) {
                        _ibanBank = bankCtrl.text.trim();
                      }
                    });
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
                  'Save',
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
    );
  }

  void _addPaymentMethod() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Add payment method — coming soon',
          style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.bone),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: const SharedAppBar(currentRoute: '/payments'),
      drawer: const AppDrawer(currentRoute: '/payments'),
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
                    'Payment',
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkStrong,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Section 1: Saved Cards ──
            FadeTransition(
              opacity: _fade(0.06, 0.50),
              child: SlideTransition(
                position: _slide(0.06, 0.50),
                child: _Section(
                  title: 'SAVED CARDS',
                  child: Column(
                    children: [
                      for (var i = 0; i < _cards.length; i++) ...[
                        if (i > 0)
                          const Divider(
                              color: AppColors.hairline,
                              height: 1,
                              thickness: 1),
                        _CardRow(
                          card: _cards[i],
                          onSetDefault: () => _setDefault(i),
                          onRemove: () => _removeCard(i),
                        ),
                      ],
                      if (_cards.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 24),
                          child: Center(
                            child: Text(
                              'No saved cards',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Section 2: Apple Pay / Google Pay ──
            FadeTransition(
              opacity: _fade(0.14, 0.58),
              child: SlideTransition(
                position: _slide(0.14, 0.58),
                child: _Section(
                  title: 'APPLE PAY / GOOGLE PAY',
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.apple,
                              size: 24, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Use Apple Pay on this device',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Configure in Wallet app on iPhone',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            size: 20, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Section 3: Payout Account (PRO) ──
            FadeTransition(
              opacity: _fade(0.22, 0.66),
              child: SlideTransition(
                position: _slide(0.22, 0.66),
                child: _Section(
                  title: 'PAYOUT ACCOUNT (PRO)',
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // IBAN row
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.sage.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.account_balance_outlined,
                                  size: 20, color: AppColors.sage),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'IBAN $_iban',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.inkSoft,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'at $_ibanBank',
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

                        const SizedBox(height: 4),

                        // Subtitle
                        Padding(
                          padding: const EdgeInsets.only(left: 54),
                          child: Text(
                            'Used for studio payouts',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.muted,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Update IBAN button
                        Padding(
                          padding: const EdgeInsets.only(left: 54),
                          child: GestureDetector(
                            onTap: _updateIban,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: AppColors.hairline, width: 1),
                              ),
                              child: Text(
                                'Update IBAN',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Disclaimer
                        const Divider(
                            color: AppColors.hairline,
                            height: 1,
                            thickness: 1),
                        const SizedBox(height: 14),
                        Text(
                          'Payouts are processed within 2 business days of sale confirmation by buyer.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: AppColors.muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Add payment method ──
            FadeTransition(
              opacity: _fade(0.30, 0.72),
              child: SlideTransition(
                position: _slide(0.30, 0.72),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: _addPaymentMethod,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppColors.hairline, width: 1),
                        color: AppColors.surface,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_rounded,
                              size: 18, color: AppColors.inkSoft),
                          const SizedBox(width: 8),
                          Text(
                            'Add payment method',
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
// ── Section wrapper ─────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.muted2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.hairline, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Card brand enum ─────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

enum CardBrand {
  visa('Visa', Color(0xFF1A1F71)),
  mastercard('Mastercard', Color(0xFFEB001B));

  final String label;
  final Color color;
  const CardBrand(this.label, this.color);
}

// ═════════════════════════════════════════════════════════════
// ── Saved card model ────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _SavedCard {
  final CardBrand brand;
  final String last4;
  final String expires;
  final bool isDefault;

  const _SavedCard({
    required this.brand,
    required this.last4,
    required this.expires,
    required this.isDefault,
  });

  _SavedCard copyWith({bool? isDefault}) => _SavedCard(
        brand: brand,
        last4: last4,
        expires: expires,
        isDefault: isDefault ?? this.isDefault,
      );
}

// ═════════════════════════════════════════════════════════════
// ── Card row ────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _CardRow extends StatelessWidget {
  final _SavedCard card;
  final VoidCallback onSetDefault;
  final VoidCallback onRemove;

  const _CardRow({
    required this.card,
    required this.onSetDefault,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand icon
          Container(
            width: 44,
            height: 30,
            decoration: BoxDecoration(
              color: card.brand.color,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              card.brand == CardBrand.visa ? 'VISA' : 'MC',
              style: GoogleFonts.inter(
                fontSize: card.brand == CardBrand.visa ? 11 : 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: card.brand == CardBrand.visa ? 1.5 : 0.5,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Card details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${card.brand.label} •••• ${card.last4}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Expires ${card.expires}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (card.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
                      )
                    else
                      GestureDetector(
                        onTap: onSetDefault,
                        child: Text(
                          'Set default',
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
                    const SizedBox(width: 16),
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
