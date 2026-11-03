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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chat Wali')),
      body: asyncValue.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              title: 'Belum ada chat room',
              subtitle: 'Buat dari admin desktop atau minta wali memulai chat',
              icon: Icons.chat_outlined,
              onRefresh: () => ref.invalidate(chatRoomsGuruProvider),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(chatRoomsGuruProvider);
              await ref.read(chatRoomsGuruProvider.future);
            },
            child: ListView.builder(
              itemCount: list.length,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemBuilder: (c, i) {
                final r = list[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    leading: CircleAvatar(
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
                    title: Text(r.waliName ?? 'Wali',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ChatRoomType.label(r.type),
                            style: const TextStyle(fontSize: 12)),
                        if (r.lastMessage != null) ...[
                          const SizedBox(height: 2),
                          Text(r.lastMessage!,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                        if (r.lastMessageAt != null) ...[
                          const SizedBox(height: 2),
                          Text(formatDateTime(r.lastMessageAt),
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ],
                    ),
                    isThreeLine: true,
                    trailing: r.messageCount > 0
                        ? StatusChip(
                            label: '${r.messageCount} pesan',
                            color: AppColors.info,
                            bg: AppColors.infoLight,
                            compact: true)
                        : null,
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
}
