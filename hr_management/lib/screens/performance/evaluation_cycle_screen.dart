import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../app_colors.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class EvaluationCycleScreen extends StatefulWidget {
  const EvaluationCycleScreen({super.key});

  @override
  State<EvaluationCycleScreen> createState() => _EvaluationCycleScreenState();
}

class _EvaluationCycleScreenState extends State<EvaluationCycleScreen> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _cycles = [];
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
      final res = await http.get(
        Uri.parse(ApiConfig.evaluationCycles),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        setState(() => _cycles =
            List<Map<String, dynamic>>.from(json.decode(res.body)['data']));
      } else {
        setState(() => _error = json.decode(res.body)['error'] ?? 'Failed to load');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Create cycle dialog ────────────────────────────────────
  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    String type = 'monthly';
    DateTime? startDate, endDate;
    final selfCtrl    = TextEditingController(text: '10');
    final peerCtrl    = TextEditingController(text: '20');
    final managerCtrl = TextEditingController(text: '50');
    final hrCtrl      = TextEditingController(text: '20');

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('New Evaluation Cycle',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Cycle name
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Cycle Name *',
                  hintText: 'e.g. Q1 2025 Evaluation',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: 12),
              // Type
              DropdownButtonFormField<String>(
                value: type,
                decoration: InputDecoration(
                  labelText: 'Cycle Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: AppColors.background,
                ),
                items: const [
                  DropdownMenuItem(value: 'monthly',   child: Text('Monthly')),
                  DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                ],
                onChanged: (v) => setS(() => type = v!),
              ),
              const SizedBox(height: 12),
              // Dates
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_rounded, size: 14),
                  label: Text(
                    startDate == null
                        ? 'Start Date *'
                        : '${startDate!.day}/${startDate!.month}/${startDate!.year}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setS(() => startDate = d);
                  },
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_rounded, size: 14),
                  label: Text(
                    endDate == null
                        ? 'End Date *'
                        : '${endDate!.day}/${endDate!.month}/${endDate!.year}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setS(() => endDate = d);
                  },
                )),
              ]),
              const SizedBox(height: 14),
              // Weights
              const Text('Evaluator Weights (must total 100%)',
                  style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(children: [
                _weightField(selfCtrl, 'Self'),
                const SizedBox(width: 6),
                _weightField(peerCtrl, 'Peer'),
                const SizedBox(width: 6),
                _weightField(managerCtrl, 'Mgr'),
                const SizedBox(width: 6),
                _weightField(hrCtrl, 'HR'),
              ]),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    if (nameCtrl.text.trim().isEmpty || startDate == null || endDate == null) {
      _showSnack('Name, start date and end date are required', isError: true);
      return;
    }

    final sw = double.tryParse(selfCtrl.text) ?? 0;
    final pw = double.tryParse(peerCtrl.text) ?? 0;
    final mw = double.tryParse(managerCtrl.text) ?? 0;
    final hw = double.tryParse(hrCtrl.text) ?? 0;
    if ((sw + pw + mw + hw).round() != 100) {
      _showSnack('Weights must total 100%. Current total: ${(sw+pw+mw+hw).toStringAsFixed(0)}%',
          isError: true);
      return;
    }

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.evaluationCycles),
        headers: await _headers(),
        body: json.encode({
          'cycle_name': nameCtrl.text.trim(),
          'cycle_type': type,
          'start_date': startDate!.toIso8601String().split('T')[0],
          'end_date':   endDate!.toIso8601String().split('T')[0],
          'self_weight':    sw,
          'peer_weight':    pw,
          'manager_weight': mw,
          'hr_weight':      hw,
        }),
      );
      if (res.statusCode == 201) {
        _showSnack('Cycle created');
        _load();
      } else {
        _showSnack(json.decode(res.body)['error'] ?? 'Error', isError: true);
      }
    } catch (e) {
      _showSnack('Network error: $e', isError: true);
    }
  }

  Widget _weightField(TextEditingController ctrl, String label) => Expanded(
    child: TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true, fillColor: AppColors.background,
      ),
    ),
  );

  // ── Initiate cycle ─────────────────────────────────────────
  Future<void> _initiate(Map<String, dynamic> cycle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Initiate Evaluations',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'This will create evaluation tasks for all active employees '
          'with job roles and KPIs under "${cycle['cycle_name']}".\n\n'
          'Admin will act as the HR evaluator.\n'
          'Peers will be auto-assigned from the same department.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Initiate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.initiateCycle(cycle['id'])),
        headers: await _headers(),
      );
      final data = json.decode(res.body);
      if (res.statusCode == 200) {
        _showSnack(data['message'] ?? 'Done');
        _load();
      } else {
        _showSnack(data['error'] ?? 'Error', isError: true);
      }
    } catch (e) {
      _showSnack('Network error: $e', isError: true);
    }
  }

  // ── Cycle status bottom sheet ─────────────────────────────
  Future<void> _showCycleStatusSheet(Map<String, dynamic> cycle) async {
    List<Map<String, dynamic>> allEvaluations = [];
    List<Map<String, dynamic>> allEmployees = [];
    bool loading = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          if (loading) {
            Future.microtask(() async {
              try {
                final headers = await _headers();
                final results = await Future.wait([
                  http.get(Uri.parse(ApiConfig.cycleEvaluationStatus(cycle['id'] as int)),
                      headers: headers),
                  http.get(Uri.parse(ApiConfig.allEmployees), headers: headers),
                ]);
                if (results[0].statusCode == 200) {
                  allEvaluations = List<Map<String, dynamic>>.from(
                      json.decode(results[0].body)['data']);
                }
                if (results[1].statusCode == 200) {
                  allEmployees = List<Map<String, dynamic>>.from(
                      json.decode(results[1].body)['data']);
                }
              } catch (_) {}
              setS(() => loading = false);
            });
          }

          // Group evaluations by employee
          final Map<int, List<Map<String, dynamic>>> byEmployee = {};
          for (final ev in allEvaluations) {
            final empId = ev['employee_id'] as int;
            if (empId == null) continue;
            byEmployee.putIfAbsent(empId, () => []);
            byEmployee[empId]!.add(ev);
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
                child: Row(children: [
                  const Icon(Icons.monitor_heart_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cycle['cycle_name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const Text('Evaluation status & peer assignment',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  )),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ]),
              ),
              const Divider(height: 20),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary))
                    : byEmployee.isEmpty
                        ? Center(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 48, color: AppColors.textSecondary),
                              const SizedBox(height: 12),
                              const Text('No evaluations yet',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 6),
                              const Text('Tap "Initiate" on the cycle card first',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            ],
                          ))
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: byEmployee.entries.map((entry) {
                              final empEvs = entry.value;
                              final empName = empEvs.first['employee_name'] ?? '';
                              final empCode = empEvs.first['employee_code'] ?? '';
                              final roleName = empEvs.first['job_role_name'] ?? 'No role';
                              final deptName = empEvs.first['department_name'] ?? '';

                              final hasPeer = empEvs.any(
                                  (e) => e['evaluator_type'] == 'peer');
                              final peerEv = empEvs.firstWhere(
                                  (e) => e['evaluator_type'] == 'peer',
                                  orElse: () => {});

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
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
                                      // Employee header
                                      Row(children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              AppColors.primary.withOpacity(0.1),
                                          radius: 18,
                                          child: Text(
                                            empName.isNotEmpty
                                                ? empName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(empName,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14)),
                                            Text('$empCode · $roleName · $deptName',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textSecondary)),
                                          ],
                                        )),
                                      ]),
                                      const SizedBox(height: 10),
                                      // Evaluator status chips
                                      Wrap(spacing: 6, runSpacing: 6,
                                        children: empEvs.map((ev) {
                                          final type = ev['evaluator_type'] as String;
                                          final submitted = ev['status'] == 'submitted';
                                          final evName = ev['evaluator_name'] ?? '';
                                          return _evalChip(
                                              type, evName, submitted);
                                        }).toList(),
                                      ),
                                      // Peer assignment section
                                      const SizedBox(height: 10),
                                      if (!hasPeer)
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            icon: const Icon(
                                                Icons.person_add_rounded,
                                                size: 14),
                                            label: const Text(
                                                'Assign Peer Evaluator',
                                                style: TextStyle(fontSize: 12)),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFF0891B2),
                                              side: const BorderSide(
                                                  color: Color(0xFF0891B2)),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 6),
                                            ),
                                            onPressed: () =>
                                                _showPeerAssignDialog(
                                              ctx: ctx,
                                              cycleId: cycle['id'],
                                              employeeId: entry.key,
                                              employeeName: empName,
                                              allEmployees: allEmployees,
                                              onAssigned: () {
                                                // Reload evaluations in sheet
                                                setS(() => loading = true);
                                              },
                                            ),
                                          ),
                                        )
                                      else if (peerEv['status'] == 'pending')
                                        Row(children: [
                                          const Icon(Icons.swap_horiz_rounded,
                                              size: 14,
                                              color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Peer: ${peerEv['evaluator_name'] ?? 'Assigned'} (pending)',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary),
                                          ),
                                          const Spacer(),
                                          TextButton(
                                            onPressed: () =>
                                                _showPeerAssignDialog(
                                              ctx: ctx,
                                              cycleId: cycle['id'],
                                              employeeId: entry.key,
                                              employeeName: empName,
                                              allEmployees: allEmployees,
                                              onAssigned: () =>
                                                  setS(() => loading = true),
                                            ),
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: const Text('Change',
                                                style: TextStyle(fontSize: 11)),
                                          ),
                                        ]),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ── Peer assignment dialog ─────────────────────────────────
  Future<void> _showPeerAssignDialog({
    required BuildContext ctx,
    required int cycleId,
    required int employeeId,
    required String employeeName,
    required List<Map<String, dynamic>> allEmployees,
    required VoidCallback onAssigned,
  }) async {
    // Exclude the employee being evaluated
    final peers = allEmployees
        .where((e) => e['id'] != employeeId && e['role'] == 'employee')
        .toList();

    final selected = await showDialog<Map<String, dynamic>>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Peer for $employeeName',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: SizedBox(
          width: 300,
          height: 350,
          child: peers.isEmpty
              ? const Center(child: Text('No other employees available'))
              : ListView.separated(
                  itemCount: peers.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = peers[i];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          (p['full_name'] as String).isNotEmpty
                              ? p['full_name'][0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ),
                      title: Text(p['full_name'] ?? '',
                          style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${p['job_role_name'] ?? 'No role'} · ${p['department_name'] ?? ''}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () => Navigator.pop(dCtx, p),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected == null) return;

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.assignPeerEvaluator),
        headers: await _headers(),
        body: json.encode({
          'cycle_id':    cycleId,
          'employee_id': employeeId,
          'peer_id':     selected['id'],
        }),
      );
      if (res.statusCode == 200) {
        _showSnack('${selected['full_name']} assigned as peer');
        onAssigned();
      } else {
        _showSnack(json.decode(res.body)['error'] ?? 'Error', isError: true);
      }
    } catch (e) {
      _showSnack('Network error: $e', isError: true);
    }
  }

  Widget _evalChip(String type, String evaluatorName, bool submitted) {
    final colors = {
      'self':    AppColors.primary,
      'peer':    const Color(0xFF0891B2),
      'manager': const Color(0xFFD97706),
      'hr':      const Color(0xFF059669),
    };
    final color = colors[type] ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: submitted
            ? color.withOpacity(0.12)
            : AppColors.border.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: submitted ? color.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          submitted
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 11,
          color: submitted ? color : AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          type.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: submitted ? color : AppColors.textSecondary,
          ),
        ),
      ]),
    );
  }

  Color _statusColor(String s) =>
      s == 'active' ? AppColors.success : s == 'closed'
          ? AppColors.error : AppColors.textSecondary;

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
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
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
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Evaluation Cycles',
                          style: TextStyle(color: Colors.white,
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      Text('Manage cycles, view status, assign peers',
                          style: TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  )),
                ]),
              ),
            ),

            if (_error != null)
              SliverToBoxAdapter(child: Container(
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
              )),

            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)))
            else if (_cycles.isEmpty && _error == null)
              const SliverFillRemaining(
                child: Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_repeat_rounded,
                        size: 48, color: AppColors.textSecondary),
                    SizedBox(height: 16),
                    Text('No evaluation cycles yet',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Text('Tap + to create your first cycle',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                )),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final c = _cycles[i];
                      final statusColor = _statusColor(c['status'] ?? 'active');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                              Row(children: [
                                Expanded(child: Text(c['cycle_name'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15))),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    (c['status'] ?? 'active').toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 4),
                              Text(
                                '${(c['cycle_type'] ?? '').toUpperCase()} · '
                                '${c['start_date']} → ${c['end_date']}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              // Weight pills
                              Wrap(spacing: 6, children: [
                                _weightPill('Self', c['self_weight']),
                                _weightPill('Peer', c['peer_weight']),
                                _weightPill('Mgr',  c['manager_weight']),
                                _weightPill('HR',   c['hr_weight']),
                              ]),
                              const SizedBox(height: 10),
                              // Action buttons
                              Row(children: [
                                Expanded(child: OutlinedButton.icon(
                                  icon: const Icon(Icons.monitor_heart_rounded,
                                      size: 14),
                                  label: const Text('View Status',
                                      style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                        color: AppColors.primary),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
                                  ),
                                  onPressed: () => _showCycleStatusSheet(c),
                                )),
                                if (c['status'] == 'active') ...[
                                  const SizedBox(width: 8),
                                  Expanded(child: FilledButton.icon(
                                    icon: const Icon(Icons.play_arrow_rounded,
                                        size: 14),
                                    label: const Text('Initiate',
                                        style: TextStyle(fontSize: 12)),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                    ),
                                    onPressed: () => _initiate(c),
                                  )),
                                ],
                              ]),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _cycles.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _weightPill(String label, dynamic value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: AppColors.border),
    ),
    child: Text('$label ${value ?? 0}%',
        style: const TextStyle(
            fontSize: 10, color: AppColors.textSecondary)),
  );
}