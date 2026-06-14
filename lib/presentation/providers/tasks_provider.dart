import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/services/api/api_client.dart';

class TasksNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref ref;
  TasksNotifier(this.ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({bool? isCompleted}) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      final params = <String, dynamic>{'page_size': 100};
      if (isCompleted != null) params['is_completed'] = isCompleted;
      final r = await dio.get('/api/v1/tasks/', queryParameters: params);
      final items = (r.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      state = AsyncValue.data(items);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> createTask({required String title, String? description, String priority = 'medium', String? dueDate}) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/v1/tasks/', data: {
        'title': title,
        if (description != null) 'description': description,
        'priority': priority,
        if (dueDate != null) 'due_date': dueDate,
      });
      await load();
    } catch (_) {}
  }

  Future<void> toggleComplete(int id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/v1/tasks/$id/complete');
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.map((t) {
        if (t['id'] == id) {
          return {...t, 'is_completed': !(t['is_completed'] as bool? ?? false)};
        }
        return t;
      }).toList());
    } catch (_) {}
  }

  Future<void> deleteTask(int id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/api/v1/tasks/$id');
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((t) => t['id'] != id).toList());
    } catch (_) {}
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) => TasksNotifier(ref));

final completedTasksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/tasks/', queryParameters: {'is_completed': true, 'page_size': 100});
  return (r.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

final pendingTasksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/tasks/', queryParameters: {'is_completed': false, 'page_size': 100});
  return (r.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});
