import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../app_colors.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class PerformanceResultsScreen extends StatefulWidget {
  const PerformanceResultsScreen({super.key});
  @override
  State<PerformanceResultsScreen> createState() => _PerformanceResultsScreenState();
}
 
class _PerformanceResultsScreenState extends State<PerformanceResultsScreen> {
  List<Map<String, dynamic>> _cycles = [];
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _selectedCycle;
  bool _loadingCycles = true;
  bool _loadingResults = false;
 
  @override
  void initState() { super.initState(); _loadCycles(); }
  Future<String?> _token() => AuthService().getToken();
 
  Future<void> _loadCycles() async {
    final token = await _token();
    final res = await http.get(Uri.parse(ApiConfig.evaluationCycles),
        headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode == 200)
      setState(() { _cycles = List<Map<String, dynamic>>.from(json.decode(res.body)['data']); _loadingCycles = false; });
  }
 
  Future<void> _loadResults(Map<String, dynamic> cycle) async {
    setState(() { _selectedCycle = cycle; _loadingResults = true; _results = []; });
    final token = await _token();
    final res = await http.get(Uri.parse(ApiConfig.performanceResults(cycle['id'])),
        headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode == 200)
      setState(() => _results = List<Map<String, dynamic>>.from(json.decode(res.body)['data']));
    setState(() => _loadingResults = false);
  }
 
  Color _gradeColor(String g) {
    switch (g) {
      case 'Excellent': return const Color(0xFF16A34A);
      case 'Good': return const Color(0xFF2563EB);
      case 'Average': return const Color(0xFFD97706);
      case 'Poor': return const Color(0xFFDC2626);
      default: return AppColors.textSecondary;
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context),
              child: Container(width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20))),
            const SizedBox(width: 14),
            const Expanded(child: Text('Performance Results',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700))),
          ]),
        )),
        // Cycle selector chips
        SliverToBoxAdapter(child: _loadingCycles
            ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.primary)))
            : SizedBox(height: 60, child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                scrollDirection: Axis.horizontal,
                itemCount: _cycles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = _cycles[i];
                  final selected = _selectedCycle?['id'] == c['id'];
                  return FilterChip(
                    selected: selected,
                    label: Text(c['cycle_name']),
                    onSelected: (_) => _loadResults(c),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    checkmarkColor: AppColors.primary,
                  );
                },
              ))),
        if (_loadingResults)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
        else if (_selectedCycle == null)
          const SliverFillRemaining(child: Center(child: Text('Select a cycle above to view results',
              style: TextStyle(color: AppColors.textSecondary))))
        else if (_results.isEmpty)
          const SliverFillRemaining(child: Center(child: Text('No results yet for this cycle.',
              style: TextStyle(color: AppColors.textSecondary))))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) {
              final r = _results[i];
              final grade = r['grade'] ?? 'Poor';
              final finalScore = double.tryParse(r['final_score']?.toString() ?? '0') ?? 0;
              final color = _gradeColor(grade);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border)),
                child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('${r['job_role_name'] ?? 'N/A'} · ${r['department_name'] ?? 'N/A'}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withOpacity(0.3))),
                      child: Column(children: [
                        Text(finalScore.toStringAsFixed(1), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                        Text(grade, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                      ])),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _chip('Self', r['self_score']),
                    const SizedBox(width: 6),
                    _chip('Peer', r['peer_score']),
                    const SizedBox(width: 6),
                    _chip('Mgr', r['manager_score']),
                    const SizedBox(width: 6),
                    _chip('HR', r['hr_score']),
                  ]),
                ])),
              );
            }, childCount: _results.length)),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ]),
    );
  }
 
  Widget _chip(String label, dynamic score) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border)),
    child: Column(children: [
      Text((double.tryParse(score?.toString() ?? '0') ?? 0).toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    ]),
  ));
}