import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/services/api/api_client.dart';

class Note {
  final int id;
  final String title;
  final String content;
  final bool isPinned;
  final String? color;
  final String createdAt;
  final String updatedAt;

  Note({required this.id, required this.title, required this.content, this.isPinned = false, this.color, required this.createdAt, required this.updatedAt});

  factory Note.fromJson(Map<String, dynamic> j) => Note(
    id: j['id'],
    title: j['title'] ?? '',
    content: j['content'] ?? '',
    isPinned: j['is_pinned'] ?? false,
    color: j['color'],
    createdAt: j['created_at'] ?? '',
    updatedAt: j['updated_at'] ?? '',
  );
}

class NotesState {
  final List<Note> notes;
  final bool isLoading;
  final String? error;
  const NotesState({this.notes = const [], this.isLoading = false, this.error});
  NotesState copyWith({List<Note>? notes, bool? isLoading, String? error}) =>
    NotesState(notes: notes ?? this.notes, isLoading: isLoading ?? this.isLoading, error: error);
}

class NotesNotifier extends StateNotifier<NotesState> {
  final Dio _dio;
  NotesNotifier(this._dio) : super(const NotesState());

  Future<void> fetchNotes({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, dynamic>{'page_size': 100};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _dio.get('/api/v1/notes/', queryParameters: params);
      final items = (res.data['items'] as List).map((e) => Note.fromJson(e)).toList();
      state = state.copyWith(notes: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createNote({required String title, required String content, bool isPinned = false, String? color}) async {
    try {
      await _dio.post('/api/v1/notes/', data: {'title': title, 'content': content, 'is_pinned': isPinned, 'color': color, 'content_type': 'text'});
      await fetchNotes();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateNote({required int id, required String title, required String content, bool isPinned = false, String? color}) async {
    try {
      await _dio.put('/api/v1/notes/$id', data: {'title': title, 'content': content, 'is_pinned': isPinned, 'color': color});
      await fetchNotes();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNote(int id) async {
    try {
      await _dio.delete('/api/v1/notes/$id');
      state = state.copyWith(notes: state.notes.where((n) => n.id != id).toList());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> togglePin(Note note) async {
    return updateNote(id: note.id, title: note.title, content: note.content, isPinned: !note.isPinned, color: note.color);
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  return NotesNotifier(ref.watch(dioProvider));
});
