import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../l10n/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _service.getNotifications();
    if (mounted) setState(() { _notifications = data; _isLoading = false; });
  }

  Future<void> _markRead(NotificationModel n) async {
    if (n.isRead) return;
    await _service.markRead(n.id);
    _load();
  }

  Future<void> _markAllRead() async {
    await _service.markAllRead();
    _load();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours  < 24)  return '${diff.inHours}h ago';
    if (diff.inDays   < 7)   return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // Header
        Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.notifications,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w700)),
                if (unreadCount > 0)
                  Text('$unreadCount unread',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12)),
              ]),
            ),
            if (unreadCount > 0)
              GestureDetector(
                onTap: _markAllRead,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                  child: Text(l.markAllRead,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),
          ]),
        ),

        // Body
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(
                  color: AppColors.primary))
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none_rounded,
                              size: 52,
                              color: AppColors.primary.withOpacity(0.3)),
                          const SizedBox(height: 14),
                          Text(l.noNotifications,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (_, i) =>
                            _buildCard(_notifications[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _buildCard(NotificationModel n) {
    return GestureDetector(
      onTap: () => _markRead(n),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.isRead
              ? AppColors.surface
              : AppColors.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: n.isRead
                ? AppColors.border
                : AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Icon circle
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(n.typeIcon,
                  style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Expanded(
                  child: Text(n.title,
                      style: TextStyle(
                          fontWeight: n.isRead
                              ? FontWeight.w600
                              : FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                ),
                Text(_timeAgo(n.createdAt),
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 3),
              Text(n.body,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          // Unread dot
          if (!n.isRead)
            Container(
              width: 9, height: 9,
              margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
            ),
        ]),
      ),
    );
  }
}
