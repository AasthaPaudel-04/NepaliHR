class Employee {
  final int id;
  final String employeeCode;
  final String fullName;
  final String email;
  final String? phone;
  final String? position;
  final String? department;
  final String? dateOfBirth; 
  final String? joinDate;
  final double? basicSalary; 
  final String role;
  final String status;
  

  Employee({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    required this.email,
    this.phone,
    this.position,
    this.department,
    this.dateOfBirth,
    this.joinDate,
    this.basicSalary,
    required this.role,
    this.status = 'active',
  });

  // Convert JSON to Employee object
factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      employeeCode: json['employee_code'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      position: json['position'],
      department: json['department'],
      dateOfBirth: json['date_of_birth'],
      joinDate: json['join_date'],
      basicSalary: json['basic_salary'] != null 
          ? double.tryParse(json['basic_salary'].toString())
          : null,
      role: json['role'] ?? 'employee',
      status: json['status'] ?? 'active',
    );
  }

  // Convert Employee to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_code': employeeCode,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'position': position,
      'department': department,
      'date_of_birth': dateOfBirth,
      'join_date': joinDate,
      'basic_salary': basicSalary,
      'role': role,
      'status': status,
    };
  }
}