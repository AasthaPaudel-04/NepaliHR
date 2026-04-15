import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/employee.dart';
import '../app_colors.dart';
import 'home/home_screen.dart';
import 'attendance/attendance_screen.dart';
import 'leave/leave_screen.dart';
import 'payroll/payroll_screen.dart';
import 'profile/profile_screen.dart';
import 'dashboard/dashboard_screen.dart'; 

class MainShell extends StatefulWidget {
  final Employee employee;
  const MainShell({super.key, required this.employee});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  bool get _isAdmin => widget.employee.role == 'admin';

  List<Widget> get _screens => [
    HomeScreen(employee: widget.employee),
    const AttendanceScreen(),
    const LeaveScreen(),
    PayrollScreen(userRole: widget.employee.role),
    _isAdmin
        ? const DashboardScreen()         
        : ProfileScreen(employee: widget.employee), 
  ];

  List<_NavItem> get _navItems => [
    const _NavItem(icon: Icons.home_rounded, label: 'Home'),
    const _NavItem(icon: Icons.fingerprint,  label: 'Attendance'),
    const _NavItem(icon: Icons.event_rounded, label: 'Leave'),
    const _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Payroll'),
    _isAdmin
        ? const _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard') 
        : const _NavItem(icon: Icons.person_rounded,    label: 'Profile'),  
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: _ModernBottomNav(
          currentIndex: _currentIndex,
          items: _navItems,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ── Bottom nav  ─────
class _ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;
  const _ModernBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(color: Color(0x141B4FD8), blurRadius: 24, offset: Offset(0, -8)),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      items[i].icon,
                      color: active ? AppColors.primary : AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: active ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
