import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../models/announcement.dart';

class AnnouncementService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<AnnouncementModel>> getAnnouncements({String? priority}) async {
    try {
      String url = ApiConfig.announcements;
      if (priority != null) url += '?priority=$priority';

      final response = await http.get(Uri.parse(url), headers: await _headers());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List).map((e) => AnnouncementModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<int> getRecentCount() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.announcementRecentCount),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String message,
    String priority = 'normal',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.announcements),
        headers: await _headers(),
        body: json.encode({'title': title, 'message': message, 'priority': priority}),
      );
      final data = json.decode(response.body);
      return {'success': response.statusCode == 201, ...data};
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  Future<Map<String, dynamic>> updateAnnouncement(int id, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.announcementById(id)),
        headers: await _headers(),
        body: json.encode(body),
      );
      final data = json.decode(response.body);
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  Future<Map<String, dynamic>> deleteAnnouncement(int id) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.announcementById(id)),
        headers: await _headers(),
      );
      final data = json.decode(response.body);
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }
}