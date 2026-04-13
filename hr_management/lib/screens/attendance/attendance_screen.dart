import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app_colors.dart';
import '../../models/attendance.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../models/employee.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  final AttendanceService _service = AttendanceService();
  final AuthService _authService = AuthService();

  Employee? _currentUser;
  bool _isAdmin = false;
  bool _isManager = false;

  // Employee vars
  List<Attendance> _monthlyAttendance = [];
  AttendanceSummary? _summary;
  String _filter = 'all';

  // Admin vars
  List<Map<String, dynamic>> _teamToday = [];
  String _adminFilter = 'all';
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = true;
  late TabController _tabController;

  final List<String> _filters = ['all', 'Present', 'Late', 'Absent', 'Half Day', 'WFH'];

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isAdmin = user?.role == 'admin';
        _isManager = user?.role == 'manager';
      });
      if (_isAdmin || _isManager) {
        _tabController = TabController(length: 2, vsync: this);
        _loadAdminToday();
        _loadMyAttendance();
      } else {
        _tabController = TabController(length: 1, vsync: this);
        _loadMyAttendance();
      }
    }
  }

  Future<void> _loadMyAttendance() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final results = await Future.wait([
        _service.getMonthlyAttendance(month: now.month, year: now.year),
        _service.getAttendanceSummary(month: now.month, year: now.year),
      ]);
      if (mounted) {
        setState(() {
          if (results[0]['success']) {
            _monthlyAttendance =
                results[0]['attendance'] as List<Attendance>;
          }
          if (results[1]['success']) {
            _summary = results[1]['summary'] as AttendanceSummary;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAdminToday() async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final data = await _service.getAllEmployeesToday(date: dateStr);
      if (mounted) {
        setState(() {
          _teamToday = data;
        });
      }
    } catch (_) {}
  }

  List<Attendance> get _filteredAttendance {
    if (_filter == 'all') return _monthlyAttendance;
    return _monthlyAttendance.where((a) => a.status == _filter).toList();
  }

  List<Map<String, dynamic>> get _filteredTeam {
    if (_adminFilter == 'all') return _teamToday;
    return _teamToday.where((e) => e['status'] == _adminFilter).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _buildHeader()),
          if (_isAdmin || _isManager)
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.surface,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: _isAdmin ? 'All Employees' : 'Team Today'),
                    const Tab(text: 'My Attendance'),
                  ],
                ),
              ),
            ),
        ],
        body: (_isAdmin || _isManager)
            ? TabBarView(
                controller: _tabController,
                children: [
                  _buildAdminTodayView(),
                  _buildMyAttendanceView(),
                ],
              )
            : _buildMyAttendanceView(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Attendance',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        if (_summary != null) ...[
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _summaryChip('Present', _summary!.presentDays, AppColors.success),
              const SizedBox(width: 8),
              _summaryChip('Late', _summary!.lateDays, AppColors.warning),
              const SizedBox(width: 8),
              _summaryChip('Absent', _summary!.absentDays, AppColors.error),
              const SizedBox(width: 8),
              _summaryChip('Half Day', _summary!.halfDays, AppColors.primary),
              const SizedBox(width: 8),
              _summaryChip('WFH', _summary!.wfhDays, const Color(0xFF8B5CF6)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text('$count',
            style: TextStyle(
                color: color == AppColors.success ? Colors.white : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(
                color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ── Admin / Manager: all employees today
  Widget _buildAdminTodayView() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAdminToday,
      child: Column(children: [
        // Date selector + filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(DateFormat('dd MMM yyyy').format(_selectedDate),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['all', 'Present', 'Late', 'Absent', 'Half Day']
                      .map((f) => _adminFilterChip(f))
                      .toList(),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _teamToday.isEmpty
              ? const Center(
                  child: Text('No data for selected date',
                      style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: _filteredTeam.length,
                  itemBuilder: (_, i) => _buildEmployeeCard(_filteredTeam[i]),
                ),
        ),
      ]),
    );
  }

  Widget _adminFilterChip(String filter) {
    final selected = _adminFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _adminFilter = filter),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(filter == 'all' ? 'All' : filter,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadAdminToday();
    }
  }

  Widget _buildEmployeeCard(Map<String, dynamic> emp) {
    final status = emp['status'] ?? 'Absent';
    Color statusColor;
    switch (status) {
      case 'Present': statusColor = AppColors.success; break;
      case 'Late': statusColor = AppColors.warning; break;
      case 'Absent': statusColor = AppColors.error; break;
      case 'Half Day': statusColor = AppColors.primary; break;
      case 'WFH': statusColor = const Color(0xFF8B5CF6); break;
      default: statusColor = AppColors.textSecondary;
    }

    String checkIn = '--';
    String checkOut = '--';
    if (emp['check_in_time'] != null) {
      try {
        checkIn = DateFormat('hh:mm a')
            .format(DateTime.parse(emp['check_in_time'].toString()).toLocal());
      } catch (_) {}
    }
    if (emp['check_out_time'] != null) {
      try {
        checkOut = DateFormat('hh:mm a')
            .format(DateTime.parse(emp['check_out_time'].toString()).toLocal());
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x081B4FD8), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: statusColor.withOpacity(0.12),
          child: Text(
            (emp['full_name'] as String? ?? '?')[0].toUpperCase(),
            style: TextStyle(
                color: statusColor, fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(emp['full_name'] ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis),
            Text('${emp['position'] ?? ''} · ${emp['department'] ?? ''}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
            if (status != 'Absent') ...[
              const SizedBox(height: 4),
              Row(children: [
                Text('In: $checkIn',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(width: 10),
                Text('Out: $checkOut',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ]),
            ],
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(status,
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11)),
        ),
      ]),
    );
  }

  // ── My Attendance (all roles, second tab for admin/manager)
  Widget _buildMyAttendanceView() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadMyAttendance,
      child: Column(children: [
        // Filter chips
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = _filters[i];
              final selected = _filter == f;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(f == 'all' ? 'All' : f,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.textSecondary)),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _filteredAttendance.isEmpty
                  ? const Center(
                      child: Text('No records',
                          style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: _filteredAttendance.length,
                      itemBuilder: (_, i) =>
                          _buildAttendanceCard(_filteredAttendance[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _buildAttendanceCard(Attendance att) {
    Color statusColor;
    switch (att.status) {
      case 'Present': statusColor = AppColors.success; break;
      case 'Late': statusColor = AppColors.warning; break;
      case 'Absent': statusColor = AppColors.error; break;
      case 'Half Day': statusColor = AppColors.primary; break;
      case 'WFH': statusColor = const Color(0xFF8B5CF6); break;
      default: statusColor = AppColors.textSecondary;
    }

    String checkIn = '--';
    String checkOut = '--';
    if (att.checkInTime != null) {
      try {
        checkIn = DateFormat('hh:mm a')
            .format(DateTime.parse(att.checkInTime!).toLocal());
      } catch (_) {
        checkIn = att.checkInTime!.length >= 5
            ? att.checkInTime!.substring(0, 5)
            : att.checkInTime!;
      }
    }
    if (att.checkOutTime != null) {
      try {
        checkOut = DateFormat('hh:mm a')
            .format(DateTime.parse(att.checkOutTime!).toLocal());
      } catch (_) {
        checkOut = att.checkOutTime!.length >= 5
            ? att.checkOutTime!.substring(0, 5)
            : att.checkOutTime!;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            att.status == 'Absent'
                ? Icons.cancel_outlined
                : Icons.check_circle_outline_rounded,
            color: statusColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(att.date,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary)),
            if (att.status != 'Absent')
              Text('In: $checkIn · Out: $checkOut',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(att.status ?? 'Unknown',
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11)),
          ),
          if (att.totalHours != null && att.totalHours! > 0) ...[
            const SizedBox(height: 3),
            Text('${att.totalHours!.toStringAsFixed(1)}h',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ]),
      ]),
    );
  }
}
