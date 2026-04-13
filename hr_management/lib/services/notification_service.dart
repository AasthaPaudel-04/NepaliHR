import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.notifications), headers: await _headers());
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return {
          'success': true,
          'data': (data['data'] as List).map((e) => NotificationModel.fromJson(e)).toList(),
          'unread_count': data['unread_count'] ?? 0,
        };
      }
      return {'success': false, 'data': [], 'unread_count': 0};
    } catch (_) {
      return {'success': false, 'data': [], 'unread_count': 0};
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.notificationsUnreadCount),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        return json.decode(res.body)['count'] ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markRead(int id) async {
    try {
      await http.put(Uri.parse(ApiConfig.notificationMarkRead(id)), headers: await _headers());
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await http.put(Uri.parse(ApiConfig.notificationsReadAll), headers: await _headers());
    } catch (_) {}
  }
}
