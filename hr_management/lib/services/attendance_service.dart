import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../config/api_config.dart';
import '../models/attendance.dart';

class AttendanceService {
  final _storage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return info.id;
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.identifierForVendor ?? 'unknown';
      }
      return 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<String> getIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4);
      for (var iface in interfaces) {
        for (var addr in iface.addresses) {
          if (addr.address.startsWith('192.168.')) return addr.address;
        }
      }
      return '192.168.0.108';
    } catch (_) {
      return '192.168.0.108';
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> clockIn() async {
    try {
      final deviceId = await getDeviceId();
      final ipAddress = await getIpAddress();
      final response = await http.post(
        Uri.parse(ApiConfig.clockIn),
        headers: await _getHeaders(),
        body: json.encode({'device_id': deviceId, 'ip_address': ipAddress}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'attendance': Attendance.fromJson(data['attendance']),
        };
      }
      return {'success': false, 'error': data['error'] ?? 'Clock in failed'};
    } catch (e) {
      return {'success': false, 'error': 'Network error. Check your connection.'};
    }
  }

  Future<Map<String, dynamic>> clockOut() async {
    try {
      final deviceId = await getDeviceId();
      final ipAddress = await getIpAddress();
      final response = await http.post(
        Uri.parse(ApiConfig.clockOut),
        headers: await _getHeaders(),
        body: json.encode({'device_id': deviceId, 'ip_address': ipAddress}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'attendance': Attendance.fromJson(data['attendance']),
          'total_hours': data['total_hours'],
        };
      }
      return {'success': false, 'error': data['error'] ?? 'Clock out failed'};
    } catch (_) {
      return {'success': false, 'error': 'Network error.'};
    }
  }

  Future<Map<String, dynamic>> getTodayAttendance() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.todayAttendance),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'hasClocked': data['hasClocked'],
          'attendance': data['attendance'] != null
              ? Attendance.fromJson(data['attendance'])
              : null,
          'shift': data['shift'],
        };
      }
      return {'success': false, 'error': 'Failed to fetch attendance'};
    } catch (_) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  Future<Map<String, dynamic>> getMonthlyAttendance(
      {int? month, int? year}) async {
    try {
      final now = DateTime.now();
      final m = month ?? now.month;
      final y = year ?? now.year;
      final response = await http.get(
        Uri.parse('${ApiConfig.monthlyAttendance}?month=$m&year=$y'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Attendance> list =
            (data['attendance'] as List).map((e) => Attendance.fromJson(e)).toList();
        return {'success': true, 'month': m, 'year': y, 'attendance': list};
      }
      return {'success': false, 'error': 'Failed'};
    } catch (_) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  Future<Map<String, dynamic>> getAttendanceSummary(
      {int? month, int? year}) async {
    try {
      final now = DateTime.now();
      final m = month ?? now.month;
      final y = year ?? now.year;
      final response = await http.get(
        Uri.parse('${ApiConfig.attendanceSummary}?month=$m&year=$y'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'summary': AttendanceSummary.fromJson(data['summary']),
        };
      }
      return {'success': false, 'error': 'Failed'};
    } catch (_) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  // Admin: get all employees' attendance for a specific date
  Future<List<Map<String, dynamic>>> getAllEmployeesToday(
      {String? date}) async {
    try {
      final d = date ?? DateTime.now().toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('${ApiConfig.allEmployeesToday}?date=$d'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getMyDevices() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.myDevices),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<RegisteredDevice> devices = (data['devices'] as List)
            .map((e) => RegisteredDevice.fromJson(e))
            .toList();
        return {
          'success': true,
          'devices': devices,
          'maxDevices': data['maxDevices'],
        };
      }
      return {'success': false, 'error': 'Failed to fetch devices'};
    } catch (_) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  Future<Map<String, dynamic>> removeDevice(int deviceId) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.removeDevice(deviceId)),
        headers: await _getHeaders(),
      );
      final data = json.decode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? data['error'],
      };
    } catch (_) {
      return {'success': false, 'error': 'Network error'};
    }
  }
}
