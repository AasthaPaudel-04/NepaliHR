// lib/models/notification_model.dart
class NotificationModel {
  final int id;
  final int recipientId;
  final int? senderId;
  final String? senderName;
  final String type;
  final String title;
  final String body;
  final int? referenceId;
  final String? referenceType;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    this.senderId,
    this.senderName,
    required this.type,
    required this.title,
    required this.body,
    this.referenceId,
    this.referenceType,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      recipientId: json['recipient_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      referenceId: json['reference_id'],
      referenceType: json['reference_type'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get typeIcon {
    switch (type) {
      case 'leave_request': return '📋';
      case 'leave_approved': return '✅';
      case 'leave_rejected': return '❌';
      case 'evaluation_assigned': return '📊';
      case 'evaluation_submitted': return '✔️';
      case 'payslip_generated': return '💰';
      case 'announcement': return '📢';
      case 'development_plan': return '🎯';
      default: return '🔔';
    }
  }
}
