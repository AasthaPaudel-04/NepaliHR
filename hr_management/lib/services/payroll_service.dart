import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../models/payroll.dart';

class PayrollService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get my payslips
  Future<List<PayrollRecord>> getMyPayslips() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.myPayslips),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((e) => PayrollRecord.fromJson(e))
            .toList();
      }
      throw Exception('Failed to load payslips');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get my salary structure
  Future<Map<String, dynamic>> getMySalary() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.mySalary),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load salary info');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get payslip detail
  Future<Map<String, dynamic>> getPayslipDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.payslipDetail(id)),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      throw Exception('Failed to load payslip');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Admin: Get all payrolls
  Future<List<PayrollRecord>> getAllPayrolls({String? monthYear, String? status}) async {
    try {
      String url = ApiConfig.allPayrolls;
      final params = <String, String>{};
      if (monthYear != null) params['month_year'] = monthYear;
      if (status != null) params['status'] = status;
      if (params.isNotEmpty) {
        url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      final response = await http.get(Uri.parse(url), headers: await _headers());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List).map((e) => PayrollRecord.fromJson(e)).toList();
      }
      throw Exception('Failed to load payrolls');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Admin: Generate payroll
  Future<Map<String, dynamic>> generatePayroll(int employeeId, String monthYear) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.generatePayroll),
        headers: await _headers(),
        body: json.encode({'employee_id': employeeId, 'month_year': monthYear}),
      );
      final data = json.decode(response.body);
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  // Admin: Generate bulk payroll
  Future<Map<String, dynamic>> generateBulkPayroll(String monthYear) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.generateBulkPayroll),
        headers: await _headers(),
        body: json.encode({'month_year': monthYear}),
      );
      final data = json.decode(response.body);
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  // Admin: Mark as paid
  Future<Map<String, dynamic>> markAsPaid(int id, String paymentMethod) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.markPayrollPaid(id)),
        headers: await _headers(),
        body: json.encode({'payment_method': paymentMethod}),
      );
      final data = json.decode(response.body);
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }
}