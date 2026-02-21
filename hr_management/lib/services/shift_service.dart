import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../models/shift.dart';

class ShiftService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<ShiftModel?> getMyShift() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.myShift),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] == null) return null;
        return ShiftModel.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<ShiftModel>> getAllShifts() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.allShifts),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List).map((e) => ShiftModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createShift({
    required String shiftName,
    required String startTime,
    required String endTime,
    int gracePeriod = 15,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createShift),
        headers: await _headers(),
        body: json.encode({
          'shift_name': shiftName,
          'start_time': startTime,
          'end_time': endTime,
          'grace_period_minutes': gracePeriod,
        }),
      );
      final data = json.decode(response.body);
      return {'success': response.statusCode == 201, ...data};
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  Future<Map<String, dynamic>> updateShift(int id, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.updateShift(id)),
        headers: await _headers(),
        body: json.encode(body),
      );
      final data = json.decode(response.body);
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  Future<Map<String, dynamic>> deleteShift(int id) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteShift(id)),
        headers: await _headers(),
      );
      final data = json.decode(response.body);
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  Future<Map<String, dynamic>> assignShift({
    required int employeeId,
    required int shiftId,
    required String effectiveFrom,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.assignShift),
        headers: await _headers(),
        body: json.encode({
          'employee_id': employeeId,
          'shift_id': shiftId,
          'effective_from': effectiveFrom,
        }),
      );
      final data = json.decode(response.body);
      return {'success': response.statusCode == 201, ...data};
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  Future<List<Map<String, dynamic>>> getEmployeeShifts() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.employeeShifts),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}