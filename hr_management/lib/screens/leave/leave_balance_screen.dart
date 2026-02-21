import 'package:flutter/material.dart';
import '../../services/leave_service.dart';
import '../../models/leave_request.dart';

class LeaveBalanceScreen extends StatefulWidget {
  const LeaveBalanceScreen({super.key});

  @override
  State<LeaveBalanceScreen> createState() => _LeaveBalanceScreenState();
}

class _LeaveBalanceScreenState extends State<LeaveBalanceScreen> {
  final _leaveService = LeaveService();
  LeaveBalance? _balance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final balance = await _leaveService.getBalance();
      setState(() {
        _balance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildBalanceCard(String title, int days, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text(
              '$days',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color),
            ),
            const Text('days left'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Balance')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _balance == null
              ? const Center(child: Text('Failed to load balance'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text('Total Leave Balance', style: TextStyle(fontSize: 18)),
                              const SizedBox(height: 8),
                              Text(
                                '${_balance!.total}',
                                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                              ),
                              const Text('days'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildBalanceCard('Casual Leave', _balance!.casualLeave, Colors.blue),
                      const SizedBox(height: 12),
                      _buildBalanceCard('Sick Leave', _balance!.sickLeave, Colors.orange),
                      const SizedBox(height: 12),
                      _buildBalanceCard('Annual Leave', _balance!.annualLeave, Colors.green),
                    ],
                  ),
                ),
    );
  }
}