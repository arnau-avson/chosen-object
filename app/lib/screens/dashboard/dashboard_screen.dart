import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../models/product.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/shared_app_bar.dart';

// ═════════════════════════════════════════════════════════════
// ── Mock sales data ─────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _Sale {
  final String productId;
  final String productName;
  final String category;
  final double revenue;
  final double cost;
  final DateTime date;

  const _Sale({
    required this.productId,
    required this.productName,
    required this.category,
    required this.revenue,
    required this.cost,
    required this.date,
  });

  double get profit => revenue - cost;
}

final _mockSales = <_Sale>[
  // June 2026
  _Sale(productId: 'curved-vessel', productName: 'Curved Vessel', category: 'Ceramic', revenue: 340, cost: 180, date: DateTime(2026, 6, 6, 10, 30)),
  _Sale(productId: 'linen-armchair', productName: 'Linen Armchair', category: 'Furniture', revenue: 1200, cost: 650, date: DateTime(2026, 6, 5, 14, 0)),
  _Sale(productId: 'stoneware-bowl', productName: 'Stoneware Bowl', category: 'Ceramic', revenue: 190, cost: 60, date: DateTime(2026, 6, 3)),
  _Sale(productId: 'glass-pendant', productName: 'Glass Pendant', category: 'Lighting', revenue: 560, cost: 280, date: DateTime(2026, 6, 1)),
  // May 2026
  _Sale(productId: 'bronze-table-lamp', productName: 'Bronze Table Lamp', category: 'Lighting', revenue: 480, cost: 220, date: DateTime(2026, 5, 28)),
  _Sale(productId: 'woven-throw', productName: 'Woven Throw', category: 'Textiles', revenue: 260, cost: 110, date: DateTime(2026, 5, 22)),
  _Sale(productId: 'curved-vessel', productName: 'Curved Vessel', category: 'Ceramic', revenue: 340, cost: 180, date: DateTime(2026, 5, 18)),
  _Sale(productId: 'walnut-side-table', productName: 'Walnut Side Table', category: 'Furniture', revenue: 720, cost: 340, date: DateTime(2026, 5, 12)),
  _Sale(productId: 'stoneware-bowl', productName: 'Stoneware Bowl', category: 'Ceramic', revenue: 190, cost: 60, date: DateTime(2026, 5, 5)),
  _Sale(productId: 'ceramic-vase', productName: 'Ceramic Vase', category: 'Ceramic', revenue: 280, cost: 90, date: DateTime(2026, 5, 2)),
  // April 2026
  _Sale(productId: 'linen-armchair', productName: 'Linen Armchair', category: 'Furniture', revenue: 1200, cost: 650, date: DateTime(2026, 4, 26)),
  _Sale(productId: 'glass-pendant', productName: 'Glass Pendant', category: 'Lighting', revenue: 560, cost: 280, date: DateTime(2026, 4, 18)),
  _Sale(productId: 'curved-vessel', productName: 'Curved Vessel', category: 'Ceramic', revenue: 340, cost: 180, date: DateTime(2026, 4, 10)),
  _Sale(productId: 'woven-throw', productName: 'Woven Throw', category: 'Textiles', revenue: 260, cost: 110, date: DateTime(2026, 4, 3)),
  // March 2026
  _Sale(productId: 'bronze-table-lamp', productName: 'Bronze Table Lamp', category: 'Lighting', revenue: 480, cost: 220, date: DateTime(2026, 3, 25)),
  _Sale(productId: 'walnut-side-table', productName: 'Walnut Side Table', category: 'Furniture', revenue: 720, cost: 340, date: DateTime(2026, 3, 14)),
  _Sale(productId: 'stoneware-bowl', productName: 'Stoneware Bowl', category: 'Ceramic', revenue: 190, cost: 60, date: DateTime(2026, 3, 6)),
  // February 2026
  _Sale(productId: 'glass-pendant', productName: 'Glass Pendant', category: 'Lighting', revenue: 560, cost: 280, date: DateTime(2026, 2, 22)),
  _Sale(productId: 'ceramic-vase', productName: 'Ceramic Vase', category: 'Ceramic', revenue: 280, cost: 90, date: DateTime(2026, 2, 12)),
  _Sale(productId: 'curved-vessel', productName: 'Curved Vessel', category: 'Ceramic', revenue: 340, cost: 180, date: DateTime(2026, 2, 4)),
  // January 2026
  _Sale(productId: 'linen-armchair', productName: 'Linen Armchair', category: 'Furniture', revenue: 1200, cost: 650, date: DateTime(2026, 1, 20)),
  _Sale(productId: 'bronze-table-lamp', productName: 'Bronze Table Lamp', category: 'Lighting', revenue: 480, cost: 220, date: DateTime(2026, 1, 8)),
  // December 2025
  _Sale(productId: 'woven-throw', productName: 'Woven Throw', category: 'Textiles', revenue: 260, cost: 110, date: DateTime(2025, 12, 18)),
  _Sale(productId: 'walnut-side-table', productName: 'Walnut Side Table', category: 'Furniture', revenue: 720, cost: 340, date: DateTime(2025, 12, 5)),
  // November 2025
  _Sale(productId: 'stoneware-bowl', productName: 'Stoneware Bowl', category: 'Ceramic', revenue: 190, cost: 60, date: DateTime(2025, 11, 22)),
  _Sale(productId: 'ceramic-vase', productName: 'Ceramic Vase', category: 'Ceramic', revenue: 280, cost: 90, date: DateTime(2025, 11, 10)),
];

// ═════════════════════════════════════════════════════════════
// ── Time range ──────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

enum _TimeRange {
  day('Today'),
  week('7 days'),
  month('30 days'),
  year('12 months'),
  all('All time');

  final String label;
  const _TimeRange(this.label);
}

// ═════════════════════════════════════════════════════════════
// ── Chart bar data ──────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _ChartBar {
  final String label;
  final double revenue;
  final double profit;
  const _ChartBar(
      {required this.label, required this.revenue, required this.profit});
}

// ═════════════════════════════════════════════════════════════
// ── Dashboard Screen ────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  _TimeRange _range = _TimeRange.month;

  // Pagination
  static const _pageSize = 4;
  int _productsPage = 0;
  int _inventoryPage = 0;
  int _recentPage = 0;

  // ── Animation helpers ──────────────────────────────────────

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
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────

  static double _parsePrice(String price) {
    return double.tryParse(price
                .replaceAll('€', '')
                .replaceAll(',', '')
                .replaceAll('.', '')
                .trim()) ??
        0;
  }

  String _fmtCur(double val) {
    if (val.abs() >= 1000) {
      final whole = val.toInt();
      final neg = whole < 0;
      final abs = whole.abs().toString();
      final buf = StringBuffer();
      for (var i = 0; i < abs.length; i++) {
        if (i > 0 && (abs.length - i) % 3 == 0) buf.write(',');
        buf.write(abs[i]);
      }
      return neg ? '-€$buf' : '€$buf';
    }
    if (val < 0) return '-€${val.abs().toStringAsFixed(0)}';
    return '€${val.toStringAsFixed(val == val.roundToDouble() ? 0 : 2)}';
  }

  // ── Filtered data ──────────────────────────────────────────

  List<_Sale> get _filteredSales {
    final now = DateTime.now();
    return _mockSales.where((s) {
      switch (_range) {
        case _TimeRange.day:
          return s.date.year == now.year &&
              s.date.month == now.month &&
              s.date.day == now.day;
        case _TimeRange.week:
          return now.difference(s.date).inDays < 7 && s.date.isBefore(now);
        case _TimeRange.month:
          return now.difference(s.date).inDays < 30 && s.date.isBefore(now);
        case _TimeRange.year:
          return now.difference(s.date).inDays < 365 && s.date.isBefore(now);
        case _TimeRange.all:
          return true;
      }
    }).toList();
  }

  double get _totalRevenue =>
      _filteredSales.fold(0.0, (s, e) => s + e.revenue);
  double get _totalCost => _filteredSales.fold(0.0, (s, e) => s + e.cost);
  double get _totalProfit => _totalRevenue - _totalCost;
  double get _margin =>
      _totalRevenue > 0 ? (_totalProfit / _totalRevenue * 100) : 0;
  int get _orderCount => _filteredSales.length;
  double get _avgOrder => _orderCount > 0 ? _totalRevenue / _orderCount : 0;

  // ── Chart bars ─────────────────────────────────────────────

  List<_ChartBar> get _chartBars {
    final now = DateTime.now();
    final sales = _filteredSales;

    switch (_range) {
      case _TimeRange.day:
        final labels = ['6–12h', '12–18h', '18–24h', '0–6h'];
        final slots = List.generate(4, (_) => <_Sale>[]);
        for (final s in sales) {
          final h = s.date.hour;
          if (h >= 6 && h < 12) {
            slots[0].add(s);
          } else if (h >= 12 && h < 18) {
            slots[1].add(s);
          } else if (h >= 18) {
            slots[2].add(s);
          } else {
            slots[3].add(s);
          }
        }
        return List.generate(
            4,
            (i) => _ChartBar(
                  label: labels[i],
                  revenue: slots[i].fold(0.0, (a, b) => a + b.revenue),
                  profit: slots[i].fold(0.0, (a, b) => a + b.profit),
                ));

      case _TimeRange.week:
        final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final slots = List.generate(7, (_) => <_Sale>[]);
        for (final s in sales) {
          slots[s.date.weekday - 1].add(s);
        }
        return List.generate(
            7,
            (i) => _ChartBar(
                  label: labels[i],
                  revenue: slots[i].fold(0.0, (a, b) => a + b.revenue),
                  profit: slots[i].fold(0.0, (a, b) => a + b.profit),
                ));

      case _TimeRange.month:
        final labels = ['W1', 'W2', 'W3', 'W4'];
        final slots = List.generate(4, (_) => <_Sale>[]);
        for (final s in sales) {
          final w = (now.difference(s.date).inDays / 7).floor().clamp(0, 3);
          slots[3 - w].add(s);
        }
        return List.generate(
            4,
            (i) => _ChartBar(
                  label: labels[i],
                  revenue: slots[i].fold(0.0, (a, b) => a + b.revenue),
                  profit: slots[i].fold(0.0, (a, b) => a + b.profit),
                ));

      case _TimeRange.year:
      case _TimeRange.all:
        const ml = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        final slots = List.generate(12, (_) => <_Sale>[]);
        for (final s in sales) {
          slots[s.date.month - 1].add(s);
        }
        return List.generate(
            12,
            (i) => _ChartBar(
                  label: ml[i],
                  revenue: slots[i].fold(0.0, (a, b) => a + b.revenue),
                  profit: slots[i].fold(0.0, (a, b) => a + b.profit),
                ));
    }
  }

  // ── Category breakdown ─────────────────────────────────────

  List<MapEntry<String, double>> get _categoryBreakdown {
    final map = <String, double>{};
    for (final s in _filteredSales) {
      map[s.category] = (map[s.category] ?? 0) + s.revenue;
    }
    return map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  Color _categoryColor(String cat) => switch (cat) {
        'Ceramic' => AppColors.accent,
        'Furniture' => AppColors.ink,
        'Lighting' => AppColors.gold,
        'Textiles' => AppColors.sage,
        _ => AppColors.muted,
      };

  // ── Product performance ────────────────────────────────────

  List<_ProductPerf> get _productPerformance {
    final map = <String, _ProductPerf>{};
    for (final s in _filteredSales) {
      final ex = map[s.productId];
      map[s.productId] = _ProductPerf(
        productId: s.productId,
        name: s.productName,
        category: s.category,
        unitsSold: (ex?.unitsSold ?? 0) + 1,
        totalRevenue: (ex?.totalRevenue ?? 0) + s.revenue,
        totalCost: (ex?.totalCost ?? 0) + s.cost,
      );
    }
    return map.values.toList()
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
  }

  // ── Product profitability (all time) ───────────────────────

  List<_ProductProfit> get _productProfitability {
    final salesByProduct = <String, List<_Sale>>{};
    for (final s in _mockSales) {
      salesByProduct.putIfAbsent(s.productId, () => []).add(s);
    }
    final results = <_ProductProfit>[];
    for (final p in mockProducts) {
      if (p.costPrice == null) continue;
      final cpu = _parsePrice(p.costPrice!);
      final sp = _parsePrice(p.price);
      final sales = salesByProduct[p.id] ?? [];
      final sold = sales.length;
      final totalUnits = p.stock + sold;
      final investment = cpu * totalUnits;
      final rev = sales.fold(0.0, (sum, s) => sum + s.revenue);
      results.add(_ProductProfit(
        name: p.name,
        category: p.category ?? '',
        imageColor: p.images.isNotEmpty ? p.images.first : AppColors.muted2,
        costPerUnit: cpu,
        salePrice: sp,
        stock: p.stock,
        unitsSold: sold,
        totalInvestment: investment,
        totalRevenue: rev,
        profit: rev - investment,
        breakEvenProgress:
            investment > 0 ? (rev / investment).clamp(0.0, 2.0) : 0.0,
        marginPerUnit: sp > 0 ? ((sp - cpu) / sp * 100) : 0,
      ));
    }
    results.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    return results;
  }

  // ── Section header helper ──────────────────────────────────

  Widget _sectionHeader(String number, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
            text: '№ $number',
            style: GoogleFonts.fraunces(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: AppColors.gold,
              height: 1.3,
            ),
          ),
          TextSpan(
            text: ' — $title',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.muted,
              height: 1.3,
            ),
          ),
        ]),
      ),
    );
  }

  static const _divider = Padding(
    padding: EdgeInsets.symmetric(horizontal: 24),
    child: Divider(color: AppColors.hairline, height: 1),
  );

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: const SharedAppBar(currentRoute: '/dashboard'),
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── A) Header ──
            FadeTransition(
              opacity: _fade(0.0, 0.40),
              child: SlideTransition(
                position: _slide(0.0, 0.40),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Dashboard',
                        style: GoogleFonts.fraunces(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: AppColors.inkStrong,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _range.label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── B) Time range chips ──
            FadeTransition(
              opacity: _fade(0.04, 0.42),
              child: SlideTransition(
                position: _slide(0.04, 0.42),
                child: SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: _TimeRange.values.map((r) {
                      final active = r == _range;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _range = r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.ink
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: active
                                    ? AppColors.ink
                                    : AppColors.hairline,
                              ),
                            ),
                            child: Text(
                              r.label,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: active
                                    ? AppColors.bone
                                    : AppColors.inkSoft,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── C) Hero revenue number ──
            FadeTransition(
              opacity: _fade(0.07, 0.47),
              child: SlideTransition(
                position: _slide(0.07, 0.47),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fmtCur(_totalRevenue),
                        style: GoogleFonts.fraunces(
                          fontSize: 38,
                          fontWeight: FontWeight.w400,
                          color: AppColors.inkStrong,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total revenue',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── D) Stats row ──
            FadeTransition(
              opacity: _fade(0.11, 0.51),
              child: SlideTransition(
                position: _slide(0.11, 0.51),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCol(
                            value: _fmtCur(_totalProfit),
                            label: 'Profit',
                            sub: '${_margin.toStringAsFixed(1)}%',
                          ),
                        ),
                        _vDiv,
                        Expanded(
                          child: _StatCol(
                            value: '$_orderCount',
                            label: 'Orders',
                          ),
                        ),
                        _vDiv,
                        Expanded(
                          child: _StatCol(
                            value: _fmtCur(_avgOrder),
                            label: 'Avg. order',
                          ),
                        ),
                        _vDiv,
                        Expanded(
                          child: _StatCol(
                            value: _fmtCur(_totalCost),
                            label: 'Costs',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),
            _divider,

            // ── E) №01 — Revenue & Profit chart ──
            FadeTransition(
              opacity: _fade(0.16, 0.56),
              child: SlideTransition(
                position: _slide(0.16, 0.56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('01', 'Revenue & Profit'),
                    const SizedBox(height: 10),
                    // Legend
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text('Revenue',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: AppColors.muted)),
                          const SizedBox(width: 16),
                          Container(
                            width: 10,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: AppColors.sage,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text('Profit',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Chart
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 200,
                        child: CustomPaint(
                          size: const Size(double.infinity, 200),
                          painter: _BarChartPainter(
                            bars: _chartBars,
                            barColor:
                                AppColors.accent.withValues(alpha: 0.55),
                            lineColor: AppColors.sage,
                            gridColor:
                                AppColors.hairline.withValues(alpha: 0.6),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 9,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),
            _divider,

            // ── F) №02 — By Category ──
            FadeTransition(
              opacity: _fade(0.22, 0.62),
              child: SlideTransition(
                position: _slide(0.22, 0.62),
                child: _buildCategories(),
              ),
            ),

            const SizedBox(height: 28),
            _divider,

            // ── G) №03 — Top Products ──
            FadeTransition(
              opacity: _fade(0.28, 0.68),
              child: SlideTransition(
                position: _slide(0.28, 0.68),
                child: _buildTopProducts(),
              ),
            ),

            const SizedBox(height: 28),
            _divider,

            // ── H) №04 — Inventory & Profit ──
            FadeTransition(
              opacity: _fade(0.34, 0.74),
              child: SlideTransition(
                position: _slide(0.34, 0.74),
                child: _buildInventory(),
              ),
            ),

            const SizedBox(height: 28),
            _divider,

            // ── I) №05 — Recent Sales ──
            FadeTransition(
              opacity: _fade(0.40, 0.80),
              child: SlideTransition(
                position: _slide(0.40, 0.80),
                child: _buildRecent(),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // ── Vertical divider ───────────────────────────────────────

  static final _vDiv = Container(
    width: 1,
    color: AppColors.hairline,
    margin: const EdgeInsets.symmetric(vertical: 4),
  );

  // ── Categories section ─────────────────────────────────────

  Widget _buildCategories() {
    final cats = _categoryBreakdown;
    final total = _totalRevenue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('02', 'By Category'),
        const SizedBox(height: 18),
        if (cats.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Text('No sales in this period',
                style:
                    GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
          )
        else
          ...cats.map((e) {
            final pct = total > 0 ? e.value / total : 0.0;
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _categoryColor(e.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 72,
                    child: Text(
                      e.key,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        backgroundColor: AppColors.hairline2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            _categoryColor(e.key).withValues(alpha: 0.65)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 64,
                    child: Text(
                      _fmtCur(e.value),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ── Top products section ───────────────────────────────────

  Widget _buildTopProducts() {
    final products = _productPerformance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('03', 'Top Products'),
        const SizedBox(height: 18),
        if (products.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Text('No sales in this period',
                style:
                    GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
          )
        else ...[
          ...() {
            final pageItems = products
                .skip(_productsPage * _pageSize)
                .take(_pageSize)
                .toList();
            final baseIndex = _productsPage * _pageSize;
            return pageItems.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              final rank = baseIndex + i;
              final margin = p.totalRevenue > 0
                  ? ((p.totalRevenue - p.totalCost) / p.totalRevenue * 100)
                  : 0.0;
              final product =
                  mockProducts.where((m) => m.id == p.productId).toList();
              final color =
                  product.isNotEmpty && product.first.images.isNotEmpty
                      ? product.first.images.first
                      : AppColors.muted2;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          // Rank number
                          SizedBox(
                            width: 22,
                            child: Text(
                              '${rank + 1}',
                              style: GoogleFonts.fraunces(
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                color: AppColors.muted2,
                              ),
                            ),
                          ),
                          // Thumbnail
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name + meta
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.inkStrong,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${p.unitsSold} sold · ${p.category}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Revenue + margin
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _fmtCur(p.totalRevenue),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${margin.toStringAsFixed(0)}% margin',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.sage,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (i < pageItems.length - 1)
                      const Divider(
                          color: AppColors.hairline, height: 1, thickness: 1),
                  ],
                ),
              );
            });
          }(),
          if (products.length > _pageSize)
            _paginator(
              page: _productsPage,
              totalPages: (products.length / _pageSize).ceil(),
              onChanged: (p) => setState(() => _productsPage = p),
            ),
        ],
      ],
    );
  }

  // ── Inventory & profit section ─────────────────────────────

  Widget _buildInventory() {
    final items = _productProfitability;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('04', 'Inventory & Profit'),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
          child: Text(
            'Investment vs. revenue per product (all time)',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 16),
        ...() {
          final pageItems = items
              .skip(_inventoryPage * _pageSize)
              .take(_pageSize)
              .toList();
          return pageItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final profitable = item.profit >= 0;
            final progress = item.breakEvenProgress.clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: product name + profit badge
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: item.imageColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.inkStrong,
                                    ),
                                  ),
                                  Text(
                                    '${item.category} · ${_fmtCur(item.costPerUnit)}/unit · ${item.unitsSold} sold · ${item.stock} in stock',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: profitable
                                    ? AppColors.success.withValues(alpha: 0.10)
                                    : AppColors.gold.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                profitable
                                    ? '+${_fmtCur(item.profit)}'
                                    : _fmtCur(item.profit),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: profitable
                                      ? AppColors.success
                                      : AppColors.gold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Row 2: progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: AppColors.hairline2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              profitable ? AppColors.success : AppColors.gold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Row 3: labels
                        Row(
                          children: [
                            Text(
                              'Invested ${_fmtCur(item.totalInvestment)}',
                              style: GoogleFonts.inter(
                                  fontSize: 10, color: AppColors.muted),
                            ),
                            const Spacer(),
                            Text(
                              profitable
                                  ? 'Earned ${_fmtCur(item.totalRevenue)}'
                                  : '${_fmtCur(item.profit.abs())} to break even',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: profitable
                                    ? AppColors.sage
                                    : AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (i < pageItems.length - 1)
                    const Divider(
                        color: AppColors.hairline, height: 1, thickness: 1),
                ],
              ),
            );
          });
        }(),
        if (items.length > _pageSize)
          _paginator(
            page: _inventoryPage,
            totalPages: (items.length / _pageSize).ceil(),
            onChanged: (p) => setState(() => _inventoryPage = p),
          ),
      ],
    );
  }

  // ── Recent sales section ───────────────────────────────────

  Widget _buildRecent() {
    final recent = List<_Sale>.from(_mockSales)
      ..sort((a, b) => b.date.compareTo(a.date));
    final display = recent
        .skip(_recentPage * _pageSize)
        .take(_pageSize)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('05', 'Recent Sales'),
        const SizedBox(height: 18),
        ...display.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final product =
              mockProducts.where((p) => p.id == s.productId).toList();
          final color =
              product.isNotEmpty && product.first.images.isNotEmpty
                  ? product.first.images.first
                  : AppColors.muted2;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.productName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.inkStrong,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.category,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _fmtCur(s.revenue),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkSoft,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _fmtDate(s.date),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (i < display.length - 1)
                  const Divider(
                      color: AppColors.hairline, height: 1, thickness: 1),
              ],
            ),
          );
        }),
        if (recent.length > _pageSize)
          _paginator(
            page: _recentPage,
            totalPages: (recent.length / _pageSize).ceil(),
            onChanged: (p) => setState(() => _recentPage = p),
          ),
      ],
    );
  }

  // ── Pagination controls ───────────────────────────────────

  Widget _paginator({
    required int page,
    required int totalPages,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Back arrow
          GestureDetector(
            onTap: page > 0 ? () => onChanged(page - 1) : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: page > 0 ? AppColors.hairline : AppColors.hairline2,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.chevron_left_rounded,
                size: 16,
                color: page > 0 ? AppColors.inkSoft : AppColors.muted2,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Page indicator
          Text(
            '${page + 1} / $totalPages',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(width: 14),
          // Forward arrow
          GestureDetector(
            onTap: page < totalPages - 1 ? () => onChanged(page + 1) : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: page < totalPages - 1
                      ? AppColors.hairline
                      : AppColors.hairline2,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: page < totalPages - 1
                    ? AppColors.inkSoft
                    : AppColors.muted2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final diff = DateTime.now().difference(dt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${diff}d ago';
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${m[dt.month - 1]}';
  }
}

// ═════════════════════════════════════════════════════════════
// ── Stat column (profile-style) ─────────────────────────────
// ═════════════════════════════════════════════════════════════

class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  final String? sub;

  const _StatCol({required this.value, required this.label, this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppColors.inkStrong,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.muted,
            letterSpacing: 0.3,
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 1),
          Text(
            sub!,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.sage,
            ),
          ),
        ],
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Bar chart painter ───────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _BarChartPainter extends CustomPainter {
  final List<_ChartBar> bars;
  final Color barColor;
  final Color lineColor;
  final Color gridColor;
  final TextStyle labelStyle;

  _BarChartPainter({
    required this.bars,
    required this.barColor,
    required this.lineColor,
    required this.gridColor,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final maxVal = bars.map((b) => b.revenue).fold(0.0, max);
    if (maxVal == 0) return;

    const bottomPad = 24.0;
    const topPad = 12.0;
    final chartH = size.height - bottomPad - topPad;
    final slotW = size.width / bars.length;
    final barW = (slotW * 0.50).clamp(6.0, 28.0);

    // Grid lines (3 subtle lines)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (var i = 1; i <= 3; i++) {
      final y = topPad + chartH * (1 - i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Bars
    final barPaint = Paint()..color = barColor;
    for (var i = 0; i < bars.length; i++) {
      final cx = slotW * i + slotW / 2;
      final h = (bars[i].revenue / maxVal) * chartH;
      if (h > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(
                cx - barW / 2, topPad + chartH - h, barW, h),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          barPaint,
        );
      }

      // Labels
      final tp = TextPainter(
        text: TextSpan(text: bars[i].label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(cx - tp.width / 2, size.height - bottomPad + 8));
    }

    // Profit line
    if (bars.length > 1) {
      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final points = <Offset>[];
      for (var i = 0; i < bars.length; i++) {
        final cx = slotW * i + slotW / 2;
        final h = (bars[i].profit / maxVal) * chartH;
        points.add(Offset(cx, topPad + chartH - h));
      }

      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);

      final dotFill = Paint()..color = lineColor;
      final dotHole = Paint()..color = AppColors.bone;
      for (final p in points) {
        canvas.drawCircle(p, 3, dotFill);
        canvas.drawCircle(p, 1.5, dotHole);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) => bars != old.bars;
}

// ═════════════════════════════════════════════════════════════
// ── Data models ─────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _ProductPerf {
  final String productId;
  final String name;
  final String category;
  final int unitsSold;
  final double totalRevenue;
  final double totalCost;

  const _ProductPerf({
    required this.productId,
    required this.name,
    required this.category,
    required this.unitsSold,
    required this.totalRevenue,
    required this.totalCost,
  });
}

class _ProductProfit {
  final String name;
  final String category;
  final Color imageColor;
  final double costPerUnit;
  final double salePrice;
  final int stock;
  final int unitsSold;
  final double totalInvestment;
  final double totalRevenue;
  final double profit;
  final double breakEvenProgress;
  final double marginPerUnit;

  const _ProductProfit({
    required this.name,
    required this.category,
    required this.imageColor,
    required this.costPerUnit,
    required this.salePrice,
    required this.stock,
    required this.unitsSold,
    required this.totalInvestment,
    required this.totalRevenue,
    required this.profit,
    required this.breakEvenProgress,
    required this.marginPerUnit,
  });
}
