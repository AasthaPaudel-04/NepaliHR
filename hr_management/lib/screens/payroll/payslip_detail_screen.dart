import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/payroll_service.dart';
import '../../app_colors.dart';

class PayslipDetailScreen extends StatefulWidget {
  final int payrollId;
  const PayslipDetailScreen({super.key, required this.payrollId});

  @override
  State<PayslipDetailScreen> createState() => _PayslipDetailScreenState();
}

class _PayslipDetailScreenState extends State<PayslipDetailScreen> {
  final PayrollService _payrollService = PayrollService();
  Map<String, dynamic>? _payslip;
  bool _isLoading = true;

  final _fmt = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _payrollService.getPayslipDetail(widget.payrollId);
      setState(() {
        _payslip = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double _d(String key) =>
      double.tryParse((_payslip![key] ?? 0).toString()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _payslip == null
              ? _buildError()
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildEarningsCard(),
                            const SizedBox(height: 12),
                            _buildDeductionsCard(),
                            const SizedBox(height: 12),
                            _buildNetCard(),
                            const SizedBox(height: 12),
                            _buildPaymentCard(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeader() {
    final month = _payslip!['month'] != null
        ? DateFormat('MMMM yyyy')
            .format(DateTime.parse(_payslip!['month']))
        : '';
    final isPaid = _payslip!['payment_status'] == 'paid';

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 32),
      child: Column(
        children: [
          Row(
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
              const Text('Payslip Detail',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 24),
          // Employee info
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.accent.withOpacity(0.3),
                  child: Text(
                    (_payslip!['full_name'] ?? 'E')[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _payslip!['full_name'] ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_payslip!['employee_code'] ?? ''} • ${_payslip!['position'] ?? ''}',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(month,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? AppColors.success.withOpacity(0.3)
                            : AppColors.warning.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPaid ? 'Paid' : 'Pending',
                        style: TextStyle(
                            color: isPaid
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    final housing = _d('housing_allowance');
    final transport = _d('transport_allowance');
    final medical = _d('medical_allowance');
    final other = _d('other_allowance');
    final basic = _d('basic_salary');
    final allowances = _d('allowances');

    return _sectionCard(
      title: 'Earnings',
      accentColor: AppColors.success,
      rows: [
        _row('Basic Salary', basic),
        if (housing > 0) _row('Housing Allowance', housing),
        if (transport > 0) _row('Transport Allowance', transport),
        if (medical > 0) _row('Medical Allowance', medical),
        if (other > 0) _row('Other Allowance', other),
      ],
      total: _rowTotal('Gross Salary', basic + allowances),
    );
  }

  Widget _buildDeductionsCard() {
    final pf = _d('pf_employee');
    final tax = _d('income_tax');
    final cit = _d('cit_amount');

    return _sectionCard(
      title: 'Deductions',
      accentColor: AppColors.error,
      rows: [
        _row('SSF – Employee (11%)', pf, isDeduction: true),
        _row('Income Tax', tax, isDeduction: true),
        if (cit > 0) _row('CIT', cit, isDeduction: true),
      ],
      total: _rowTotal('Total Deductions', pf + tax + cit, isDeduction: true),
    );
  }

  Widget _buildNetCard() {
    final net = _d('net_salary');
    final employerPf = _d('pf_employer');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text('Net Salary',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Text('NPR ${_fmt.format(net)}',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1)),
          if (employerPf > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Employer SSF Contribution: NPR ${_fmt.format(employerPf)}',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    final isPaid = _payslip!['payment_status'] == 'paid';
    return _sectionCard(
      title: 'Payment Info',
      accentColor: AppColors.primary,
      rows: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Text('Status',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPaid ? 'Paid' : 'Pending',
                  style: TextStyle(
                      color: isPaid ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        if (_payslip!['payment_date'] != null)
          _infoRow('Payment Date',
              DateFormat('dd MMM yyyy').format(DateTime.parse(_payslip!['payment_date']))),
        if (_payslip!['payment_method'] != null)
          _infoRow('Method',
              (_payslip!['payment_method'] as String).replaceAll('_', ' ').toUpperCase()),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required Color accentColor,
    required List<Widget> rows,
    Widget? total,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x081B4FD8), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(children: rows),
          ),
          if (total != null) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: total,
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, double amount, {bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(
            '${isDeduction ? '–' : ''}NPR ${_fmt.format(amount)}',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDeduction ? AppColors.error : AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _rowTotal(String label, double amount, {bool isDeduction = false}) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        const Spacer(),
        Text(
          '${isDeduction ? '–' : ''}NPR ${_fmt.format(amount)}',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDeduction ? AppColors.error : AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          SizedBox(height: 12),
          Text('Could not load payslip',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}