import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/services/api/api_client.dart';

class JournalEntry {
  final int id;
  final String? title;
  final String content;
  final String date;
  final String? mood;
  final int? moodScore;
  final List<String> gratitude;
  final List<String> highlights;
  final List<String> goalsTomorrow;
  final String? createdAt;

  const JournalEntry({
    required this.id,
    this.title,
    required this.content,
    required this.date,
    this.mood,
    this.moodScore,
    this.gratitude = const [],
    this.highlights = const [],
    this.goalsTomorrow = const [],
    this.createdAt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'],
        title: j['title'],
        content: j['content'] ?? '',
        date: j['date']?.toString() ?? '',
        mood: j['mood'],
        moodScore: j['mood_score'],
        gratitude: j['gratitude'] != null
            ? List<String>.from(j['gratitude'])
            : const [],
        highlights: j['highlights'] != null
            ? List<String>.from(j['highlights'])
            : const [],
        goalsTomorrow: j['goals_tomorrow'] != null
            ? List<String>.from(j['goals_tomorrow'])
            : const [],
        createdAt: j['created_at']?.toString(),
      );
}

class JournalState {
  final List<JournalEntry> entries;
  final bool loading;
  final String? error;

  const JournalState({
    this.entries = const [],
    this.loading = false,
    this.error,
  });

  JournalState copyWith({
    List<JournalEntry>? entries,
    bool? loading,
    String? error,
  }) =>
      JournalState(
        entries: entries ?? this.entries,
        loading: loading ?? this.loading,
        error: error,
      );
}

class JournalNotifier extends StateNotifier<JournalState> {
  final Dio _dio;
  JournalNotifier(this._dio) : super(const JournalState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final r = await _dio.get('/api/v1/journal/', queryParameters: {'page_size': 100});
      final items = (r.data['items'] as List)
          .map((e) => JournalEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      state = state.copyWith(entries: items, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> create({
    String? title,
    required String content,
    String? mood,
    int? moodScore,
    List<String>? gratitude,
    List<String>? highlights,
    List<String>? goalsTomorrow,
  }) async {
    try {
      await _dio.post('/api/v1/journal/', data: {
        if (title != null && title.isNotEmpty) 'title': title,
        'content': content,
        if (mood != null) 'mood': mood,
        if (moodScore != null) 'mood_score': moodScore,
        if (gratitude != null) 'gratitude': gratitude,
        if (highlights != null) 'highlights': highlights,
        if (goalsTomorrow != null) 'goals_tomorrow': goalsTomorrow,
      });
      await fetch();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(
    int id, {
    String? title,
    required String content,
    String? mood,
    int? moodScore,
    List<String>? gratitude,
    List<String>? highlights,
    List<String>? goalsTomorrow,
  }) async {
    try {
      await _dio.put('/api/v1/journal/$id', data: {
        if (title != null && title.isNotEmpty) 'title': title,
        'content': content,
        if (mood != null) 'mood': mood,
        if (moodScore != null) 'mood_score': moodScore,
        if (gratitude != null) 'gratitude': gratitude,
        if (highlights != null) 'highlights': highlights,
        if (goalsTomorrow != null) 'goals_tomorrow': goalsTomorrow,
      });
      await fetch();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/api/v1/journal/$id');
      state = state.copyWith(
        entries: state.entries.where((e) => e.id != id).toList(),
      );
    } catch (_) {}
  }
}

final journalProvider = StateNotifierProvider<JournalNotifier, JournalState>(
  (ref) => JournalNotifier(ref.watch(dioProvider)),
);
