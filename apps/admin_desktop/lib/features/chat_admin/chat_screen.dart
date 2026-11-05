// Chat — read-only list of chat rooms.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(chatRoomsListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        AdminScreenHeader(
          title: 'Chat Admin',
          icon: Icons.chat_outlined,
          subtitle: 'Moderasi chat & support',
          actions: [
            IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(chatRoomsListAdminProvider)),
          ],
        ),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 6),
          error: (e, _) => ErrorView(message: friendlyError(e), onRetry: () => ref.invalidate(chatRoomsListAdminProvider)),
          data: (list) => list.isEmpty ? EmptyState(title: 'Belum ada chat room', subtitle: 'Chat room akan muncul di sini setelah percakapan dimulai.', icon: Icons.chat_outlined, onRefresh: () => ref.invalidate(chatRoomsListAdminProvider)) : ModernDataTableContainer(child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Type')), DataColumn(label: Text('Wali')), DataColumn(label: Text('Guru')), DataColumn(label: Text('Santri')), DataColumn(label: Text('Last Message')), DataColumn(label: Text('Last Activity'))],
              rows: list.map((r) => DataRow(cells: [
                DataCell(StatusChip(label: ChatRoomType.label(r.type), color: AppColors.info, bg: AppColors.infoLight, compact: true)),
                DataCell(Text(r.waliName, style: const TextStyle(fontSize: 13))),
                DataCell(Text(r.guruName, style: const TextStyle(fontSize: 13))),
                DataCell(Text(r.santriName != '-' ? r.santriName : '-', style: AppTextStyles.body3)),
                DataCell(Container(constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.3), child: Text(r.lastMessage ?? '-', style: AppTextStyles.body3, maxLines: 1, overflow: TextOverflow.ellipsis))),
                DataCell(Text(r.lastMessageAt != null ? formatDateTime(r.lastMessageAt) : '-', style: AppTextStyles.body3)),
              ])).toList(),
              headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 24,
            ))),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }
}
