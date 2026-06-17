import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/services/api/api_client.dart';

class Habit {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final String color;
  final String frequency;
  final int streakCurrent;
  final int streakLongest;
  final int targetCount;
  final bool isActive;

  const Habit({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color = '#6366F1',
    this.frequency = 'daily',
    this.streakCurrent = 0,
    this.streakLongest = 0,
    this.targetCount = 1,
    this.isActive = true,
  });

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'],
        name: j['name'] ?? '',
        description: j['description'],
        icon: j['icon'],
        color: j['color'] ?? '#6366F1',
        frequency: j['frequency'] ?? 'daily',
        streakCurrent: j['streak_current'] ?? 0,
        streakLongest: j['streak_longest'] ?? 0,
        targetCount: j['target_count'] ?? 1,
        isActive: j['is_active'] != false,
      );
}

class TodayHabit {
  final Habit habit;
  final bool logged;
  final bool completed;

  const TodayHabit({
    required this.habit,
    required this.logged,
    required this.completed,
  });

  factory TodayHabit.fromJson(Map<String, dynamic> j) {
    final habitMap = j['habit'] as Map<String, dynamic>;
    return TodayHabit(
      habit: Habit.fromJson(habitMap),
      logged: j['logged'] == true,
      completed: j['completed'] == true,
    );
  }
}

class HabitState {
  final List<TodayHabit> todayHabits;
  final List<Habit> allHabits;
  final bool loading;
  final String? error;

  const HabitState({
    this.todayHabits = const [],
    this.allHabits = const [],
    this.loading = false,
    this.error,
  });

  HabitState copyWith({
    List<TodayHabit>? todayHabits,
    List<Habit>? allHabits,
    bool? loading,
    String? error,
  }) =>
      HabitState(
        todayHabits: todayHabits ?? this.todayHabits,
        allHabits: allHabits ?? this.allHabits,
        loading: loading ?? this.loading,
        error: error,
      );
}

class HabitNotifier extends StateNotifier<HabitState> {
  final Dio _dio;
  HabitNotifier(this._dio) : super(const HabitState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final todayR = await _dio.get('/api/v1/habits/today');
      final allR = await _dio.get('/api/v1/habits/');
      final todayHabits = (todayR.data['habits'] as List)
          .map((e) => TodayHabit.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final allHabits = (allR.data['items'] as List)
          .map((e) => Habit.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      state = state.copyWith(
        todayHabits: todayHabits,
        allHabits: allHabits,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> create(
    String name, {
    String? icon,
    String color = '#6366F1',
    String frequency = 'daily',
    String? description,
  }) async {
    try {
      await _dio.post('/api/v1/habits/', data: {
        'name': name,
        if (icon != null) 'icon': icon,
        'color': color,
        'frequency': frequency,
        if (description != null) 'description': description,
      });
      await fetch();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> logHabit(int habitId) async {
    try {
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await _dio.post('/api/v1/habits/logs', data: {
        'habit_id': habitId,
        'date': today,
        'count': 1,
      });
      // Optimistic update
      state = state.copyWith(
        todayHabits: state.todayHabits
            .map((th) => th.habit.id == habitId
                ? TodayHabit(habit: th.habit, logged: true, completed: true)
                : th)
            .toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/api/v1/habits/$id');
      await fetch();
    } catch (_) {}
  }
}

final habitProvider = StateNotifierProvider<HabitNotifier, HabitState>(
  (ref) => HabitNotifier(ref.watch(dioProvider)),
);
