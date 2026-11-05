// ============================================================================
// SIM MADIN — Chat Messages Pagination (StateNotifier)
// ============================================================================
// Paginated chat messages dengan cursor-based loading.
// - Initial load: latest 50 messages
// - Load more: fetch 50 older messages when user scrolls to top
// - Realtime: refresh new messages saat realtimeRefreshTick bump
//
// Dipakai oleh mobile_wali + mobile_guru chat_detail_screen.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'query_providers.dart' show realtimeRefreshTick;

/// State untuk paginated chat messages.
class ChatMessagesState {
  const ChatMessagesState({
    this.messages = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isInitialLoading = true,
    this.error,
  });

  /// Pesan dalam urutan kronologis (oldest first, newest last).
  final List<ChatMessageModel> messages;

  /// Apakah masih ada pesan lama yang bisa di-load.
  final bool hasMore;

  /// Loading state untuk pagination (load more older messages).
  final bool isLoadingMore;

  /// Loading state untuk initial load.
  final bool isInitialLoading;

  /// Error message (null kalau tidak ada error).
  final String? error;

  ChatMessagesState copyWith({
    List<ChatMessageModel>? messages,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isInitialLoading,
    String? error,
  }) {
    return ChatMessagesState(
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      error: error,
    );
  }
}

/// StateNotifier untuk paginated chat messages.
///
/// Cara pakai:
///   final state = ref.watch(chatMessagesPaginatedProvider(roomId));
///   ref.read(chatMessagesPaginatedProvider(roomId).notifier).loadMore();
///
/// Realtime: otomatis refresh new messages saat `realtimeRefreshTick` bump.
/// Pesan lama yang sudah di-load tetap dipertahankan (tidak reset).
class ChatMessagesNotifier extends StateNotifier<ChatMessagesState> {
  static const _pageSize = 50;

  final SupabaseClient _client;
  final String _roomId;

  ChatMessagesNotifier(this._client, this._roomId)
      : super(const ChatMessagesState()) {
    _loadInitial();
  }

  /// Initial load — fetch latest 50 messages (newest first, then reverse).
  Future<void> _loadInitial() async {
    state = state.copyWith(isInitialLoading: true, error: null);
    try {
      final res = await _client
          .from('ChatMessage')
          .select()
          .eq('chatRoomId', _roomId)
          .order('createdAt', ascending: false)
          .limit(_pageSize);
      final list = (res as List)
          .map((r) => ChatMessageModel.fromJson(r as Map<String, dynamic>))
          .toList();
      // Reverse to chronological order (oldest first, newest last).
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      state = ChatMessagesState(
        messages: list,
        hasMore: list.length >= _pageSize,
        isInitialLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load 50 older messages — prepend to existing list.
  /// Dipanggil saat user scroll ke atas (top of reversed ListView).
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.messages.isEmpty) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    try {
      final oldest = state.messages.first.createdAt;
      final res = await _client
          .from('ChatMessage')
          .select()
          .eq('chatRoomId', _roomId)
          .lt('createdAt', oldest.toIso8601String())
          .order('createdAt', ascending: false)
          .limit(_pageSize);
      final olderList = (res as List)
          .map((r) => ChatMessageModel.fromJson(r as Map<String, dynamic>))
          .toList();
      // Reverse to chronological order.
      olderList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      state = state.copyWith(
        messages: [...olderList, ...state.messages],
        hasMore: olderList.length >= _pageSize,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Refresh new messages — fetch messages newer than the newest in our list.
  /// Dipanggil saat realtime tick bumps (auto-refresh).
  /// Hanya fetch new messages, tidak reset loaded older messages.
  Future<void> refreshNew() async {
    if (state.messages.isEmpty) {
      await _loadInitial();
      return;
    }
    try {
      final newest = state.messages.last.createdAt;
      final res = await _client
          .from('ChatMessage')
          .select()
          .eq('chatRoomId', _roomId)
          .gt('createdAt', newest.toIso8601String())
          .order('createdAt', ascending: true);
      final newList = (res as List)
          .map((r) => ChatMessageModel.fromJson(r as Map<String, dynamic>))
          .toList();
      if (newList.isNotEmpty) {
        state = state.copyWith(messages: [...state.messages, ...newList]);
      }
    } catch (_) {
      // Best-effort refresh — jangan tampilkan error untuk realtime refresh.
    }
  }

  /// Force reload — reset state dan fetch ulang dari awal.
  Future<void> reload() async {
    await _loadInitial();
  }
}

/// Provider untuk paginated chat messages per room.
/// Pakai StateNotifierProvider.family supaya setiap room punya state sendiri.
final chatMessagesPaginatedProvider = StateNotifierProvider.family<
    ChatMessagesNotifier, ChatMessagesState, String>(
  (ref, roomId) {
    final client = ref.read(supabaseClientProvider);
    final notifier = ChatMessagesNotifier(client, roomId);
    // Listen to realtime tick — when it bumps, refresh new messages.
    // Tidak pakai ref.watch karena itu akan rebuild entire notifier
    // dan kehilangan pesan lama yang sudah di-load.
    ref.listen(realtimeRefreshTick, (_, __) {
      notifier.refreshNew();
    });
    return notifier;
  },
);
