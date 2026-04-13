import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/announcement.dart';
import '../../services/announcement_service.dart';
import '../../app_colors.dart';

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

  bool get isManager =>
      widget.userRole == 'admin' || widget.userRole == 'manager';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _service.getAnnouncements();
    setState(() {
      _announcements = data;
      _isLoading = false;
    });
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'urgent': return AppColors.error;
      case 'high': return AppColors.warning;
      case 'low': return AppColors.textSecondary;
      default: return AppColors.primary;
    }
  }

  IconData _priorityIcon(String p) {
    switch (p) {
      case 'urgent': return Icons.warning_amber_rounded;
      case 'high': return Icons.priority_high_rounded;
      case 'low': return Icons.arrow_downward_rounded;
      default: return Icons.campaign_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: isManager
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: _showCreateDialog,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            if (_isLoading)
              const SliverFillRemaining(
                  child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary)))
            else if (_announcements.isEmpty)
              SliverFillRemaining(child: _buildEmpty())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildCard(_announcements[i]),
                  childCount: _announcements.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
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
            child: Text('Announcements',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign_rounded,
                size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No announcements yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildCard(AnnouncementModel ann) {
    final color = _priorityColor(ann.priority);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x081B4FD8), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(ann),
        child: Column(
          children: [
            // Priority accent bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_priorityIcon(ann.priority),
                            color: color, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ann.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (ann.isRecent)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('NEW',
                              style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ann.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(ann.createdByName ?? 'Unknown',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const Spacer(),
                      Text(
                        DateFormat('dd MMM yyyy').format(ann.createdAt),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  if (isManager) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _actionBtn(
                          Icons.edit_rounded,
                          'Edit',
                          AppColors.primary,
                          () => _showEditDialog(ann),
                        ),
                        const SizedBox(width: 8),
                        _actionBtn(
                          Icons.delete_outline_rounded,
                          'Delete',
                          AppColors.error,
                          () => _confirmDelete(ann),
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

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showDetail(AnnouncementModel ann) {
    final color = _priorityColor(ann.priority);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_priorityIcon(ann.priority),
                                color: color, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(ann.priorityLabel,
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(ann.title,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Text(
                        'By ${ann.createdByName ?? 'Unknown'} • ${DateFormat('dd MMMM yyyy, hh:mm a').format(ann.createdAt)}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 16),
                      Text(ann.message,
                          style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              height: 1.7)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog() => _showAnnouncementDialog();
  void _showEditDialog(AnnouncementModel ann) =>
      _showAnnouncementDialog(existing: ann);

  void _showAnnouncementDialog({AnnouncementModel? existing}) {
    final titleController =
        TextEditingController(text: existing?.title ?? '');
    final messageController =
        TextEditingController(text: existing?.message ?? '');
    String selectedPriority = existing?.priority ?? 'normal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existing == null ? 'New Announcement' : 'Edit Announcement',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(titleController, 'Title', maxLines: 1),
                const SizedBox(height: 12),
                _dialogField(messageController, 'Message', maxLines: 4),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: _inputDecoration('Priority'),
                  items: [
                    _priorityDropItem('low', 'Low', AppColors.textSecondary),
                    _priorityDropItem('normal', 'Normal', AppColors.primary),
                    _priorityDropItem('high', 'High', AppColors.warning),
                    _priorityDropItem('urgent', 'Urgent', AppColors.error),
                  ],
                  onChanged: (v) => setS(() => selectedPriority = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
                    content: Text(result['success']
                        ? (result['message'] ?? 'Done')
                        : (result['error'] ?? 'Failed')),
                    backgroundColor: result['success']
                        ? AppColors.success
                        : AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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

  DropdownMenuItem<String> _priorityDropItem(
      String value, String label, Color color) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(_priorityIcon(value), color: color, size: 16),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(AnnouncementModel ann) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Announcement',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text('Delete "${ann.title}"?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
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
    if (confirmed == true) {
      final result = await _service.deleteAnnouncement(ann.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(result['message'] ?? result['error'] ?? ''),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        if (result['success']) _load();
      }
    }
  }

  TextField _dialogField(TextEditingController c, String label,
      {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}