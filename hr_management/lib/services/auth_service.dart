import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/employee.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        await _storage.write(key: 'auth_token', value: data['token']);
        return {'success': true, 'employee': Employee.fromJson(data['employee'])};
      }
      return {'success': false, 'error': data['error'] ?? 'Login failed'};
    } catch (_) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  Future<String?> getToken() async {
    return _storage.read(key: 'auth_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  Future<Employee?> getCurrentUser() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return null;
      final response = await http.get(
        Uri.parse(ApiConfig.getCurrentUser),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return Employee.fromJson(json.decode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllEmployees() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse(ApiConfig.allEmployees),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? data);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }
}
