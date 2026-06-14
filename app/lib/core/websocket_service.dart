import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'constants.dart';
import 'message_service.dart';

/// Manages a single WebSocket connection to a conversation.
class WebSocketService extends ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._();
  static WebSocketService get instance => _instance;
  WebSocketService._();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  int? _conversationId;
  bool _connected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  bool get connected => _connected;
  int? get conversationId => _conversationId;

  /// Callback for incoming messages — set by the conversation screen.
  void Function(ChatMessage message)? onMessage;

  /// Callback for incoming reactions.
  void Function(int messageId, String? reaction)? onReaction;

  /// Callback for read receipts.
  void Function(int userId)? onRead;

  /// Connect to a conversation's WebSocket.
  Future<void> connect(int conversationId) async {
    // Disconnect existing connection if any
    await disconnect();

    _conversationId = conversationId;
    _reconnectAttempts = 0;

    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_conversationId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    // Build WebSocket URL from the API base URL
    final baseUrl = ApiConstants.baseUrl;
    final wsBase = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final wsUrl =
        '$wsBase/api/v1/ws/$_conversationId?token=$token';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _subscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );
      _connected = true;
      _reconnectAttempts = 0;
      notifyListeners();
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = json['type'] as String?;
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return;

      switch (type) {
        case 'message':
          final msg = ChatMessage.fromJson(data);
          onMessage?.call(msg);
          break;
        case 'reaction':
          final msgId = data['message_id'] as int;
          final reaction = data['reaction'] as String?;
          onReaction?.call(msgId, reaction);
          break;
        case 'read':
          final userId = data['user_id'] as int;
          onRead?.call(userId);
          break;
      }
    } catch (_) {
      // Ignore malformed messages
    }
  }

  void _onError(dynamic error) {
    _connected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  void _onDone() {
    _connected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_conversationId == null) return;
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    // Exponential backoff: 1s, 2s, 4s, 8s, max 15s
    final delay = Duration(
      seconds: (_reconnectAttempts * 2).clamp(1, 15),
    );
    _reconnectTimer = Timer(delay, () async {
      if (_conversationId != null) {
        await _doConnect();
      }
    });
  }

  /// Send a message via WebSocket.
  void sendMessage(String text, {int? replyToId}) {
    if (_channel == null || !_connected) return;
    _channel!.sink.add(jsonEncode({
      'type': 'message',
      'text': text,
      'reply_to_id': replyToId,
    }));
  }

  /// Send a reaction via WebSocket.
  void sendReaction(int messageId, String? reaction) {
    if (_channel == null || !_connected) return;
    _channel!.sink.add(jsonEncode({
      'type': 'reaction',
      'message_id': messageId,
      'reaction': reaction,
    }));
  }

  /// Send a read receipt via WebSocket.
  void sendRead() {
    if (_channel == null || !_connected) return;
    _channel!.sink.add(jsonEncode({'type': 'read'}));
  }

  /// Disconnect from the current conversation.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _conversationId = null;
    onMessage = null;
    onReaction = null;
    onRead = null;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _connected = false;
    notifyListeners();
  }
}
