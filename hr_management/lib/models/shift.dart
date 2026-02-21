class ShiftModel {
  final int id;
  final int? companyId;
  final String shiftName;
  final String startTime;
  final String endTime;
  final int gracePeriodMinutes;
  final bool isActive;
  final int? assignedCount;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  ShiftModel({
    required this.id,
    this.companyId,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    required this.gracePeriodMinutes,
    required this.isActive,
    this.assignedCount,
    this.effectiveFrom,
    this.effectiveTo,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'],
      companyId: json['company_id'],
      shiftName: json['shift_name'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      gracePeriodMinutes: json['grace_period_minutes'] ?? 15,
      isActive: json['is_active'] ?? true,
      assignedCount: json['assigned_count'] != null
          ? int.parse(json['assigned_count'].toString())
          : null,
      effectiveFrom: json['effective_from'] != null
          ? DateTime.tryParse(json['effective_from'])
          : null,
      effectiveTo: json['effective_to'] != null
          ? DateTime.tryParse(json['effective_to'])
          : null,
    );
  }

  String get timeRange => '$startTime - $endTime';
}