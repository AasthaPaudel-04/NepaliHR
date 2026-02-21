import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/payroll_service.dart';

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

  final currencyFormat = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _payrollService.getPayslipDetail(widget.payrollId);
      setState(() { _payslip = data; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payslip'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payslip == null
              ? const Center(child: Text('Could not load payslip'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildEarningsCard(),
                      const SizedBox(height: 12),
                      _buildDeductionsCard(),
                      const SizedBox(height: 12),
                      _buildNetSalaryCard(),
                      const SizedBox(height: 12),
                      _buildPaymentInfoCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final month = _payslip!['month'] != null
        ? DateFormat('MMMM yyyy').format(DateTime.parse(_payslip!['month']))
        : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.indigo, Colors.indigoAccent]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long, color: Colors.white, size: 40),
          const SizedBox(height: 8),
          Text(
            _payslip!['full_name'] ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            '${_payslip!['employee_code']} • ${_payslip!['position'] ?? ''}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              month,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    final basicSalary = double.parse((_payslip!['basic_salary'] ?? 0).toString());
    final housingAllowance = double.parse((_payslip!['housing_allowance'] ?? 0).toString());
    final transportAllowance = double.parse((_payslip!['transport_allowance'] ?? 0).toString());
    final medicalAllowance = double.parse((_payslip!['medical_allowance'] ?? 0).toString());
    final otherAllowance = double.parse((_payslip!['other_allowance'] ?? 0).toString());
    final allowances = double.parse((_payslip!['allowances'] ?? 0).toString());
    final gross = basicSalary + allowances;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Earnings', Colors.green),
            const Divider(),
            _rowItem('Basic Salary', basicSalary),
            if (housingAllowance > 0) _rowItem('Housing Allowance', housingAllowance),
            if (transportAllowance > 0) _rowItem('Transport Allowance', transportAllowance),
            if (medicalAllowance > 0) _rowItem('Medical Allowance', medicalAllowance),
            if (otherAllowance > 0) _rowItem('Other Allowance', otherAllowance),
            const Divider(),
            _rowItem('Gross Salary', gross, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDeductionsCard() {
    final pfEmployee = double.parse((_payslip!['pf_employee'] ?? 0).toString());
    final incomeTax = double.parse((_payslip!['income_tax'] ?? 0).toString());
    final cit = double.parse((_payslip!['cit_amount'] ?? 0).toString());
    final total = pfEmployee + incomeTax + cit;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Deductions', Colors.red),
            const Divider(),
            _rowItem('SSF (Employee 11%)', pfEmployee, isDeduction: true),
            _rowItem('Income Tax', incomeTax, isDeduction: true),
            if (cit > 0) _rowItem('CIT', cit, isDeduction: true),
            const Divider(),
            _rowItem('Total Deductions', total, isBold: true, isDeduction: true),
          ],
        ),
      ),
    );
  }

  Widget _buildNetSalaryCard() {
    final netSalary = double.parse((_payslip!['net_salary'] ?? 0).toString());
    final pfEmployer = double.parse((_payslip!['pf_employer'] ?? 0).toString());

    return Card(
      color: Colors.indigo.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Net Salary', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              'NPR ${currencyFormat.format(netSalary)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 8),
            Text(
              'Employer SSF Contribution: NPR ${currencyFormat.format(pfEmployer)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    final status = _payslip!['payment_status'] ?? 'pending';
    final isPaid = status == 'paid';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Payment Info', Colors.blue),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPaid ? 'Paid' : 'Pending',
                    style: TextStyle(
                      color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_payslip!['payment_date'] != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Date'),
                  Text(DateFormat('dd MMM yyyy').format(DateTime.parse(_payslip!['payment_date']))),
                ],
              ),
            ],
            if (_payslip!['payment_method'] != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Method'),
                  Text((_payslip!['payment_method'] as String).replaceAll('_', ' ').toUpperCase()),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _rowItem(String label, double amount, {bool isBold = false, bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '${isDeduction ? '-' : ''}NPR ${currencyFormat.format(amount)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDeduction ? Colors.red.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }
}