import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../services/leave_service.dart';
import '../../services/payroll_service.dart';
import '../../l10n/app_localizations.dart';

// ── Bar chart painter ──────────────────────────────────────────────────────

class _BarChartPainter extends CustomPainter {
  final List<_Bar> bars;
  final double maxVal;
  _BarChartPainter(this.bars, this.maxVal);

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final n    = bars.length;
    const gap  = 5.0;
    final barW = (size.width - gap * (n + 1)) / n;
    final maxH = size.height - 24.0;

    for (int i = 0; i <= 4; i++) {
      final y = maxH * (1 - i / 4);
      canvas.drawLine(
        Offset(0, y), Offset(size.width, y),
        Paint()..color = AppColors.border..strokeWidth = 1,
      );
    }

    for (int i = 0; i < n; i++) {
      final bar  = bars[i];
      final x    = gap + i * (barW + gap);
      final barH = maxVal > 0 ? (bar.value / maxVal) * maxH : 0.0;
      final y    = maxH - barH;
      final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, barH), const Radius.circular(5));

      final grad = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: bar.highlight
            ? [AppColors.accent, AppColors.accent.withOpacity(0.6)]
            : [AppColors.primary.withOpacity(0.85),
               AppColors.primary.withOpacity(0.45)],
      );

      canvas.drawRRect(rect,
          Paint()..shader = grad.createShader(rect.outerRect));

      if (bar.value > 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${bar.value.toInt()}',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: bar.highlight ? AppColors.accent : AppColors.primary),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        tp.paint(canvas,
            Offset(x + barW / 2 - tp.width / 2, y - tp.height - 2));
      }

      final lp = TextPainter(
        text: TextSpan(
          text: bar.label,
          style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      lp.paint(canvas,
          Offset(x + barW / 2 - lp.width / 2, size.height - lp.height));
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter o) => o.bars != bars;
}

class _Bar {
  final String label;
  final double value;
  final bool highlight;
  const _Bar(this.label, this.value, {this.highlight = false});
}

// ── Donut painter ──────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final List<_Slice> slices;
  _DonutPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r  = math.min(cx, cy) - 6;
    final total = slices.fold(0.0, (s, e) => s + e.value);
    if (total <= 0) return;
    double angle = -math.pi / 2;
    for (final s in slices) {
      final sweep = (s.value / total) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        angle, sweep, false,
        Paint()
          ..color = s.color
          ..strokeWidth = 16
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      angle += sweep + 0.05;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter o) => o.slices != slices;
}

class _Slice {
  final double value;
  final Color color;
  _Slice(this.value, this.color);
}

// ── Dashboard Screen ───────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth       = AuthService();
  final _attendance = AttendanceService();
  final _leave      = LeaveService();
  final _payroll    = PayrollService();

  bool _loading = true;
  int _totalEmp = 0, _present = 0, _late = 0, _absent = 0;
  int _pendingLeave = 0, _pendingPayroll = 0;
  int _casual = 0, _sick = 0, _annual = 0;
  List<_Bar> _bars = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await Future.wait([
        _loadEmployees(),
        _loadAttendance(),
        _loadLeave(),
        _loadPayroll(),
      ]);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadEmployees() async {
    _totalEmp = (await _auth.getAllEmployees()).length;
  }

  Future<void> _loadAttendance() async {
    final today = await _attendance.getAllEmployeesToday();
    _present = today.where((e) => e['status'] == 'Present').length;
    _late    = today.where((e) => e['status'] == 'Late').length;
    _absent  = today.where((e) => e['status'] == 'Absent').length;

    final bars = <_Bar>[];
    final now  = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d  = now.subtract(Duration(days: i));
      final ds = '${d.year}-${d.month.toString().padLeft(2, '0')}'
                 '-${d.day.toString().padLeft(2, '0')}';
      final data = await _attendance.getAllEmployeesToday(date: ds);
      final cnt  = data
          .where((e) => e['status'] == 'Present' || e['status'] == 'Late')
          .length;
      bars.add(_Bar(
        DateFormat('EEE').format(d).substring(0, 2),
        cnt.toDouble(),
        highlight: i == 0,
      ));
    }
    _bars = bars;
  }

  Future<void> _loadLeave() async {
    try {
      final pending = await _leave.getPending();
      _pendingLeave = pending.length;
      _casual = 0; _sick = 0; _annual = 0;
      for (final r in pending) {
        switch (r.leaveType) {
          case 'casual': _casual++; break;
          case 'sick':   _sick++;   break;
          case 'annual': _annual++; break;
        }
      }
    } catch (_) {}
  }

  Future<void> _loadPayroll() async {
    try {
      _pendingPayroll =
          (await _payroll.getAllPayrolls(status: 'pending')).length;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(l)),
                  SliverToBoxAdapter(child: _buildMetrics(l)),
                  SliverToBoxAdapter(child: _buildChart(l)),
                  SliverToBoxAdapter(child: _buildBreakdown(l)),
                  SliverToBoxAdapter(child: _buildLeaveDonut(l)),
                  // REMOVED: _buildQuickActions(l) — no longer shown in dashboard
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  // FIX: Header pills now use Flexible to prevent right overflow

  Widget _buildHeader(AppLocalizations l) {
    final now = DateTime.now();
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(l.hrDashboard,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              Text(DateFormat('EEEE, d MMMM yyyy').format(now),
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12)),
            ]),
          ),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ]),
        const SizedBox(height: 18),
        // FIX: Use IntrinsicHeight + overflow-safe layout for pills row
        Row(children: [
          Expanded(child: _pill(Icons.people_rounded,          '$_totalEmp',     l.totalStaff)),
          const SizedBox(width: 8),
          Expanded(child: _pill(Icons.check_circle_rounded,    '$_present',      l.present)),
          const SizedBox(width: 8),
          Expanded(child: _pill(Icons.pending_actions_rounded, '$_pendingLeave', l.pendingApprovals)),
        ]),
      ]),
    );
  }

  Widget _pill(IconData icon, String val, String lbl) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2))),
    child: Row(children: [
      Icon(icon, color: Colors.white70, size: 16),
      const SizedBox(width: 6),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(val,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.1)),
          Text(lbl,
              style: const TextStyle(color: Colors.white54, fontSize: 9),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    ]),
  );

  // ── Metric cards ─────────────────────────────────────────────────────────

  Widget _buildMetrics(AppLocalizations l) {
    final total = _totalEmp > 0 ? _totalEmp : 1;
    final pct   = ((_present + _late) / total * 100).round();
    final tiles = [
      _Metric(Icons.fingerprint,                    l.attendanceRate,    '$pct%',
          'Attendance today',   AppColors.primary,           pct >= 80),
      _Metric(Icons.event_busy_rounded,             l.absentToday,       '$_absent',
          'Not clocked in',     AppColors.error,             false),
      _Metric(Icons.approval_rounded,               l.pendingApprovals,  '$_pendingLeave',
          'Leave requests',     AppColors.warning,           false),
      _Metric(Icons.account_balance_wallet_rounded, 'Payroll',           '$_pendingPayroll',
          'Pending payslips',   const Color(0xFF8B5CF6),     false),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: tiles.map((t) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x081B4FD8),
                    blurRadius: 12,
                    offset: Offset(0, 3))
              ]),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: t.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(t.icon, color: t.color, size: 18),
              ),
              const Spacer(),
              if (t.good)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('Good',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success))),
            ]),
            const Spacer(),
            Text(t.value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1)),
            const SizedBox(height: 2),
            Text(t.sub,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
          ]),
        )).toList(),
      ),
    );
  }

  // ── Bar chart ─────────────────────────────────────────────────────────────

  Widget _buildChart(AppLocalizations l) {
    final maxV = _bars.isEmpty
        ? 10.0
        : _bars.map((b) => b.value).reduce(math.max).clamp(1.0, double.infinity);

    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(l.weeklyAttendance,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Text('Employees present per day',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8)),
            child: Text(l.thisWeek,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary))),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: _bars.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2))
              : CustomPaint(
                  painter: _BarChartPainter(_bars, maxV),
                  size: const Size(double.infinity, 160)),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _dot(AppColors.primary, 'Regular days'),
          const SizedBox(width: 14),
          _dot(AppColors.accent, 'Today'),
        ]),
      ]),
    );
  }

  // ── Today breakdown ───────────────────────────────────────────────────────

  Widget _buildBreakdown(AppLocalizations l) {
    final total = _totalEmp > 0 ? _totalEmp : 1;
    final rows  = [
      ['Present',  _present,      AppColors.success, Icons.check_circle_rounded],
      ['Late',     _late,         AppColors.warning,  Icons.watch_later_rounded],
      ['Absent',   _absent,       AppColors.error,    Icons.cancel_rounded],
      ['On Leave', _pendingLeave, AppColors.primary,  Icons.beach_access_rounded],
    ];

    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.todayBreakdown,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        Text(DateFormat('EEEE, d MMMM').format(DateTime.now()),
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 14),
        ...rows.map((r) {
          final lbl   = r[0] as String;
          final count = r[1] as int;
          final color = r[2] as Color;
          final icon  = r[3] as IconData;
          final pct   = (count / total).clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(lbl,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
                Text('$count',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color)),
                Text('/$_totalEmp',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(color))),
            ]),
          );
        }),
      ]),
    );
  }

  // ── Leave donut ───────────────────────────────────────────────────────────

  Widget _buildLeaveDonut(AppLocalizations l) {
    final total = (_casual + _sick + _annual).toDouble();
    final slices = total > 0
        ? [
            _Slice(_casual.toDouble(), AppColors.warning),
            _Slice(_sick.toDouble(),   AppColors.error),
            _Slice(_annual.toDouble(), AppColors.primary),
          ]
        : [_Slice(1, AppColors.border)];

    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('Pending Leave by Type',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text('$_pendingLeave pending',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning))),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(painter: _DonutPainter(slices))),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legend(AppColors.warning, l.casualLeave, _casual),
                const SizedBox(height: 8),
                _legend(AppColors.error,   l.sickLeave,   _sick),
                const SizedBox(height: 8),
                _legend(AppColors.primary, l.annualLeave,  _annual),
              ],
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x081B4FD8), blurRadius: 16, offset: Offset(0, 4))
        ]),
    child: child,
  );

  Widget _dot(Color c, String lbl) => Row(children: [
    Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(lbl,
        style: const TextStyle(
            fontSize: 11, color: AppColors.textSecondary)),
  ]);

  Widget _legend(Color c, String lbl, int n) => Row(children: [
    Container(
        width: 12,
        height: 12,
        decoration:
            BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 8),
    Expanded(
        child: Text(lbl,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis)),
    Text('$n',
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: c)),
  ]);
}

// ── Data classes ──────────────────────────────────────────────────────────

class _Metric {
  final IconData icon;
  final String label, value, sub;
  final Color color;
  final bool good;
  const _Metric(this.icon, this.label, this.value, this.sub, this.color,
      this.good);
}
