// Chat list (wali view).
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
    final asyncValue = ref.watch(chatRoomsWaliProvider);
    final unreadAsync = ref.watch(chatUnreadCountWaliProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chat dengan Guru')),
      body: asyncValue.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(chatRoomsWaliProvider)),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              title: 'Belum ada chat room',
              subtitle: 'Hubungi admin madrasah untuk membuat chat room dengan guru.',
              icon: Icons.chat_outlined,
              onRefresh: () => ref.invalidate(chatRoomsWaliProvider),
            );
          }
          // Resolve unread count map (empty map kalau masih loading).
          final unreadCounts = unreadAsync.maybeWhen(
            data: (m) => m,
            orElse: () => <String, int>{},
          );
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(chatRoomsWaliProvider);
              ref.invalidate(chatUnreadCountWaliProvider);
              await ref.read(chatRoomsWaliProvider.future);
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
                    leading: CircleAvatar(
                      backgroundColor: unread > 0
                          ? AppColors.dangerLight
                          : AppColors.infoLight,
                      foregroundColor:
                          unread > 0 ? AppColors.danger : AppColors.info,
                      child: const Icon(Icons.school),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(r.guruName ?? 'Guru',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (r.lastMessageAt != null)
                          Text(
                            _formatChatTime(r.lastMessageAt!),
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (r.lastMessage != null) ...[
                          Text(r.lastMessage!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: unread > 0
                                      ? AppColors.text
                                      : AppColors.textMuted,
                                  fontWeight: unread > 0
                                      ? FontWeight.w600
                                      : FontWeight.w400),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ] else
                          const Text('Belum ada pesan',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: unread > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white),
                            ),
                          )
                        : null,
                    onTap: () =>
                        context.push('/dashboard/chat/${r.id}'),
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
