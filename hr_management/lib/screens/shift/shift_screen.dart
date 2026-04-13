import 'package:flutter/material.dart';
import '../../models/shift.dart';
import '../../services/shift_service.dart';
import '../../app_colors.dart';

class ShiftScreen extends StatefulWidget {
  final String userRole;
  const ShiftScreen({super.key, required this.userRole});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen>
    with SingleTickerProviderStateMixin {
  final ShiftService _shiftService = ShiftService();
  late TabController _tabController;

  List<ShiftModel> _shifts = [];
  List<Map<String, dynamic>> _employeeShifts = [];
  ShiftModel? _myShift;
  bool _isLoading = true;

  bool get isManager =>
      widget.userRole == 'admin' || widget.userRole == 'manager';

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: isManager ? 2 : 1, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    if (isManager) {
      final shifts = await _shiftService.getAllShifts();
      final empShifts = await _shiftService.getEmployeeShifts();
      setState(() {
        _shifts = shifts;
        _employeeShifts = empShifts;
        _isLoading = false;
      });
    } else {
      final myShift = await _shiftService.getMyShift();
      setState(() {
        _myShift = myShift;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: isManager
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: _showCreateShiftDialog,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                _buildHeader(),
                if (isManager)
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildShiftsList(),
                        _buildEmployeeShiftsList(),
                      ],
                    ),
                  )
                else
                  Expanded(child: _buildMyShift()),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 56, 20, isManager ? 0.0 : 28.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                const Text('Shift Management',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (isManager)
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14),
              tabs: const [
                Tab(text: 'Shifts'),
                Tab(text: 'Assignments'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMyShift() {
    if (_myShift == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.schedule_rounded,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('No shift assigned',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text('Contact your manager to assign a shift',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x101B4FD8),
                  blurRadius: 24,
                  offset: Offset(0, 4))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.access_time_rounded,
                    size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                _myShift!.shiftName,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _myShift!.timeRange,
                style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Grace Period: ${_myShift!.gracePeriodMinutes} minutes',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (_myShift!.effectiveFrom != null) ...[
                const SizedBox(height: 14),
                Text(
                  'Effective from ${_myShift!.effectiveFrom!.day}/${_myShift!.effectiveFrom!.month}/${_myShift!.effectiveFrom!.year}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShiftsList() {
    if (_shifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.schedule_rounded,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('No shifts created yet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _shifts.length,
      itemBuilder: (_, i) {
        final shift = _shifts[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x081B4FD8),
                  blurRadius: 8,
                  offset: Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: shift.isActive
                      ? AppColors.primary.withOpacity(0.08)
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.access_time_rounded,
                    color: shift.isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shift.shiftName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text(shift.timeRange,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    Text(
                      'Grace: ${shift.gracePeriodMinutes} min • ${shift.assignedCount ?? 0} employees',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (!shift.isActive)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Inactive',
                      style: TextStyle(
                          color: AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textSecondary, size: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'edit') _showEditShiftDialog(shift);
                  if (v == 'delete') _confirmDelete(shift);
                  if (v == 'toggle') _toggleShift(shift);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(shift.isActive ? 'Deactivate' : 'Activate'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmployeeShiftsList() {
    if (_employeeShifts.isEmpty) {
      return const Center(
          child: Text('No employees found',
              style: TextStyle(color: AppColors.textSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _employeeShifts.length,
      itemBuilder: (_, i) {
        final emp = _employeeShifts[i];
        final hasShift = emp['shift_name'] != null;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x081B4FD8),
                  blurRadius: 8,
                  offset: Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  (emp['full_name'] as String? ?? '?')[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emp['full_name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                    Text(
                      hasShift
                          ? '${emp['shift_name']} (${emp['start_time']} – ${emp['end_time']})'
                          : 'No shift assigned',
                      style: TextStyle(
                          color: hasShift
                              ? AppColors.textSecondary
                              : AppColors.warning,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showAssignShiftDialog(emp),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Text(
                    hasShift ? 'Change' : 'Assign',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateShiftDialog() => _showShiftDialog();
  void _showEditShiftDialog(ShiftModel shift) =>
      _showShiftDialog(existing: shift);

  void _showShiftDialog({ShiftModel? existing}) {
    final nameCtrl =
        TextEditingController(text: existing?.shiftName ?? '');
    final startCtrl =
        TextEditingController(text: existing?.startTime ?? '09:00');
    final endCtrl =
        TextEditingController(text: existing?.endTime ?? '17:00');
    final graceCtrl = TextEditingController(
        text: existing?.gracePeriodMinutes.toString() ?? '15');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? 'Create Shift' : 'Edit Shift',
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameCtrl, 'Shift Name'),
              const SizedBox(height: 12),
              _dialogField(startCtrl, 'Start Time (HH:MM)'),
              const SizedBox(height: 12),
              _dialogField(endCtrl, 'End Time (HH:MM)'),
              const SizedBox(height: 12),
              _dialogField(graceCtrl, 'Grace Period (minutes)',
                  keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              Map<String, dynamic> result;
              if (existing == null) {
                result = await _shiftService.createShift(
                  shiftName: nameCtrl.text.trim(),
                  startTime: startCtrl.text.trim(),
                  endTime: endCtrl.text.trim(),
                  gracePeriod: int.tryParse(graceCtrl.text) ?? 15,
                );
              } else {
                result = await _shiftService.updateShift(existing.id, {
                  'shift_name': nameCtrl.text.trim(),
                  'start_time': startCtrl.text.trim(),
                  'end_time': endCtrl.text.trim(),
                  'grace_period_minutes':
                      int.tryParse(graceCtrl.text) ?? 15,
                });
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['success']
                      ? (result['message'] ?? 'Done')
                      : (result['error'] ?? 'Failed')),
                  backgroundColor: result['success']
                      ? AppColors.success
                      : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
                if (result['success']) _load();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleShift(ShiftModel shift) async {
    await _shiftService.updateShift(shift.id, {'is_active': !shift.isActive});
    _load();
  }

  Future<void> _confirmDelete(ShiftModel shift) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Shift',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text('Delete "${shift.shiftName}"?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await _shiftService.deleteShift(shift.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(result['message'] ?? result['error'] ?? ''),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
        if (result['success']) _load();
      }
    }
  }

  void _showAssignShiftDialog(Map<String, dynamic> emp) {
    ShiftModel? selected;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Assign Shift — ${emp['full_name']}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _shifts
                .where((s) => s.isActive)
                .map((shift) => RadioListTile<ShiftModel>(
                      value: shift,
                      groupValue: selected,
                      title: Text(shift.shiftName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(shift.timeRange),
                      activeColor: AppColors.primary,
                      onChanged: (v) => setS(() => selected = v),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: selected == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final today = DateTime.now();
                      final result = await _shiftService.assignShift(
                        employeeId: emp['employee_id'],
                        shiftId: selected!.id,
                        effectiveFrom:
                            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(result['success']
                              ? 'Shift assigned!'
                              : (result['error'] ?? 'Failed')),
                          backgroundColor: result['success']
                              ? AppColors.success
                              : AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ));
                        if (result['success']) _load();
                      }
                    },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  TextField _dialogField(TextEditingController c, String label,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}