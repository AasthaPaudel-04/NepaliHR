import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../app_colors.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class LeaveTypeManagementScreen extends StatefulWidget {
  final bool embedded;
  const LeaveTypeManagementScreen({super.key, this.embedded = false});

  @override
  State<LeaveTypeManagementScreen> createState() =>
      _LeaveTypeManagementScreenState();
}

class _LeaveTypeManagementScreenState
    extends State<LeaveTypeManagementScreen> {
  final _authService = AuthService();
  List<Map<String, dynamic>> _types = [];
  bool _isLoading = true;

  static const _icons = [
    {'value': 'beach_access', 'label': 'Beach / Casual'},
    {'value': 'medical_services', 'label': 'Medical'},
    {'value': 'flight_takeoff', 'label': 'Flight / Annual'},
    {'value': 'home', 'label': 'Home'},
    {'value': 'family_restroom', 'label': 'Family'},
    {'value': 'child_care', 'label': 'Child Care'},
    {'value': 'event', 'label': 'Event'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.leaveTypesAll),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _types = List<Map<String, dynamic>>.from(data['data'] ?? data);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  IconData _iconFromString(String? name) {
    switch (name) {
      case 'beach_access': return Icons.beach_access_rounded;
      case 'medical_services': return Icons.medical_services_rounded;
      case 'flight_takeoff': return Icons.flight_takeoff_rounded;
      case 'home': return Icons.home_rounded;
      case 'family_restroom': return Icons.family_restroom_rounded;
      case 'child_care': return Icons.child_care_rounded;
      case 'event': return Icons.event_rounded;
      default: return Icons.event_note_rounded;
    }
  }

  Future<void> _showDialog({Map<String, dynamic>? type}) async {
    final nameCtrl = TextEditingController(text: type?['name'] ?? '');
    final codeCtrl = TextEditingController(text: type?['code'] ?? '');
    final daysCtrl =
        TextEditingController(text: type?['days_allowed']?.toString() ?? '');
    String selectedIcon = type?['icon'] ?? 'event';
    final isEdit = type != null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? 'Edit Leave Type' : 'New Leave Type',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                enabled: !isEdit,
                decoration: InputDecoration(
                  labelText: 'Code * (e.g. casual)',
                  helperText: isEdit ? 'Code cannot be changed' : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: daysCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Days allowed per year *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedIcon,
                decoration: InputDecoration(
                  labelText: 'Icon',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: AppColors.background,
                ),
                items: _icons
                    .map((i) => DropdownMenuItem(
                          value: i['value'],
                          child: Row(children: [
                            Icon(_iconFromString(i['value']),
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(i['label']!),
                          ]),
                        ))
                    .toList(),
                onChanged: (v) => setS(() => selectedIcon = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    if (nameCtrl.text.trim().isEmpty ||
        codeCtrl.text.trim().isEmpty ||
        daysCtrl.text.trim().isEmpty) {
      _snack('All fields are required', isError: true);
      return;
    }

    final body = json.encode({
      'name': nameCtrl.text.trim(),
      'code': codeCtrl.text.trim(),
      'days_allowed': int.tryParse(daysCtrl.text) ?? 0,
      'icon': selectedIcon,
    });

    try {
      final res = isEdit
          ? await http.put(
              Uri.parse(ApiConfig.leaveTypeById(type!['id'])),
              headers: await _headers(), body: body)
          : await http.post(
              Uri.parse(ApiConfig.leaveTypes),
              headers: await _headers(), body: body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        _snack(isEdit ? 'Leave type updated' : 'Leave type created');
        _load();
      } else {
        _snack(json.decode(res.body)['error'] ?? 'Error', isError: true);
      }
    } catch (_) {
      _snack('Network error', isError: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Leave Type',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Delete "${type['name']}"? Existing requests won\'t be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final res = await http.delete(
        Uri.parse(ApiConfig.leaveTypeById(type['id'])),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        _snack('Leave type deleted');
        _load();
      } else {
        _snack(json.decode(res.body)['error'] ?? 'Error', isError: true);
      }
    } catch (_) {
      _snack('Network error', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final list = RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _types.isEmpty
              ? const Center(
                  child: Text('No leave types yet',
                      style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: _types.length,
                  itemBuilder: (_, i) => _buildCard(_types[i]),
                ),
    );

    if (widget.embedded) {
      return Stack(children: [
        list,
        Positioned(
          bottom: 16, right: 16,
          child: FloatingActionButton(
            backgroundColor: AppColors.primary,
            onPressed: () => _showDialog(),
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ),
      ]);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: CustomScrollView(slivers: [
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
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              const Text('Leave Types',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
        SliverFillRemaining(child: list),
      ]),
    );
  }

  Widget _buildCard(Map<String, dynamic> type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x081B4FD8), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(_iconFromString(type['icon']),
              color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(type['name'] ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary)),
            Text('${type['days_allowed'] ?? 0} days/year · code: ${type['code'] ?? ''}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.edit_rounded,
              color: AppColors.primary, size: 18),
          onPressed: () => _showDialog(type: type),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(6),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.error, size: 18),
          onPressed: () => _delete(type),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(6),
        ),
      ]),
    );
  }
}
