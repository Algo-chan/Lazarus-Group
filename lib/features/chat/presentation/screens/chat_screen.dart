import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_service_app/api_service.dart';
import 'package:local_service_app/providers/other_providers.dart';
import 'package:local_service_app/providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.title,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<dynamic> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _myUserId = auth.currentUser?['id'] ?? auth.currentUser?['_id'];
    _loadMessages();
    _setupSocketListener();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final data = await ApiService.getMessages(widget.chatId);
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(data['messages'] as List? ?? []);
          _loading = false;
        });
        _scrollToBottom();
        await ApiService.markMessagesAsRead(widget.chatId);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setupSocketListener() {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.socket?.on('new_message', (data) {
      if (data['chatId'] == widget.chatId && mounted) {
        setState(() {
          _messages.add(data);
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    
    setState(() => _sending = true);
    try {
      await ApiService.sendMessage(widget.chatId, text);
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMine = message['senderId'] == _myUserId;
                      return _buildMessageBubble(message, isMine, colors);
                    },
                  ),
          ),
          _buildInputBar(colors),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic message, bool isMine, ColorScheme colors) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMine ? colors.primary : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMine ? 20 : 0),
                bottomRight: Radius.circular(isMine ? 0 : 20),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
              ],
            ),
            child: Text(
              message['text'] ?? '',
              style: TextStyle(color: isMine ? colors.onPrimary : colors.onSurface, fontSize: 15),
            ),
          ),
          Text(
            _formatTime(message['timestamp']),
            style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant.withOpacity(0.6)),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildInputBar(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _sendMessage,
              child: CircleAvatar(
                backgroundColor: colors.primary,
                child: _sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
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
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
