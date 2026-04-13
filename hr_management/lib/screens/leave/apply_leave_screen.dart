import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../app_colors.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../services/leave_service.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _leaveService = LeaveService();
  final _authService  = AuthService();
  final _reasonController = TextEditingController();

  // Leave types loaded from API
  List<Map<String, dynamic>> _leaveTypes = [];
  bool _loadingTypes = true;

  String? _leaveType;      // selected code e.g. 'sick'
  DateTime _startDate = DateTime.now();
  DateTime _endDate   = DateTime.now();
  bool _isLoading = false;

  int get _totalDays => _endDate.difference(_startDate).inDays + 1;

  @override
  void initState() {
    super.initState();
    _loadLeaveTypes();
  }

  Future<void> _loadLeaveTypes() async {
    setState(() => _loadingTypes = true);
    try {
      final token = await _authService.getToken();
      final res = await http.get(
        Uri.parse(ApiConfig.leaveTypes),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final types = List<Map<String, dynamic>>.from(
            json.decode(res.body)['data']);
        setState(() {
          _leaveTypes = types;
          if (types.isNotEmpty) _leaveType = types.first['code'];
        });
      }
    } catch (_) {
      // Fallback to hardcoded if API fails
      setState(() {
        _leaveTypes = [
          {'code': 'casual', 'name': 'Casual Leave',  'icon': 'beach_access'},
          {'code': 'sick',   'name': 'Sick Leave',    'icon': 'medical_services'},
          {'code': 'annual', 'name': 'Annual Leave',  'icon': 'flight_takeoff'},
        ];
        _leaveType = 'casual';
      });
    } finally {
      setState(() => _loadingTypes = false);
    }
  }

  IconData _iconFromString(String? iconName) {
    switch (iconName) {
      case 'beach_access':     return Icons.beach_access_rounded;
      case 'medical_services': return Icons.medical_services_rounded;
      case 'flight_takeoff':   return Icons.flight_takeoff_rounded;
      case 'home':             return Icons.home_rounded;
      case 'family_restroom':  return Icons.family_restroom_rounded;
      case 'child_care':       return Icons.child_care_rounded;
      case 'event':            return Icons.event_rounded;
      default:                 return Icons.event_note_rounded;
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_leaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a leave type'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _isLoading = true);
    final result = await _leaveService.applyLeave(
      leaveType: _leaveType!,
      startDate: _startDate,
      endDate:   _endDate,
      reason:    _reasonController.text.trim().isEmpty
          ? null : _reasonController.text.trim(),
    );
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success'] ? result['message'] : result['error']),
        backgroundColor: result['success'] ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      if (result['success']) Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _buildLeaveTypeCard(),
                  const SizedBox(height: 12),
                  _buildDateCard(),
                  const SizedBox(height: 12),
                  _buildDurationCard(),
                  const SizedBox(height: 12),
                  _buildReasonCard(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
        const Text('Apply for Leave',
            style: TextStyle(color: Colors.white,
                fontSize: 20, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildLeaveTypeCard() {
    return _card(
      label: 'Leave Type',
      child: _loadingTypes
          ? const Center(child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2)))
          : Column(
              children: _leaveTypes.map((t) {
                final selected = _leaveType == t['code'];
                return GestureDetector(
                  onTap: () => setState(() => _leaveType = t['code']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withOpacity(0.08)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Icon(
                        _iconFromString(t['icon']),
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t['name'],
                              style: TextStyle(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: selected
                                    ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 14,
                              )),
                          if (t['days_allowed'] != null)
                            Text('${t['days_allowed']} days/year',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                        ],
                      )),
                      if (selected)
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary, size: 18),
                    ]),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildDateCard() {
    return _card(
      label: 'Duration',
      child: Row(children: [
        Expanded(child: _datePicker('Start Date', _startDate, true)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(height: 1, width: 20, color: AppColors.border),
        ),
        Expanded(child: _datePicker('End Date', _endDate, false)),
      ]),
    );
  }

  Widget _datePicker(String label, DateTime date, bool isStart) {
    return GestureDetector(
      onTap: () => _selectDate(isStart),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd MMM yyyy').format(date),
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700),
          ),
        ]),
      ),
    );
  }

  Widget _buildDurationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded,
            color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Text(
          'Total duration: $_totalDays day${_totalDays == 1 ? '' : 's'}',
          style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14),
        ),
      ]),
    );
  }

  Widget _buildReasonCard() {
    return _card(
      label: 'Reason (Optional)',
      child: TextFormField(
        controller: _reasonController,
        maxLines: 4,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Describe the reason for your leave...',
          hintStyle: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 2)),
          filled: true,
          fillColor: AppColors.background,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _isLoading ? null : _submit,
        child: _isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('Submit Request',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _card({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x081B4FD8), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}