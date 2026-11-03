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
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Chat Rooms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(chatRoomsListAdminProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 6),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(chatRoomsListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada chat room', icon: Icons.chat_outlined) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Type')), DataColumn(label: Text('Wali')), DataColumn(label: Text('Guru')), DataColumn(label: Text('Santri')), DataColumn(label: Text('Last Message')), DataColumn(label: Text('Last Activity'))],
              rows: list.map((r) => DataRow(cells: [
                DataCell(StatusChip(label: ChatRoomType.label(r.type), color: AppColors.info, bg: AppColors.infoLight, compact: true)),
                DataCell(Text(r.waliName, style: const TextStyle(fontSize: 13))),
                DataCell(Text(r.guruName, style: const TextStyle(fontSize: 13))),
                DataCell(Text(r.santriName != '-' ? r.santriName : '-', style: const TextStyle(fontSize: 12))),
                DataCell(Container(constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.3), child: Text(r.lastMessage ?? '-', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis))),
                DataCell(Text(r.lastMessageAt != null ? formatDateTime(r.lastMessageAt) : '-', style: const TextStyle(fontSize: 12))),
              ])).toList(),
              headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 24,
            )),
          ),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }
}
