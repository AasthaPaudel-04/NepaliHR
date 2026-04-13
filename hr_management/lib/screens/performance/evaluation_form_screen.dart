import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../app_colors.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class EvaluationFormScreen extends StatefulWidget {
  final int evaluationId;
  final String evaluatorType;
  final String employeeName;

  const EvaluationFormScreen({
    super.key,
    required this.evaluationId,
    required this.evaluatorType,
    required this.employeeName,
  });

  @override
  State<EvaluationFormScreen> createState() => _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends State<EvaluationFormScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _kpis = [];
  // Map of kpi_id -> { achieved_value, rating, notes }
  final Map<int, Map<String, dynamic>> _scores = {};

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<String?> _getToken() => AuthService().getToken();

  Future<void> _loadForm() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse(ApiConfig.evaluationForm(widget.evaluationId)),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'];
        final kpis = List<Map<String, dynamic>>.from(data['kpis']);
        final existing = data['existing_scores'] as Map<String, dynamic>;

        setState(() {
          _kpis = kpis;
          for (final kpi in kpis) {
            final kpiId = kpi['id'];
            final existingScore = existing[kpiId.toString()];
            _scores[kpiId] = {
              'achieved_value': existingScore?['achieved_value']?.toString() ?? '',
              'rating': existingScore?['rating'] ?? 3,
              'notes': existingScore?['notes'] ?? '',
            };
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading evaluation form'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    // Validate
    for (final kpi in _kpis) {
      final kpiId = kpi['id'];
      final score = _scores[kpiId]!;
      if (kpi['kpi_type'] == 'quantitative') {
        if (score['achieved_value'].toString().trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Please enter achieved value for: ${kpi['name']}'),
            backgroundColor: AppColors.error,
          ));
          return;
        }
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final token = await _getToken();
      final scoresPayload = _kpis.map((kpi) {
        final kpiId = kpi['id'];
        final score = _scores[kpiId]!;
        return {
          'kpi_id': kpiId,
          'achieved_value': kpi['kpi_type'] == 'quantitative'
              ? double.tryParse(score['achieved_value'].toString())
              : null,
          'rating': kpi['kpi_type'] == 'rating' ? score['rating'] : null,
          'notes': score['notes'],
        };
      }).toList();

      final res = await http.post(
        Uri.parse(ApiConfig.submitEvaluation(widget.evaluationId)),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'scores': scoresPayload}),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluation submitted successfully!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      } else {
        final err = json.decode(res.body)['error'] ?? 'Submission failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildKpiCard(Map<String, dynamic> kpi) {
    final kpiId = kpi['id'] as int;
    final isQuantitative = kpi['kpi_type'] == 'quantitative';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x081B4FD8), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isQuantitative
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isQuantitative ? 'Quantitative' : 'Rating',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isQuantitative ? AppColors.primary : AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Weight: ${kpi['weightage']}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(kpi['name'],
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            if (kpi['description'] != null) ...[
              const SizedBox(height: 4),
              Text(kpi['description'],
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
            if (isQuantitative && kpi['target_value'] != null) ...[
              const SizedBox(height: 4),
              Text('Target: ${kpi['target_value']}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 14),
            // Input based on type
            if (isQuantitative)
              TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => _scores[kpiId]!['achieved_value'] = v,
                controller: TextEditingController(text: _scores[kpiId]!['achieved_value']),
                decoration: InputDecoration(
                  labelText: 'Achieved Value *',
                  hintText: 'e.g. 45',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rating (1 = Poor, 5 = Excellent)',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (idx) {
                      final val = idx + 1;
                      final selected = _scores[kpiId]!['rating'] == val;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _scores[kpiId]!['rating'] = val),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 44,
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text('$val',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: selected ? Colors.white : AppColors.textSecondary,
                                  )),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (v) => _scores[kpiId]!['notes'] = v,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.headerGradient),
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 16),
                  Text(
                    '${widget.evaluatorType.toUpperCase()} Evaluation',
                    style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.employeeName,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildKpiCard(_kpis[i]),
                  childCount: _kpis.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Submit Evaluation',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}