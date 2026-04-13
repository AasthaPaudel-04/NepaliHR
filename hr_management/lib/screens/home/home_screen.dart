import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employee.dart';
import '../../models/attendance.dart';
import '../../services/attendance_service.dart';
import '../../services/notification_service.dart';
import '../../app_colors.dart';
import '../leave/apply_leave_screen.dart';
import '../leave/pending_approvals_screen.dart';
import '../leave/leave_type_management_screen.dart';
import '../shift/shift_screen.dart';
import '../documents/document_screen.dart';
import '../announcements/announcement_screen.dart';
import '../profile/profile_screen.dart';
import '../performance/add_employee_screen.dart';
import '../performance/department_screen.dart';
import '../performance/job_role_screen.dart';
import '../performance/kpi_screen.dart';
import '../performance/evaluation_cycle_screen.dart';
import '../performance/my_evaluations_screen.dart';
import '../performance/performance_results_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final Employee employee;
  const HomeScreen({super.key, required this.employee});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final NotificationService _notificationService = NotificationService();

  Attendance? todayAttendance;
  Map<String, dynamic>? shiftInfo;
  bool isLoadingAttendance = true;
  bool hasClocked = false;
  bool isClockingIn = false;
  int notificationCount = 0;

  bool get isAdmin => widget.employee.role == 'admin';
  bool get isManager => widget.employee.role == 'manager';
  bool get isAdminOrManager => isAdmin || isManager;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
    _loadNotificationCount();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => isLoadingAttendance = true);
    try {
      final data = await _attendanceService.getTodayAttendance();
      if (mounted) {
        setState(() {
          if (data['success']) {
            hasClocked = data['hasClocked'];
            todayAttendance = data['attendance'];
            shiftInfo = data['shift'];
          }
          isLoadingAttendance = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoadingAttendance = false);
    }
  }

  Future<void> _loadNotificationCount() async {
    final count = await _notificationService.getUnreadCount();
    if (mounted) setState(() => notificationCount = count);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await _loadAttendanceData();
          await _loadNotificationCount();
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
                    _buildQuickActionsGrid(),
                    const SizedBox(height: 24),
                    _buildShortcutsSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_greeting(),
                style: const TextStyle(
                    color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w400)),
            const SizedBox(height: 2),
            Text(
              widget.employee.fullName,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.employee.position ?? ''} · ${widget.employee.role.toUpperCase()}',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        // Notification bell
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ).then((_) => _loadNotificationCount()),
          child: Stack(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 21),
            ),
            if (notificationCount > 0)
              Positioned(
                right: 6, top: 6,
                child: Container(
                  width: 9, height: 9,
                  decoration: const BoxDecoration(
                      color: AppColors.warning, shape: BoxShape.circle),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 8),
        // Avatar
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen(employee: widget.employee)),
          ),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.accent, Color(0xFF00A891)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(13),
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  Widget _buildClockInOutCard() {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x101B4FD8), blurRadius: 24, offset: Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: isLoadingAttendance
            ? const Center(
                child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary),
              ))
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(DateFormat('EEEE, d MMM').format(DateTime.now()),
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(DateFormat('hh:mm a').format(DateTime.now()),
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1)),
                    ]),
                  ),
                  if (shiftInfo != null)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.schedule_rounded,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${shiftInfo!['start_time']} - ${shiftInfo!['end_time']}',
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
                const SizedBox(height: 14),
                _buildClockButton(),
              ]),
      ),
    );
  }

  Widget _buildAttendanceStatus() {
    String formatTime(String? timeStr) {
      if (timeStr == null) return '--';
      try {
        // Parse and convert to local Nepal time
        final dt = DateTime.parse(timeStr).toLocal();
        return DateFormat('hh:mm a').format(dt);
      } catch (_) {
        return timeStr.length >= 5 ? timeStr.substring(0, 5) : timeStr;
      }
    }

    final checkIn = formatTime(todayAttendance!.checkInTime);
    final checkOut = formatTime(todayAttendance!.checkOutTime);
    Color statusColor;
    switch (todayAttendance!.status) {
      case 'Present': statusColor = AppColors.success; break;
      case 'Late': statusColor = AppColors.warning; break;
      case 'Half Day': statusColor = AppColors.primary; break;
      case 'WFH': statusColor = const Color(0xFF8B5CF6); break;
      default: statusColor = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        _timeColumn('Clock In', checkIn),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(todayAttendance!.status ?? '',
              style: TextStyle(
                  color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
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
    Color bgColor = AppColors.success;
    if (isClockedIn) bgColor = AppColors.warning;
    if (alreadyDone) bgColor = AppColors.textSecondary;
    String label = 'Clock In';
    if (isClockingIn) label = 'Processing...';
    if (isClockedIn) label = 'Clock Out';
    if (alreadyDone) label = 'Completed for Today';
    IconData icon = Icons.login_rounded;
    if (isClockedIn) icon = Icons.logout_rounded;
    if (alreadyDone) icon = Icons.check_circle_rounded;

    return SizedBox(
      width: double.infinity, height: 48,
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
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ── Role-based quick actions GRID
  Widget _buildQuickActionsGrid() {
    final List<_QuickAction> actions = _getQuickActions();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Quick Actions',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
        children: actions.map(_buildGridItem).toList(),
      ),
    ]);
  }

  List<_QuickAction> _getQuickActions() {
    if (isAdmin) {
      return [
        _QuickAction(Icons.schedule_rounded, 'Edit Shifts', AppColors.primary,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShiftScreen(userRole: 'admin')))),
        _QuickAction(Icons.assessment_rounded, 'Evals', const Color(0xFF7C3AED),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyEvaluationsScreen()))),
        _QuickAction(Icons.campaign_rounded, 'Notices', AppColors.accent,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementScreen(userRole: 'admin')))),
        _QuickAction(Icons.folder_rounded, 'Documents', const Color(0xFF8B5CF6),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentScreen(userRole: 'admin')))),
      ];
    } else if (isManager) {
      return [
        _QuickAction(Icons.event_rounded, 'Apply Leave', AppColors.warning,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()))),
        _QuickAction(Icons.campaign_rounded, 'Notices', AppColors.accent,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementScreen(userRole: 'manager')))),
        _QuickAction(Icons.folder_rounded, 'Documents', const Color(0xFF8B5CF6),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentScreen(userRole: 'manager')))),
        _QuickAction(Icons.schedule_rounded, 'My Shift', AppColors.primary,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShiftScreen(userRole: 'manager')))),
        _QuickAction(Icons.assessment_rounded, 'Evals', const Color(0xFF7C3AED),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyEvaluationsScreen()))),
        _QuickAction(Icons.approval_rounded, 'Approvals', AppColors.error,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingApprovalsScreen()))),
      ];
    } else {
      // Employee
      return [
        _QuickAction(Icons.event_rounded, 'Apply Leave', AppColors.warning,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()))),
        _QuickAction(Icons.campaign_rounded, 'Notices', AppColors.accent,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementScreen(userRole: 'employee')))),
        _QuickAction(Icons.folder_rounded, 'Documents', const Color(0xFF8B5CF6),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentScreen(userRole: 'employee')))),
        _QuickAction(Icons.schedule_rounded, 'My Shift', AppColors.primary,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShiftScreen(userRole: 'employee')))),
        _QuickAction(Icons.assessment_rounded, 'My Evals', const Color(0xFF7C3AED),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyEvaluationsScreen()))),
      ];
    }
  }

  Widget _buildGridItem(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: action.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: action.color.withOpacity(0.2), width: 1),
          ),
          child: Icon(action.icon, color: action.color, size: 26),
        ),
        const SizedBox(height: 6),
        Text(action.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildShortcutsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('More',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 12),
      // Common to all roles
      _shortcutTile(
        icon: Icons.assessment_rounded,
        label: 'My Evaluations',
        subtitle: 'Pending evaluation tasks',
        color: const Color(0xFF7C3AED),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const MyEvaluationsScreen())),
      ),
      // Admin-only
      if (isAdmin) ...[
        const SizedBox(height: 10),
        _shortcutTile(
          icon: Icons.person_add_rounded,
          label: 'Add Employee',
          subtitle: 'Register a new employee',
          color: AppColors.success,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AddEmployeeScreen())),
        ),
        const SizedBox(height: 10),
        _shortcutTile(
          icon: Icons.business_rounded,
          label: 'Departments',
          subtitle: 'Manage company departments',
          color: const Color(0xFF0891B2),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const DepartmentScreen())),
        ),
        const SizedBox(height: 10),
        _shortcutTile(
          icon: Icons.badge_rounded,
          label: 'Job Roles',
          subtitle: 'Manage roles & assign employees',
          color: const Color(0xFF7C3AED),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const JobRoleScreen())),
        ),
        const SizedBox(height: 10),
        _shortcutTile(
          icon: Icons.track_changes_rounded,
          label: 'KPI Management',
          subtitle: 'Create & assign KPIs to roles',
          color: const Color(0xFF059669),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const KpiScreen())),
        ),
        const SizedBox(height: 10),
        _shortcutTile(
          icon: Icons.event_repeat_rounded,
          label: 'Evaluation Cycles',
          subtitle: 'Create cycles & assign peers',
          color: const Color(0xFFD97706),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const EvaluationCycleScreen())),
        ),
        const SizedBox(height: 10),
        _shortcutTile(
          icon: Icons.leaderboard_rounded,
          label: 'Performance Results',
          subtitle: 'View 360° scores & grades',
          color: const Color(0xFFDC2626),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const PerformanceResultsScreen())),
        ),
      ],
      // Manager shortcuts
      if (isManager) ...[
        const SizedBox(height: 10),
        _shortcutTile(
          icon: Icons.approval_rounded,
          label: 'Pending Approvals',
          subtitle: 'Review leave requests',
          color: AppColors.error,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const PendingApprovalsScreen())),
        ),
        const SizedBox(height: 10),
        _shortcutTile(
          icon: Icons.leaderboard_rounded,
          label: 'Performance Results',
          subtitle: 'View team evaluation results',
          color: const Color(0xFFDC2626),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const PerformanceResultsScreen())),
        ),
      ],
    ]);
  }

  Widget _shortcutTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: const [
            BoxShadow(color: Color(0x081B4FD8), blurRadius: 12, offset: Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _QuickAction(this.icon, this.label, this.color, this.onTap);
}
