import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app_colors.dart';
import '../../utils/nepali_date.dart';

Future<DateTime?> showDualDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? labelText,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _DualDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      labelText: labelText,
    ),
  );
}


class _DualDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? labelText;

  const _DualDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.labelText,
  });

  @override
  State<_DualDatePickerDialog> createState() => _DualDatePickerDialogState();
}

class _DualDatePickerDialogState extends State<_DualDatePickerDialog> {
  bool _useNepali = true; // default to Nepali calendar
  late DateTime _selectedAd;

  late NepaliDate _viewMonth;
  late NepaliDate _todayBs;

  @override
  void initState() {
    super.initState();
    _selectedAd = widget.initialDate;
    _todayBs    = NepaliDate.fromDateTime(DateTime.now());
    final selBs = NepaliDate.fromDateTime(_selectedAd);
    _viewMonth  = NepaliDate(selBs.year, selBs.month, 1);
  }


  void _prevMonth() => setState(() => _viewMonth = _viewMonth.prevMonth);
  void _nextMonth() => setState(() => _viewMonth = _viewMonth.nextMonth);


  bool _isSelectable(DateTime ad) =>
      !ad.isBefore(widget.firstDate) && !ad.isAfter(widget.lastDate);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;


  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildCalendarToggle(),
            _useNepali ? _buildNepaliCalendar() : _buildEnglishCalendar(),
            _buildActions(),
          ],
        ),
      ),
    );
  }


  Widget _buildHeader() {
    final bs = NepaliDate.fromDateTime(_selectedAd);
    final adFmt = DateFormat('EEE, d MMM yyyy').format(_selectedAd);
    final bsFmt =
        '${bs.monthNameEnglish} ${bs.day}, ${bs.year} BS';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (widget.labelText != null)
          Text(widget.labelText!,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
        if (widget.labelText != null) const SizedBox(height: 4),
        Text(adFmt,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        Text(bsFmt,
            style: const TextStyle(
                color: Colors.white60, fontSize: 13)),
      ]),
    );
  }


  Widget _buildCalendarToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border)),
        child: Row(children: [
          _toggleBtn('नेपाली (BS)', true),
          _toggleBtn('English (AD)', false),
        ]),
      ),
    );
  }

  Widget _toggleBtn(String label, bool isNepali) {
    final selected = _useNepali == isNepali;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _useNepali = isNepali),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildNepaliCalendar() {
    final firstAdOfMonth = NepaliDate.toDateTime(
        NepaliDate(_viewMonth.year, _viewMonth.month, 1));
    final startWeekday = firstAdOfMonth.weekday % 7; // Sun=0 … Sat=6
    final daysInMonth  = _viewMonth.daysInMonth;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      child: Column(children: [
        // Month navigation
        _monthNav(
          label: '${_viewMonth.monthNameEnglish} ${_viewMonth.year} BS',
          subLabel: DateFormat('MMM yyyy').format(firstAdOfMonth),
          onPrev: _prevMonth,
          onNext: _nextMonth,
        ),
        const SizedBox(height: 10),
        // Weekday headers
        Row(
          children: NepaliDate.weekDaysEnglish.map((d) => Expanded(
            child: Center(
              child: Text(d,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 6),
        // Day grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, childAspectRatio: 1),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (_, i) {
            if (i < startWeekday) return const SizedBox();
            final bsDay  = i - startWeekday + 1;
            final adDate = NepaliDate.toDateTime(
                NepaliDate(_viewMonth.year, _viewMonth.month, bsDay));
            final selectable = _isSelectable(adDate);
            final isSelected = _isSameDay(adDate, _selectedAd);
            final isToday    = _viewMonth.year == _todayBs.year &&
                               _viewMonth.month == _todayBs.month &&
                               bsDay == _todayBs.day;

            return GestureDetector(
              onTap: selectable
                  ? () => setState(() => _selectedAd = adDate)
                  : null,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isToday
                          ? AppColors.primary.withOpacity(0.12)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$bsDay',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : selectable
                              ? (isToday ? AppColors.primary : AppColors.textPrimary)
                              : AppColors.textSecondary.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ]),
    );
  }


  Widget _buildEnglishCalendar() {
    // Inline mini-calendar for English
    final firstOfMonth = DateTime(_selectedAd.year, _selectedAd.month, 1);
    final daysInMonth  = DateUtils.getDaysInMonth(
        _selectedAd.year, _selectedAd.month);
    final startWeekday = firstOfMonth.weekday % 7; // Sun=0
    const weekDays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      child: Column(children: [
        _monthNav(
          label: DateFormat('MMMM yyyy').format(firstOfMonth),
          onPrev: () => setState(() {
            final prev = DateTime(_selectedAd.year, _selectedAd.month - 1);
            _selectedAd = DateTime(prev.year, prev.month,
                _selectedAd.day.clamp(1,
                    DateUtils.getDaysInMonth(prev.year, prev.month)));
          }),
          onNext: () => setState(() {
            final next = DateTime(_selectedAd.year, _selectedAd.month + 1);
            _selectedAd = DateTime(next.year, next.month,
                _selectedAd.day.clamp(1,
                    DateUtils.getDaysInMonth(next.year, next.month)));
          }),
        ),
        const SizedBox(height: 10),
        Row(
          children: weekDays.map((d) => Expanded(
            child: Center(
              child: Text(d,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, childAspectRatio: 1),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (_, i) {
            if (i < startWeekday) return const SizedBox();
            final day    = i - startWeekday + 1;
            final adDate = DateTime(_selectedAd.year, _selectedAd.month, day);
            final selectable = _isSelectable(adDate);
            final isSelected = _isSameDay(adDate, _selectedAd);
            final isToday    = _isSameDay(adDate, DateTime.now());

            return GestureDetector(
              onTap: selectable
                  ? () => setState(() => _selectedAd = adDate)
                  : null,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isToday
                          ? AppColors.primary.withOpacity(0.12)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : selectable
                              ? (isToday ? AppColors.primary : AppColors.textPrimary)
                              : AppColors.textSecondary.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ]),
    );
  }


  Widget _monthNav({
    required String label,
    String? subLabel,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    return Row(children: [
      IconButton(
        onPressed: onPrev,
        icon: const Icon(Icons.chevron_left_rounded),
        color: AppColors.primary,
        iconSize: 22,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
      Expanded(
        child: Column(children: [
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          if (subLabel != null)
            Text(subLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ),
      IconButton(
        onPressed: onNext,
        icon: const Icon(Icons.chevron_right_rounded),
        color: AppColors.primary,
        iconSize: 22,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    ]);
  }


  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Cancel',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () => Navigator.pop(context, _selectedAd),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Select',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}


class DualDateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  const DualDateField({
    super.key,
    required this.label,
    required this.date,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bs    = NepaliDate.fromDateTime(date);
    final adFmt = DateFormat('dd MMM yyyy').format(date);
    final bsFmt = '${bs.day} ${bs.monthNameEnglish} ${bs.year} BS';

    return GestureDetector(
      onTap: () async {
        final picked = await showDualDatePicker(
          context: context,
          initialDate: date,
          firstDate: firstDate,
          lastDate: lastDate,
          labelText: label,
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3)),
              const SizedBox(height: 2),
              Text(adFmt,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text(bsFmt,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary)),
            ]),
          ),
          const Icon(Icons.arrow_drop_down_rounded,
              color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}
