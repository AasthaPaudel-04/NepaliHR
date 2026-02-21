import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/leave_request.dart';
import 'auth_service.dart';

class LeaveService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> applyLeave({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/leave/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'leave_type': leaveType,
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
          'reason': reason,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error']};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<List<LeaveRequest>> getMyRequests() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/leave/my-requests'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => LeaveRequest.fromJson(item)).toList();
      }
      throw Exception('Failed to load requests');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<LeaveBalance> getBalance() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/leave/my-balance'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return LeaveBalance.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to load balance');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<LeaveRequest>> getPending() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/leave/pending'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => LeaveRequest.fromJson(item)).toList();
      }
      throw Exception('Failed to load pending');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> approveLeave(int id) async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/leave/$id/approve'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectLeave(int id, String reason) async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/leave/$id/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'rejection_reason': reason}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}