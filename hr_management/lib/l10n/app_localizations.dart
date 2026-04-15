import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ne'),
  ];

  bool get isNepali => locale.languageCode == 'ne';

  static const Map<String, Map<String, String>> _values = {
    'en': {
      // Navigation
      'home': 'Home', 'attendance': 'Attendance', 'leave': 'Leave',
      'payroll': 'Payroll', 'profile': 'Profile', 'dashboard': 'Dashboard',
      'calendar': 'Calendar',
      // Greeting
      'goodMorning': 'Good morning 👋', 'goodAfternoon': 'Good afternoon 👋',
      'goodEvening': 'Good evening 👋',
      // Auth
      'login': 'Login', 'logout': 'Logout', 'email': 'Email',
      'password': 'Password', 'welcomeBack': 'Welcome back',
      'signInToContinue': 'Sign in to continue',
      // Attendance
      'clockIn': 'Clock In', 'clockOut': 'Clock Out',
      'completedForToday': 'Completed for Today',
      'present': 'Present', 'late': 'Late', 'absent': 'Absent',
      'halfDay': 'Half Day', 'wfh': 'WFH', 'all': 'All',
      'notClockedIn': 'Not clocked in',
      'myAttendance': 'My Attendance', 'teamAttendance': 'Team Attendance',
      'allEmployees': 'All Employees', 'selectDate': 'Select Date',
      'attendanceSummary': 'Summary', 'totalDays': 'Total',
      'avgHours': 'Avg Hrs', 'totalHours': 'Total Hrs',
      'noShiftAssigned': 'No shift assigned. Contact HR.',
      'ipNotAuthorized': 'IP not authorized. Contact HR.',
      // Leave
      'applyLeave': 'Apply Leave', 'leaveType': 'Leave Type',
      'startDate': 'Start Date', 'endDate': 'End Date',
      'reason': 'Reason (Optional)', 'submitRequest': 'Submit Request',
      'leaveBalance': 'Leave Balance', 'casualLeave': 'Casual',
      'sickLeave': 'Sick', 'annualLeave': 'Annual', 'days': 'days',
      'myRequests': 'My Requests', 'pendingApprovals': 'Pending Approvals',
      'leaveTypes': 'Leave Types', 'approve': 'Approve', 'reject': 'Reject',
      'pending': 'Pending', 'approved': 'Approved', 'rejected': 'Rejected',
      'cancelled': 'Cancelled', 'rejectionReason': 'Rejection Reason',
      'noLeaveRequests': 'No leave requests',
      'noPendingApprovals': 'No pending approvals',
      // Payroll
      'myPayslips': 'My Payslips', 'allPayrolls': 'All Payrolls',
      'generatePayroll': 'Generate Payroll', 'bulkGenerate': 'Bulk Generate',
      'markAsPaid': 'Mark as Paid', 'basicSalary': 'Basic Salary',
      'allowances': 'Allowances', 'grossSalary': 'Gross Salary',
      'deductions': 'Deductions', 'netSalary': 'Net Salary', 'paid': 'Paid',
      // Shifts
      'editShifts': 'Edit Shifts', 'myShift': 'My Shift',
      'noShift': 'No shift assigned',
      // Documents
      'myDocuments': 'My Documents', 'allDocuments': 'All Documents',
      'upload': 'Upload', 'deleteDocument': 'Delete Document',
      'noDocuments': 'No documents found',
      'downloadingFile': 'Downloading...', 'citizenship': 'Citizenship',
      'certificate': 'Certificate', 'contract': 'Contract',
      'photo': 'Photo', 'other': 'Other',
      // Announcements & Notifications
      'announcements': 'Announcements', 'notifications': 'Notifications',
      'noNotifications': 'No notifications yet',
      'markAllRead': 'Mark all read',
      'createAnnouncement': 'Create Announcement',
      // Performance
      'myEvaluations': 'My Evaluations', 'evals': 'Evals',
      'evaluationCycles': 'Eval Cycles', 'performanceResults': 'Results',
      'kpiManagement': 'KPI Management', 'departments': 'Departments',
      'jobRoles': 'Job Roles', 'addEmployee': 'Add Employee',
      // Dashboard
      'hrDashboard': 'HR Dashboard', 'attendanceRate': 'Attendance Rate',
      'absentToday': 'Absent Today', 'weeklyAttendance': 'Weekly Attendance',
      'todayBreakdown': "Today's Breakdown", 'quickActions': 'Quick Actions',
      'upcomingEvents': 'Upcoming Events', 'thisWeek': 'This Week',
      'totalStaff': 'Total Staff',
      // Calendar
      'nepaliCalendar': 'Nepali Calendar',
      // Common
      'cancel': 'Cancel', 'save': 'Save', 'delete': 'Delete',
      'edit': 'Edit', 'create': 'Create', 'confirm': 'Confirm',
      'close': 'Close', 'refresh': 'Refresh',
      'loading': 'Loading...', 'error': 'An error occurred',
      'noData': 'No data available', 'employees': 'Employees',
      'language': 'Language', 'english': 'English', 'nepali': 'नेपाली',
      'changeLanguage': 'Change Language',
    },
    'ne': {
      // Navigation
      'home': 'गृह', 'attendance': 'उपस्थिति', 'leave': 'बिदा',
      'payroll': 'तलब', 'profile': 'प्रोफाइल', 'dashboard': 'ड्यासबोर्ड',
      'calendar': 'पात्रो',
      // Greeting
      'goodMorning': 'शुभ प्रभात 👋', 'goodAfternoon': 'शुभ अपराह्न 👋',
      'goodEvening': 'शुभ साँझ 👋',
      // Auth
      'login': 'लगइन', 'logout': 'लगआउट', 'email': 'इमेल',
      'password': 'पासवर्ड', 'welcomeBack': 'स्वागत छ',
      'signInToContinue': 'जारी राख्न साइन इन गर्नुहोस्',
      // Attendance
      'clockIn': 'हाजिरी लगाउनुहोस्', 'clockOut': 'हाजिरी बाहिर',
      'completedForToday': 'आजको लागि पूरा भयो',
      'present': 'उपस्थित', 'late': 'ढिलो', 'absent': 'अनुपस्थित',
      'halfDay': 'आधा दिन', 'wfh': 'घरबाट काम', 'all': 'सबै',
      'notClockedIn': 'हाजिरी लगाइएको छैन',
      'myAttendance': 'मेरो उपस्थिति', 'teamAttendance': 'टोलीको उपस्थिति',
      'allEmployees': 'सबै कर्मचारी', 'selectDate': 'मिति छान्नुहोस्',
      'attendanceSummary': 'सारांश', 'totalDays': 'कुल',
      'avgHours': 'औसत घण्टा', 'totalHours': 'कुल घण्टा',
      'noShiftAssigned': 'शिफ्ट तोकिएको छैन। HR सम्पर्क गर्नुहोस्।',
      'ipNotAuthorized': 'IP अधिकृत छैन। HR सम्पर्क गर्नुहोस्।',
      // Leave
      'applyLeave': 'बिदाको लागि निवेदन', 'leaveType': 'बिदाको प्रकार',
      'startDate': 'सुरु मिति', 'endDate': 'अन्त्य मिति',
      'reason': 'कारण (ऐच्छिक)', 'submitRequest': 'निवेदन पठाउनुहोस्',
      'leaveBalance': 'बिदा शेष', 'casualLeave': 'आकस्मिक',
      'sickLeave': 'बिरामी', 'annualLeave': 'वार्षिक', 'days': 'दिन',
      'myRequests': 'मेरा निवेदन', 'pendingApprovals': 'अनुमोदन बाँकी',
      'leaveTypes': 'बिदाका प्रकार', 'approve': 'स्वीकृत गर्नुहोस्',
      'reject': 'अस्वीकार', 'pending': 'बाँकी', 'approved': 'स्वीकृत',
      'rejected': 'अस्वीकृत', 'cancelled': 'रद्द',
      'rejectionReason': 'अस्वीकारको कारण',
      'noLeaveRequests': 'कुनै बिदा निवेदन छैन',
      'noPendingApprovals': 'अनुमोदन बाँकी छैन',
      // Payroll
      'myPayslips': 'मेरा तलबपत्र', 'allPayrolls': 'सबै तलब',
      'generatePayroll': 'तलब तयार गर्नुहोस्',
      'bulkGenerate': 'एकमुष्ट तयार', 'markAsPaid': 'भुक्तानी भयो',
      'basicSalary': 'आधारभूत तलब', 'allowances': 'भत्ता',
      'grossSalary': 'कुल तलब', 'deductions': 'कटौती',
      'netSalary': 'खुद तलब', 'paid': 'भुक्तानी भएको',
      // Shifts
      'editShifts': 'शिफ्ट सम्पादन', 'myShift': 'मेरो शिफ्ट',
      'noShift': 'शिफ्ट तोकिएको छैन',
      // Documents
      'myDocuments': 'मेरा कागजातहरू', 'allDocuments': 'सबै कागजातहरू',
      'upload': 'अपलोड', 'deleteDocument': 'कागजात मेटाउनुहोस्',
      'noDocuments': 'कुनै कागजात फेला परेन',
      'downloadingFile': 'डाउनलोड गर्दै...', 'citizenship': 'नागरिकता',
      'certificate': 'प्रमाणपत्र', 'contract': 'सम्झौता',
      'photo': 'फोटो', 'other': 'अन्य',
      // Announcements & Notifications
      'announcements': 'सूचनाहरू', 'notifications': 'सूचनाहरू',
      'noNotifications': 'अहिलेसम्म कुनै सूचना छैन',
      'markAllRead': 'सबै पढिएको चिह्न लगाउनुहोस्',
      'createAnnouncement': 'सूचना बनाउनुहोस्',
      // Performance
      'myEvaluations': 'मेरा मूल्याङ्कन', 'evals': 'मूल्याङ्कन',
      'evaluationCycles': 'मूल्याङ्कन चक्र',
      'performanceResults': 'कार्यसम्पादन नतिजा',
      'kpiManagement': 'KPI व्यवस्थापन', 'departments': 'विभागहरू',
      'jobRoles': 'पदहरू', 'addEmployee': 'कर्मचारी थप्नुहोस्',
      // Dashboard
      'hrDashboard': 'HR ड्यासबोर्ड', 'attendanceRate': 'उपस्थिति दर',
      'absentToday': 'आज अनुपस्थित', 'weeklyAttendance': 'साप्ताहिक उपस्थिति',
      'todayBreakdown': 'आजको विवरण', 'quickActions': 'द्रुत कार्यहरू',
      'upcomingEvents': 'आगामी कार्यक्रमहरू', 'thisWeek': 'यस हप्ता',
      'totalStaff': 'कुल कर्मचारी',
      // Calendar
      'nepaliCalendar': 'नेपाली पात्रो',
      // Common
      'cancel': 'रद्द', 'save': 'सुरक्षित', 'delete': 'मेटाउनुहोस्',
      'edit': 'सम्पादन', 'create': 'बनाउनुहोस्', 'confirm': 'पुष्टि',
      'close': 'बन्द', 'refresh': 'ताजा गर्नुहोस्',
      'loading': 'लोड हुँदैछ...', 'error': 'त्रुटि भयो',
      'noData': 'डेटा उपलब्ध छैन', 'employees': 'कर्मचारीहरू',
      'language': 'भाषा', 'english': 'English', 'nepali': 'नेपाली',
      'changeLanguage': 'भाषा परिवर्तन',
    },
  };

  String _t(String key) =>
      _values[locale.languageCode]?[key] ?? _values['en']![key] ?? key;

  // ── All getters ────────────────────────────────────────────────────────────
  String get home => _t('home');
  String get attendance => _t('attendance');
  String get leave => _t('leave');
  String get payroll => _t('payroll');
  String get profile => _t('profile');
  String get dashboard => _t('dashboard');
  String get calendar => _t('calendar');
  String get goodMorning => _t('goodMorning');
  String get goodAfternoon => _t('goodAfternoon');
  String get goodEvening => _t('goodEvening');
  String get login => _t('login');
  String get logout => _t('logout');
  String get email => _t('email');
  String get password => _t('password');
  String get welcomeBack => _t('welcomeBack');
  String get signInToContinue => _t('signInToContinue');
  String get clockIn => _t('clockIn');
  String get clockOut => _t('clockOut');
  String get completedForToday => _t('completedForToday');
  String get present => _t('present');
  String get late => _t('late');
  String get absent => _t('absent');
  String get halfDay => _t('halfDay');
  String get wfh => _t('wfh');
  String get all => _t('all');
  String get notClockedIn => _t('notClockedIn');
  String get myAttendance => _t('myAttendance');
  String get teamAttendance => _t('teamAttendance');
  String get allEmployees => _t('allEmployees');
  String get selectDate => _t('selectDate');
  String get attendanceSummary => _t('attendanceSummary');
  String get totalDays => _t('totalDays');
  String get avgHours => _t('avgHours');
  String get totalHours => _t('totalHours');
  String get noShiftAssigned => _t('noShiftAssigned');
  String get ipNotAuthorized => _t('ipNotAuthorized');
  String get applyLeave => _t('applyLeave');
  String get leaveType => _t('leaveType');
  String get startDate => _t('startDate');
  String get endDate => _t('endDate');
  String get reason => _t('reason');
  String get submitRequest => _t('submitRequest');
  String get leaveBalance => _t('leaveBalance');
  String get casualLeave => _t('casualLeave');
  String get sickLeave => _t('sickLeave');
  String get annualLeave => _t('annualLeave');
  String get days => _t('days');
  String get myRequests => _t('myRequests');
  String get pendingApprovals => _t('pendingApprovals');
  String get leaveTypes => _t('leaveTypes');
  String get approve => _t('approve');
  String get reject => _t('reject');
  String get pending => _t('pending');
  String get approved => _t('approved');
  String get rejected => _t('rejected');
  String get cancelled => _t('cancelled');
  String get rejectionReason => _t('rejectionReason');
  String get noLeaveRequests => _t('noLeaveRequests');
  String get noPendingApprovals => _t('noPendingApprovals');
  String get myPayslips => _t('myPayslips');
  String get allPayrolls => _t('allPayrolls');
  String get generatePayroll => _t('generatePayroll');
  String get bulkGenerate => _t('bulkGenerate');
  String get markAsPaid => _t('markAsPaid');
  String get basicSalary => _t('basicSalary');
  String get allowances => _t('allowances');
  String get grossSalary => _t('grossSalary');
  String get deductions => _t('deductions');
  String get netSalary => _t('netSalary');
  String get paid => _t('paid');
  String get editShifts => _t('editShifts');
  String get myShift => _t('myShift');
  String get noShift => _t('noShift');
  String get myDocuments => _t('myDocuments');
  String get allDocuments => _t('allDocuments');
  String get upload => _t('upload');
  String get deleteDocument => _t('deleteDocument');
  String get noDocuments => _t('noDocuments');
  String get downloadingFile => _t('downloadingFile');
  String get citizenship => _t('citizenship');
  String get certificate => _t('certificate');
  String get contract => _t('contract');
  String get photo => _t('photo');
  String get other => _t('other');
  String get announcements => _t('announcements');
  String get notifications => _t('notifications');
  String get noNotifications => _t('noNotifications');
  String get markAllRead => _t('markAllRead');
  String get createAnnouncement => _t('createAnnouncement');
  String get myEvaluations => _t('myEvaluations');
  String get evals => _t('evals');
  String get evaluationCycles => _t('evaluationCycles');
  String get performanceResults => _t('performanceResults');
  String get kpiManagement => _t('kpiManagement');
  String get departments => _t('departments');
  String get jobRoles => _t('jobRoles');
  String get addEmployee => _t('addEmployee');
  String get hrDashboard => _t('hrDashboard');
  String get attendanceRate => _t('attendanceRate');
  String get absentToday => _t('absentToday');
  String get weeklyAttendance => _t('weeklyAttendance');
  String get todayBreakdown => _t('todayBreakdown');
  String get quickActions => _t('quickActions');
  String get upcomingEvents => _t('upcomingEvents');
  String get thisWeek => _t('thisWeek');
  String get totalStaff => _t('totalStaff');
  String get nepaliCalendar => _t('nepaliCalendar');
  String get cancel => _t('cancel');
  String get save => _t('save');
  String get delete => _t('delete');
  String get edit => _t('edit');
  String get create => _t('create');
  String get confirm => _t('confirm');
  String get close => _t('close');
  String get refresh => _t('refresh');
  String get loading => _t('loading');
  String get error => _t('error');
  String get noData => _t('noData');
  String get employees => _t('employees');
  String get language => _t('language');
  String get english => _t('english');
  String get nepali => _t('nepali');
  String get changeLanguage => _t('changeLanguage');

  // Helper: status string from DB → translated
  String statusLabel(String? status) {
    switch (status) {
      case 'Present': return present;
      case 'Late':    return late;
      case 'Absent':  return absent;
      case 'Half Day': return halfDay;
      case 'WFH':     return wfh;
      default:        return notClockedIn;
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale l) => ['en', 'ne'].contains(l.languageCode);
  @override
  Future<AppLocalizations> load(Locale l) async => AppLocalizations(l);
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
