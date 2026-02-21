import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employee.dart';
import '../../models/attendance.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../services/announcement_service.dart';
import '../auth/login_screen.dart';
import '../leave/apply_leave_screen.dart';
import '../leave/my_requests_screen.dart';
import '../leave/leave_balance_screen.dart';
import '../leave/pending_approvals_screen.dart';
import '../attendance/attendance_screen.dart';
import '../payroll/payroll_screen.dart';
import '../shift/shift_screen.dart';
import '../documents/document_screen.dart';
import '../announcements/announcement_screen.dart';

class HomeScreen extends StatefulWidget {
  final Employee employee;
  const HomeScreen({super.key, required this.employee});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final AnnouncementService _announcementService = AnnouncementService();

  Attendance? todayAttendance;
  Map<String, dynamic>? shiftInfo;
  bool isLoadingAttendance = true;
  bool hasClocked = false;
  bool isClockingIn = false;
  int announcementCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
    _loadAnnouncementCount();
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
    } catch (e) {
      if (mounted) setState(() => isLoadingAttendance = false);
    }
  }

  Future<void> _loadAnnouncementCount() async {
    final count = await _announcementService.getRecentCount();
    if (mounted) setState(() => announcementCount = count);
  }

  Future<void> _handleClockIn() async {
    setState(() => isClockingIn = true);
    final result = await _attendanceService.clockIn();
    if (mounted) {
      setState(() => isClockingIn = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success'] ? result['message'] : result['error']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
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
            ? '${result['message']} - ${result['total_hours']} hours'
            : result['error']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ));
      if (result['success']) _loadAttendanceData();
    }
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );
    if (shouldLogout == true) {
      await AuthService().logout();
      if (context.mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.campaign),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnnouncementScreen(userRole: widget.employee.role),
                  ),
                ).then((_) => _loadAnnouncementCount()),
                tooltip: 'Announcements',
              ),
              if (announcementCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      announcementCount > 9 ? '9+' : announcementCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadAttendanceData();
          await _loadAnnouncementCount();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 16),
              _buildClockInOutCard(),
              const SizedBox(height: 24),
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildActionCard('Attendance', Icons.fingerprint, Colors.blue,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()))),
                  _buildActionCard('Apply Leave', Icons.event_busy, Colors.orange,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()))),
                  _buildActionCard('My Requests', Icons.list_alt, Colors.purple,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRequestsScreen()))),
                  _buildActionCard('Leave Balance', Icons.calendar_today, Colors.green,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveBalanceScreen()))),
                  _buildActionCard('Payroll', Icons.attach_money, Colors.indigo,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => PayrollScreen(userRole: widget.employee.role)))),
                  _buildActionCard('My Shift', Icons.access_time, Colors.teal,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShiftScreen(userRole: widget.employee.role)))),
                  _buildActionCard('Documents', Icons.folder, Colors.deepPurple,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentScreen(userRole: widget.employee.role)))),
                  _buildActionCardWithBadge('Announcements', Icons.campaign, Colors.amber.shade700, announcementCount,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementScreen(userRole: widget.employee.role))).then((_) => _loadAnnouncementCount())),
                  if (widget.employee.role == 'manager' || widget.employee.role == 'admin')
                    _buildActionCard('Pending Approvals', Icons.approval, Colors.red,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingApprovalsScreen()))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                widget.employee.fullName[0].toUpperCase(),
                style: const TextStyle(fontSize: 22, color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back,', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  Text(widget.employee.fullName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    '${widget.employee.position ?? ''} • ${widget.employee.role.toUpperCase()}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockInOutCard() {
    if (isLoadingAttendance) {
      return const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())));
    }

    final now = DateTime.now();
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(DateFormat('EEEE, MMMM d, yyyy').format(now),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(DateFormat('hh:mm a').format(now),
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (shiftInfo != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.schedule, size: 18, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text('${shiftInfo!['shift_name']} (${shiftInfo!['start_time']} - ${shiftInfo!['end_time']})'),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (hasClocked && todayAttendance != null) ...[
              _buildAttendanceStatus(),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: (isClockingIn || isLoadingAttendance)
                    ? null
                    : (hasClocked && todayAttendance?.checkOutTime == null
                        ? _handleClockOut
                        : (!hasClocked ? _handleClockIn : null)),
                icon: Icon(hasClocked && todayAttendance?.checkOutTime == null
                    ? Icons.logout
                    : Icons.login),
                label: Text(
                  isClockingIn
                      ? 'Processing...'
                      : (hasClocked && todayAttendance?.checkOutTime == null
                          ? 'Clock Out'
                          : (hasClocked ? 'Already Clocked Out' : 'Clock In')),
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasClocked && todayAttendance?.checkOutTime == null
                      ? Colors.orange
                      : (hasClocked ? Colors.grey : Colors.green),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStatus() {
    if (todayAttendance == null) return const SizedBox();
    final checkIn = todayAttendance!.checkInTime != null
        ? DateFormat('hh:mm a').format(DateTime.parse(todayAttendance!.checkInTime!))
        : '-';
    final checkOut = todayAttendance!.checkOutTime != null
        ? DateFormat('hh:mm a').format(DateTime.parse(todayAttendance!.checkOutTime!))
        : '-';

    Color statusColor = Colors.grey;
    switch (todayAttendance!.status) {
      case 'Present': statusColor = Colors.green; break;
      case 'Late': statusColor = Colors.orange; break;
      case 'Half Day': statusColor = Colors.blue; break;
      case 'WFH': statusColor = Colors.purple; break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Clock In', style: TextStyle(fontSize: 11, color: Colors.grey)),
            Text(checkIn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
            child: Text(todayAttendance!.status ?? '', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('Clock Out', style: TextStyle(fontSize: 11, color: Colors.grey)),
            Text(checkOut, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 46, color: color),
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCardWithBadge(String title, IconData icon, Color color, int badge, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 46, color: color),
                  if (badge > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          badge > 9 ? '9+' : badge.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}