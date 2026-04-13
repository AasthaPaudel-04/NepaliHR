import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../app_colors.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class JobRoleScreen extends StatefulWidget {
  const JobRoleScreen({super.key});

  @override
  State<JobRoleScreen> createState() => _JobRoleScreenState();
}

class _JobRoleScreenState extends State<JobRoleScreen> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = true;
  String? _error;

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
    setState(() { _isLoading = true; _error = null; });
    try {
      final headers = await _headers();
      final results = await Future.wait([
        http.get(Uri.parse(ApiConfig.jobRoles), headers: headers),
        http.get(Uri.parse(ApiConfig.departments), headers: headers),
      ]);

      if (results[0].statusCode == 200) {
        setState(() => _roles =
            List<Map<String, dynamic>>.from(json.decode(results[0].body)['data']));
      }
      if (results[1].statusCode == 200) {
        setState(() => _departments =
            List<Map<String, dynamic>>.from(json.decode(results[1].body)['data']));
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── CREATE / EDIT role dialog ──────────────────────────────
  Future<void> _showCreateOrEditDialog({Map<String, dynamic>? role}) async {
    final nameCtrl = TextEditingController(text: role?['name'] ?? '');
    final descCtrl = TextEditingController(text: role?['description'] ?? '');
    int? selectedDeptId = role?['department_id'];
    final isEdit = role != null;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? 'Edit Job Role' : 'New Job Role',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              value: selectedDeptId,
              decoration: InputDecoration(
                labelText: 'Department *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              items: _departments.map((d) => DropdownMenuItem<int>(
                value: d['id'] as int,
                child: Text(d['name']),
              )).toList(),
              onChanged: (v) => setS(() => selectedDeptId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              autofocus: !isEdit,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Role Name *',
                prefixIcon: const Icon(Icons.badge_rounded, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Save Changes' : 'Create'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    if (nameCtrl.text.trim().isEmpty || selectedDeptId == null) {
      _showSnack('Role name and department are required', isError: true);
      return;
    }

    try {
      final body = json.encode({
        'name': nameCtrl.text.trim(),
        'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        'department_id': selectedDeptId,
      });
      final response = isEdit
          ? await http.put(
              Uri.parse(ApiConfig.jobRoleById(role!['id'])),
              headers: await _headers(), body: body)
          : await http.post(
              Uri.parse(ApiConfig.jobRoles),
              headers: await _headers(), body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnack(isEdit ? 'Role updated' : 'Role created');
        _load();
      } else {
        _showSnack(json.decode(response.body)['error'] ?? 'Error', isError: true);
      }
    } catch (e) {
      _showSnack('Network error: $e', isError: true);
    }
  }

  // ── DELETE role ────────────────────────────────────────────
  Future<void> _deleteRole(Map<String, dynamic> role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Role', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Delete "${role['name']}"? This cannot be undone.',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.jobRoleById(role['id'])),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        _showSnack('Role deleted');
        _load();
      } else {
        _showSnack(json.decode(response.body)['error'] ?? 'Error', isError: true);
      }
    } catch (e) {
      _showSnack('Network error: $e', isError: true);
    }
  }

  // ── ASSIGN EMPLOYEES bottom sheet ──────────────────────────
  Future<void> _showAssignEmployeesSheet(Map<String, dynamic> role) async {
    // Load all employees
    List<Map<String, dynamic>> allEmployees = [];
    bool loadingEmps = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          // Load employees when sheet opens
          if (loadingEmps) {
            Future.microtask(() async {
              try {
                final headers = await _headers();
                final response = await http.get(
                  Uri.parse(ApiConfig.allEmployees),
                  headers: headers,
                );
                if (response.statusCode == 200) {
                  setS(() {
                    allEmployees = List<Map<String, dynamic>>.from(
                        json.decode(response.body)['data']);
                    loadingEmps = false;
                  });
                } else {
                  setS(() => loadingEmps = false);
                }
              } catch (e) {
                setS(() => loadingEmps = false);
              }
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.people_rounded,
                        color: Color(0xFF7C3AED), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Assign to "${role['name']}"',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(role['department_name'] ?? '',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ]),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ]),
              ),
              const Divider(height: 24),
              // Content
              Expanded(
                child: loadingEmps
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary))
                    : allEmployees.isEmpty
                        ? const Center(
                            child: Text('No employees found',
                                style: TextStyle(color: AppColors.textSecondary)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: allEmployees.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final emp = allEmployees[i];
                              final isAssignedToThisRole =
                                  emp['job_role_id'] != null &&
                                  emp['job_role_id'] == role['id'];
                              final currentRoleName =
                                  emp['job_role_name'] as String?;
                              final currentDeptName =
                                  emp['department_name'] as String?;

                              return Container(
                                decoration: BoxDecoration(
                                  color: isAssignedToThisRole
                                      ? const Color(0xFF7C3AED).withOpacity(0.06)
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isAssignedToThisRole
                                        ? const Color(0xFF7C3AED).withOpacity(0.3)
                                        : AppColors.border,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: isAssignedToThisRole
                                        ? const Color(0xFF7C3AED).withOpacity(0.15)
                                        : AppColors.primary.withOpacity(0.1),
                                    child: Text(
                                      emp['full_name'].toString().isNotEmpty
                                          ? emp['full_name'].toString()[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isAssignedToThisRole
                                            ? const Color(0xFF7C3AED)
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    emp['full_name'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        emp['employee_code'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                      ),
                                      if (currentRoleName != null)
                                        Text(
                                          'Current: $currentRoleName'
                                          '${currentDeptName != null ? ' · $currentDeptName' : ''}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isAssignedToThisRole
                                                ? const Color(0xFF7C3AED)
                                                : AppColors.textSecondary,
                                            fontWeight: isAssignedToThisRole
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        )
                                      else
                                        const Text(
                                          'No role assigned yet',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.warning),
                                        ),
                                    ],
                                  ),
                                  trailing: isAssignedToThisRole
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7C3AED)
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Assigned',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF7C3AED),
                                            ),
                                          ),
                                        )
                                      : FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 0),
                                            minimumSize: const Size(0, 32),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                          ),
                                          onPressed: () => _assignEmployee(
                                            emp: emp,
                                            role: role,
                                            allEmployees: allEmployees,
                                            setS: setS,
                                          ),
                                          child: const Text('Assign',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                ),
                              );
                            },
                          ),
              ),
            ]),
          );
        },
      ),
    );

    // Reload roles after sheet closes to update employee_count
    _load();
  }

  // ── Actually call the assign API ───────────────────────────
  Future<void> _assignEmployee({
    required Map<String, dynamic> emp,
    required Map<String, dynamic> role,
    required List<Map<String, dynamic>> allEmployees,
    required StateSetter setS,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.assignEmployeeRole),
        headers: await _headers(),
        body: json.encode({
          'employee_id': emp['id'],
          'job_role_id': role['id'],
          'department_id': role['department_id'],
        }),
      );

      if (response.statusCode == 200) {
        // Update local state so the UI reflects the change immediately
        setS(() {
          final idx = allEmployees.indexWhere((e) => e['id'] == emp['id']);
          if (idx != -1) {
            allEmployees[idx] = {
              ...allEmployees[idx],
              'job_role_id': role['id'],
              'job_role_name': role['name'],
              'department_id': role['department_id'],
              'department_name': role['department_name'],
            };
          }
        });
        _showSnack('${emp['full_name']} assigned to ${role['name']}');
      } else {
        _showSnack(
          json.decode(response.body)['error'] ?? 'Failed to assign',
          isError: true,
        );
      }
    } catch (e) {
      _showSnack('Network error: $e', isError: true);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showCreateOrEditDialog(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Job Roles',
                        style: TextStyle(color: Colors.white,
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('${_roles.length} roles across ${_departments.length} departments',
                        style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ]),
                ]),
              ),
            ),

            // Error
            if (_error != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13))),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ]),
                ),
              ),

            // Loading
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)))

            // Empty
            else if (_roles.isEmpty && _error == null)
              SliverFillRemaining(
                child: Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.badge_rounded,
                          size: 48, color: Color(0xFF7C3AED)),
                    ),
                    const SizedBox(height: 16),
                    const Text('No job roles yet',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    const Text('Create departments first, then add roles',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ]),
                ),
              )

            // List
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final role = _roles[i];
                      final empCount = role['employee_count'] ?? 0;
                      final kpiCount = role['kpi_count'] ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [BoxShadow(
                              color: Color(0x081B4FD8),
                              blurRadius: 8, offset: Offset(0, 2))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Role name + dept tag
                              Row(children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.badge_rounded,
                                      color: Color(0xFF7C3AED), size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(role['name'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                    Text(role['department_name'] ?? '',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12)),
                                  ],
                                )),
                                // Edit + Delete
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded,
                                      color: AppColors.primary, size: 18),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(6),
                                  onPressed: () =>
                                      _showCreateOrEditDialog(role: role),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: AppColors.error, size: 18),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(6),
                                  onPressed: () => _deleteRole(role),
                                ),
                              ]),

                              const SizedBox(height: 10),

                              // Stats row
                              Row(children: [
                                _statChip(Icons.people_rounded,
                                    '$empCount employee${empCount == 1 ? '' : 's'}',
                                    AppColors.primary),
                                const SizedBox(width: 8),
                                _statChip(Icons.track_changes_rounded,
                                    '$kpiCount KPI${kpiCount == 1 ? '' : 's'}',
                                    AppColors.success),
                              ]),

                              const SizedBox(height: 10),

                              // Assign employees button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                      Icons.person_add_rounded, size: 16),
                                  label: const Text('Assign Employees'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF7C3AED),
                                    side: const BorderSide(
                                        color: Color(0xFF7C3AED), width: 1),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8),
                                  ),
                                  onPressed: () =>
                                      _showAssignEmployeesSheet(role),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _roles.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}