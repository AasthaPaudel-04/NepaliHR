class PayrollRecord {
  final int id;
  final int employeeId;
  final String? fullName;
  final String? employeeCode;
  final String? department;
  final String? position;
  final DateTime month;
  final double basicSalary;
  final double allowances;
  final double pfEmployee;
  final double pfEmployer;
  final double incomeTax;
  final double otherDeductions;
  final double netSalary;
  final DateTime? paymentDate;
  final String paymentStatus;
  final String? paymentMethod;
  final String? remarks;
  final DateTime createdAt;

  PayrollRecord({
    required this.id,
    required this.employeeId,
    this.fullName,
    this.employeeCode,
    this.department,
    this.position,
    required this.month,
    required this.basicSalary,
    required this.allowances,
    required this.pfEmployee,
    required this.pfEmployer,
    required this.incomeTax,
    required this.otherDeductions,
    required this.netSalary,
    this.paymentDate,
    required this.paymentStatus,
    this.paymentMethod,
    this.remarks,
    required this.createdAt,
  });

  factory PayrollRecord.fromJson(Map<String, dynamic> json) {
    return PayrollRecord(
      id: json['id'],
      employeeId: json['employee_id'],
      fullName: json['full_name'],
      employeeCode: json['employee_code'],
      department: json['department'],
      position: json['position'],
      month: DateTime.parse(json['month']),
      basicSalary: double.parse(json['basic_salary'].toString()),
      allowances: double.parse((json['allowances'] ?? 0).toString()),
      pfEmployee: double.parse((json['pf_employee'] ?? 0).toString()),
      pfEmployer: double.parse((json['pf_employer'] ?? 0).toString()),
      incomeTax: double.parse((json['income_tax'] ?? 0).toString()),
      otherDeductions: double.parse((json['other_deductions'] ?? 0).toString()),
      netSalary: double.parse(json['net_salary'].toString()),
      paymentDate: json['payment_date'] != null ? DateTime.parse(json['payment_date']) : null,
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentMethod: json['payment_method'],
      remarks: json['remarks'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  double get grossSalary => basicSalary + allowances;
  double get totalDeductions => pfEmployee + incomeTax + otherDeductions;
}