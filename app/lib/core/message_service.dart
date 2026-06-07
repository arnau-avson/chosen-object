import 'package:flutter/foundation.dart';

import 'api_client.dart';

// ═════════════════════════════════════════════════════════════
// ── MessageService (singleton ChangeNotifier) ─────────────────
// ═════════════════════════════════════════════════════════════

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String? senderUsername;
  final String text;
  final int? replyToId;
  final String? reaction;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderUsername,
    required this.text,
    this.replyToId,
    this.reaction,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as int,
        conversationId: j['conversation_id'] as int,
        senderId: j['sender_id'] as int,
        senderUsername: j['sender_username'] as String?,
        text: j['text'] as String,
        replyToId: j['reply_to_id'] as int?,
        reaction: j['reaction'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class Conversation {
  final int id;
  final int otherUserId;
  final String? otherUsername;
  final String otherAvatarType;
  final String otherAvatarColor;
  final String? otherAvatarImageB64;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isRequest;
  final bool requestAccepted;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.otherUserId,
    this.otherUsername,
    this.otherAvatarType = 'color',
    this.otherAvatarColor = '#2E2520',
    this.otherAvatarImageB64,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isRequest = false,
    this.requestAccepted = false,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: j['id'] as int,
        otherUserId: j['other_user_id'] as int,
        otherUsername: j['other_username'] as String?,
        otherAvatarType: j['other_avatar_type'] as String? ?? 'color',
        otherAvatarColor: j['other_avatar_color'] as String? ?? '#2E2520',
        otherAvatarImageB64: j['other_avatar_image_b64'] as String?,
        lastMessage: j['last_message'] as String?,
        lastMessageAt: j['last_message_at'] != null
            ? DateTime.parse(j['last_message_at'] as String)
            : null,
        unreadCount: j['unread_count'] as int? ?? 0,
        isRequest: j['is_request'] as bool? ?? false,
        requestAccepted: j['request_accepted'] as bool? ?? false,
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );
}

class MessageService extends ChangeNotifier {
  static final MessageService _instance = MessageService._();
  static MessageService get instance => _instance;
  MessageService._();

  List<Conversation> _conversations = [];
  List<Conversation> _requests = [];

  List<Conversation> get accepted => _conversations;
  List<Conversation> get requests => _requests;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;
  int get requestCount => _requests.length;

  bool _loading = false;
  bool get loading => _loading;

  /// Fetch conversations.
  Future<void> fetchConversations({int offset = 0, int limit = 20}) async {
    _loading = true;
    notifyListeners();

    try {
      final data = await ApiClient.instance
          .get('/messages/conversations?requests=false&offset=$offset&limit=$limit');
      _conversations = (data as List)
          .map((j) => Conversation.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // keep existing
    }

    _loading = false;
    notifyListeners();
  }

  /// Fetch message requests.
  Future<void> fetchRequests({int offset = 0, int limit = 20}) async {
    try {
      final data = await ApiClient.instance
          .get('/messages/conversations?requests=true&offset=$offset&limit=$limit');
      _requests = (data as List)
          .map((j) => Conversation.fromJson(j as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {
      // keep existing
    }
  }

  /// Get messages in a conversation.
  Future<List<ChatMessage>> fetchMessages(int conversationId,
      {int offset = 0, int limit = 50}) async {
    try {
      final data = await ApiClient.instance.get(
          '/messages/conversations/$conversationId?offset=$offset&limit=$limit');
      return (data as List)
          .map((j) => ChatMessage.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Start or get conversation with a user.
  Future<Conversation?> startConversation(int userId, {String? text}) async {
    try {
      final body = <String, dynamic>{'user_id': userId};
      if (text != null) body['text'] = text;
      final data =
          await ApiClient.instance.post('/messages/conversations', body);
      return Conversation.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Send a message.
  Future<ChatMessage?> sendMessage(int conversationId, String text,
      {int? replyToId}) async {
    try {
      final body = <String, dynamic>{'text': text};
      if (replyToId != null) body['reply_to_id'] = replyToId;
      final data = await ApiClient.instance
          .post('/messages/conversations/$conversationId', body);
      return ChatMessage.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Mark conversation as read.
  Future<void> markAsRead(int conversationId) async {
    try {
      await ApiClient.instance
          .patch('/messages/conversations/$conversationId/read', {});
    } catch (_) {
      // ignore
    }
  }

  /// Accept a message request.
  Future<void> acceptRequest(int conversationId) async {
    try {
      await ApiClient.instance
          .patch('/messages/conversations/$conversationId/accept', {});
      _requests.removeWhere((c) => c.id == conversationId);
      await fetchConversations();
    } catch (_) {
      // ignore
    }
  }

  /// Decline/delete a conversation.
  Future<void> declineRequest(int conversationId) async {
    try {
      await ApiClient.instance
          .delete('/messages/conversations/$conversationId');
      _requests.removeWhere((c) => c.id == conversationId);
      _conversations.removeWhere((c) => c.id == conversationId);
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  /// React to a message.
  Future<void> reactToMessage(int messageId, String? emoji) async {
    try {
      await ApiClient.instance
          .patch('/messages/$messageId/reaction', {'reaction': emoji});
    } catch (_) {
      // ignore
    }
  }

  /// Fetch unread count.
  Future<void> fetchUnreadCount() async {
    try {
      final data = await ApiClient.instance.get('/messages/unread-count');
      _unreadCount = (data as Map<String, dynamic>)['unread_count'] as int;
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }
}
