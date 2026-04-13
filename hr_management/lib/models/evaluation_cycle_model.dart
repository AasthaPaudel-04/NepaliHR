class EvaluationCycleModel {
  final int id;
  final String cycleName;
  final String cycleType; // 'monthly' | 'quarterly'
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'active' | 'closed' | 'draft'
  final double selfWeight;
  final double peerWeight;
  final double managerWeight;
  final double hrWeight;
  final String? createdByName;
  final int evaluatedEmployeeCount;
 
  EvaluationCycleModel({
    required this.id,
    required this.cycleName,
    required this.cycleType,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.selfWeight,
    required this.peerWeight,
    required this.managerWeight,
    required this.hrWeight,
    this.createdByName,
    required this.evaluatedEmployeeCount,
  });
 
  factory EvaluationCycleModel.fromJson(Map<String, dynamic> json) {
    return EvaluationCycleModel(
      id: json['id'],
      cycleName: json['cycle_name'],
      cycleType: json['cycle_type'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'] ?? 'active',
      selfWeight: double.parse(json['self_weight'].toString()),
      peerWeight: double.parse(json['peer_weight'].toString()),
      managerWeight: double.parse(json['manager_weight'].toString()),
      hrWeight: double.parse(json['hr_weight'].toString()),
      createdByName: json['created_by_name'],
      evaluatedEmployeeCount: int.tryParse(json['evaluated_employee_count']?.toString() ?? '0') ?? 0,
    );
  }
}