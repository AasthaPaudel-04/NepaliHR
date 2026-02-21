import 'package:flutter/material.dart';
import '../../models/shift.dart';
import '../../services/shift_service.dart';

class ShiftScreen extends StatefulWidget {
  final String userRole;
  const ShiftScreen({super.key, required this.userRole});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> with SingleTickerProviderStateMixin {
  final ShiftService _shiftService = ShiftService();
  late TabController _tabController;

  List<ShiftModel> _shifts = [];
  List<Map<String, dynamic>> _employeeShifts = [];
  ShiftModel? _myShift;
  bool _isLoading = true;

  bool get isManager => widget.userRole == 'admin' || widget.userRole == 'manager';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: isManager ? 2 : 1, vsync: this);
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
      setState(() { _shifts = shifts; _employeeShifts = empShifts; _isLoading = false; });
    } else {
      final myShift = await _shiftService.getMyShift();
      setState(() { _myShift = myShift; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Management'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: isManager
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Shifts'),
                  Tab(text: 'Assignments'),
                ],
              )
            : null,
      ),
      floatingActionButton: isManager
          ? FloatingActionButton(
              backgroundColor: Colors.teal,
              onPressed: _showCreateShiftDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isManager
              ? TabBarView(
                  controller: _tabController,
                  children: [_buildShiftsList(), _buildEmployeeShiftsList()],
                )
              : _buildMyShift(),
    );
  }

  Widget _buildMyShift() {
    if (_myShift == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No shift assigned', style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text('Contact your manager to assign a shift'),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.access_time, size: 60, color: Colors.teal),
                ),
                const SizedBox(height: 20),
                Text(
                  _myShift!.shiftName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _myShift!.timeRange,
                  style: TextStyle(fontSize: 20, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Grace Period: ${_myShift!.gracePeriodMinutes} minutes',
                    style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w500),
                  ),
                ),
                if (_myShift!.effectiveFrom != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Effective from: ${_myShift!.effectiveFrom!.day}/${_myShift!.effectiveFrom!.month}/${_myShift!.effectiveFrom!.year}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShiftsList() {
    if (_shifts.isEmpty) {
      return const Center(child: Text('No shifts created yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _shifts.length,
      itemBuilder: (context, index) {
        final shift = _shifts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: shift.isActive ? Colors.teal.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.access_time,
                color: shift.isActive ? Colors.teal : Colors.grey),
            ),
            title: Text(shift.shiftName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(shift.timeRange),
                Text('Grace: ${shift.gracePeriodMinutes} mins • ${shift.assignedCount ?? 0} employees'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!shift.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Inactive', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _showEditShiftDialog(shift);
                    if (value == 'delete') _confirmDelete(shift);
                    if (value == 'toggle') _toggleShift(shift);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(shift.isActive ? 'Deactivate' : 'Activate'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmployeeShiftsList() {
    if (_employeeShifts.isEmpty) {
      return const Center(child: Text('No employees found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _employeeShifts.length,
      itemBuilder: (context, index) {
        final emp = _employeeShifts[index];
        final hasShift = emp['shift_name'] != null;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              child: Text(
                (emp['full_name'] as String? ?? '?')[0].toUpperCase(),
                style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(emp['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              hasShift
                  ? '${emp['shift_name']} (${emp['start_time']} - ${emp['end_time']})'
                  : 'No shift assigned',
              style: TextStyle(color: hasShift ? null : Colors.orange),
            ),
            trailing: TextButton(
              onPressed: () => _showAssignShiftDialog(emp),
              child: Text(hasShift ? 'Change' : 'Assign',
                style: const TextStyle(color: Colors.teal)),
            ),
          ),
        );
      },
    );
  }

  void _showCreateShiftDialog() {
    _showShiftDialog();
  }

  void _showEditShiftDialog(ShiftModel shift) {
    _showShiftDialog(existing: shift);
  }

  void _showShiftDialog({ShiftModel? existing}) {
    final nameController = TextEditingController(text: existing?.shiftName ?? '');
    final startController = TextEditingController(text: existing?.startTime ?? '09:00');
    final endController = TextEditingController(text: existing?.endTime ?? '17:00');
    final graceController = TextEditingController(
        text: existing?.gracePeriodMinutes.toString() ?? '15');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Create Shift' : 'Edit Shift'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Shift Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: startController,
                decoration: const InputDecoration(labelText: 'Start Time (HH:MM)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endController,
                decoration: const InputDecoration(labelText: 'End Time (HH:MM)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: graceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Grace Period (minutes)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              Map<String, dynamic> result;
              if (existing == null) {
                result = await _shiftService.createShift(
                  shiftName: nameController.text.trim(),
                  startTime: startController.text.trim(),
                  endTime: endController.text.trim(),
                  gracePeriod: int.tryParse(graceController.text) ?? 15,
                );
              } else {
                result = await _shiftService.updateShift(existing.id, {
                  'shift_name': nameController.text.trim(),
                  'start_time': startController.text.trim(),
                  'end_time': endController.text.trim(),
                  'grace_period_minutes': int.tryParse(graceController.text) ?? 15,
                });
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['success'] ? (result['message'] ?? 'Done') : (result['error'] ?? 'Failed')),
                    backgroundColor: result['success'] ? Colors.green : Colors.red,
                  ),
                );
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
        title: const Text('Delete Shift'),
        content: Text('Delete "${shift.shiftName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await _shiftService.deleteShift(shift.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? result['error'] ?? '')));
        if (result['success']) _load();
      }
    }
  }

  void _showAssignShiftDialog(Map<String, dynamic> emp) {
    ShiftModel? selectedShift;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Assign Shift to ${emp['full_name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _shifts
                .where((s) => s.isActive)
                .map((shift) => RadioListTile<ShiftModel>(
                      value: shift,
                      groupValue: selectedShift,
                      title: Text(shift.shiftName),
                      subtitle: Text(shift.timeRange),
                      activeColor: Colors.teal,
                      onChanged: (v) => setS(() => selectedShift = v),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: selectedShift == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final today = DateTime.now();
                      final result = await _shiftService.assignShift(
                        employeeId: emp['employee_id'],
                        shiftId: selectedShift!.id,
                        effectiveFrom:
                            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['success'] ? 'Shift assigned!' : (result['error'] ?? 'Failed')),
                            backgroundColor: result['success'] ? Colors.green : Colors.red,
                          ),
                        );
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
}