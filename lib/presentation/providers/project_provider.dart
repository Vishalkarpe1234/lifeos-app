import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/services/api/api_client.dart';

class Project {
  final int id;
  final String title;
  final String? description;
  final String status;
  final double progressPercent;
  final String? githubUrl;
  final String? liveUrl;
  final List<String> techStack;
  final String? startDate;
  final String? endDate;
  final String? createdAt;

  const Project({
    required this.id,
    required this.title,
    this.description,
    this.status = 'active',
    this.progressPercent = 0,
    this.githubUrl,
    this.liveUrl,
    this.techStack = const [],
    this.startDate,
    this.endDate,
    this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        id: j['id'],
        title: j['title'] ?? '',
        description: j['description'],
        status: j['status'] ?? 'active',
        progressPercent:
            (j['progress_percent'] ?? 0).toDouble(),
        githubUrl: j['github_url'],
        liveUrl: j['live_url'],
        techStack: j['technologies'] != null
            ? List<String>.from(j['technologies'])
            : (j['tech_stack'] != null ? List<String>.from(j['tech_stack']) : const []),
        startDate: j['start_date'],
        endDate: j['end_date'],
        createdAt: j['created_at']?.toString(),
      );
}

class ProjectState {
  final List<Project> projects;
  final bool loading;
  final String? error;

  const ProjectState({
    this.projects = const [],
    this.loading = false,
    this.error,
  });

  ProjectState copyWith({
    List<Project>? projects,
    bool? loading,
    String? error,
  }) =>
      ProjectState(
        projects: projects ?? this.projects,
        loading: loading ?? this.loading,
        error: error,
      );
}

class ProjectNotifier extends StateNotifier<ProjectState> {
  final Dio _dio;
  ProjectNotifier(this._dio) : super(const ProjectState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final r = await _dio.get('/api/v1/projects/', queryParameters: {'page_size': 100});
      final items = (r.data['items'] as List)
          .map((e) => Project.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      state = state.copyWith(projects: items, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> create(
    String title, {
    String? description,
    String status = 'active',
    String? githubUrl,
    String? liveUrl,
    List<String>? techStack,
  }) async {
    try {
      await _dio.post('/api/v1/projects/', data: {
        'title': title,
        if (description != null) 'description': description,
        'status': status,
        if (githubUrl != null) 'github_url': githubUrl,
        if (liveUrl != null) 'live_url': liveUrl,
        if (techStack != null) 'technologies': techStack,
      });
      await fetch();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/api/v1/projects/$id');
      state = state.copyWith(
        projects: state.projects.where((p) => p.id != id).toList(),
      );
    } catch (_) {}
  }
}

final projectProvider = StateNotifierProvider<ProjectNotifier, ProjectState>(
  (ref) => ProjectNotifier(ref.watch(dioProvider)),
);
