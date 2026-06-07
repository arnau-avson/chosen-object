import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/rental_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/shared_app_bar.dart';
import '../orders/orders_screen.dart';

// ═════════════════════════════════════════════════════════════
// ── Rental Calendar Screen ──────────────────────────────────
// ═════════════════════════════════════════════════════════════

class RentalCalendarScreen extends StatefulWidget {
  const RentalCalendarScreen({super.key});

  @override
  State<RentalCalendarScreen> createState() => _RentalCalendarScreenState();
}

class _RentalCalendarScreenState extends State<RentalCalendarScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late DateTime _focusMonth;
  bool _weekly = false;
  int _weekIndex = 0;
  bool _blockMode = false;
  late Set<String> _blockedKeys; // 'yyyy-mm-dd'
  String _filter = 'All pieces';

  bool _loading = true;
  List<RentalData> _rentals = [];

  // ── Animation helpers ──────────────────────────────────────

  Animation<double> _fade(double s, double e) => CurvedAnimation(
        parent: _anim,
        curve: Interval(s.clamp(0, 1), e.clamp(0, 1), curve: Curves.easeOut),
      );

  Animation<Offset> _slide(double s, double e) =>
      Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _anim,
          curve:
              Interval(s.clamp(0, 1), e.clamp(0, 1), curve: Curves.easeOut),
        ),
      );

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusMonth = DateTime(now.year, now.month);
    _blockedKeys = {};
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fetchRentals();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── Fetch rentals ───────────────────────────────────────────

  Future<void> _fetchRentals() async {
    setState(() => _loading = true);
    await RentalService.instance.fetchRentals(role: 'owner', limit: 100);
    if (mounted) {
      setState(() {
        _rentals = RentalService.instance.rentals;
        _loading = false;
      });
    }
  }

  // ── Date helpers ───────────────────────────────────────────

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inRange(DateTime date, DateTime start, DateTime end) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  bool _isToday(DateTime d) => _sameDay(d, DateTime.now());
  bool _isBlocked(DateTime d) => _blockedKeys.contains(_dayKey(d));

  // ── Filtered rentals ───────────────────────────────────────

  List<RentalData> get _filteredRentals {
    if (_filter == 'All pieces') return _rentals;
    return _rentals.where((r) => r.pieceTitle == _filter).toList();
  }

  List<RentalData> get _pendingRentals =>
      _rentals.where((r) => r.status == 'pending').toList();

  // Get rental info for a specific day
  RentalData? _getRentalForDay(DateTime date) {
    // Non-pending takes priority
    for (final r in _filteredRentals) {
      if (r.status != 'pending' &&
          r.status != 'cancelled' &&
          r.status != 'rejected' &&
          _inRange(date, r.startDate, r.endDate)) {
        return r;
      }
    }
    for (final r in _filteredRentals) {
      if (r.status == 'pending' && _inRange(date, r.startDate, r.endDate)) {
        return r;
      }
    }
    return null;
  }

  // ── Unique product names for filter ────────────────────────

  List<String> get _productNames {
    final names = <String>{};
    for (final r in _rentals) {
      if (r.pieceTitle != null) {
        names.add(r.pieceTitle!);
      }
    }
    return names.toList()..sort();
  }

  // ── Stats ──────────────────────────────────────────────────

  int get _daysRentedThisMonth {
    final y = _focusMonth.year;
    final m = _focusMonth.month;
    final daysInMonth = DateTime(y, m + 1, 0).day;
    int count = 0;
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(y, m, d);
      final r = _getRentalForDay(date);
      if (r != null && r.status != 'pending') count++;
    }
    return count;
  }

  double get _revenueThisMonth {
    final y = _focusMonth.year;
    final m = _focusMonth.month;
    double total = 0;
    for (final r in _filteredRentals) {
      if (r.status == 'pending' || r.status == 'cancelled' || r.status == 'rejected') continue;
      final daysInMonth = DateTime(y, m + 1, 0).day;
      final dailyRate = r.dailyRateCents / 100.0;
      for (var d = 1; d <= daysInMonth; d++) {
        final date = DateTime(y, m, d);
        if (_inRange(date, r.startDate, r.endDate)) {
          total += dailyRate;
        }
      }
    }
    return total;
  }

  int get _avgDuration {
    final confirmed =
        _filteredRentals.where((r) => r.status != 'pending' && r.status != 'cancelled' && r.status != 'rejected');
    if (confirmed.isEmpty) return 0;
    final totalDays = confirmed.fold(0, (s, r) => s + r.days);
    return (totalDays / confirmed.length).round();
  }

  int get _onRentalNow {
    final now = DateTime.now();
    return _filteredRentals
        .where((r) =>
            (r.status == 'approved' || r.status == 'active') &&
            _inRange(now, r.startDate, r.endDate))
        .length;
  }

  String _fmtCur(double val) {
    if (val >= 1000) {
      final abs = val.toInt().toString();
      final buf = StringBuffer();
      for (var i = 0; i < abs.length; i++) {
        if (i > 0 && (abs.length - i) % 3 == 0) buf.write(',');
        buf.write(abs[i]);
      }
      return '\u20AC$buf';
    }
    return '\u20AC${val.toStringAsFixed(0)}';
  }

  // ── Date label for rental ──────────────────────────────────

  String _rentalDateLabel(RentalData r) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    if (r.startDate.month == r.endDate.month) {
      return '${m[r.startDate.month - 1]} ${r.startDate.day}\u2013${r.endDate.day}';
    }
    return '${m[r.startDate.month - 1]} ${r.startDate.day} \u2013 ${m[r.endDate.month - 1]} ${r.endDate.day}';
  }

  // ── Month name ─────────────────────────────────────────────

  String get _monthLabel {
    const m = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${m[_focusMonth.month - 1]} ${_focusMonth.year}';
  }

  // ── Navigation ─────────────────────────────────────────────

  void _prevMonth() => setState(() {
        _focusMonth = DateTime(_focusMonth.year, _focusMonth.month - 1);
        _weekIndex = 0;
      });
  void _nextMonth() => setState(() {
        _focusMonth = DateTime(_focusMonth.year, _focusMonth.month + 1);
        _weekIndex = 0;
      });

  // ── Filter bottom sheet ────────────────────────────────────

  void _showFilterSheet() {
    final options = ['All pieces', ..._productNames];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((o) => ListTile(
                  dense: true,
                  leading: o == _filter
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: AppColors.accent)
                      : const SizedBox(width: 16),
                  title: Text(o,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: o == _filter
                            ? AppColors.accent
                            : AppColors.inkSoft,
                        fontWeight: o == _filter
                            ? FontWeight.w500
                            : FontWeight.w400,
                      )),
                  onTap: () {
                    setState(() => _filter = o);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── Respond to rental ──────────────────────────────────────

  Future<void> _respondToRental(RentalData rental, bool approve) async {
    final result = await RentalService.instance.respondToRental(
      rental.id,
      accept: approve,
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve
              ? '${rental.pieceTitle ?? 'Rental'} approved for ${rental.renterUsername ?? 'renter'}'
              : '${rental.pieceTitle ?? 'Rental'} declined'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchRentals();
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: const SharedAppBar(currentRoute: '/rental-calendar'),
      drawer: const AppDrawer(currentRoute: '/rental-calendar'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── A) Title + controls ──
                  FadeTransition(
                    opacity: _fade(0.0, 0.40),
                    child: SlideTransition(
                      position: _slide(0.0, 0.40),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rental Calendar',
                              style: GoogleFonts.fraunces(
                                fontSize: 28,
                                fontWeight: FontWeight.w400,
                                color: AppColors.inkStrong,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Filter + Block dates
                            Row(
                              children: [
                                // Filter chip
                                GestureDetector(
                                  onTap: _showFilterSheet,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                          color: AppColors.hairline, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _filter,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.inkSoft,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.keyboard_arrow_down_rounded,
                                            size: 16, color: AppColors.muted),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Block dates toggle
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _blockMode = !_blockMode),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _blockMode
                                          ? AppColors.ink
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: _blockMode
                                            ? AppColors.ink
                                            : AppColors.hairline,
                                      ),
                                    ),
                                    child: Text(
                                      'Block dates',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _blockMode
                                            ? AppColors.bone
                                            : AppColors.inkSoft,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // View toggle
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _weekly = !_weekly),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                          color: AppColors.hairline, width: 1),
                                    ),
                                    child: Icon(
                                      _weekly
                                          ? Icons.calendar_month_rounded
                                          : Icons.view_week_rounded,
                                      size: 16,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── B) Month navigation ──
                  FadeTransition(
                    opacity: _fade(0.06, 0.46),
                    child: SlideTransition(
                      position: _slide(0.06, 0.46),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _prevMonth,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.chevron_left_rounded,
                                    size: 22, color: AppColors.inkSoft),
                              ),
                            ),
                            Text(
                              _monthLabel,
                              style: GoogleFonts.fraunces(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: AppColors.inkStrong,
                              ),
                            ),
                            GestureDetector(
                              onTap: _nextMonth,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.chevron_right_rounded,
                                    size: 22, color: AppColors.inkSoft),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── C) Calendar grid ──
                  FadeTransition(
                    opacity: _fade(0.12, 0.52),
                    child: SlideTransition(
                      position: _slide(0.12, 0.52),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _weekly
                            ? _buildWeeklyView(key: ValueKey('w$_weekIndex'))
                            : _buildMonthlyView(key: const ValueKey('monthly')),
                      ),
                    ),
                  ),

                  // ── Week navigation (weekly mode) ──
                  if (_weekly)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _weekIndex > 0
                                ? () => setState(() => _weekIndex--)
                                : null,
                            child: Icon(Icons.chevron_left_rounded,
                                size: 20,
                                color: _weekIndex > 0
                                    ? AppColors.inkSoft
                                    : AppColors.hairline),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Week ${_weekIndex + 1}',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.muted),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _weekIndex < _totalWeeks - 1
                                ? () => setState(() => _weekIndex++)
                                : null,
                            child: Icon(Icons.chevron_right_rounded,
                                size: 20,
                                color: _weekIndex < _totalWeeks - 1
                                    ? AppColors.inkSoft
                                    : AppColors.hairline),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ── D) Legend ──
                  FadeTransition(
                    opacity: _fade(0.18, 0.58),
                    child: SlideTransition(
                      position: _slide(0.18, 0.58),
                      child: _buildLegend(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── E) Stats row ──
                  FadeTransition(
                    opacity: _fade(0.24, 0.64),
                    child: SlideTransition(
                      position: _slide(0.24, 0.64),
                      child: _buildStats(),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child:
                        Divider(color: AppColors.hairline, height: 1, thickness: 1),
                  ),

                  // ── F) Pending requests ──
                  FadeTransition(
                    opacity: _fade(0.30, 0.70),
                    child: SlideTransition(
                      position: _slide(0.30, 0.70),
                      child: _buildPendingRequests(),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child:
                        Divider(color: AppColors.hairline, height: 1, thickness: 1),
                  ),

                  // ── G) Footer link ──
                  FadeTransition(
                    opacity: _fade(0.38, 0.78),
                    child: SlideTransition(
                      position: _slide(0.38, 0.78),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (_, _, _) =>
                                    const OrdersScreen(canGoBack: true),
                                transitionsBuilder: (_, anim, _, child) =>
                                    FadeTransition(opacity: anim, child: child),
                                transitionDuration:
                                    const Duration(milliseconds: 300),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                'View all confirmed rentals',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 15, color: AppColors.inkSoft),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }

  // ── Total weeks in month ───────────────────────────────────

  int get _totalWeeks {
    final y = _focusMonth.year;
    final m = _focusMonth.month;
    final daysInMonth = DateTime(y, m + 1, 0).day;
    final firstWeekday = DateTime(y, m, 1).weekday; // 1=Mon
    return ((firstWeekday - 1 + daysInMonth) / 7).ceil();
  }

  // ── Monthly calendar grid ──────────────────────────────────

  Widget _buildMonthlyView({Key? key}) {
    final y = _focusMonth.year;
    final m = _focusMonth.month;
    final daysInMonth = DateTime(y, m + 1, 0).day;
    final firstWeekday = DateTime(y, m, 1).weekday; // 1=Mon, 7=Sun

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Day-of-week header
          _buildDayHeaders(),
          const SizedBox(height: 6),
          // Day cells
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.05,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            children: [
              // Empty cells before first day
              for (var i = 1; i < firstWeekday; i++) const SizedBox(),
              // Day cells
              for (var d = 1; d <= daysInMonth; d++)
                _buildDayCell(DateTime(y, m, d), d),
            ],
          ),
        ],
      ),
    );
  }

  // ── Weekly calendar view ───────────────────────────────────

  Widget _buildWeeklyView({Key? key}) {
    final y = _focusMonth.year;
    final m = _focusMonth.month;
    final daysInMonth = DateTime(y, m + 1, 0).day;
    final firstWeekday = DateTime(y, m, 1).weekday;

    // Calculate which days fall in the selected week
    final weekDays = <DateTime?>[];
    final startDayNum = _weekIndex * 7 - (firstWeekday - 1) + 1;
    for (var i = 0; i < 7; i++) {
      final d = startDayNum + i;
      if (d >= 1 && d <= daysInMonth) {
        weekDays.add(DateTime(y, m, d));
      } else {
        weekDays.add(null);
      }
    }

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildDayHeaders(),
          const SizedBox(height: 6),
          SizedBox(
            height: 80,
            child: Row(
              children: weekDays.map((date) {
                if (date == null) return const Expanded(child: SizedBox());
                final rental = _getRentalForDay(date);
                final blocked = _isBlocked(date);
                final today = _isToday(date);

                Color bg = Colors.transparent;
                Color textColor = AppColors.inkSoft;
                String? productLabel;

                if (blocked) {
                  bg = AppColors.muted2.withValues(alpha: 0.5);
                  textColor = AppColors.muted;
                } else if (rental != null) {
                  if (rental.status != 'pending') {
                    bg = AppColors.sage.withValues(alpha: 0.25);
                    textColor = AppColors.inkStrong;
                    productLabel = rental.pieceTitle;
                  } else {
                    bg = AppColors.gold.withValues(alpha: 0.12);
                    textColor = AppColors.gold;
                    productLabel = rental.pieceTitle;
                  }
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: _blockMode && rental == null
                        ? () {
                            final k = _dayKey(date);
                            setState(() {
                              if (_blockedKeys.contains(k)) {
                                _blockedKeys.remove(k);
                              } else {
                                _blockedKeys.add(k);
                              }
                            });
                          }
                        : null,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6),
                        border: today
                            ? Border.all(color: AppColors.accent, width: 1.5)
                            : rental?.status == 'pending'
                                ? Border.all(
                                    color: AppColors.gold, width: 1)
                                : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${date.day}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          if (productLabel != null) ...[
                            const SizedBox(height: 4),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Text(
                                productLabel,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: textColor.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                          if (blocked)
                            Icon(Icons.block_rounded,
                                size: 10, color: AppColors.muted),
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
    );
  }

  // ── Day-of-week header row ─────────────────────────────────

  Widget _buildDayHeaders() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: days
          .map((d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  // ── Single day cell ────────────────────────────────────────

  Widget _buildDayCell(DateTime date, int day) {
    final rental = _getRentalForDay(date);
    final blocked = _isBlocked(date);
    final today = _isToday(date);

    Color bg = Colors.transparent;
    Color textColor = AppColors.inkSoft;
    Border? border;

    if (blocked) {
      bg = AppColors.muted2.withValues(alpha: 0.45);
      textColor = AppColors.muted;
    } else if (rental != null) {
      if (rental.status != 'pending') {
        bg = AppColors.sage.withValues(alpha: 0.3);
        textColor = AppColors.inkStrong;
      } else {
        bg = AppColors.gold.withValues(alpha: 0.10);
        textColor = AppColors.gold;
        border = Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1);
      }
    }

    if (today) {
      border = Border.all(color: AppColors.accent, width: 1.5);
    }

    // Determine border radius based on span position
    BorderRadius radius = BorderRadius.circular(6);
    if (rental != null) {
      final isSpanStart =
          _sameDay(date, rental.startDate) || date.weekday == DateTime.monday;
      final isSpanEnd =
          _sameDay(date, rental.endDate) || date.weekday == DateTime.sunday;
      if (isSpanStart && isSpanEnd) {
        radius = BorderRadius.circular(6);
      } else if (isSpanStart) {
        radius = const BorderRadius.horizontal(left: Radius.circular(6));
      } else if (isSpanEnd) {
        radius = const BorderRadius.horizontal(right: Radius.circular(6));
      } else {
        radius = BorderRadius.zero;
      }
    }

    return GestureDetector(
      onTap: _blockMode && rental == null
          ? () {
              final k = _dayKey(date);
              setState(() {
                if (_blockedKeys.contains(k)) {
                  _blockedKeys.remove(k);
                } else {
                  _blockedKeys.add(k);
                }
              });
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: border,
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: today ? FontWeight.w700 : FontWeight.w400,
            color: textColor,
          ),
        ),
      ),
    );
  }

  // ── Legend ──────────────────────────────────────────────────

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _legendDot(AppColors.sage.withValues(alpha: 0.5), 'Confirmed'),
          const SizedBox(width: 16),
          _legendDot(AppColors.gold.withValues(alpha: 0.4), 'Pending',
              bordered: true),
          const SizedBox(width: 16),
          _legendDot(Colors.transparent, 'Available'),
          const SizedBox(width: 16),
          _legendDot(AppColors.muted2.withValues(alpha: 0.5), 'Blocked'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, {bool bordered = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: bordered
                ? Border.all(color: AppColors.gold, width: 1)
                : label == 'Available'
                    ? Border.all(color: AppColors.hairline, width: 1)
                    : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.muted)),
      ],
    );
  }

  // ── Stats row ──────────────────────────────────────────────

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _stat('$_daysRentedThisMonth', 'Days rented', 'this month'),
            _vDiv,
            _stat(_fmtCur(_revenueThisMonth), 'Revenue', 'this month'),
            _vDiv,
            _stat('$_avgDuration days', 'Avg duration', 'per booking'),
            _vDiv,
            _stat('$_onRentalNow', 'On rental', 'now'),
          ],
        ),
      ),
    );
  }

  static final _vDiv = Container(
    width: 1,
    color: AppColors.hairline,
    margin: const EdgeInsets.symmetric(vertical: 4),
  );

  Widget _stat(String value, String label, String sub) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.fraunces(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: AppColors.inkStrong,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.muted,
                  letterSpacing: 0.3)),
          Text(sub,
              style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.muted2)),
        ],
      ),
    );
  }

  // ── Pending requests ───────────────────────────────────────

  Widget _buildPendingRequests() {
    final pending = _pendingRentals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'Pending requests',
                style: GoogleFonts.fraunces(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.inkStrong,
                ),
              ),
              TextSpan(
                text: '  ${pending.length}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gold,
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        if (pending.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text('No pending requests',
                style:
                    GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
          )
        else
          ...pending.map((r) => _PendingCard(
                rental: r,
                dateLabel: _rentalDateLabel(r),
                onApprove: () => _respondToRental(r, true),
                onDecline: () => _respondToRental(r, false),
              )),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Pending request card ────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _PendingCard extends StatelessWidget {
  final RentalData rental;
  final String dateLabel;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  const _PendingCard({
    required this.rental,
    required this.dateLabel,
    required this.onApprove,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product + renter
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.muted2,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_outlined,
                          size: 16, color: AppColors.muted),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rental.pieceTitle ?? 'Untitled piece',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkStrong,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${rental.renterUsername ?? 'Unknown'} \u00B7 $dateLabel',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      rental.totalFormatted,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    _actionBtn(context, 'Decline', Icons.close_rounded,
                        AppColors.danger, onDecline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: onApprove,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Approve',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.bone,
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
          const Divider(
              color: AppColors.hairline, height: 1, thickness: 1),
        ],
      ),
    );
  }

  Widget _actionBtn(
      BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.hairline, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
