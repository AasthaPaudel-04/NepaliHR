class DepartmentModel {
  final int id;
  final int companyId;
  final String name;
  final String? description;
  final bool isActive;
  final int roleCount;
  final DateTime createdAt;
 
  DepartmentModel({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    required this.isActive,
    required this.roleCount,
    required this.createdAt,
  });
 
  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'],
      companyId: json['company_id'],
      name: json['name'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
      roleCount: int.tryParse(json['role_count']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}