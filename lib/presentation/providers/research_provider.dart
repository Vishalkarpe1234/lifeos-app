import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/services/api/api_client.dart';

class PublicationsNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref ref;
  PublicationsNotifier(this.ref) : super(const AsyncValue.loading()) { load(); }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      final r = await dio.get('/api/v1/research/publications', queryParameters: {'page_size': 100});
      state = AsyncValue.data((r.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }

  Future<void> create(Map<String, dynamic> data) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/v1/research/publications', data: data);
      await load();
    } catch (_) {}
  }

  Future<void> delete(int id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/api/v1/research/publications/$id');
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((p) => p['id'] != id).toList());
    } catch (_) {}
  }
}

final publicationsProvider = StateNotifierProvider<PublicationsNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) => PublicationsNotifier(ref));

final conferencesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/research/conferences');
  return (r.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

final researchStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/research/stats');
  return Map<String, dynamic>.from(r.data as Map);
});
