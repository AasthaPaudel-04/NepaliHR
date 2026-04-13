class PerformanceResultModel {
  final int id;
  final int cycleId;
  final int employeeId;
  final double selfScore;
  final double peerScore;
  final double managerScore;
  final double hrScore;
  final double finalScore;
  final String grade; // 'Excellent' | 'Good' | 'Average' | 'Poor'
  final String? developmentAction;
  final String? devNotes;
  final String? fullName;
  final String? employeeCode;
  final String? jobRoleName;
  final String? departmentName;
  final String? cycleName;
 
  PerformanceResultModel({
    required this.id,
    required this.cycleId,
    required this.employeeId,
    required this.selfScore,
    required this.peerScore,
    required this.managerScore,
    required this.hrScore,
    required this.finalScore,
    required this.grade,
    this.developmentAction,
    this.devNotes,
    this.fullName,
    this.employeeCode,
    this.jobRoleName,
    this.departmentName,
    this.cycleName,
  });
 
  factory PerformanceResultModel.fromJson(Map<String, dynamic> json) {
    return PerformanceResultModel(
      id: json['id'],
      cycleId: json['cycle_id'],
      employeeId: json['employee_id'],
      selfScore: double.parse(json['self_score']?.toString() ?? '0'),
      peerScore: double.parse(json['peer_score']?.toString() ?? '0'),
      managerScore: double.parse(json['manager_score']?.toString() ?? '0'),
      hrScore: double.parse(json['hr_score']?.toString() ?? '0'),
      finalScore: double.parse(json['final_score']?.toString() ?? '0'),
      grade: json['grade'] ?? 'Poor',
      developmentAction: json['development_action'],
      devNotes: json['dev_notes'],
      fullName: json['full_name'],
      employeeCode: json['employee_code'],
      jobRoleName: json['job_role_name'],
      departmentName: json['department_name'],
      cycleName: json['cycle_name'],
    );
  }
 
  // Helper for grade color
  String get gradeEmoji {
    switch (grade) {
      case 'Excellent': return '🏆';
      case 'Good': return '👍';
      case 'Average': return '📊';
      case 'Poor': return '⚠️';
      default: return '📊';
    }
  }
}