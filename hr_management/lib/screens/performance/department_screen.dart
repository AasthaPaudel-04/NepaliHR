import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../app_colors.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';


class DepartmentScreen extends StatefulWidget {
  const DepartmentScreen({super.key});

  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _getToken() => AuthService().getToken();

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse(ApiConfig.departments),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => _departments = List<Map<String, dynamic>>.from(data['data']));
      }
    } catch (e) {
      _showSnack('Error loading departments', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createOrEdit({Map<String, dynamic>? dept}) async {
    final nameCtrl = TextEditingController(text: dept?['name']);
    final descCtrl = TextEditingController(text: dept?['description']);
    final isEdit = dept != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? 'Edit Department' : 'New Department',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField(nameCtrl, 'Department Name *', Icons.business_rounded),
            const SizedBox(height: 12),
            _buildField(descCtrl, 'Description (optional)', Icons.notes_rounded, maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isEdit ? 'Save' : 'Create'),
          ),
        ],
      ),
    );

    if (result != true) return;
    if (nameCtrl.text.trim().isEmpty) {
      _showSnack('Department name is required', isError: true);
      return;
    }

    try {
      final token = await _getToken();
      final body = json.encode({'name': nameCtrl.text.trim(), 'description': descCtrl.text});
      http.Response res;
      if (isEdit) {
        res = await http.put(
          Uri.parse(ApiConfig.departmentById(dept!['id'])),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: body,
        );
      } else {
        res = await http.post(
          Uri.parse(ApiConfig.departments),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: body,
        );
      }
      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnack(isEdit ? 'Department updated' : 'Department created');
        _load();
      } else {
        final err = json.decode(res.body)['error'] ?? 'Error';
        _showSnack(err, isError: true);
      }
    } catch (e) {
      _showSnack('Network error', isError: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> dept) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Department'),
        content: Text('Are you sure you want to delete "${dept['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final token = await _getToken();
      final res = await http.delete(
        Uri.parse(ApiConfig.departmentById(dept['id'])),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        _showSnack('Department deleted');
        _load();
      } else {
        final err = json.decode(res.body)['error'] ?? 'Error';
        _showSnack(err, isError: true);
      }
    } catch (e) {
      _showSnack('Network error', isError: true);
    }
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _createOrEdit(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.headerGradient),
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Departments',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_departments.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.business_rounded, size: 48, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    const Text('No departments yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    const Text('Tap + to create your first department',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final dept = _departments[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(color: Color(0x081B4FD8), blurRadius: 8, offset: Offset(0, 2))
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 20),
                        ),
                        title: Text(dept['name'],
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        subtitle: Text(
                          '${dept['role_count'] ?? 0} roles${dept['description'] != null ? ' · ${dept['description']}' : ''}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
                              onPressed: () => _createOrEdit(dept: dept),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                              onPressed: () => _delete(dept),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _departments.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}