import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/services/api/api_client.dart';

class Note {
  final int id;
  final String title;
  final String content;
  final bool isPinned;
  final String createdAt;
  final String updatedAt;
  Note({required this.id, required this.title, required this.content, this.isPinned = false, required this.createdAt, required this.updatedAt});
  factory Note.fromJson(Map<String, dynamic> j) => Note(
    id: j['id'], title: j['title'] ?? '', content: j['content'] ?? '',
    isPinned: j['is_pinned'] ?? false, createdAt: j['created_at']?.toString() ?? '', updatedAt: j['updated_at']?.toString() ?? '');
}

class NotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final Dio _dio;
  NotesNotifier(this._dio) : super(const AsyncValue.loading());

  Future<void> fetch({String? search}) async {
    state = const AsyncValue.loading();
    try {
      final params = <String, dynamic>{'page_size': 100};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final r = await _dio.get('/api/v1/notes/', queryParameters: params);
      state = AsyncValue.data((r.data['items'] as List).map((e) => Note.fromJson(e)).toList());
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }

  Future<bool> create(String title, String content) async {
    try {
      await _dio.post('/api/v1/notes/', data: {'title': title, 'content': content, 'content_type': 'text'});
      await fetch();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> update(int id, String title, String content, {bool? isPinned}) async {
    try {
      await _dio.put('/api/v1/notes/$id', data: {'title': title, 'content': content, if (isPinned != null) 'is_pinned': isPinned});
      await fetch();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> delete(int id) async {
    try {
      await _dio.delete('/api/v1/notes/$id');
      state = AsyncValue.data(state.value?.where((n) => n.id != id).toList() ?? []);
      return true;
    } catch (_) { return false; }
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<Note>>>((ref) => NotesNotifier(ref.watch(dioProvider)));
