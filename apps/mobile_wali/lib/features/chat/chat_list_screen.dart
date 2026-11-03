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
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(chatRoomsWaliProvider);
              await ref.read(chatRoomsWaliProvider.future);
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
                      backgroundColor: AppColors.infoLight,
                      foregroundColor: AppColors.info,
                      child: const Icon(Icons.school),
                    ),
                    title: Text(r.guruName ?? 'Guru',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (r.lastMessage != null) ...[
                          Text(r.lastMessage!,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ] else
                          const Text('Belum ada pesan',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                        if (r.lastMessageAt != null) ...[
                          const SizedBox(height: 2),
                          Text(formatDateTime(r.lastMessageAt),
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted)),
                        ],
                      ],
                    ),
                    isThreeLine: true,
                    trailing: r.messageCount > 0
                        ? StatusChip(
                            label: '${r.messageCount}',
                            color: AppColors.info,
                            bg: AppColors.infoLight,
                            compact: true)
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
}
