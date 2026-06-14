import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/services/api/api_client.dart';

class NotesNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref ref;
  NotesNotifier(this.ref) : super(const AsyncValue.loading()) { load(); }

  Future<void> load({String? search, String? category}) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      final params = <String, dynamic>{'page_size': 100, 'is_archived': false};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (category != null) params['category'] = category;
      final r = await dio.get('/api/v1/notes/', queryParameters: params);
      state = AsyncValue.data((r.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<int?> createNote({required String title, String? content, String contentType = 'markdown'}) async {
    try {
      final dio = ref.read(dioProvider);
      final r = await dio.post('/api/v1/notes/', data: {
        'title': title,
        if (content != null) 'content': content,
        'content_type': contentType,
      });
      await load();
      return r.data['id'] as int?;
    } catch (_) { return null; }
  }

  Future<void> updateNote(int id, {required String title, required String content}) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/api/v1/notes/$id', data: {'title': title, 'content': content});
      await load();
    } catch (_) {}
  }

  Future<void> deleteNote(int id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/api/v1/notes/$id');
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((n) => n['id'] != id).toList());
    } catch (_) {}
  }

  Future<void> togglePin(int id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/v1/notes/$id/pin');
      await load();
    } catch (_) {}
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) => NotesNotifier(ref));

final noteDetailProvider = FutureProvider.family<Map<String, dynamic>?, int>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/notes/$id');
  return Map<String, dynamic>.from(r.data as Map);
});
