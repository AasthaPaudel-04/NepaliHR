class Attendance {
  final int? id;
  final int employeeId;
  final String date;
  final String? checkInTime;
  final String? checkOutTime;
  final String? checkInIp;
  final String? checkInDeviceId;
  final String? checkOutIp;
  final String? checkOutDeviceId;
  final double? totalHours;
  final String? status;
  final String? notes;
  final String? shiftName;
  final String? shiftStartTime;
  final String? shiftEndTime;

  Attendance({
    this.id,
    required this.employeeId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.checkInIp,
    this.checkInDeviceId,
    this.checkOutIp,
    this.checkOutDeviceId,
    this.totalHours,
    this.status,
    this.notes,
    this.shiftName,
    this.shiftStartTime,
    this.shiftEndTime,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      employeeId: json['employee_id'],
      date: json['date'],
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      checkInIp: json['check_in_ip'],
      checkInDeviceId: json['check_in_device_id'],
      checkOutIp: json['check_out_ip'],
      checkOutDeviceId: json['check_out_device_id'],
      totalHours: json['total_hours'] != null 
          ? double.tryParse(json['total_hours'].toString())
          : null,
      status: json['status'],
      notes: json['notes'],
      shiftName: json['shift_name'],
      shiftStartTime: json['start_time'],
      shiftEndTime: json['end_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'date': date,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'check_in_ip': checkInIp,
      'check_in_device_id': checkInDeviceId,
      'check_out_ip': checkOutIp,
      'check_out_device_id': checkOutDeviceId,
      'total_hours': totalHours,
      'status': status,
      'notes': notes,
    };
  }
}

class AttendanceSummary {
  final int totalDays;
  final int presentDays;
  final int lateDays;
  final int halfDays;
  final int absentDays;
  final int wfhDays;
  final double? avgHours;
  final double? totalHoursWorked;

  AttendanceSummary({
    required this.totalDays,
    required this.presentDays,
    required this.lateDays,
    required this.halfDays,
    required this.absentDays,
    required this.wfhDays,
    this.avgHours,
    this.totalHoursWorked,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalDays: int.tryParse(json['total_days']?.toString() ?? '0') ?? 0,
      presentDays: int.tryParse(json['present_days']?.toString() ?? '0') ?? 0,
      lateDays: int.tryParse(json['late_days']?.toString() ?? '0') ?? 0,
      halfDays: int.tryParse(json['half_days']?.toString() ?? '0') ?? 0,
      absentDays: int.tryParse(json['absent_days']?.toString() ?? '0') ?? 0,
      wfhDays: int.tryParse(json['wfh_days']?.toString() ?? '0') ?? 0,
      avgHours: json['avg_hours'] != null 
          ? double.tryParse(json['avg_hours'].toString())
          : null,
      totalHoursWorked: json['total_hours_worked'] != null 
          ? double.tryParse(json['total_hours_worked'].toString())
          : null,
    );
  }
}

class RegisteredDevice {
  final int id;
  final String deviceId;
  final String? deviceName;
  final bool isActive;
  final String registeredAt;
  final String? lastUsedAt;

  RegisteredDevice({
    required this.id,
    required this.deviceId,
    this.deviceName,
    required this.isActive,
    required this.registeredAt,
    this.lastUsedAt,
  });

  factory RegisteredDevice.fromJson(Map<String, dynamic> json) {
    return RegisteredDevice(
      id: json['id'],
      deviceId: json['device_id'],
      deviceName: json['device_name'],
      isActive: json['is_active'] ?? true,
      registeredAt: json['registered_at'],
      lastUsedAt: json['last_used_at'],
    );
  }
}