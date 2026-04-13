import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../app_colors.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  // Form controllers
  final _codeCtrl      = TextEditingController();
  final _nameCtrl      = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _positionCtrl  = TextEditingController();
  final _salaryCtrl    = TextEditingController();

  // Dropdown values
  String _role = 'employee';
  DateTime? _dob;
  DateTime? _joinDate;

  // Department & job role (optional — can be assigned later)
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _jobRoles    = [];
  int? _selectedDeptId;
  int? _selectedRoleId;
  bool _loadingDepts = false;

  @override
  void initState() {
    super.initState();
    _loadJoinDate();
    _loadDepartments();
  }

  void _loadJoinDate() {
    _joinDate = DateTime.now();
  }

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _loadDepartments() async {
    setState(() => _loadingDepts = true);
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.departments),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        setState(() => _departments =
            List<Map<String, dynamic>>.from(json.decode(res.body)['data']));
      }
    } catch (_) {}
    setState(() => _loadingDepts = false);
  }

  Future<void> _loadJobRoles(int deptId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.jobRoles}?department_id=$deptId'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        setState(() {
          _jobRoles = List<Map<String, dynamic>>.from(
              json.decode(res.body)['data']);
          _selectedRoleId = null;
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_joinDate == null) {
      _showSnack('Please select a join date', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final body = {
        'employee_code': _codeCtrl.text.trim(),
        'full_name':     _nameCtrl.text.trim(),
        'email':         _emailCtrl.text.trim().toLowerCase(),
        'password':      _passwordCtrl.text,
        'phone':         _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'position':      _positionCtrl.text.trim().isEmpty ? null : _positionCtrl.text.trim(),
        'basic_salary':  double.tryParse(_salaryCtrl.text),
        'role':          _role,
        'join_date':     _joinDate!.toIso8601String().split('T')[0],
        'date_of_birth': _dob?.toIso8601String().split('T')[0],
      };

      final res = await http.post(
        Uri.parse(ApiConfig.register),
        headers: await _headers(),
        body: json.encode(body),
      );

      final data = json.decode(res.body);

      if (res.statusCode == 201) {
        // If department + job role selected, assign them too
        if (_selectedDeptId != null && _selectedRoleId != null) {
          final empId = data['employee']['id'];
          await http.post(
            Uri.parse(ApiConfig.assignEmployeeRole),
            headers: await _headers(),
            body: json.encode({
              'employee_id':  empId,
              'job_role_id':  _selectedRoleId,
              'department_id': _selectedDeptId,
            }),
          );
        }
        if (mounted) {
          _showSnack('Employee "${_nameCtrl.text.trim()}" added successfully');
          Navigator.pop(context, true); // return true so caller can refresh
        }
      } else {
        _showSnack(data['error'] ?? 'Failed to add employee', isError: true);
      }
    } catch (e) {
      _showSnack('Network error: $e', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickDate({required bool isDob}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isDob
          ? DateTime(now.year - 25)
          : now,
      firstDate: isDob ? DateTime(1950) : DateTime(2000),
      lastDate: isDob ? DateTime(now.year - 18) : now,
    );
    if (picked != null) {
      setState(() {
        if (isDob) _dob = picked;
        else _joinDate = picked;
      });
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _positionCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.headerGradient),
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Add Employee',
                      style: TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  Text('Create a new employee account',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                ]),
              ]),
            ),
          ),

          // Form
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── SECTION: Account Info ──────────────────
                    _sectionHeader('Account Information', Icons.person_rounded),
                    const SizedBox(height: 12),

                    // Employee code + Full name (side by side)
                    Row(children: [
                      Expanded(child: _buildField(
                        controller: _codeCtrl,
                        label: 'Employee Code *',
                        hint: 'e.g. EMP001',
                        icon: Icons.badge_rounded,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Required' : null,
                        caps: TextCapitalization.characters,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _buildField(
                        controller: _nameCtrl,
                        label: 'Full Name *',
                        hint: 'e.g. Ramesh Sharma',
                        icon: Icons.person_rounded,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Required' : null,
                        caps: TextCapitalization.words,
                      )),
                    ]),
                    const SizedBox(height: 12),

                    // Email
                    _buildField(
                      controller: _emailCtrl,
                      label: 'Email Address *',
                      hint: 'ramesh@company.com',
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Password
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        hintText: 'Min 6 characters',
                        prefixIcon: const Icon(Icons.lock_rounded,
                            size: 18, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 18, color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Phone
                    _buildField(
                      controller: _phoneCtrl,
                      label: 'Phone Number',
                      hint: 'e.g. 9800000000',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),

                    // ── SECTION: Role & Position ───────────────
                    _sectionHeader('Role & Position', Icons.work_rounded),
                    const SizedBox(height: 12),

                    // System role
                    DropdownButtonFormField<String>(
                      value: _role,
                      decoration: InputDecoration(
                        labelText: 'System Role *',
                        prefixIcon: const Icon(Icons.admin_panel_settings_rounded,
                            size: 18, color: AppColors.primary),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        helperText: 'Controls app access level',
                        helperStyle: const TextStyle(fontSize: 11),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'employee',
                            child: Text('Employee')),
                        DropdownMenuItem(value: 'manager',
                            child: Text('Manager')),
                        DropdownMenuItem(value: 'admin',
                            child: Text('Admin')),
                      ],
                      onChanged: (v) => setState(() => _role = v!),
                    ),
                    const SizedBox(height: 12),

                    // Position (free text job title)
                    _buildField(
                      controller: _positionCtrl,
                      label: 'Job Title / Position',
                      hint: 'e.g. Senior Reporter',
                      icon: Icons.work_outline_rounded,
                      caps: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),

                    // Department dropdown
                    _loadingDepts
                        ? const Center(child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                                color: AppColors.primary, strokeWidth: 2)))
                        : DropdownButtonFormField<int>(
                            value: _selectedDeptId,
                            decoration: InputDecoration(
                              labelText: 'Department (optional)',
                              prefixIcon: const Icon(Icons.business_rounded,
                                  size: 18, color: AppColors.primary),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              helperText: 'Can also be assigned later',
                              helperStyle: const TextStyle(fontSize: 11),
                            ),
                            items: [
                              const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('— None —',
                                      style: TextStyle(
                                          color: AppColors.textSecondary))),
                              ..._departments.map((d) =>
                                  DropdownMenuItem<int>(
                                    value: d['id'] as int,
                                    child: Text(d['name']),
                                  )),
                            ],
                            onChanged: (v) {
                              setState(() {
                                _selectedDeptId = v;
                                _jobRoles = [];
                                _selectedRoleId = null;
                              });
                              if (v != null) _loadJobRoles(v);
                            },
                          ),

                    // Job role dropdown (only shows if dept selected)
                    if (_selectedDeptId != null && _jobRoles.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedRoleId,
                        decoration: InputDecoration(
                          labelText: 'Job Role (optional)',
                          prefixIcon: const Icon(Icons.badge_rounded,
                              size: 18, color: AppColors.primary),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                              value: null,
                              child: Text('— None —',
                                  style: TextStyle(
                                      color: AppColors.textSecondary))),
                          ..._jobRoles.map((r) => DropdownMenuItem<int>(
                                value: r['id'] as int,
                                child: Text(r['name']),
                              )),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedRoleId = v),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── SECTION: Personal & Financial ──────────
                    _sectionHeader(
                        'Personal & Financial', Icons.account_balance_wallet_rounded),
                    const SizedBox(height: 12),

                    // Date of birth + Join date
                    Row(children: [
                      Expanded(child: _datePicker(
                        label: 'Date of Birth',
                        value: _dob,
                        onTap: () => _pickDate(isDob: true),
                        icon: Icons.cake_rounded,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _datePicker(
                        label: 'Join Date *',
                        value: _joinDate,
                        onTap: () => _pickDate(isDob: false),
                        icon: Icons.calendar_today_rounded,
                        required: true,
                      )),
                    ]),
                    const SizedBox(height: 12),

                    // Basic salary
                    _buildField(
                      controller: _salaryCtrl,
                      label: 'Basic Salary (NPR)',
                      hint: 'e.g. 50000',
                      icon: Icons.payments_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 28),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_add_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Add Employee',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
      const SizedBox(width: 8),
      Expanded(child: Divider(color: AppColors.border)),
    ]);
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization caps = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: caps,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required IconData icon,
    bool required = false,
  }) {
    final display = value != null
        ? '${value.day}/${value.month}/${value.year}'
        : 'Select';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: required && value == null
                ? AppColors.error
                : AppColors.border,
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(display,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary)),
            ],
          )),
          const Icon(Icons.edit_calendar_rounded,
              size: 14, color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}