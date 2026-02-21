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

  // Get device ID
  Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id; // Unique Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      }
      return 'unknown';
    } catch (e) {
      print('Error getting device ID: $e');
      return 'unknown';
    }
  }

// Get IP Address - Use local network IP only
Future<String> getIpAddress() async {
  try {
    // Get device's local network IP
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    
    for (var interface in interfaces) {
      print('🔍 Checking interface: ${interface.name}');
      
      for (var addr in interface.addresses) {
        print('   IP: ${addr.address}');
        
        // Only accept 192.168.x.x addresses (local network)
        if (addr.address.startsWith('192.168.')) {
          print('✅ Using local IP: ${addr.address}');
          return addr.address;
        }
      }
    }
    
    // Fallback
    print('⚠️ No 192.168.x.x IP found, using fallback');
    return '192.168.0.108';
  } catch (e) {
    print('❌ Error getting IP: $e');
    return '192.168.0.108';
  }
}
  // Get authorization header
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Clock In
  Future<Map<String, dynamic>> clockIn() async {
    try {
      final deviceId = await getDeviceId();
      final ipAddress = await getIpAddress();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/attendance/clock-in'),
        headers: await _getHeaders(),
        body: json.encode({
          'device_id': deviceId,
          'ip_address': ipAddress,
        }),
      );

      print('Clock in response: ${response.statusCode}');
      print('Clock in body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'attendance': Attendance.fromJson(data['attendance']),
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Clock in failed',
        };
      }
    } catch (e) {
      print('Clock in error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // Clock Out
  Future<Map<String, dynamic>> clockOut() async {
    try {
      final deviceId = await getDeviceId();
      final ipAddress = await getIpAddress();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/attendance/clock-out'),
        headers: await _getHeaders(),
        body: json.encode({
          'device_id': deviceId,
          'ip_address': ipAddress,
        }),
      );

      print('Clock out response: ${response.statusCode}');
      print('Clock out body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'attendance': Attendance.fromJson(data['attendance']),
          'total_hours': data['total_hours'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Clock out failed',
        };
      }
    } catch (e) {
      print('Clock out error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // Get Today's Attendance
  Future<Map<String, dynamic>> getTodayAttendance() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance/today'),
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
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch today\'s attendance',
        };
      }
    } catch (e) {
      print('Get today attendance error: $e');
      return {
        'success': false,
        'error': 'Network error',
      };
    }
  }

  // Get Monthly Attendance
  Future<Map<String, dynamic>> getMonthlyAttendance({int? month, int? year}) async {
    try {
      final now = DateTime.now();
      final targetMonth = month ?? now.month;
      final targetYear = year ?? now.year;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance/monthly?month=$targetMonth&year=$targetYear'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final List<Attendance> attendanceList = (data['attendance'] as List)
            .map((item) => Attendance.fromJson(item))
            .toList();

        return {
          'success': true,
          'month': data['month'],
          'year': data['year'],
          'attendance': attendanceList,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch monthly attendance',
        };
      }
    } catch (e) {
      print('Get monthly attendance error: $e');
      return {
        'success': false,
        'error': 'Network error',
      };
    }
  }

  // Get Attendance Summary
  Future<Map<String, dynamic>> getAttendanceSummary({int? month, int? year}) async {
    try {
      final now = DateTime.now();
      final targetMonth = month ?? now.month;
      final targetYear = year ?? now.year;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance/summary?month=$targetMonth&year=$targetYear'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return {
          'success': true,
          'month': data['month'],
          'year': data['year'],
          'summary': AttendanceSummary.fromJson(data['summary']),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch attendance summary',
        };
      }
    } catch (e) {
      print('Get attendance summary error: $e');
      return {
        'success': false,
        'error': 'Network error',
      };
    }
  }

  // Get My Devices
  Future<Map<String, dynamic>> getMyDevices() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance/my-devices'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final List<RegisteredDevice> devices = (data['devices'] as List)
            .map((item) => RegisteredDevice.fromJson(item))
            .toList();

        return {
          'success': true,
          'devices': devices,
          'maxDevices': data['maxDevices'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch devices',
        };
      }
    } catch (e) {
      print('Get devices error: $e');
      return {
        'success': false,
        'error': 'Network error',
      };
    }
  }

  // Remove Device
  Future<Map<String, dynamic>> removeDevice(int deviceId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/attendance/devices/$deviceId'),
        headers: await _getHeaders(),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to remove device',
        };
      }
    } catch (e) {
      print('Remove device error: $e');
      return {
        'success': false,
        'error': 'Network error',
      };
    }
  }
}