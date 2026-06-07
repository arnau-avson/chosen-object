import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/shared_app_bar.dart';

// ═════════════════════════════════════════════════════════════
// ── Time range ──────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

enum _TimeRange {
  day('Today', 'day'),
  week('7 days', 'week'),
  month('30 days', 'month'),
  year('12 months', 'year'),
  all('All time', 'all');

  final String label;
  final String apiValue;
  const _TimeRange(this.label, this.apiValue);
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

  // API data
  bool _loading = true;
  int _totalRevenueCents = 0;
  int _totalOrders = 0;
  int _totalRentals = 0;
  List<_TopPiece> _topPieces = [];
  List<_RecentSale> _recentSales = [];

  // Pagination
  static const _pageSize = 4;
  int _productsPage = 0;
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
    _fetchDashboard();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── Fetch dashboard data ────────────────────────────────────

  Future<void> _fetchDashboard() async {
    setState(() => _loading = true);
    try {
      final data = await ApiClient.instance.get('/dashboard?range=${_range.apiValue}');
      final map = data as Map<String, dynamic>;
      _totalRevenueCents = (map['total_revenue_cents'] as num?)?.toInt() ?? 0;
      _totalOrders = (map['total_orders'] as num?)?.toInt() ?? 0;
      _totalRentals = (map['total_rentals'] as num?)?.toInt() ?? 0;
      _topPieces = ((map['top_pieces'] as List?) ?? [])
          .map((j) => _TopPiece.fromJson(j as Map<String, dynamic>))
          .toList();
      _recentSales = ((map['recent_sales'] as List?) ?? [])
          .map((j) => _RecentSale.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // keep defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  // ── Helpers ────────────────────────────────────────────────

  String _fmtCents(int cents) {
    final euros = cents / 100;
    if (euros.abs() >= 1000) {
      final whole = euros.toInt();
      final neg = whole < 0;
      final abs = whole.abs().toString();
      final buf = StringBuffer();
      for (var i = 0; i < abs.length; i++) {
        if (i > 0 && (abs.length - i) % 3 == 0) buf.write(',');
        buf.write(abs[i]);
      }
      return neg ? '-\u20AC$buf' : '\u20AC$buf';
    }
    if (euros < 0) return '-\u20AC${euros.abs().toStringAsFixed(2)}';
    return '\u20AC${euros.toStringAsFixed(2)}';
  }


  // ── Section header helper ──────────────────────────────────

  Widget _sectionHeader(String number, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
            text: '\u2116 $number',
            style: GoogleFonts.fraunces(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: AppColors.gold,
              height: 1.3,
            ),
          ),
          TextSpan(
            text: ' \u2014 $title',
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
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
                                onTap: () {
                                  setState(() => _range = r);
                                  _fetchDashboard();
                                },
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
                              _fmtCents(_totalRevenueCents),
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
                                  value: '$_totalOrders',
                                  label: 'Orders',
                                ),
                              ),
                              _vDiv,
                              Expanded(
                                child: _StatCol(
                                  value: '$_totalRentals',
                                  label: 'Rentals',
                                ),
                              ),
                              _vDiv,
                              Expanded(
                                child: _StatCol(
                                  value: '${_topPieces.length}',
                                  label: 'Top pieces',
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

                  // ── E) Top Pieces ──
                  FadeTransition(
                    opacity: _fade(0.22, 0.62),
                    child: SlideTransition(
                      position: _slide(0.22, 0.62),
                      child: _buildTopPieces(),
                    ),
                  ),

                  const SizedBox(height: 28),
                  _divider,

                  // ── F) Recent Sales ──
                  FadeTransition(
                    opacity: _fade(0.34, 0.74),
                    child: SlideTransition(
                      position: _slide(0.34, 0.74),
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

  // ── Top pieces section ───────────────────────────────────

  Widget _buildTopPieces() {
    final pieces = _topPieces;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('01', 'Top Pieces'),
        const SizedBox(height: 18),
        if (pieces.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Text('No data in this period',
                style:
                    GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
          )
        else ...[
          ...() {
            final pageItems = pieces
                .skip(_productsPage * _pageSize)
                .take(_pageSize)
                .toList();
            final baseIndex = _productsPage * _pageSize;
            return pageItems.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              final rank = baseIndex + i;

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
                          // Thumbnail placeholder
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.muted2,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.image_outlined,
                                size: 18, color: AppColors.muted),
                          ),
                          const SizedBox(width: 12),
                          // Name + meta
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title,
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
                                  '${p.ordersCount} orders',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Revenue
                          Text(
                            _fmtCents(p.revenueCents),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkSoft,
                            ),
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
          if (pieces.length > _pageSize)
            _paginator(
              page: _productsPage,
              totalPages: (pieces.length / _pageSize).ceil(),
              onChanged: (p) => setState(() => _productsPage = p),
            ),
        ],
      ],
    );
  }

  // ── Recent sales section ───────────────────────────────────

  Widget _buildRecent() {
    final recent = _recentSales;
    final display = recent
        .skip(_recentPage * _pageSize)
        .take(_pageSize)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('02', 'Recent Sales'),
        const SizedBox(height: 18),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Text('No recent sales',
                style:
                    GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
          )
        else ...[
          ...display.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        // Avatar placeholder
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.muted2,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            s.buyerUsername.isNotEmpty
                                ? s.buyerUsername[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.buyerUsername,
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
                                'Order #${s.orderId}',
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
                              _fmtCents(s.totalCents),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _fmtDate(s.createdAt),
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
// ── Stat column ─────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _StatCol extends StatelessWidget {
  final String value;
  final String label;

  const _StatCol({required this.value, required this.label});

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
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Data models ─────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _TopPiece {
  final int pieceId;
  final String title;
  final int revenueCents;
  final int ordersCount;

  const _TopPiece({
    required this.pieceId,
    required this.title,
    required this.revenueCents,
    required this.ordersCount,
  });

  factory _TopPiece.fromJson(Map<String, dynamic> j) => _TopPiece(
        pieceId: (j['piece_id'] as num?)?.toInt() ?? 0,
        title: (j['title'] as String?) ?? 'Untitled',
        revenueCents: (j['revenue_cents'] as num?)?.toInt() ?? 0,
        ordersCount: (j['orders_count'] as num?)?.toInt() ?? 0,
      );
}

class _RecentSale {
  final int orderId;
  final String buyerUsername;
  final int totalCents;
  final DateTime createdAt;

  const _RecentSale({
    required this.orderId,
    required this.buyerUsername,
    required this.totalCents,
    required this.createdAt,
  });

  factory _RecentSale.fromJson(Map<String, dynamic> j) => _RecentSale(
        orderId: (j['order_id'] as num?)?.toInt() ?? 0,
        buyerUsername: (j['buyer_username'] as String?) ?? 'Unknown',
        totalCents: (j['total_cents'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
