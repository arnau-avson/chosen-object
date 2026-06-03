import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/message_service.dart';
import '../../models/user_profile.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/shared_app_bar.dart';

// ═════════════════════════════════════════════════════════════
// ── Messages Screen ─────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  int _tabIndex = 0; // 0 = Messages, 1 = Requests

  // ── Animation helpers ──────────────────────────────────────

  Animation<double> _fade(double start, double end) => CurvedAnimation(
        parent: _anim,
        curve: Interval(start.clamp(0, 1), end.clamp(0, 1),
            curve: Curves.easeOut),
      );

  Animation<Offset> _slide(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _anim,
          curve: Interval(start.clamp(0, 1), end.clamp(0, 1),
              curve: Curves.easeOut),
        ),
      );

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _openConversation(Conversation conv) {
    final profile = findProfileById(conv.participantId);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => _ConversationScreen(
          conversationId: conv.id,
          participantName: profile.name,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: const SharedAppBar(currentRoute: '/messages'),
      drawer: const AppDrawer(currentRoute: '/messages'),
      body: ListenableBuilder(
        listenable: MessageService.instance,
        builder: (context, _) {
          final service = MessageService.instance;
          final conversations = service.accepted;
          final reqs = service.requests;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                FadeTransition(
                  opacity: _fade(0.0, 0.45),
                  child: SlideTransition(
                    position: _slide(0.0, 0.45),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Text(
                        'Messages',
                        style: GoogleFonts.fraunces(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: AppColors.inkStrong,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ── Tab row ──
                FadeTransition(
                  opacity: _fade(0.06, 0.50),
                  child: SlideTransition(
                    position: _slide(0.06, 0.50),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _TabLabel(
                            label: 'Messages',
                            active: _tabIndex == 0,
                            onTap: () => setState(() => _tabIndex = 0),
                          ),
                          const SizedBox(width: 28),
                          _TabLabel(
                            label: 'Requests',
                            active: _tabIndex == 1,
                            onTap: () => setState(() => _tabIndex = 1),
                          ),
                          if (reqs.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${reqs.length}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.bone,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Tab content ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _tabIndex == 0
                      ? _MessagesTab(
                          key: const ValueKey('messages'),
                          conversations: conversations,
                          onTap: _openConversation,
                          fade: _fade,
                          slide: _slide,
                        )
                      : _RequestsTab(
                          key: const ValueKey('requests'),
                          requests: reqs,
                          onTap: _openConversation,
                          fade: _fade,
                          slide: _slide,
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Tab label (underlined editorial style) ──────────────────
// ═════════════════════════════════════════════════════════════

class _TabLabel extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabLabel({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: GoogleFonts.fraunces(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: active ? AppColors.inkStrong : AppColors.muted,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 1.5,
            width: active ? 32 : 0,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Messages tab ────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _MessagesTab extends StatelessWidget {
  final List<Conversation> conversations;
  final void Function(Conversation) onTap;
  final Animation<double> Function(double, double) fade;
  final Animation<Offset> Function(double, double) slide;

  const _MessagesTab({
    super.key,
    required this.conversations,
    required this.onTap,
    required this.fade,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 36, color: AppColors.hairline2),
              const SizedBox(height: 12),
              Text(
                'No messages yet',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Start a conversation from\na designer\'s profile',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted2,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: fade(0.12, 0.55),
      child: SlideTransition(
        position: slide(0.12, 0.55),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: conversations
                .map((conv) => _ConversationRow(
                      conversation: conv,
                      onTap: () => onTap(conv),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Requests tab ────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _RequestsTab extends StatelessWidget {
  final List<Conversation> requests;
  final void Function(Conversation) onTap;
  final Animation<double> Function(double, double) fade;
  final Animation<Offset> Function(double, double) slide;

  const _RequestsTab({
    super.key,
    required this.requests,
    required this.onTap,
    required this.fade,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.mark_chat_unread_outlined,
                  size: 36, color: AppColors.hairline2),
              const SizedBox(height: 12),
              Text(
                'No requests',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Message requests from people\nyou don\'t follow will appear here',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted2,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: fade(0.12, 0.55),
      child: SlideTransition(
        position: slide(0.12, 0.55),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: requests
                .map((conv) => _RequestRow(
                      conversation: conv,
                      onTap: () => onTap(conv),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Conversation row ────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _ConversationRow extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationRow({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final profile = findProfileById(conversation.participantId);
    final unread = !conversation.isRead;
    final initials =
        profile.name.split(' ').map((w) => w[0]).take(2).join();

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                // Unread dot
                if (unread)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                SizedBox(width: unread ? 10 : 16),

                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: profile.avatarColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: GoogleFonts.fraunces(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Name + message preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight:
                                    unread ? FontWeight.w500 : FontWeight.w400,
                                color: AppColors.inkStrong,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(conversation.lastTimestamp),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conversation.lastMessagePreview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: unread ? AppColors.inkSoft : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(color: AppColors.hairline, height: 1, thickness: 1),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Request row ─────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _RequestRow extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _RequestRow({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final profile = findProfileById(conversation.participantId);
    final initials =
        profile.name.split(' ').map((w) => w[0]).take(2).join();

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 16),

                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: profile.avatarColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: GoogleFonts.fraunces(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Name + preview + actions
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.inkStrong,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(conversation.lastTimestamp),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conversation.lastMessagePreview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.inkSoft,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => MessageService.instance
                                .acceptRequest(conversation.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Accept',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.bone,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => MessageService.instance
                                .declineRequest(conversation.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: AppColors.hairline, width: 1),
                              ),
                              child: Text(
                                'Decline',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(color: AppColors.hairline, height: 1, thickness: 1),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Timestamp formatter ─────────────────────────────────────
// ═════════════════════════════════════════════════════════════

String _formatTimestamp(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return 'Now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dt.weekday - 1];
  }
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${dt.day} ${months[dt.month - 1]}';
}

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _formatDateSeparator(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(date).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${dt.day} ${months[dt.month - 1]}';
}

bool _isDifferentDay(DateTime a, DateTime b) =>
    a.year != b.year || a.month != b.month || a.day != b.day;

// ═════════════════════════════════════════════════════════════
// ── Conversation Screen ─────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String participantName;
  const _ConversationScreen({
    required this.conversationId,
    required this.participantName,
  });

  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  ChatMessage? _replyingTo;
  String? _highlightedMessageId;
  Timer? _highlightTimer;
  final Map<String, GlobalKey> _messageKeys = {};

  Animation<double> _fade(double start, double end) => CurvedAnimation(
        parent: _anim,
        curve: Interval(start.clamp(0, 1), end.clamp(0, 1),
            curve: Curves.easeOut),
      );

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      MessageService.instance.markAsRead(widget.conversationId);
    });
  }

  GlobalKey _keyFor(String messageId) =>
      _messageKeys.putIfAbsent(messageId, () => GlobalKey());

  void _scrollToMessage(String messageId) {
    final key = _messageKeys[messageId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.4,
      );
    }
    setState(() => _highlightedMessageId = messageId);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _highlightedMessageId = null);
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _anim.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    MessageService.instance.sendMessage(
      widget.conversationId,
      text,
      replyToId: _replyingTo?.id,
    );
    _textController.clear();
    setState(() => _replyingTo = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: SharedAppBar(
        currentRoute: '/messages',
        showBack: true,
        title: widget.participantName,
      ),
      body: ListenableBuilder(
        listenable: MessageService.instance,
        builder: (context, _) {
          final conv = MessageService.instance.findById(widget.conversationId);
          final profile = findProfileById(conv.participantId);
          final messages = conv.messages;
          final isUnacceptedRequest =
              conv.isRequest && !conv.requestAccepted;

          // Build items list: messages + date separators
          final items = <_ChatItem>[];
          for (var i = 0; i < messages.length; i++) {
            if (i == 0 ||
                _isDifferentDay(
                    messages[i].timestamp, messages[i - 1].timestamp)) {
              items.add(_ChatItem.separator(messages[i].timestamp));
            }
            items.add(_ChatItem.message(messages[i]));
          }

          return Column(
            children: [
              // ── Request banner ──
              if (isUnacceptedRequest)
                FadeTransition(
                  opacity: _fade(0.0, 0.4),
                  child: Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${profile.name} wants to message you',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => MessageService.instance
                              .acceptRequest(conv.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Accept',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.bone,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            MessageService.instance
                                .declineRequest(conv.id);
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: AppColors.hairline, width: 1),
                            ),
                            child: Text(
                              'Decline',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (isUnacceptedRequest)
                const Divider(
                    color: AppColors.hairline, height: 1, thickness: 1),

              // ── Chat messages ──
              Expanded(
                child: FadeTransition(
                  opacity: _fade(0.05, 0.5),
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 0, vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      // Reversed list: newest first
                      final item = items[items.length - 1 - index];

                      if (item.isSeparator) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                    color: AppColors.hairline,
                                    height: 1,
                                    thickness: 1),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  _formatDateSeparator(item.timestamp!),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(
                                    color: AppColors.hairline,
                                    height: 1,
                                    thickness: 1),
                              ),
                            ],
                          ),
                        );
                      }

                      final msg = item.chatMessage!;
                      final isMine = msg.senderId == 'me';

                      // Determine if this is the last consecutive message
                      // from the same sender (gets the tail).
                      final k = items.length - 1 - index;
                      bool isLastInGroup = true;
                      if (k + 1 < items.length) {
                        final next = items[k + 1];
                        if (!next.isSeparator &&
                            next.chatMessage!.senderId == msg.senderId) {
                          isLastInGroup = false;
                        }
                      }

                      return KeyedSubtree(
                        key: _keyFor(msg.id),
                        child: _ChatBubble(
                          message: msg,
                          isMine: isMine,
                          conversationId: widget.conversationId,
                          onReply: (m) => setState(() => _replyingTo = m),
                          isHighlighted: _highlightedMessageId == msg.id,
                          isLastInGroup: isLastInGroup,
                          onTapReply: msg.replyToId != null
                              ? () => _scrollToMessage(msg.replyToId!)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Message input ──
              FadeTransition(
                opacity: _fade(0.1, 0.55),
                child: _MessageInput(
                  controller: _textController,
                  enabled: !isUnacceptedRequest,
                  onSend: _sendMessage,
                  replyingTo: _replyingTo,
                  onCancelReply: () => setState(() => _replyingTo = null),
                  conversationId: widget.conversationId,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Chat item (message or date separator) ───────────────────
// ═════════════════════════════════════════════════════════════

class _ChatItem {
  final ChatMessage? chatMessage;
  final DateTime? timestamp;
  final bool isSeparator;

  _ChatItem.message(ChatMessage msg)
      : chatMessage = msg,
        timestamp = null,
        isSeparator = false;

  _ChatItem.separator(DateTime dt)
      : chatMessage = null,
        timestamp = dt,
        isSeparator = true;
}

// ═════════════════════════════════════════════════════════════
// ── Chat bubble ─────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final String conversationId;
  final void Function(ChatMessage) onReply;
  final bool isHighlighted;
  final bool isLastInGroup;
  final VoidCallback? onTapReply;

  const _ChatBubble({
    required this.message,
    required this.isMine,
    required this.conversationId,
    required this.onReply,
    this.isHighlighted = false,
    this.isLastInGroup = true,
    this.onTapReply,
  });

  void _showReactionPicker(BuildContext context, Offset tapPosition) {
    final screenWidth = MediaQuery.of(context).size.width;
    const pickerWidth = 248.0;

    double top = tapPosition.dy - 60;
    if (top < 50) top = tapPosition.dy + 20;

    double left =
        isMine ? screenWidth - pickerWidth - 16 : 16.0;
    left = left.clamp(12.0, screenWidth - pickerWidth - 12);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.05),
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              behavior: HitTestBehavior.opaque,
            ),
          ),
          Positioned(
            top: top,
            left: left,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1.0),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              builder: (_, scale, child) => Opacity(
                opacity: ((scale - 0.85) / 0.15).clamp(0.0, 1.0),
                child: Transform.scale(scale: scale, child: child),
              ),
              child: _ReactionBar(
                onSelect: (emoji) {
                  MessageService.instance
                      .reactToMessage(conversationId, message.id, emoji);
                  Navigator.of(ctx).pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _profileName(String senderId) {
    try {
      return findProfileById(senderId).name;
    } catch (_) {
      return 'Unknown';
    }
  }

  Widget _buildReplyQuote() {
    final original = MessageService.instance
        .findMessageInConversation(conversationId, message.replyToId!);
    if (original == null) return const SizedBox.shrink();

    final senderName =
        original.senderId == 'me' ? 'You' : _profileName(original.senderId);

    return GestureDetector(
      onTap: onTapReply,
      child: Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: isMine
            ? AppColors.inkSoft.withValues(alpha: 0.3)
            : AppColors.bone,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 2,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderName,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isMine
                          ? AppColors.bone.withValues(alpha: 0.6)
                          : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    original.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: isMine
                          ? AppColors.bone.withValues(alpha: 0.7)
                          : AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasReaction = message.reaction != null;

    return Dismissible(
      key: ValueKey(message.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onReply(message);
        return false;
      },
      movementDuration: const Duration(milliseconds: 200),
      dismissThresholds: const {DismissDirection.endToStart: 0.15},
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(
          Icons.reply_rounded,
          color: AppColors.muted,
          size: 22,
        ),
      ),
      child: GestureDetector(
        onLongPressStart: (details) =>
            _showReactionPicker(context, details.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          color: isHighlighted
              ? Colors.blue.withValues(alpha: 0.15)
              : Colors.transparent,
          child: Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              left: isMine ? 64 : 16,
              right: isMine ? 16 : 64,
              top: 4,
              bottom: hasReaction ? 14 : (isLastInGroup ? 6 : 1),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Bubble ──
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine ? AppColors.ink : AppColors.surface,
                    borderRadius: isLastInGroup
                        ? BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft:
                                Radius.circular(isMine ? 16 : 0),
                            bottomRight:
                                Radius.circular(isMine ? 0 : 16),
                          )
                        : BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: isMine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.replyToId != null) ...[
                        _buildReplyQuote(),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        message.text,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: isMine ? AppColors.bone : AppColors.inkSoft,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: isMine
                              ? AppColors.bone.withValues(alpha: 0.5)
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Reaction pill ──
                if (hasReaction)
                  Positioned(
                    bottom: -10,
                    left: isMine ? null : 8,
                    right: isMine ? 8 : null,
                    child: GestureDetector(
                      onTap: () => MessageService.instance.reactToMessage(
                          conversationId, message.id, message.reaction!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border:
                              Border.all(color: AppColors.hairline, width: 1),
                        ),
                        child: Text(
                          message.reaction!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Message input ───────────────────────────────────────────
// ═════════════════════════════════════════════════════════════

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;
  final ChatMessage? replyingTo;
  final VoidCallback? onCancelReply;
  final String conversationId;

  const _MessageInput({
    required this.controller,
    required this.enabled,
    required this.onSend,
    this.replyingTo,
    this.onCancelReply,
    required this.conversationId,
  });

  String _senderName(String senderId) {
    if (senderId == 'me') return 'You';
    try {
      return findProfileById(senderId).name;
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Reply preview bar ──
          if (replyingTo != null)
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.hairline, width: 1),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Container(
                    width: 2.5,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to ${_senderName(replyingTo!.senderId)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          replyingTo!.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onCancelReply,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    color: AppColors.muted,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

          // ── Input row ──
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: AppColors.hairline,
                  width: replyingTo != null ? 0 : 1,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkStrong,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          enabled ? 'Message...' : 'Accept request to reply',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.muted,
                      ),
                      filled: true,
                      fillColor: AppColors.bone,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(
                            color: AppColors.hairline, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide:
                            const BorderSide(color: AppColors.ink, width: 1),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(
                            color: AppColors.hairline, width: 1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: enabled ? onSend : null,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: enabled ? AppColors.ink : AppColors.hairline,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 18,
                      color: enabled ? AppColors.bone : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ── Reaction bar (emoji picker overlay) ─────────────────────
// ═════════════════════════════════════════════════════════════

class _ReactionBar extends StatelessWidget {
  final void Function(String emoji) onSelect;

  const _ReactionBar({required this.onSelect});

  static const _emojis = ['❤️', '👍', '😂', '😮', '😢', '🔥'];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.hairline, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _emojis
              .map((e) => GestureDetector(
                    onTap: () => onSelect(e),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
