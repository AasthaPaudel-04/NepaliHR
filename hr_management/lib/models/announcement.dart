class AnnouncementModel {
  final int id;
  final int? companyId;
  final String title;
  final String message;
  final String priority;
  final int createdBy;
  final String? createdByName;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    this.companyId,
    required this.title,
    required this.message,
    required this.priority,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'],
      companyId: json['company_id'],
      title: json['title'],
      message: json['message'],
      priority: json['priority'] ?? 'normal',
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Priority color helper
  String get priorityLabel {
    switch (priority) {
      case 'urgent':
        return 'URGENT';
      case 'high':
        return 'HIGH';
      case 'low':
        return 'LOW';
      default:
        return 'NORMAL';
    }
  }

  bool get isRecent =>
      DateTime.now().difference(createdAt).inDays <= 7;
}