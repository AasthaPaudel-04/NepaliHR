import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.notifications),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['data'] ?? data;
        return (list as List).map((e) => NotificationModel.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.notifUnreadCount),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['count'] ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> markRead(int id) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.notifMarkRead(id)),
        headers: await _headers(),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllRead() async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.notifMarkAllRead),
        headers: await _headers(),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
