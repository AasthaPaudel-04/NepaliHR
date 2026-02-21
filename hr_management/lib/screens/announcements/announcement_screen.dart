import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/announcement.dart';
import '../../services/announcement_service.dart';

class AnnouncementScreen extends StatefulWidget {
  final String userRole;
  const AnnouncementScreen({super.key, required this.userRole});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final AnnouncementService _service = AnnouncementService();
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = true;

  bool get isManager => widget.userRole == 'admin' || widget.userRole == 'manager';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _service.getAnnouncements();
    setState(() { _announcements = data; _isLoading = false; });
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent': return Colors.red;
      case 'high': return Colors.orange;
      case 'low': return Colors.grey;
      default: return Colors.blue;
    }
  }

  IconData _priorityIcon(String priority) {
    switch (priority) {
      case 'urgent': return Icons.emergency;
      case 'high': return Icons.priority_high;
      case 'low': return Icons.low_priority;
      default: return Icons.campaign;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: isManager
          ? FloatingActionButton(
              backgroundColor: Colors.amber.shade700,
              onPressed: _showCreateDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _announcements.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No announcements yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _announcements.length,
                    itemBuilder: (_, index) => _buildCard(_announcements[index]),
                  ),
      ),
    );
  }

  Widget _buildCard(AnnouncementModel ann) {
    final color = _priorityColor(ann.priority);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(ann),
        child: Column(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_priorityIcon(ann.priority), color: color, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ann.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          ann.priorityLabel,
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ann.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'By ${ann.createdByName ?? 'Unknown'}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Row(
                        children: [
                          if (ann.isRecent)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('NEW', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          Text(
                            DateFormat('dd MMM yyyy').format(ann.createdAt),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isManager) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showEditDialog(ann),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                          style: TextButton.styleFrom(foregroundColor: Colors.blue, padding: EdgeInsets.zero),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _confirmDelete(ann),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red, padding: EdgeInsets.zero),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(AnnouncementModel ann) {
    final color = _priorityColor(ann.priority);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_priorityIcon(ann.priority), color: color),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(ann.priorityLabel, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(ann.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'By ${ann.createdByName ?? 'Unknown'} • ${DateFormat('dd MMMM yyyy, hh:mm a').format(ann.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Divider(height: 24),
              Text(ann.message, style: const TextStyle(fontSize: 16, height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog() => _showAnnouncementDialog();
  void _showEditDialog(AnnouncementModel ann) => _showAnnouncementDialog(existing: ann);

  void _showAnnouncementDialog({AnnouncementModel? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final messageController = TextEditingController(text: existing?.message ?? '');
    String selectedPriority = existing?.priority ?? 'normal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'New Announcement' : 'Edit Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                  items: [
                    DropdownMenuItem(value: 'low', child: Row(children: [Icon(Icons.low_priority, color: Colors.grey, size: 18), const SizedBox(width: 8), const Text('Low')])),
                    DropdownMenuItem(value: 'normal', child: Row(children: [Icon(Icons.campaign, color: Colors.blue, size: 18), const SizedBox(width: 8), const Text('Normal')])),
                    DropdownMenuItem(value: 'high', child: Row(children: [Icon(Icons.priority_high, color: Colors.orange, size: 18), const SizedBox(width: 8), const Text('High')])),
                    DropdownMenuItem(value: 'urgent', child: Row(children: [Icon(Icons.emergency, color: Colors.red, size: 18), const SizedBox(width: 8), const Text('Urgent')])),
                  ],
                  onChanged: (v) => setS(() => selectedPriority = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                Map<String, dynamic> result;
                if (existing == null) {
                  result = await _service.createAnnouncement(
                    title: titleController.text.trim(),
                    message: messageController.text.trim(),
                    priority: selectedPriority,
                  );
                } else {
                  result = await _service.updateAnnouncement(existing.id, {
                    'title': titleController.text.trim(),
                    'message': messageController.text.trim(),
                    'priority': selectedPriority,
                  });
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result['success'] ? (result['message'] ?? 'Done') : (result['error'] ?? 'Failed')),
                    backgroundColor: result['success'] ? Colors.green : Colors.red,
                  ));
                  if (result['success']) _load();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(AnnouncementModel ann) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Delete "${ann.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await _service.deleteAnnouncement(ann.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? result['error'] ?? '')));
        if (result['success']) _load();
      }
    }
  }
}