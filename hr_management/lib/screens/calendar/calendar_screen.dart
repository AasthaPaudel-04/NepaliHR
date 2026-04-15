import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app_colors.dart';
import '../../utils/nepali_date.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late NepaliDate _viewMonth;
  final DateTime  _todayAd = DateTime.now();
  late NepaliDate _todayBs;
  DateTime? _selected;
  bool _showNepali = true;

  // Simple event map — replace with API data
  final Map<String, List<_Event>> _events = {
    '2025-04-14': [_Event('Nepali New Year', Colors.orange, holiday: true)],
    '2025-04-18': [_Event('Team Meeting', AppColors.primary)],
    '2025-04-22': [_Event('Payroll Day', AppColors.success)],
    '2025-05-01': [_Event('Labour Day', Colors.red, holiday: true)],
  };

  @override
  void initState() {
    super.initState();
    _todayBs  = NepaliDate.fromDateTime(_todayAd);
    _viewMonth = NepaliDate(_todayBs.year, _todayBs.month, 1);
    _selected  = _todayAd;
  }

  List<_Event> _eventsOn(DateTime ad) {
    final k = '${ad.year}-${ad.month.toString().padLeft(2,'0')}-${ad.day.toString().padLeft(2,'0')}';
    return _events[k] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildLangToggle()),
        SliverToBoxAdapter(child: _buildCard()),
        SliverToBoxAdapter(child: _buildSelectedInfo()),
        SliverToBoxAdapter(child: _buildUpcoming()),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final adDate  = NepaliDate.toDateTime(NepaliDate(_viewMonth.year, _viewMonth.month, 1));
    final adLabel = DateFormat('MMMM yyyy').format(adDate);
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_showNepali
              ? '${_viewMonth.monthNameNepali} ${_viewMonth.yearNepali}'
              : adLabel,
              style: const TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w800)),
          Text(_showNepali
              ? '${_viewMonth.monthNameEnglish} ${_viewMonth.year} BS · $adLabel'
              : '${_viewMonth.monthNameNepali} ${_viewMonth.yearNepali} BS',
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ])),
        _navBtn(Icons.chevron_left_rounded,
            () => setState(() => _viewMonth = _viewMonth.prevMonth)),
        const SizedBox(width: 8),
        _navBtn(Icons.chevron_right_rounded,
            () => setState(() => _viewMonth = _viewMonth.nextMonth)),
      ]),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: Colors.white, size: 22)),
  );

  // ── Language toggle ─────────────────────────────────────────────────────────
  Widget _buildLangToggle() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border)),
      child: Row(children: [
        _toggleBtn('नेपाली',  _showNepali,  () => setState(() => _showNepali = true)),
        _toggleBtn('English', !_showNepali, () => setState(() => _showNepali = false)),
      ]),
    ),
  );

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textSecondary)),
      ),
    ),
  );

  // ── Calendar card ───────────────────────────────────────────────────────────
  Widget _buildCard() => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(color: Color(0x0C1B4FD8), blurRadius: 20, offset: Offset(0, 4))
      ]),
    child: Column(children: [
      _buildDayHeaders(),
      const Divider(height: 1, color: AppColors.border),
      _buildGrid(),
    ]),
  );

  Widget _buildDayHeaders() {
    final days = _showNepali
        ? NepaliDate.weekDaysNepali
        : NepaliDate.weekDaysEnglish;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Row(children: List.generate(7, (i) => Expanded(
        child: Center(child: Text(days[i],
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: i == 6 ? AppColors.error : AppColors.textSecondary))),
      ))),
    );
  }

  Widget _buildGrid() {
    final firstAd    = NepaliDate.toDateTime(
        NepaliDate(_viewMonth.year, _viewMonth.month, 1));
    final startCol   = firstAd.weekday % 7; // 0=Sun
    final totalDays  = _viewMonth.daysInMonth;
    final totalCells = startCol + totalDays;
    final rows       = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
      child: Column(children: List.generate(rows, (row) => Row(
        children: List.generate(7, (col) {
          final idx   = row * 7 + col;
          final bsDay = idx - startCol + 1;
          if (bsDay < 1 || bsDay > totalDays) {
            return const Expanded(child: SizedBox(height: 52));
          }
          final adDate = NepaliDate.toDateTime(
              NepaliDate(_viewMonth.year, _viewMonth.month, bsDay));
          return Expanded(child: _buildCell(bsDay, adDate, col));
        }),
      ))),
    );
  }

  Widget _buildCell(int bsDay, DateTime ad, int col) {
    final isToday = ad.year == _todayAd.year &&
        ad.month == _todayAd.month && ad.day == _todayAd.day;
    final isSelected = _selected != null &&
        ad.year == _selected!.year &&
        ad.month == _selected!.month &&
        ad.day == _selected!.day;
    final isSat    = col == 6;
    final evts     = _eventsOn(ad);
    final holiday  = evts.any((e) => e.holiday);

    return GestureDetector(
      onTap: () => setState(() => _selected = ad),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(2),
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary
              : isToday ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isToday && !isSelected
              ? Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5)
              : null),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Large BS number
          Text(
            _showNepali ? NepaliDate.toNepaliNumerals(bsDay) : '$bsDay',
            style: TextStyle(
              fontSize: 15,
              fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? Colors.white
                  : holiday ? AppColors.error
                  : isSat ? AppColors.error.withOpacity(0.7)
                  : AppColors.textPrimary),
          ),
          // Small AD number
          Text(
            _showNepali ? '${ad.day}' : NepaliDate.toNepaliNumerals(bsDay),
            style: TextStyle(
              fontSize: 9,
              color: isSelected ? Colors.white70
                  : AppColors.textSecondary.withOpacity(0.5)),
          ),
          // Event dot
          if (evts.isNotEmpty)
            Container(
              width: 4, height: 4,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white : evts.first.color))
          else
            const SizedBox(height: 5),
        ]),
      ),
    );
  }

  // ── Selected day info ───────────────────────────────────────────────────────
  Widget _buildSelectedInfo() {
    if (_selected == null) return const SizedBox.shrink();
    final ad   = _selected!;
    final bs   = NepaliDate.fromDateTime(ad);
    final evts = _eventsOn(ad);
    final isToday = ad.year == _todayAd.year &&
        ad.month == _todayAd.month && ad.day == _todayAd.day;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isToday ? AppColors.primary.withOpacity(0.3) : AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: isToday ? AppColors.headerGradient : null,
              color: isToday ? null : AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14)),
            child: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${ad.day}', style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: isToday ? Colors.white : AppColors.primary)),
                  Text(DateFormat('MMM').format(ad), style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: isToday ? Colors.white70
                          : AppColors.primary.withOpacity(0.7))),
                ])),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Text(DateFormat('EEEE').format(ad),
                  style: const TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 15, color: AppColors.textPrimary)),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('Today', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: AppColors.primary))),
              ],
            ]),
            Text('${bs.monthNameNepali} ${bs.dayNepali}, ${bs.yearNepali} BS',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text(DateFormat('d MMMM yyyy').format(ad),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ])),
        ]),
        if (evts.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          ...evts.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(color: e.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(e.title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: e.holiday ? AppColors.error : AppColors.textPrimary))),
              if (e.holiday) Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: const Text('Holiday', style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.error))),
            ]),
          )),
        ],
      ]),
    );
  }

  // ── Upcoming events ─────────────────────────────────────────────────────────
  Widget _buildUpcoming() {
    final upcoming = _events.entries
        .map((e) {
          try {
            final p  = e.key.split('-');
            final dt = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
            return MapEntry(dt, e.value);
          } catch (_) { return null; }
        })
        .whereType<MapEntry<DateTime, List<_Event>>>()
        .where((e) => !e.key.isBefore(_todayAd))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Upcoming Events',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        ...upcoming.take(5).map((entry) {
          final dt  = entry.key;
          final bs  = NepaliDate.fromDateTime(dt);
          final evt = entry.value.first;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.surface, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: evt.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Text('${dt.day}', style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14, color: evt.color)),
                  Text(DateFormat('MMM').format(dt), style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w600,
                      color: evt.color.withOpacity(0.7))),
                ])),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(evt.title, style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13,
                    color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                Text('${bs.monthNameNepali} ${bs.dayNepali} BS · ${DateFormat('EEEE').format(dt)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: evt.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(evt.holiday ? 'Holiday' : 'Event',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: evt.color))),
            ]),
          );
        }),
      ]),
    );
  }
}

class _Event {
  final String title;
  final Color color;
  final bool holiday;
  const _Event(this.title, this.color, {this.holiday = false});
}
