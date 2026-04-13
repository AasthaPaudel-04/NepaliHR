class KpiModel {
  final int id;
  final String name;
  final String? description;
  final String kpiType; // 'quantitative' | 'rating'
  final double? targetValue;
  final double weightage;
  final bool isActive;
  final String? createdByName;
  final List<Map<String, dynamic>> assignedRoles;
 
  KpiModel({
    required this.id,
    required this.name,
    this.description,
    required this.kpiType,
    this.targetValue,
    required this.weightage,
    required this.isActive,
    this.createdByName,
    required this.assignedRoles,
  });
 
  bool get isQuantitative => kpiType == 'quantitative';
 
  factory KpiModel.fromJson(Map<String, dynamic> json) {
    return KpiModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      kpiType: json['kpi_type'],
      targetValue: json['target_value'] != null
          ? double.tryParse(json['target_value'].toString())
          : null,
      weightage: double.parse(json['weightage'].toString()),
      isActive: json['is_active'] ?? true,
      createdByName: json['created_by_name'],
      assignedRoles: List<Map<String, dynamic>>.from(json['assigned_roles'] ?? []),
    );
  }
}