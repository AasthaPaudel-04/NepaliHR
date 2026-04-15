class ApiConfig {
  static const String baseUrl = 'http://192.168.137.1:3000/api';

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String getCurrentUser = '$baseUrl/auth/me';
  static const String allEmployees = '$baseUrl/auth/employees';

  // Leave
  static const String applyLeave = '$baseUrl/leave/request';
  static const String myLeaveRequests = '$baseUrl/leave/my-requests';
  static const String leaveBalance = '$baseUrl/leave/my-balance';
  static const String pendingApprovals = '$baseUrl/leave/pending';
  static const String leaveTypes = '$baseUrl/leave/types';
  static const String leaveTypesAll = '$baseUrl/leave/types/all';
  static String leaveTypeById(int id) => '$baseUrl/leave/types/$id';
  static String approveLeave(int id) => '$baseUrl/leave/$id/approve';
  static String rejectLeave(int id) => '$baseUrl/leave/$id/reject';

  // Attendance
  static const String clockIn = '$baseUrl/attendance/clock-in';
  static const String clockOut = '$baseUrl/attendance/clock-out';
  static const String todayAttendance = '$baseUrl/attendance/today';
  static const String monthlyAttendance = '$baseUrl/attendance/monthly';
  static const String attendanceSummary = '$baseUrl/attendance/summary';
  static const String teamAttendance = '$baseUrl/attendance/team';
  static const String allEmployeesToday = '$baseUrl/attendance/all-today';
  static const String monthlyAttendanceAdmin = '$baseUrl/attendance/monthly-admin';
  static const String myDevices = '$baseUrl/attendance/my-devices';
  static String removeDevice(int id) => '$baseUrl/attendance/devices/$id';

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

  // Notifications
  static const String notifications     = '$baseUrl/notifications';
  static const String notifUnreadCount  = '$baseUrl/notifications/unread-count';
  static const String notifMarkAllRead  = '$baseUrl/notifications/read-all';
  static String notifMarkRead(int id)   => '$baseUrl/notifications/$id/read';

  // Departments
  static const String departments = '$baseUrl/departments';
  static String departmentById(int id) => '$baseUrl/departments/$id';

  // Job Roles
  static const String jobRoles = '$baseUrl/job-roles';
  static String jobRoleById(int id) => '$baseUrl/job-roles/$id';
  static const String assignEmployeeRole = '$baseUrl/job-roles/assign-employee';

  // KPIs
  static const String kpis = '$baseUrl/kpis';
  static String kpiById(int id) => '$baseUrl/kpis/$id';
  static String kpisForRole(int roleId) => '$baseUrl/kpis/role/$roleId';
  static const String assignKPIToRoles = '$baseUrl/kpis/assign-roles';

  // Evaluation Cycles
  static const String evaluationCycles = '$baseUrl/evaluation-cycles';
  static String evaluationCycleById(int id) => '$baseUrl/evaluation-cycles/$id';
  static String initiateCycle(int cycleId) => '$baseUrl/evaluations/cycle/$cycleId/initiate';

  // Evaluations
  static const String myPendingEvaluations = '$baseUrl/evaluations/my-evaluations';
  static String evaluationForm(int evaluationId) => '$baseUrl/evaluations/form/$evaluationId';
  static String submitEvaluation(int evaluationId) => '$baseUrl/evaluations/submit/$evaluationId';
  static String evaluationFeedback(int evaluationId) => '$baseUrl/evaluations/feedback/$evaluationId';
  static const String assignPeerEvaluator = '$baseUrl/evaluations/assign-peer';
  static String cycleEvaluationStatus(int cycleId) => '$baseUrl/evaluations/cycle-status/$cycleId';

  // Performance Results
  static String performanceResults(int cycleId) => '$baseUrl/evaluations/results/$cycleId';
  static String myPerformanceResult(int cycleId) => '$baseUrl/evaluations/my-result/$cycleId';
  static String developmentPlan(int cycleId, int employeeId) =>
      '$baseUrl/evaluations/development/$cycleId/$employeeId';
}
