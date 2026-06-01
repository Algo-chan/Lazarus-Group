import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../api_service.dart';
import '../core/constants/api_constants.dart';

class BookingProvider extends ChangeNotifier {
  List<dynamic> _bookings = [];
  bool _isLoading = false;

  List<dynamic> get bookings => _bookings;
  bool get isLoading => _isLoading;

  Future<void> fetchMyBookings() async {
    _isLoading = true;
    notifyListeners();
    try {
      _bookings = await ApiService.getMyBookings();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProviderBookings() async {
    _isLoading = true;
    notifyListeners();
    try {
      _bookings = await ApiService.getProviderBookings();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateStatus(String id, String action) async {
    try {
      await ApiService.updateBookingStatus(id, action);
      final index = _bookings.indexWhere((b) => b['id'] == id);
      if (index != -1) {
        // Optimistically update or just re-fetch
        if (action == 'confirm') _bookings[index]['status'] = 'confirmed';
        if (action == 'start') _bookings[index]['status'] = 'in_progress';
        if (action == 'complete') _bookings[index]['status'] = 'completed';
        if (action == 'cancel') _bookings[index]['status'] = 'cancelled';
        notifyListeners();
      }
    } catch (_) {}
  }
}

class ChatProvider extends ChangeNotifier {
  List<dynamic> _chats = [];
  bool _isLoading = false;
  io.Socket? _socket;

  List<dynamic> get chats => _chats;
  bool get isLoading => _isLoading;
  io.Socket? get socket => _socket;

  Future<void> fetchChats() async {
    _isLoading = true;
    notifyListeners();
    try {
      _chats = await ApiService.getChats();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  void initSocket(String token) {
    if (_socket != null) return;
    
    final baseUrl = ApiConstants.baseUrl.replaceFirst('/api', '');
    _socket = io.io(baseUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .build());

    _socket!.onConnect((_) {
      debugPrint('Socket connected');
    });

    _socket!.on('new_message', (data) {
      // Update chat list preview and unread count
      final chatId = data['chatId'];
      final index = _chats.indexWhere((c) => c['id'] == chatId);
      if (index != -1) {
        _chats[index]['lastMessagePreview'] = data['text'];
        _chats[index]['lastMessageAt'] = data['timestamp'];
        if (data['senderId'] != _socket!.auth?['userId']) {
          _chats[index]['unreadCount'] = (_chats[index]['unreadCount'] ?? 0) + 1;
        }
        // Move to top
        final chat = _chats.removeAt(index);
        _chats.insert(0, chat);
        notifyListeners();
      }
    });

    _socket!.onDisconnect((_) => debugPrint('Socket disconnected'));
  }

  void disposeSocket() {
    _socket?.dispose();
    _socket = null;
  }
}

class NotificationProvider extends ChangeNotifier {
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<dynamic> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notifications = await ApiService.getNotifications();
      _unreadCount = await ApiService.getUnreadNotificationCount();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      for (var n in _notifications) {
        n['read'] = true;
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  void addNotification(dynamic notification) {
    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
  }
}
