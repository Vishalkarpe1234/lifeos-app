import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/services/api/api_client.dart';

class Task {
  final int id;
  final String title;
  final String? description;
  final String priority; // high/medium/low
  final String status; // todo/in_progress/done
  final bool isCompleted;
  final String? dueDate;
  final String? categoryName;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.priority = 'medium',
    this.status = 'todo',
    this.isCompleted = false,
    this.dueDate,
    this.categoryName,
  });

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'],
        title: j['title'] ?? '',
        description: j['description'],
        priority: j['priority'] ?? 'medium',
        status: j['status'] ?? 'todo',
        isCompleted: j['is_completed'] == true,
        dueDate: j['due_date'],
        categoryName: j['category_name'],
      );

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? priority,
    String? status,
    bool? isCompleted,
    String? dueDate,
    String? categoryName,
  }) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        isCompleted: isCompleted ?? this.isCompleted,
        dueDate: dueDate ?? this.dueDate,
        categoryName: categoryName ?? this.categoryName,
      );
}

class TaskState {
  final List<Task> tasks;
  final bool loading;
  final String? error;
  final String filter; // all/today/completed

  const TaskState({
    this.tasks = const [],
    this.loading = false,
    this.error,
    this.filter = 'all',
  });

  TaskState copyWith({
    List<Task>? tasks,
    bool? loading,
    String? error,
    String? filter,
  }) =>
      TaskState(
        tasks: tasks ?? this.tasks,
        loading: loading ?? this.loading,
        error: error,
        filter: filter ?? this.filter,
      );
}

class TaskNotifier extends StateNotifier<TaskState> {
  final Dio _dio;
  TaskNotifier(this._dio) : super(const TaskState()) {
    fetch();
  }

  Future<void> fetch({String? status, String? priority}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final params = <String, dynamic>{'page_size': 100};
      if (status != null) params['status'] = status;
      if (priority != null) params['priority'] = priority;
      final r = await _dio.get('/api/v1/tasks/', queryParameters: params);
      final items = (r.data['items'] as List)
          .map((e) => Task.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      state = state.copyWith(tasks: items, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> create(
    String title, {
    String priority = 'medium',
    String? dueDate,
    String? description,
  }) async {
    try {
      await _dio.post('/api/v1/tasks/', data: {
        'title': title,
        'priority': priority,
        if (dueDate != null) 'due_date': dueDate,
        if (description != null) 'description': description,
      });
      await fetch();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleComplete(int id) async {
    try {
      await _dio.patch('/api/v1/tasks/$id/complete');
      state = state.copyWith(
        tasks: state.tasks
            .map((t) => t.id == id
                ? t.copyWith(
                    isCompleted: !t.isCompleted,
                    status: t.isCompleted ? 'todo' : 'done',
                  )
                : t)
            .toList(),
      );
    } catch (_) {}
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/api/v1/tasks/$id');
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != id).toList(),
      );
    } catch (_) {}
  }

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>(
  (ref) => TaskNotifier(ref.watch(dioProvider)),
);
