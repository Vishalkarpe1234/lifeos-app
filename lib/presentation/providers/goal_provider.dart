import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/services/api/api_client.dart';

class Goal {
  final int id;
  final String title;
  final String? description;
  final String category;
  final String status;
  final double progressPercent;
  final String? targetDate;
  final String? createdAt;

  const Goal({
    required this.id,
    required this.title,
    this.description,
    this.category = 'personal',
    this.status = 'active',
    this.progressPercent = 0,
    this.targetDate,
    this.createdAt,
  });

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        id: j['id'],
        title: j['title'] ?? '',
        description: j['description'],
        category: j['category'] ?? 'personal',
        status: j['status'] ?? 'active',
        progressPercent:
            (j['progress'] ?? j['progress_percent'] ?? 0).toDouble(),
        targetDate: j['target_date'],
        createdAt: j['created_at']?.toString(),
      );
}

class GoalState {
  final List<Goal> goals;
  final bool loading;
  final String? error;

  const GoalState({
    this.goals = const [],
    this.loading = false,
    this.error,
  });

  GoalState copyWith({List<Goal>? goals, bool? loading, String? error}) =>
      GoalState(
        goals: goals ?? this.goals,
        loading: loading ?? this.loading,
        error: error,
      );
}

class GoalNotifier extends StateNotifier<GoalState> {
  final Dio _dio;
  GoalNotifier(this._dio) : super(const GoalState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(loading: true, error: null);
    try {
      // Goals endpoint returns a list directly (not wrapped in items)
      final r = await _dio.get('/api/v1/goals');
      final List<dynamic> list = r.data is List ? r.data : (r.data['items'] ?? []);
      final items = list
          .map((e) => Goal.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      state = state.copyWith(goals: items, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> create(
    String title, {
    String category = 'personal',
    String? description,
    String? targetDate,
  }) async {
    try {
      await _dio.post('/api/v1/goals', data: {
        'title': title,
        'category': category,
        if (description != null) 'description': description,
        if (targetDate != null) 'target_date': targetDate,
      });
      await fetch();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProgress(int id, double progress) async {
    try {
      await _dio.patch('/api/v1/goals/$id', data: {'progress': progress.toInt()});
      await fetch();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/api/v1/goals/$id');
      state = state.copyWith(
        goals: state.goals.where((g) => g.id != id).toList(),
      );
    } catch (_) {}
  }
}

final goalProvider = StateNotifierProvider<GoalNotifier, GoalState>(
  (ref) => GoalNotifier(ref.watch(dioProvider)),
);
