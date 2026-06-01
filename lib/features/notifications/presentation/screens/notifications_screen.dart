import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_service_app/providers/other_providers.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<NotificationProvider>().fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notificationProvider.notifications.any((n) => !n['read']))
            TextButton(
              onPressed: () => notificationProvider.markAllAsRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notificationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notificationProvider.notifications.isEmpty
              ? _buildEmptyState(colors)
              : RefreshIndicator(
                  onRefresh: notificationProvider.fetchNotifications,
                  child: ListView.separated(
                    itemCount: notificationProvider.notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = notificationProvider.notifications[index];
                      return _buildNotificationTile(notification, colors);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 80, color: colors.outline.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No notifications yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(dynamic notification, ColorScheme colors) {
    final isRead = notification['read'] == true;
    final type = notification['type'] as String?;
    
    IconData icon;
    Color iconColor;
    switch (type) {
      case 'new_booking': icon = Icons.event_note; iconColor = Colors.blue; break;
      case 'booking_status_change': icon = Icons.update; iconColor = Colors.orange; break;
      case 'new_message': icon = Icons.chat; iconColor = Colors.green; break;
      case 'new_review': icon = Icons.star; iconColor = Colors.purple; break;
      default: icon = Icons.notifications; iconColor = colors.primary;
    }

    return ListTile(
      onTap: () {
        // Handle navigation based on type
      },
      tileColor: isRead ? null : colors.primary.withOpacity(0.05),
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        notification['message'] ?? 'Notification',
        style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
      ),
      subtitle: Text(_formatTime(notification['createdAt'])),
      trailing: isRead ? null : Container(width: 8, height: 8, decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle)),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}
