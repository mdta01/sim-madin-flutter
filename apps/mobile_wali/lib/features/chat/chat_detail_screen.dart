// Chat detail (wali view).
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
  bool _sending = false;

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _msgController.text.trim();
    if (msg.isEmpty) return;
    setState(() => _sending = true);
    _msgController.clear();
    try {
      await sendChatMessageAsWali(ref,
          roomId: widget.roomId, message: msg);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(chatMessagesWaliProvider(widget.roomId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chat Guru')),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const LoadingSkeleton(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                      title: 'Belum ada pesan',
                      subtitle: 'Mulai percakapan dengan mengirim pesan',
                      icon: Icons.chat_outlined);
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: list.length,
                  itemBuilder: (c, i) {
                    final m = list[list.length - 1 - i];
                    final isMe = m.senderType == ChatSenderType.wali;
                    return _MessageBubble(
                      message: m.message,
                      isMe: isMe,
                      time: formatDateTime(m.createdAt),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: 'Tulis pesan...',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.white))
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: isMe ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message,
                style: TextStyle(
                    fontSize: 14,
                    color: isMe ? AppColors.white : AppColors.text)),
            const SizedBox(height: 2),
            Text(time,
                style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? AppColors.white.withOpacity(0.7)
                        : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
