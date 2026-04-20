import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/employee.dart';
import '../../models/attendance.dart';
import '../../services/attendance_service.dart';
import '../../services/announcement_service.dart';
import '../../services/notification_service.dart';
import '../../app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_switcher.dart';
import '../leave/apply_leave_screen.dart';
import '../leave/pending_approvals_screen.dart';
import '../leave/leave_type_management_screen.dart';
import '../leave/leave_screen.dart';
import '../shift/shift_screen.dart';
import '../documents/document_screen.dart';
import '../announcements/announcement_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../performance/add_employee_screen.dart';
import '../performance/department_screen.dart';
import '../performance/job_role_screen.dart';
import '../performance/kpi_screen.dart';
import '../performance/evaluation_cycle_screen.dart';
import '../performance/my_evaluations_screen.dart';
import '../performance/performance_results_screen.dart';

class HomeScreen extends StatefulWidget {
  final Employee employee;
  const HomeScreen({super.key, required this.employee});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AttendanceService   _attendanceService   = AttendanceService();
  final AnnouncementService _announcementService = AnnouncementService();
  final NotificationService _notifService        = NotificationService();

  Attendance? todayAttendance;
  Map<String, dynamic>? shiftInfo;
  bool isLoadingAttendance = true;
  bool hasClocked          = false;
  bool isClockingIn        = false;
  int  announcementCount   = 0;
  int  _unreadNotifs       = 0;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
    _loadAnnouncementCount();
    _loadUnreadNotifs();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => isLoadingAttendance = true);
    try {
      final data = await _attendanceService.getTodayAttendance();
      if (mounted) {
        setState(() {
          if (data['success']) {
            hasClocked      = data['hasClocked'];
            todayAttendance = data['attendance'];
            shiftInfo       = data['shift'];
          }
          isLoadingAttendance = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingAttendance = false);
    }
  }

  Future<void> _loadAnnouncementCount() async {
    final count = await _announcementService.getRecentCount();
    if (mounted) setState(() => announcementCount = count);
  }

  Future<void> _loadUnreadNotifs() async {
    final count = await _notifService.getUnreadCount();
    if (mounted) setState(() => _unreadNotifs = count);
  }

  Future<void> _handleClockIn() async {
    setState(() => isClockingIn = true);
    final result = await _attendanceService.clockIn();
    if (mounted) {
      setState(() => isClockingIn = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success'] ? result['message'] : result['error']),
        backgroundColor: result['success'] ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      if (result['success']) _loadAttendanceData();
    }
  }

  Future<void> _handleClockOut() async {
    setState(() => isClockingIn = true);
    final result = await _attendanceService.clockOut();
    if (mounted) {
      setState(() => isClockingIn = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success']
            ? '${result['message']} • ${result['total_hours']} hours'
            : result['error']),
        backgroundColor: result['success'] ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      if (result['success']) _loadAttendanceData();
    }
  }

  bool get isAdmin =>
      widget.employee.role == 'admin' || widget.employee.role == 'manager';

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await _loadAttendanceData();
          await _loadAnnouncementCount();
          await _loadUnreadNotifs();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClockInOutCard(),
                    const SizedBox(height: 24),
                    _buildLeaveSection(),
                    const SizedBox(height: 16),
                    _buildAttendanceSection(),
                    const SizedBox(height: 16),
                    if (isAdmin) _buildEmployeeManagementSection(),
                    if (isAdmin) const SizedBox(height: 16),
                    _buildEvaluationSection(),
                    const SizedBox(height: 16),
                    _buildMoreSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _greeting(l),
              style: const TextStyle(
                  color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 2),
            Text(
              widget.employee.fullName,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                '${widget.employee.position ?? ''} • ${widget.employee.role.toUpperCase()}',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ).then((_) {
            _loadUnreadNotifs();
            _loadAnnouncementCount();
          }),
          child: Stack(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.notifications_rounded,
                  color: Colors.white, size: 22),
            ),
            if (_unreadNotifs > 0)
              Positioned(
                right: 6, top: 6,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                      color: AppColors.warning, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      _unreadNotifs > 9 ? '9+' : '$_unreadNotifs',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 8),
        const LanguageSwitcher(compact: true),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ProfileScreen(employee: widget.employee)),
          ),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.accent, Color(0xFF00A891)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                widget.employee.fullName[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  String _greeting(AppLocalizations l) {
    final h = DateTime.now().hour;
    if (h < 12) return l.goodMorning;
    if (h < 17) return l.goodAfternoon;
    return l.goodEvening;
  }

  // ── Clock In/Out Card ──────────────────────────────────────────────────────

  Widget _buildClockInOutCard() {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x101B4FD8), blurRadius: 24, offset: Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: isLoadingAttendance
            ? const Center(
                child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary)))
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // FIX: Use flexible layout to prevent right overflow
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        DateFormat('EEEE, d MMM').format(DateTime.now()),
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('hh:mm a').format(DateTime.now()),
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1),
                      ),
                    ]),
                  ),
                  if (shiftInfo != null)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.schedule_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '${shiftInfo!['start_time']}–${shiftInfo!['end_time']}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      ),
                    ),
                ]),
                if (hasClocked && todayAttendance != null) ...[
                  const SizedBox(height: 14),
                  _buildAttendanceStatus(),
                ],
                const SizedBox(height: 16),
                _buildClockButton(),
              ]),
      ),
    );
  }

  Widget _buildAttendanceStatus() {
    String formatTime(String? timeStr) {
      if (timeStr == null) return '--';
      try {
        final dt    = DateTime.parse(timeStr);
        final local = dt.isUtc ? dt.toLocal() : dt;
        return DateFormat('hh:mm a').format(local);
      } catch (_) {
        return timeStr.length >= 5 ? timeStr.substring(0, 5) : timeStr;
      }
    }

    final checkIn  = formatTime(todayAttendance!.checkInTime);
    final checkOut = formatTime(todayAttendance!.checkOutTime);

    Color statusColor;
    switch (todayAttendance!.status) {
      case 'Present':  statusColor = AppColors.success;           break;
      case 'Late':     statusColor = AppColors.warning;           break;
      case 'Half Day': statusColor = AppColors.primary;           break;
      case 'WFH':      statusColor = const Color(0xFF8B5CF6);     break;
      default:         statusColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        _timeColumn('Clock In', checkIn),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20)),
          child: Text(
            todayAttendance!.status ?? '',
            style: TextStyle(
                color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
        const Spacer(),
        _timeColumn('Clock Out', checkOut, alignEnd: true),
      ]),
    );
  }

  Widget _timeColumn(String label, String time, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(time,
            style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildClockButton() {
    final isClockedIn = hasClocked && todayAttendance?.checkOutTime == null;
    final alreadyDone = hasClocked && todayAttendance?.checkOutTime != null;

    Color    bgColor = AppColors.success;
    if (isClockedIn) bgColor = AppColors.warning;
    if (alreadyDone) bgColor = AppColors.textSecondary;

    final l = AppLocalizations.of(context);
    String label = l.clockIn;
    if (isClockingIn) label = 'Processing...';
    if (isClockedIn)  label = l.clockOut;
    if (alreadyDone)  label = l.completedForToday;

    IconData icon = Icons.login_rounded;
    if (isClockedIn) icon = Icons.logout_rounded;
    if (alreadyDone) icon = Icons.check_circle_rounded;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: alreadyDone || isClockingIn || isLoadingAttendance
            ? null
            : (isClockedIn ? _handleClockOut : _handleClockIn),
        icon: isClockingIn
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ]),
    );
  }

  Widget _sectionCard({required List<Widget> tiles}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x081B4FD8), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: tiles.asMap().entries.map((entry) {
          final idx = entry.key;
          final tile = entry.value;
          return Column(
            children: [
              tile,
              if (idx < tiles.length - 1)
                const Divider(height: 1, indent: 56, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            if (badge > 0)
              Positioned(
                right: -4, top: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: AppColors.error, shape: BoxShape.circle),
                  child: Text(badge > 9 ? '9+' : '$badge',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary, size: 20),
        ]),
      ),
    );
  }

  // ── Leave Section ──────────────────────────────────────────────────────────

  Widget _buildLeaveSection() {
    final l = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Leave', Icons.event_available_rounded, AppColors.warning),
      _sectionCard(tiles: [
        _sectionTile(
          icon: Icons.add_circle_outline_rounded,
          label: l.applyLeave,
          subtitle: 'Submit a leave request',
          color: AppColors.warning,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()))
              .then((_) => _loadAttendanceData()),
        ),
        _sectionTile(
          icon: Icons.list_alt_rounded,
          label: 'My Leave Requests',
          subtitle: 'View your leave history',
          color: AppColors.primary,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const LeaveScreen())),
        ),
        if (isAdmin)
          _sectionTile(
            icon: Icons.approval_rounded,
            label: l.pendingApprovals,
            subtitle: 'Review and approve requests',
            color: AppColors.error,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PendingApprovalsScreen())),
          ),
        if (isAdmin)
          _sectionTile(
            icon: Icons.category_rounded,
            label: l.leaveTypes,
            subtitle: 'Edit leave categories & days',
            color: const Color(0xFFD97706),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const LeaveTypeManagementScreen())),
          ),
      ]),
    ]);
  }

  // ── Attendance Section ─────────────────────────────────────────────────────

  Widget _buildAttendanceSection() {
    final l = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Attendance & Schedule', Icons.fingerprint_rounded, AppColors.primary),
      _sectionCard(tiles: [
        _sectionTile(
          icon: Icons.schedule_rounded,
          label: l.myShift,
          subtitle: 'View your shift schedule',
          color: AppColors.primary,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) =>
                  ShiftScreen(userRole: widget.employee.role))),
        ),
        _sectionTile(
          icon: Icons.campaign_rounded,
          label: l.announcements,
          subtitle: 'Company news & updates',
          color: AppColors.accent,
          badge: announcementCount,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) =>
                  AnnouncementScreen(userRole: widget.employee.role)))
              .then((_) => _loadAnnouncementCount()),
        ),
        _sectionTile(
          icon: Icons.folder_rounded,
          label: l.myDocuments,
          subtitle: 'Your documents & files',
          color: const Color(0xFF8B5CF6),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) =>
                  DocumentScreen(userRole: widget.employee.role))),
        ),
      ]),
    ]);
  }

  // ── Employee Management Section (admin/manager only) ───────────────────────

  Widget _buildEmployeeManagementSection() {
    final l = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Manage Employees', Icons.people_rounded, AppColors.success),
      _sectionCard(tiles: [
        _sectionTile(
          icon: Icons.person_add_rounded,
          label: l.addEmployee,
          subtitle: 'Register a new employee',
          color: AppColors.success,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddEmployeeScreen())),
        ),
        _sectionTile(
          icon: Icons.business_rounded,
          label: l.departments,
          subtitle: 'Manage company departments',
          color: const Color(0xFF0891B2),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DepartmentScreen())),
        ),
        _sectionTile(
          icon: Icons.badge_rounded,
          label: l.jobRoles,
          subtitle: 'Manage roles & assign employees',
          color: const Color(0xFF7C3AED),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const JobRoleScreen())),
        ),
      ]),
    ]);
  }

  // ── Evaluation Section ─────────────────────────────────────────────────────

  Widget _buildEvaluationSection() {
    final l = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Evaluation & Performance', Icons.assessment_rounded, const Color(0xFF7C3AED)),
      _sectionCard(tiles: [
        _sectionTile(
          icon: Icons.assignment_turned_in_rounded,
          label: l.myEvaluations,
          subtitle: 'Pending evaluation tasks',
          color: const Color(0xFF7C3AED),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MyEvaluationsScreen())),
        ),
        if (isAdmin) ...[
          _sectionTile(
            icon: Icons.track_changes_rounded,
            label: l.kpiManagement,
            subtitle: 'Create & assign KPIs to roles',
            color: const Color(0xFF059669),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const KpiScreen())),
          ),
          _sectionTile(
            icon: Icons.event_repeat_rounded,
            label: l.evaluationCycles,
            subtitle: 'Create cycles & assign peers',
            color: const Color(0xFFD97706),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EvaluationCycleScreen())),
          ),
          _sectionTile(
            icon: Icons.leaderboard_rounded,
            label: l.performanceResults,
            subtitle: 'View 360° scores & grades',
            color: const Color(0xFFDC2626),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PerformanceResultsScreen())),
          ),
        ],
      ]),
    ]);
  }

  // ── More Section ───────────────────────────────────────────────────────────

  Widget _buildMoreSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Profile & Settings', Icons.settings_rounded, AppColors.textSecondary),
      _sectionCard(tiles: [
        _sectionTile(
          icon: Icons.person_rounded,
          label: 'My Profile',
          subtitle: 'View and edit your profile',
          color: AppColors.primary,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => ProfileScreen(employee: widget.employee))),
        ),
      ]),
    ]);
  }
}
