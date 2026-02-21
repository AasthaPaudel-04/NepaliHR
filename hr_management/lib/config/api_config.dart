class ApiConfig {
  static const String baseUrl = 'http://192.168.0.108:3000/api';

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String getCurrentUser = '$baseUrl/auth/me';

  // Leave
  static const String applyLeave = '$baseUrl/leave/request';
  static const String myLeaveRequests = '$baseUrl/leave/my-requests';
  static const String leaveBalance = '$baseUrl/leave/my-balance';
  static const String pendingApprovals = '$baseUrl/leave/pending';

  // Attendance
  static const String clockIn = '$baseUrl/attendance/clock-in';
  static const String clockOut = '$baseUrl/attendance/clock-out';
  static const String todayAttendance = '$baseUrl/attendance/today';
  static const String monthlyAttendance = '$baseUrl/attendance/monthly';
  static const String attendanceSummary = '$baseUrl/attendance/summary';
  static const String teamAttendance = '$baseUrl/attendance/team';

  // Payroll
  static const String myPayslips = '$baseUrl/payroll/my-payslips';
  static const String mySalary = '$baseUrl/payroll/my-salary';
  static String payslipDetail(int id) => '$baseUrl/payroll/payslip/$id';
  static const String allPayrolls = '$baseUrl/payroll/all';
  static const String generatePayroll = '$baseUrl/payroll/generate';
  static const String generateBulkPayroll = '$baseUrl/payroll/generate-bulk';
  static String markPayrollPaid(int id) => '$baseUrl/payroll/$id/mark-paid';
  static const String salaryStructure = '$baseUrl/payroll/salary';

  // Shifts
  static const String myShift = '$baseUrl/shifts/my-shift';
  static const String allShifts = '$baseUrl/shifts/';
  static const String createShift = '$baseUrl/shifts/';
  static String updateShift(int id) => '$baseUrl/shifts/$id';
  static String deleteShift(int id) => '$baseUrl/shifts/$id';
  static const String assignShift = '$baseUrl/shifts/assign';
  static const String employeeShifts = '$baseUrl/shifts/employee-shifts';

  // Documents
  static const String myDocuments = '$baseUrl/documents/my-documents';
  static const String uploadDocument = '$baseUrl/documents/upload';
  static String deleteDocument(int id) => '$baseUrl/documents/$id';
  static const String allDocuments = '$baseUrl/documents/all';

  // Announcements
  static const String announcements = '$baseUrl/announcements/';
  static const String announcementRecentCount = '$baseUrl/announcements/recent-count';
  static String announcementById(int id) => '$baseUrl/announcements/$id';
}