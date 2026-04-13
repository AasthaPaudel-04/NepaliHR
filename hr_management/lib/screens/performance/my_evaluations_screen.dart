import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../app_colors.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import 'evaluation_form_screen.dart';

class MyEvaluationsScreen extends StatefulWidget {
  const MyEvaluationsScreen({super.key});
  @override
  State<MyEvaluationsScreen> createState() => _MyEvaluationsScreenState();
}
 
class _MyEvaluationsScreenState extends State<MyEvaluationsScreen> {
  List<Map<String, dynamic>> _evals = [];
  bool _isLoading = true;
 
  @override
  void initState() { super.initState(); _load(); }
  Future<String?> _token() => AuthService().getToken();
 
  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = await _token();
      final res = await http.get(Uri.parse(ApiConfig.myPendingEvaluations),
          headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200)
        setState(() => _evals = List<Map<String, dynamic>>.from(json.decode(res.body)['data']));
    } catch (_) {} finally { setState(() => _isLoading = false); }
  }
 
  Color _typeColor(String t) {
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
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Container(
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
            child: Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20))),
              const SizedBox(width: 14),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('My Evaluations', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                Text('Pending tasks assigned to you', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ])),
            ]),
          )),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
          else if (_evals.isEmpty)
            const SliverFillRemaining(child: Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.success),
                SizedBox(height: 16),
                Text('No pending evaluations!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text('You\'re all caught up.', style: TextStyle(color: AppColors.textSecondary)),
              ],
            )))
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) {
                final e = _evals[i];
                final typeColor = _typeColor(e['evaluator_type']);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => EvaluationFormScreen(
                        evaluationId: e['id'],
                        evaluatorType: e['evaluator_type'],
                        employeeName: e['employee_name'] ?? '',
                      ),
                    )).then((_) => _load()),
                    child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
                      Container(width: 44, height: 44,
                        decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text(e['evaluator_type'].toString()[0].toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: typeColor)))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e['employee_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('${e['job_role_name'] ?? 'N/A'} · ${e['department_name'] ?? 'N/A'}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(e['cycle_name'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(e['evaluator_type'].toString().toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: typeColor))),
                        const SizedBox(height: 6),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondary),
                      ]),
                    ])),
                  ),
                );
              }, childCount: _evals.length)),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ]),
      ),
    );
  }
}
 