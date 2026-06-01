import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:local_service_app/providers/other_providers.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ChatProvider>().fetchChats());
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: chatProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : chatProvider.chats.isEmpty
              ? _buildEmptyState(colors)
              : RefreshIndicator(
                  onRefresh: chatProvider.fetchChats,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chatProvider.chats.length,
                    separatorBuilder: (context, index) => const Divider(indent: 80, height: 1),
                    itemBuilder: (context, index) {
                      final chat = chatProvider.chats[index];
                      return _buildChatTile(chat, colors);
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
          Icon(Icons.chat_bubble_outline, size: 80, color: colors.outline.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No messages yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Your conversations will appear here', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChatTile(dynamic chat, ColorScheme colors) {
    final otherUser = chat['otherUser'] ?? {};
    final lastMessage = chat['lastMessagePreview'] ?? 'Start a conversation';
    final unreadCount = chat['unreadCount'] ?? 0;
    final time = _formatTime(chat['lastMessageAt']);

    return ListTile(
      onTap: () => context.push('/customer/chat/${chat['id']}', extra: otherUser['name'] ?? 'Chat'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colors.primaryContainer,
            child: Text(otherUser['name']?[0].toUpperCase() ?? 'U', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
          ),
          if (otherUser['is_verified'] == true)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.verified, color: Colors.blue, size: 14),
              ),
            ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(otherUser['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(time, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: unreadCount > 0 ? colors.onSurface : colors.onSurfaceVariant, fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal),
              ),
            ),
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}
