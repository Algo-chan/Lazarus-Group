import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/other_providers.dart';
import '../../../shared/widgets/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => notificationProvider.markAllAsRead(),
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyStateWidget(
              title: 'You\'re all caught up',
              message: 'No new notifications at the moment.',
              icon: Icons.notifications_none,
            )
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isUnread = notification['isRead'] == false;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getIconColor(notification['type']).withOpacity(0.1),
                    child: Icon(
                      _getIcon(notification['type']),
                      color: _getIconColor(notification['type']),
                    ),
                  ),
                  title: Text(
                    notification['title'],
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification['body']),
                      const SizedBox(height: 4),
                      Text(
                        notification['time'] ?? 'Just now',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  tileColor: isUnread ? Theme.of(context).primaryColor.withOpacity(0.05) : null,
                  onTap: () {
                    notificationProvider.markAsRead(notification['id']);
                    // Navigate based on type
                  },
                ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
              },
            ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'booking': return Icons.calendar_today;
      case 'message': return Icons.chat_bubble_outline;
      case 'review': return Icons.star_outline;
      default: return Icons.notifications_none;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'booking': return Colors.blue;
      case 'message': return Colors.green;
      case 'review': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
