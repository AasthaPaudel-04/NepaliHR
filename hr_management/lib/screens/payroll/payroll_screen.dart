import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app_colors.dart';
import '../../models/payroll.dart';
import '../../services/payroll_service.dart';
import '../../services/auth_service.dart';
import '../../models/employee.dart';
import 'payslip_detail_screen.dart';

class PayrollScreen extends StatefulWidget {
  final String userRole;
  const PayrollScreen({super.key, required this.userRole});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen>
    with SingleTickerProviderStateMixin {
  final PayrollService _service = PayrollService();
  final AuthService _authService = AuthService();

  Employee? _currentUser;
  bool get _isAdmin => widget.userRole == 'admin';

  // Employee vars
  List<PayrollRecord> _myPayslips = [];
  Map<String, dynamic>? _mySalary;

  // Admin vars
  List<PayrollRecord> _allPayrolls = [];
  List<Map<String, dynamic>> _employees = [];
  String _selectedMonthYear = '';
  String _statusFilter = 'all';

  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonthYear =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    if (_isAdmin) {
      _tabController = TabController(length: 2, vsync: this);
      _loadAdminPayrolls();
      _loadEmployees();
    } else {
      _tabController = TabController(length: 1, vsync: this);
      _loadMyPayslips();
    }
    _initUser();
  }

  Future<void> _initUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) setState(() => _currentUser = user);
  }

  Future<void> _loadMyPayslips() async {
    setState(() => _isLoading = true);
    try {
      final payslips = await _service.getMyPayslips();
      final salary = await _service.getMySalary();
      if (mounted) {
        setState(() {
          _myPayslips = payslips;
          _mySalary = salary;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAdminPayrolls() async {
    setState(() => _isLoading = true);
    try {
      final payrolls = await _service.getAllPayrolls(
        monthYear: _selectedMonthYear,
        status: _statusFilter == 'all' ? null : _statusFilter,
      );
      if (mounted) setState(() { _allPayrolls = payrolls; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final emps = await _authService.getAllEmployees();
      if (mounted) setState(() => _employees = emps);
    } catch (_) {}
  }

  Future<void> _generateBulk() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Generate Bulk Payroll',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Generate payroll for ALL employees for $_selectedMonthYear?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _service.generateBulkPayroll(_selectedMonthYear);
    if (mounted) {
      _snack(result['success']
          ? (result['message'] ?? 'Payroll generated')
          : (result['error'] ?? 'Failed'));
      if (result['success']) _loadAdminPayrolls();
    }
  }

  Future<void> _generateSingle(int employeeId) async {
    final result = await _service.generatePayroll(employeeId, _selectedMonthYear);
    if (mounted) {
      _snack(result['success']
          ? 'Payroll generated'
          : (result['error'] ?? 'Failed'),
          isError: !result['success']);
      if (result['success']) _loadAdminPayrolls();
    }
  }

  Future<void> _markPaid(PayrollRecord record) async {
    String method = 'bank_transfer';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Mark as Paid',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Mark payroll for ${record.fullName} as paid?'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: method,
              decoration: InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                filled: true, fillColor: AppColors.background,
              ),
              items: const [
                DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
              ],
              onChanged: (v) => setS(() => method = v!),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Mark Paid'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final result = await _service.markAsPaid(record.id, method);
    if (mounted) {
      _snack(result['success'] ? 'Marked as paid' : (result['error'] ?? 'Failed'),
          isError: !result['success']);
      if (result['success']) _loadAdminPayrolls();
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _buildHeader()),
          if (_isAdmin)
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.surface,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'All Payrolls'),
                    Tab(text: 'Generate'),
                  ],
                ),
              ),
            ),
        ],
        body: _isAdmin
            ? TabBarView(
                controller: _tabController,
                children: [
                  _buildAdminPayrollsView(),
                  _buildGenerateView(),
                ],
              )
            : _buildMyPayslipsView(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_isAdmin ? 'Payroll Management' : 'Payroll',
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        if (!_isAdmin && _mySalary != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                'Basic: NPR ${NumberFormat('#,##0').format(_mySalary!['basic_salary'] ?? 0)}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── Admin: view all payrolls
  Widget _buildAdminPayrollsView() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAdminPayrolls,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            Expanded(
              child: _monthPicker(),
            ),
            const SizedBox(width: 10),
            _statusChip('all', 'All'),
            const SizedBox(width: 6),
            _statusChip('pending', 'Pending'),
            const SizedBox(width: 6),
            _statusChip('paid', 'Paid'),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _allPayrolls.isEmpty
                  ? const Center(
                      child: Text('No payrolls for this period',
                          style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: _allPayrolls.length,
                      itemBuilder: (_, i) => _buildAdminPayrollCard(_allPayrolls[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _monthPicker() {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(2023),
          lastDate: now,
          initialDatePickerMode: DatePickerMode.year,
        );
        if (picked != null) {
          setState(() {
            _selectedMonthYear =
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
          });
          _loadAdminPayrolls();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_month_rounded,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(_selectedMonthYear,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ]),
      ),
    );
  }

  Widget _statusChip(String value, String label) {
    final selected = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = value);
        _loadAdminPayrolls();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildAdminPayrollCard(PayrollRecord record) {
    final isPaid = record.paymentStatus == 'paid';
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              (record.fullName ?? 'E')[0].toUpperCase(),
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(record.fullName ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis),
              Text('${record.employeeCode ?? ''} · ${record.department ?? ''}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isPaid ? AppColors.success : AppColors.warning)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(isPaid ? 'Paid' : 'Pending',
                style: TextStyle(
                    color: isPaid ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 11)),
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Expanded(
              child: _amountCol('Basic',
                  'NPR ${NumberFormat('#,##0').format(record.basicSalary)}'),
            ),
            Expanded(
              child: _amountCol('Deductions',
                  'NPR ${NumberFormat('#,##0').format(record.totalDeductions)}'),
            ),
            Expanded(
              child: _amountCol(
                  'Net',
                  'NPR ${NumberFormat('#,##0').format(record.netSalary)}',
                  highlight: true),
            ),
          ]),
        ),
        if (!isPaid) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('Mark as Paid'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => _markPaid(record),
            ),
          ),
        ] else if (record.paymentDate != null) ...[
          const SizedBox(height: 6),
          Text(
            'Paid on ${DateFormat('dd MMM yyyy').format(record.paymentDate!)} · ${record.paymentMethod ?? ''}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ]),
    );
  }

  Widget _amountCol(String label, String value, {bool highlight = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(value,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.primary : AppColors.textPrimary),
          overflow: TextOverflow.ellipsis),
    ]);
  }

  // ── Admin: generate payroll tab
  Widget _buildGenerateView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        // Month selector
        Row(children: [
          const Text('Month:',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(width: 10),
          _monthPicker(),
        ]),
        const SizedBox(height: 16),
        // Bulk generate
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Bulk Generate',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('Generate payroll for all active employees at once.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.people_rounded, size: 18),
                label: Text('Generate All · $_selectedMonthYear'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _generateBulk,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('Generate Individual',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        ..._employees.map((emp) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                (emp['full_name'] as String? ?? 'E')[0].toUpperCase(),
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(emp['full_name'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis),
            ),
            TextButton(
              onPressed: () => _generateSingle(emp['id']),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Generate', style: TextStyle(fontSize: 12)),
            ),
          ]),
        )),
      ]),
    );
  }

  // ── Employee: my payslips
  Widget _buildMyPayslipsView() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadMyPayslips,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _myPayslips.isEmpty
              ? const Center(
                  child: Text('No payslips yet',
                      style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: _myPayslips.length,
                  itemBuilder: (_, i) {
                    final p = _myPayslips[i];
                    final isPaid = p.paymentStatus == 'paid';
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PayslipDetailScreen(payrollId: p.id)),
                      ),
                      child: Container(
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
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: (isPaid ? AppColors.success : AppColors.warning)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPaid
                                  ? Icons.check_circle_rounded
                                  : Icons.pending_rounded,
                              color: isPaid ? AppColors.success : AppColors.warning,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat('MMMM yyyy').format(p.month),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.textPrimary)),
                                Text(
                                    'Net: NPR ${NumberFormat('#,##0').format(p.netSalary)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isPaid
                                          ? AppColors.success
                                          : AppColors.warning)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(isPaid ? 'Paid' : 'Pending',
                                    style: TextStyle(
                                        color: isPaid
                                            ? AppColors.success
                                            : AppColors.warning,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11)),
                              ),
                              const SizedBox(height: 4),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary, size: 18),
                            ],
                          ),
                        ]),
                      ),
                    );
                  }),
    );
  }
}
