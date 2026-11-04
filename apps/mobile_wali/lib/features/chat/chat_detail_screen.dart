// Chat detail (wali view) — paginated messages + send.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.roomId});
  final String roomId;
  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  bool _wasAtBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Detect scroll position — load more older messages when user reaches
  /// the top (maxScrollExtent in a reversed ListView).
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // Track if user is at the bottom (newest messages).
    _wasAtBottom = pos.pixels < 200;

    // Load more when near the top (end of reversed list).
    if (pos.pixels >= pos.maxScrollExtent - 100 && !pos.outOfRange) {
      final notifier =
          ref.read(chatMessagesPaginatedProvider(widget.roomId).notifier);
      notifier.loadMore();
    }
  }

  Future<void> _send() async {
    final msg = _msgController.text.trim();
    if (msg.isEmpty) return;
    setState(() => _sending = true);
    try {
      await sendChatMessageAsWali(ref,
          roomId: widget.roomId, message: msg);
      if (mounted) _msgController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal: ${friendlyError(e)}'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Scroll to bottom (newest message) after new messages load.
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatMessagesPaginatedProvider(widget.roomId));
    final messages = chatState.messages;

    // Auto-scroll to bottom when new messages arrive (if user was at bottom).
    if (chatState.isInitialLoading == false && messages.isNotEmpty && _wasAtBottom) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chat Guru')),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(chatState, messages),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBody(ChatMessagesState chatState, List<ChatMessageModel> messages) {
    if (chatState.isInitialLoading) {
      return const LoadingSkeleton();
    }
    if (chatState.error != null && messages.isEmpty) {
      return ErrorView(
        message: chatState.error!,
        onRetry: () => ref
            .read(chatMessagesPaginatedProvider(widget.roomId).notifier)
            .reload(),
      );
    }
    if (messages.isEmpty) {
      return const EmptyState(
          title: 'Belum ada pesan',
          subtitle: 'Mulai percakapan dengan mengirim pesan',
          icon: Icons.chat_outlined);
    }
    // Reversed ListView: index 0 = bottom (newest), last index = top (oldest).
    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: messages.length + (chatState.isLoadingMore ? 1 : 0),
      itemBuilder: (c, i) {
        // Loading indicator at the top (end of reversed list).
        if (i == messages.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final m = messages[messages.length - 1 - i];
        final isMe = m.senderType == ChatSenderType.wali;
        return _MessageBubble(
          message: m.message,
          isMe: isMe,
          time: formatDateTime(m.createdAt),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgController,
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  hintStyle: AppTextStyles.body2
                      .copyWith(color: AppColors.textMuted),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.backgroundSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
                ),
                style: AppTextStyles.body1,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppColors.primaryShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _sending ? null : _send,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.white))
                        : const Icon(Icons.send,
                            color: AppColors.white, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.time,
  });
  final String message;
  final bool isMe;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: isMe ? AppColors.primaryGradient : null,
          color: isMe ? null : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isMe ? AppRadius.lg : AppRadius.xs),
            bottomRight: Radius.circular(isMe ? AppRadius.xs : AppRadius.lg),
          ),
          boxShadow: isMe
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : AppColors.cardShadow,
          border: isMe ? null : Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message,
                style: AppTextStyles.body1.copyWith(
                    color: isMe ? AppColors.white : AppColors.text,
                    height: 1.4)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time,
                    style: AppTextStyles.caption.copyWith(
                        color: isMe
                            ? AppColors.white.withValues(alpha: 0.7)
                            : AppColors.textMuted)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all,
                      size: 12,
                      color: AppColors.white.withValues(alpha: 0.7)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
