class LeaveRequest {
  final int id;
  final int employeeId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String? reason;
  final String status;
  final int? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final String? fullName;
  final String? employeeCode;
  final String? approvedByName;

  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    this.reason,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    this.fullName,
    this.employeeCode,
    this.approvedByName,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'],
      employeeId: json['employee_id'],
      leaveType: json['leave_type'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      totalDays: json['total_days'],
      reason: json['reason'],
      status: json['status'],
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at']),
      fullName: json['full_name'],
      employeeCode: json['employee_code'],
      approvedByName: json['approved_by_name'],
    );
  }
}

class LeaveBalance {
  final int casualLeave;
  final int sickLeave;
  final int annualLeave;

  LeaveBalance({
    required this.casualLeave,
    required this.sickLeave,
    required this.annualLeave,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      casualLeave: json['casual_leave_balance'],
      sickLeave: json['sick_leave_balance'],
      annualLeave: json['annual_leave_balance'],
    );
  }

  int get total => casualLeave + sickLeave + annualLeave;
}