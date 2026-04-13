import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../app_colors.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class KpiScreen extends StatefulWidget {
  const KpiScreen({super.key});

  @override
  State<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends State<KpiScreen> {
  List<Map<String, dynamic>> _kpis = [];
  List<Map<String, dynamic>> _roles = [];
  bool _isLoading = true;

  static const _evalTypes = [
    {'value': 'all', 'label': 'All evaluator types'},
    {'value': 'self', 'label': 'Self evaluation'},
    {'value': 'peer', 'label': 'Peer evaluation'},
    {'value': 'manager', 'label': 'Manager evaluation'},
    {'value': 'hr', 'label': 'HR evaluation'},
  ];

  static const _targetRoles = [
    {'value': 'all', 'label': 'All employees & managers'},
    {'value': 'employee', 'label': 'Employees only'},
    {'value': 'manager', 'label': 'Managers only'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _token() => AuthService().getToken();

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = await _token();
      final headers = {'Authorization': 'Bearer $token'};
      final results = await Future.wait([
        http.get(Uri.parse(ApiConfig.kpis), headers: headers),
        http.get(Uri.parse(ApiConfig.jobRoles), headers: headers),
      ]);
      if (results[0].statusCode == 200) {
        setState(() => _kpis = List<Map<String, dynamic>>.from(
            json.decode(results[0].body)['data']));
      }
      if (results[1].statusCode == 200) {
        setState(() => _roles = List<Map<String, dynamic>>.from(
            json.decode(results[1].body)['data']));
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _createOrEdit({Map<String, dynamic>? kpi}) async {
    final nameCtrl = TextEditingController(text: kpi?['name']);
    final descCtrl = TextEditingController(text: kpi?['description']);
    final targetCtrl =
        TextEditingController(text: kpi?['target_value']?.toString());
    final weightCtrl =
        TextEditingController(text: kpi?['weightage']?.toString());
    String kpiType = kpi?['kpi_type'] ?? 'rating';
    String evalType = kpi?['evaluator_type'] ?? 'all';
    String targetRole = kpi?['target_role'] ?? 'all';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(kpi != null ? 'Edit KPI' : 'New KPI',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'KPI Name *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: 12),
              // KPI Type
              DropdownButtonFormField<String>(
                value: kpiType,
                decoration: InputDecoration(
                  labelText: 'KPI Type *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: AppColors.background,
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'rating',
                      child: Text('Rating (1–5 scale)')),
                  DropdownMenuItem(
                      value: 'quantitative',
                      child: Text('Quantitative (achieved vs target)')),
                ],
                onChanged: (v) => setS(() => kpiType = v!),
              ),
              if (kpiType == 'quantitative') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Target Value *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true, fillColor: AppColors.background,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: weightCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Weightage % *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Evaluator type scoping
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Evaluation scope',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5)),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: evalType,
                decoration: InputDecoration(
                  labelText: 'For which evaluator type?',
                  helperText:
                      'e.g. Self evals can be quantitative, peer evals more qualitative',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: AppColors.background,
                ),
                items: _evalTypes
                    .map((e) => DropdownMenuItem(
                          value: e['value'],
                          child: Text(e['label']!),
                        ))
                    .toList(),
                onChanged: (v) => setS(() => evalType = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: targetRole,
                decoration: InputDecoration(
                  labelText: 'For which employee level?',
                  helperText:
                      'Managers may have different KPIs than regular employees',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: AppColors.background,
                ),
                items: _targetRoles
                    .map((e) => DropdownMenuItem(
                          value: e['value'],
                          child: Text(e['label']!),
                        ))
                    .toList(),
                onChanged: (v) => setS(() => targetRole = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(kpi != null ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;
    final token = await _token();
    final body = json.encode({
      'name': nameCtrl.text.trim(),
      'description': descCtrl.text,
      'kpi_type': kpiType,
      'target_value': kpiType == 'quantitative'
          ? double.tryParse(targetCtrl.text)
          : null,
      'weightage': double.tryParse(weightCtrl.text) ?? 0,
      'evaluator_type': evalType,
      'target_role': targetRole,
    });
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    try {
      final res = kpi != null
          ? await http.put(Uri.parse(ApiConfig.kpiById(kpi['id'])),
              headers: headers, body: body)
          : await http.post(Uri.parse(ApiConfig.kpis),
              headers: headers, body: body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        _load();
      } else {
        _snack(json.decode(res.body)['error'] ?? 'Error', isError: true);
      }
    } catch (_) {
      _snack('Network error', isError: true);
    }
  }

  // Rich role assignment with evaluator_type + target_role per assignment
  Future<void> _assignRoles(Map<String, dynamic> kpi) async {
    final currentAssignments =
        (kpi['assigned_roles'] as List).cast<Map<String, dynamic>>();

    // Build a mutable set of assignments: {job_role_id, evaluator_type, target_role}
    final List<Map<String, dynamic>> assignments =
        currentAssignments.map((a) => Map<String, dynamic>.from(a)).toList();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Assign "${kpi['name']}" to Roles'),
          content: SizedBox(
            width: 320,
            height: 400,
            child: Column(children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'You can assign this KPI to multiple roles. Each assignment can have a different evaluator type and target level.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: _roles.map((role) {
                    final existing = assignments.firstWhere(
                      (a) => a['job_role_id'] == role['id'],
                      orElse: () => <String, dynamic>{},
                    );
                    final isAssigned = existing.isNotEmpty;
                    String evalType = existing['evaluator_type'] ?? 'all';
                    String tRole = existing['target_role'] ?? 'all';

                    return StatefulBuilder(
                      builder: (_, setI) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isAssigned
                              ? AppColors.primary.withOpacity(0.04)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isAssigned
                                ? AppColors.primary.withOpacity(0.3)
                                : AppColors.border,
                          ),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Checkbox(
                                  value: isAssigned,
                                  activeColor: AppColors.primary,
                                  onChanged: (v) {
                                    setS(() {
                                      if (v == true) {
                                        assignments.add({
                                          'job_role_id': role['id'],
                                          'evaluator_type': 'all',
                                          'target_role': 'all',
                                        });
                                      } else {
                                        assignments.removeWhere(
                                            (a) => a['job_role_id'] == role['id']);
                                      }
                                    });
                                    setI(() {});
                                  },
                                ),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(role['name'] ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13)),
                                        Text(
                                            role['department_name'] ?? '',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary)),
                                      ]),
                                ),
                              ]),
                              if (isAssigned) ...[
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: evalType,
                                  isDense: true,
                                  decoration: InputDecoration(
                                    labelText: 'Evaluator type',
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    filled: true,
                                    fillColor: AppColors.background,
                                  ),
                                  items: _evalTypes
                                      .map((e) => DropdownMenuItem(
                                            value: e['value'],
                                            child: Text(e['label']!,
                                                style: const TextStyle(
                                                    fontSize: 12)),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    setS(() {
                                      final idx = assignments.indexWhere(
                                          (a) => a['job_role_id'] == role['id']);
                                      if (idx != -1) {
                                        assignments[idx]['evaluator_type'] = v;
                                      }
                                    });
                                    setI(() => evalType = v!);
                                  },
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: tRole,
                                  isDense: true,
                                  decoration: InputDecoration(
                                    labelText: 'For employee level',
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    filled: true,
                                    fillColor: AppColors.background,
                                  ),
                                  items: _targetRoles
                                      .map((e) => DropdownMenuItem(
                                            value: e['value'],
                                            child: Text(e['label']!,
                                                style: const TextStyle(
                                                    fontSize: 12)),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    setS(() {
                                      final idx = assignments.indexWhere(
                                          (a) => a['job_role_id'] == role['id']);
                                      if (idx != -1) {
                                        assignments[idx]['target_role'] = v;
                                      }
                                    });
                                    setI(() => tRole = v!);
                                  },
                                ),
                              ],
                            ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final token = await _token();
    final res = await http.post(
      Uri.parse(ApiConfig.assignKPIToRoles),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'kpi_id': kpi['id'], 'assignments': assignments}),
    );
    if (res.statusCode == 200) {
      _snack('Roles assigned');
      _load();
    } else {
      _snack(json.decode(res.body)['error'] ?? 'Error', isError: true);
    }
  }

  void _snack(String m, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

  Color _evalTypeColor(String t) {
    switch (t) {
      case 'self': return const Color(0xFF7C3AED);
      case 'peer': return const Color(0xFF0891B2);
      case 'manager': return const Color(0xFFD97706);
      case 'hr': return const Color(0xFF059669);
      default: return AppColors.primary;
    }
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
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration:
                const BoxDecoration(gradient: AppColors.headerGradient),
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
              const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KPI Management',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      Text(
                          'Create KPIs scoped by evaluator type & employee level',
                          style: TextStyle(
                              color: Colors.white60, fontSize: 12)),
                    ]),
              ),
            ]),
          ),
        ),
        if (_isLoading)
          const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)))
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final k = _kpis[i];
                  final isQuant = k['kpi_type'] == 'quantitative';
                  final evalType = k['evaluator_type'] ?? 'all';
                  final targetRole = k['target_role'] ?? 'all';
                  final assignedRoles =
                      (k['assigned_roles'] as List).length;
                  final evalColor = _evalTypeColor(evalType);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              // KPI type badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isQuant
                                      ? AppColors.primary.withOpacity(0.1)
                                      : AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isQuant ? 'Quantitative' : 'Rating',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isQuant
                                          ? AppColors.primary
                                          : AppColors.warning),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Evaluator type badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: evalColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  evalType == 'all'
                                      ? 'All types'
                                      : evalType.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: evalColor),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Weight badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${k['weightage']}%',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded,
                                    color: AppColors.primary, size: 16),
                                onPressed: () => _createOrEdit(kpi: k),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            Text(k['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.textPrimary)),
                            if (k['description'] != null) ...[
                              const SizedBox(height: 2),
                              Text(k['description'],
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'For: ${targetRole == 'all' ? 'all levels' : targetRole + 's'}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Row(children: [
                              const Icon(Icons.group_rounded,
                                  size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('$assignedRoles role assignment${assignedRoles == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                              const Spacer(),
                              TextButton(
                                onPressed: () => _assignRoles(k),
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    minimumSize: Size.zero),
                                child: const Text('Assign Roles',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ]),
                          ]),
                    ),
                  );
                },
                childCount: _kpis.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ]),
    );
  }
}
