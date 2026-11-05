// Chat list (guru view).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(chatRoomsGuruProvider);
    final unreadAsync = ref.watch(chatUnreadCountGuruProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chat Wali')),
      body: asyncValue.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorView(message: friendlyError(e)),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              title: 'Belum ada chat room',
              subtitle: 'Buat dari admin desktop atau minta wali memulai chat',
              icon: Icons.chat_outlined,
              onRefresh: () => ref.invalidate(chatRoomsGuruProvider),
            );
          }
          final unreadCounts = unreadAsync.maybeWhen(
            data: (m) => m,
            orElse: () => <String, int>{},
          );
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(chatRoomsGuruProvider);
              ref.invalidate(chatUnreadCountGuruProvider);
              await ref.read(chatRoomsGuruProvider.future);
            },
            child: ListView.builder(
              itemCount: list.length,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemBuilder: (c, i) {
                final r = list[i];
                final unread = unreadCounts[r.id] ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: r.type == ChatRoomType.waliGuru
                              ? AppColors.infoLight
                              : r.type == ChatRoomType.waliWali
                                  ? AppColors.successLight
                                  : const Color(0xFFEDE9FE),
                          child: Icon(
                            r.type == ChatRoomType.waliGuru
                                ? Icons.school
                                : Icons.people,
                            color: r.type == ChatRoomType.waliGuru
                                ? AppColors.info
                                : r.type == ChatRoomType.waliWali
                                    ? AppColors.success
                                    : const Color(0xFF7C3AED),
                          ),
                        ),
                        if (unread > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.white, width: 1.5),
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(r.waliName ?? 'Wali',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (r.santriName != null)
                          Text('anak: ${r.santriName}',
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textMuted)),
                        if (r.lastMessageAt != null) ...[
                          const SizedBox(width: 4),
                          Text(_formatChatTime(r.lastMessageAt!),
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ChatRoomType.label(r.type),
                            style: const TextStyle(fontSize: 11)),
                        if (r.lastMessage != null) ...[
                          const SizedBox(height: 2),
                          Text(r.lastMessage!,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: unread > 0
                                      ? AppColors.text
                                      : AppColors.textMuted,
                                  fontWeight: unread > 0
                                      ? FontWeight.w600
                                      : FontWeight.w400),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () =>
                        context.push('/dashboard/akademik/chat/${r.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Format waktu chat — relative time untuk <24 jam, kalau lebih pakai tanggal.
  String _formatChatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} mnt lalu';
    if (diff.inDays < 1) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return formatDate(dt, pattern: 'd MMM');
  }
}
