import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/services/api/api_client.dart';

class CodeSnippet {
  final int id;
  final String title;
  final String language;
  final String code;
  final String? description;
  final List<String> tags;
  final bool isFavorite;
  final String? createdAt;

  const CodeSnippet({
    required this.id,
    required this.title,
    required this.language,
    required this.code,
    this.description,
    this.tags = const [],
    this.isFavorite = false,
    this.createdAt,
  });

  factory CodeSnippet.fromJson(Map<String, dynamic> j) => CodeSnippet(
        id: j['id'],
        title: j['title'] ?? '',
        language: j['language'] ?? 'python',
        code: j['code'] ?? '',
        description: j['description'],
        tags: j['tags'] != null ? List<String>.from(j['tags']) : const [],
        isFavorite: j['is_favorite'] == true,
        createdAt: j['created_at']?.toString(),
      );
}

class SnippetState {
  final List<CodeSnippet> snippets;
  final bool loading;
  final String? error;
  final String searchQuery;
  final String? languageFilter;

  const SnippetState({
    this.snippets = const [],
    this.loading = false,
    this.error,
    this.searchQuery = '',
    this.languageFilter,
  });

  SnippetState copyWith({
    List<CodeSnippet>? snippets,
    bool? loading,
    String? error,
    String? searchQuery,
    String? languageFilter,
  }) =>
      SnippetState(
        snippets: snippets ?? this.snippets,
        loading: loading ?? this.loading,
        error: error,
        searchQuery: searchQuery ?? this.searchQuery,
        languageFilter: languageFilter ?? this.languageFilter,
      );
}

class SnippetNotifier extends StateNotifier<SnippetState> {
  final Dio _dio;
  SnippetNotifier(this._dio) : super(const SnippetState()) {
    fetch();
  }

  Future<void> fetch({String? search, String? language}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final params = <String, dynamic>{'page_size': 100};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (language != null) params['language'] = language;
      final r = await _dio.get('/api/v1/snippets/', queryParameters: params);
      final items = (r.data['items'] as List)
          .map((e) => CodeSnippet.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      state = state.copyWith(snippets: items, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> create(
    String title,
    String code, {
    String language = 'python',
    String? description,
    List<String>? tags,
    bool isFavorite = false,
  }) async {
    try {
      await _dio.post('/api/v1/snippets/', data: {
        'title': title,
        'code': code,
        'language': language,
        if (description != null) 'description': description,
        'tags': tags ?? [],
        'is_favorite': isFavorite,
      });
      await fetch();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleFavorite(CodeSnippet snippet) async {
    try {
      await _dio.put('/api/v1/snippets/${snippet.id}', data: {
        'is_favorite': !snippet.isFavorite,
      });
      state = state.copyWith(
        snippets: state.snippets
            .map((s) => s.id == snippet.id
                ? CodeSnippet(
                    id: s.id,
                    title: s.title,
                    language: s.language,
                    code: s.code,
                    description: s.description,
                    tags: s.tags,
                    isFavorite: !s.isFavorite,
                    createdAt: s.createdAt,
                  )
                : s)
            .toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/api/v1/snippets/$id');
      state = state.copyWith(
        snippets: state.snippets.where((s) => s.id != id).toList(),
      );
    } catch (_) {}
  }
}

final snippetProvider = StateNotifierProvider<SnippetNotifier, SnippetState>(
  (ref) => SnippetNotifier(ref.watch(dioProvider)),
);
