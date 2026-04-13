class JobRoleModel {
  final int id;
  final int departmentId;
  final String name;
  final String? description;
  final String departmentName;
  final bool isActive;
  final int employeeCount;
  final int kpiCount;
 
  JobRoleModel({
    required this.id,
    required this.departmentId,
    required this.name,
    this.description,
    required this.departmentName,
    required this.isActive,
    required this.employeeCount,
    required this.kpiCount,
  });
 
  factory JobRoleModel.fromJson(Map<String, dynamic> json) {
    return JobRoleModel(
      id: json['id'],
      departmentId: json['department_id'],
      name: json['name'],
      description: json['description'],
      departmentName: json['department_name'] ?? '',
      isActive: json['is_active'] ?? true,
      employeeCount: int.tryParse(json['employee_count']?.toString() ?? '0') ?? 0,
      kpiCount: int.tryParse(json['kpi_count']?.toString() ?? '0') ?? 0,
    );
  }
}