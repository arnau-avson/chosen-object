import 'package:flutter/foundation.dart';

// ── ChatMessage model ───────────────────────────────────────

class ChatMessage {
  final String id;
  final String senderId; // UserProfile.id or 'me'
  final String text;
  final DateTime timestamp;
  String? reaction;
  final String? replyToId;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.reaction,
    this.replyToId,
  });
}

// ── Conversation model ──────────────────────────────────────

class Conversation {
  final String id;
  final String participantId;
  final List<ChatMessage> messages;
  bool isRead;
  bool isRequest;
  bool requestAccepted;

  Conversation({
    required this.id,
    required this.participantId,
    required this.messages,
    this.isRead = false,
    this.isRequest = false,
    this.requestAccepted = false,
  });

  ChatMessage get lastMessage => messages.last;
  DateTime get lastTimestamp => lastMessage.timestamp;

  String get lastMessagePreview {
    final t = lastMessage.text;
    return t.length > 60 ? '${t.substring(0, 60)}...' : t;
  }
}

// ── MessageService (singleton ChangeNotifier) ───────────────

class MessageService extends ChangeNotifier {
  static final MessageService _instance = MessageService._();
  static MessageService get instance => _instance;

  MessageService._() {
    _conversations = _buildMockConversations();
  }

  late final List<Conversation> _conversations;

  /// Accepted conversations (not a request, or request already accepted),
  /// sorted by most recent first.
  List<Conversation> get accepted {
    final list = _conversations
        .where((c) => !c.isRequest || c.requestAccepted)
        .toList();
    list.sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));
    return list;
  }

  /// Pending requests (not yet accepted).
  List<Conversation> get requests =>
      _conversations.where((c) => c.isRequest && !c.requestAccepted).toList();

  int get unreadCount =>
      accepted.where((c) => !c.isRead).length;

  int get requestCount => requests.length;

  Conversation findById(String id) =>
      _conversations.firstWhere((c) => c.id == id);

  void markAsRead(String conversationId) {
    final conv = findById(conversationId);
    if (!conv.isRead) {
      conv.isRead = true;
      notifyListeners();
    }
  }

  void acceptRequest(String conversationId) {
    final conv = findById(conversationId);
    conv.requestAccepted = true;
    conv.isRead = true;
    notifyListeners();
  }

  void declineRequest(String conversationId) {
    _conversations.removeWhere((c) => c.id == conversationId);
    notifyListeners();
  }

  void sendMessage(String conversationId, String text, {String? replyToId}) {
    final conv = findById(conversationId);
    conv.messages.add(ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me',
      text: text,
      timestamp: DateTime.now(),
      replyToId: replyToId,
    ));
    conv.isRead = true;
    notifyListeners();
  }

  void reactToMessage(String conversationId, String messageId, String emoji) {
    final conv = findById(conversationId);
    final msg = conv.messages.firstWhere((m) => m.id == messageId);
    msg.reaction = msg.reaction == emoji ? null : emoji;
    notifyListeners();
  }

  ChatMessage? findMessageInConversation(String conversationId, String messageId) {
    final conv = findById(conversationId);
    return conv.messages.where((m) => m.id == messageId).firstOrNull;
  }

  // ── Mock data ─────────────────────────────────────────────

  static List<Conversation> _buildMockConversations() {
    final now = DateTime.now();

    return [
      // ── Accepted conversations ────────────────────────────

      // 1. Marta Sala — unread
      Conversation(
        id: 'conv-marta',
        participantId: 'marta-sala',
        isRead: false,
        messages: [
          ChatMessage(
            id: 'msg-m1',
            senderId: 'me',
            text: 'Hi Marta! I love the reactive glaze on the wide bowl. Is it possible to get a custom colour?',
            timestamp: now.subtract(const Duration(hours: 2, minutes: 15)),
          ),
          ChatMessage(
            id: 'msg-m2',
            senderId: 'marta-sala',
            text: 'Thank you! Yes, I can work with different earth tones. What palette are you thinking?',
            timestamp: now.subtract(const Duration(hours: 1, minutes: 50)),
          ),
          ChatMessage(
            id: 'msg-m3',
            senderId: 'me',
            text: 'Something warm — terracotta with a matte finish, if possible.',
            timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
          ),
          ChatMessage(
            id: 'msg-m4',
            senderId: 'marta-sala',
            text: 'I can do a custom glaze in that tone. Want me to send some options?',
            timestamp: now.subtract(const Duration(minutes: 12)),
          ),
        ],
      ),

      // 2. Atelier NM — read
      Conversation(
        id: 'conv-atelier',
        participantId: 'atelier-nm',
        isRead: true,
        messages: [
          ChatMessage(
            id: 'msg-a1',
            senderId: 'me',
            text: 'Hi, is the linen daybed still available?',
            timestamp: now.subtract(const Duration(days: 1, hours: 5)),
          ),
          ChatMessage(
            id: 'msg-a2',
            senderId: 'atelier-nm',
            text: 'Yes! We have one in stock in the oat linen. Shall I reserve it for you?',
            timestamp: now.subtract(const Duration(days: 1, hours: 4)),
          ),
          ChatMessage(
            id: 'msg-a3',
            senderId: 'me',
            text: 'Yes please. Can you ship to Barcelona?',
            timestamp: now.subtract(const Duration(days: 1, hours: 3)),
          ),
          ChatMessage(
            id: 'msg-a4',
            senderId: 'atelier-nm',
            text: 'Perfect, I\'ll ship it Monday',
            timestamp: now.subtract(const Duration(days: 1, hours: 2)),
          ),
        ],
      ),

      // 3. Studio Vèra — unread
      Conversation(
        id: 'conv-vera',
        participantId: 'studio-vera',
        isRead: false,
        messages: [
          ChatMessage(
            id: 'msg-v1',
            senderId: 'me',
            text: 'Is the tall floor lamp from the autumn collection still available?',
            timestamp: now.subtract(const Duration(hours: 5)),
          ),
          ChatMessage(
            id: 'msg-v2',
            senderId: 'studio-vera',
            text: 'The lamp is still available, yes! It comes with the natural linen shade.',
            timestamp: now.subtract(const Duration(hours: 3)),
          ),
        ],
      ),

      // 4. Teixidors — read
      Conversation(
        id: 'conv-teixidors',
        participantId: 'teixidors',
        isRead: true,
        messages: [
          ChatMessage(
            id: 'msg-t1',
            senderId: 'me',
            text: 'Just placed an order for the merino throw in grey. Can\'t wait!',
            timestamp: now.subtract(const Duration(days: 3, hours: 2)),
          ),
          ChatMessage(
            id: 'msg-t2',
            senderId: 'teixidors',
            text: 'Thanks for your order! The throw ships next week. We hope you love it.',
            timestamp: now.subtract(const Duration(days: 3)),
          ),
        ],
      ),

      // 5. Clara Boj — unread
      Conversation(
        id: 'conv-clara',
        participantId: 'clara-boj',
        isRead: false,
        messages: [
          ChatMessage(
            id: 'msg-c1',
            senderId: 'me',
            text: 'The sage plate sold out — will you restock?',
            timestamp: now.subtract(const Duration(days: 2, hours: 8)),
          ),
          ChatMessage(
            id: 'msg-c2',
            senderId: 'clara-boj',
            text: 'I have a similar piece in a slightly larger size if you\'re interested.',
            timestamp: now.subtract(const Duration(days: 2, hours: 6)),
          ),
        ],
      ),

      // ── Requests ──────────────────────────────────────────

      // 6. Elena Martí — request
      Conversation(
        id: 'conv-elena',
        participantId: 'elena-marti',
        isRead: false,
        isRequest: true,
        messages: [
          ChatMessage(
            id: 'msg-e1',
            senderId: 'elena-marti',
            text: 'Hi! I saw your collection and wondered if you\'d be open to a trade? I have some ceramic pieces that might complement yours.',
            timestamp: now.subtract(const Duration(hours: 8)),
          ),
        ],
      ),

      // 7. Pau Vives — request
      Conversation(
        id: 'conv-pau',
        participantId: 'pau-vives',
        isRead: false,
        isRequest: true,
        messages: [
          ChatMessage(
            id: 'msg-p1',
            senderId: 'pau-vives',
            text: 'Hello, I\'m a textile designer based in Valencia. Would love to discuss a collaboration on a woven piece for your space.',
            timestamp: now.subtract(const Duration(days: 1, hours: 12)),
          ),
        ],
      ),

      // 8. Nuria Coll — request
      Conversation(
        id: 'conv-nuria',
        participantId: 'nuria-coll',
        isRead: false,
        isRequest: true,
        messages: [
          ChatMessage(
            id: 'msg-n1',
            senderId: 'nuria-coll',
            text: 'I\'m curating a show in Seville and your pieces would be a perfect fit. Could we chat about a possible feature?',
            timestamp: now.subtract(const Duration(days: 4)),
          ),
        ],
      ),
    ];
  }
}
