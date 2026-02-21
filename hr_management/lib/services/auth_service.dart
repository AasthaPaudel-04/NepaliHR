import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/employee.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'auth_token';

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Save token
        await _storage.write(key: _tokenKey, value: data['token']);
        
        // Parse employee data
        final employee = Employee.fromJson(data['employee']);
        
        return {
          'success': true,
          'employee': employee,
          'message': data['message']
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Login failed'
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection and ensure backend is running.'
      };
    }
  }

  // Get saved token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Get current user info
  Future<Employee?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse(ApiConfig.getCurrentUser),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Employee.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }
}