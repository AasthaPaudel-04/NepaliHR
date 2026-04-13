import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app_colors.dart';
import '../../models/leave_request.dart';
import '../../services/leave_service.dart';
import '../../services/auth_service.dart';
import '../../models/employee.dart';
import 'apply_leave_screen.dart';
import 'leave_type_management_screen.dart';
import 'pending_approvals_screen.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen>
    with SingleTickerProviderStateMixin {
  final _leaveService = LeaveService();
  final _authService = AuthService();

  Employee? _currentUser;
  bool _isAdmin = false;
  bool _isManager = false;

  List<LeaveRequest> _requests = [];
  LeaveBalance? _balance;
  bool _isLoading = true;
  String _filter = 'all';
  late TabController _tabController;

  bool get _isEmployee => !_isAdmin && !_isManager;

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

      if (_isAdmin) {
        // Admin: Pending Approvals tab + Leave Types tab
        _tabController = TabController(length: 2, vsync: this);
      } else if (_isManager) {
        // Manager: My Requests + Pending Approvals
        _tabController = TabController(length: 2, vsync: this);
        _loadMyLeave();
      } else {
        // Employee: My Requests only
        _tabController = TabController(length: 1, vsync: this);
        _loadMyLeave();
      }
    }
  }

  Future<void> _loadMyLeave() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _leaveService.getMyRequests();
      final balance = await _leaveService.getBalance();
      if (mounted) {
        setState(() {
          _requests = requests;
          _balance = balance;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<LeaveRequest> get _filtered {
    if (_filter == 'all') return _requests;
    return _requests.where((r) => r.status == _filter).toList();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'approved': return Icons.check_circle_rounded;
      case 'rejected': return Icons.cancel_rounded;
      default: return Icons.schedule_rounded;
    }
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
      floatingActionButton: _isEmployee
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()),
              ).then((_) => _loadMyLeave()),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Apply Leave',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : (_isManager
              ? FloatingActionButton.extended(
                  backgroundColor: AppColors.primary,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()),
                  ).then((_) => _loadMyLeave()),
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text('Apply Leave',
                      style:
                          TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                )
              : null),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              child: _isAdmin
                  ? TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      tabs: const [
                        Tab(text: 'Pending Approvals'),
                        Tab(text: 'Leave Types'),
                      ],
                    )
                  : _isManager
                      ? TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: AppColors.primary,
                          tabs: const [
                            Tab(text: 'My Requests'),
                            Tab(text: 'Pending Approvals'),
                          ],
                        )
                      : null,
            ),
          ),
        ],
        body: _isAdmin
            ? TabBarView(
                controller: _tabController,
                children: [
                  const PendingApprovalsScreen(embedded: true),
                  const LeaveTypeManagementScreen(embedded: true),
                ],
              )
            : _isManager
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMyRequestsView(),
                      const PendingApprovalsScreen(embedded: true),
                    ],
                  )
                : _buildMyRequestsView(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          _isAdmin ? 'Leave Management' : 'Leave',
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        if (!_isAdmin && _balance != null) ...[
          const SizedBox(height: 14),
          const Text('YOUR BALANCE',
              style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _balanceChip('Casual', _balance!.casualLeave)),
            const SizedBox(width: 8),
            Expanded(child: _balanceChip('Sick', _balance!.sickLeave)),
            const SizedBox(width: 8),
            Expanded(child: _balanceChip('Annual', _balance!.annualLeave)),
            const SizedBox(width: 8),
            Expanded(child: _balanceChip('Total', _balance!.total, isAccent: true)),
          ]),
        ],
      ]),
    );
  }

  Widget _balanceChip(String label, int days, {bool isAccent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isAccent
            ? AppColors.accent.withOpacity(0.2)
            : Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAccent
              ? AppColors.accent.withOpacity(0.4)
              : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(children: [
        Text('$days',
            style: TextStyle(
                color: isAccent ? AppColors.accent : Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildMyRequestsView() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadMyLeave,
      child: Column(children: [
        // Filter row
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: ['all', 'pending', 'approved', 'rejected'].length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = ['all', 'pending', 'approved', 'rejected'][i];
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
                  child: Text(f[0].toUpperCase() + f.substring(1),
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
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.06),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.event_rounded,
                                size: 40, color: AppColors.primary),
                          ),
                          const SizedBox(height: 14),
                          const Text('No leave requests',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: AppColors.textPrimary)),
                        ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _buildRequestCard(_filtered[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _buildRequestCard(LeaveRequest req) {
    final color = _statusColor(req.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(_statusIcon(req.status), color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(req.leaveType,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              '${DateFormat('dd MMM').format(req.startDate)} – ${DateFormat('dd MMM yyyy').format(req.endDate)} · ${req.totalDays} day${req.totalDays == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
            if (req.rejectionReason != null)
              Text('Reason: ${req.rejectionReason}',
                  style: const TextStyle(fontSize: 11, color: AppColors.error),
                  overflow: TextOverflow.ellipsis),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(req.status,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 11)),
        ),
      ]),
    );
  }
}
