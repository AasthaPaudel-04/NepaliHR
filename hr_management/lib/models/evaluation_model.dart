class EvaluationModel {
  final int id;
  final int cycleId;
  final int employeeId;
  final int evaluatorId;
  final String evaluatorType; // 'self' | 'peer' | 'manager' | 'hr'
  final String status; // 'pending' | 'submitted'
  final String cycleName;
  final DateTime startDate;
  final DateTime endDate;
  final String employeeName;
  final String employeeCode;
  final String? jobRoleName;
  final String? departmentName;
 
  EvaluationModel({
    required this.id,
    required this.cycleId,
    required this.employeeId,
    required this.evaluatorId,
    required this.evaluatorType,
    required this.status,
    required this.cycleName,
    required this.startDate,
    required this.endDate,
    required this.employeeName,
    required this.employeeCode,
    this.jobRoleName,
    this.departmentName,
  });
 
  factory EvaluationModel.fromJson(Map<String, dynamic> json) {
    return EvaluationModel(
      id: json['id'],
      cycleId: json['cycle_id'],
      employeeId: json['employee_id'],
      evaluatorId: json['evaluator_id'],
      evaluatorType: json['evaluator_type'],
      status: json['status'],
      cycleName: json['cycle_name'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      employeeName: json['employee_name'] ?? '',
      employeeCode: json['employee_code'] ?? '',
      jobRoleName: json['job_role_name'],
      departmentName: json['department_name'],
    );
  }
}