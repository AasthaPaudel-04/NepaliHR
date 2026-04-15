class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final int? referenceId;
  final String? referenceType;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.referenceId,
    this.referenceType,
  });

  String get typeIcon {
    switch (type) {
      case 'leave_request':   return '📋';
      case 'leave_approved':  return '✅';
      case 'leave_rejected':  return '❌';
      case 'payslip_generated': return '💰';
      case 'evaluation_assigned': return '📊';
      case 'evaluation_submitted': return '📝';
      case 'development_plan': return '🎯';
      case 'announcement':    return '📢';
      default:                return '🔔';
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'],
        type: json['type'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        isRead: json['is_read'] ?? false,
        createdAt: DateTime.parse(json['created_at']),
        referenceId: json['reference_id'],
        referenceType: json['reference_type'],
      );
}
