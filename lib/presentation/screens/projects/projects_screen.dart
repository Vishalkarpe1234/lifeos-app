import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/widgets/animations/shimmer_loading.dart';
import 'package:lifeos/services/api/api_client.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_projectsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Projects', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () {})],
      ),
      body: async.when(
        data: (projects) => projects.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.folder_outlined, size: 60, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('No projects yet', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')),
              ]))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85),
                itemCount: projects.length,
                itemBuilder: (_, i) => _ProjectCard(project: projects[i]).animate(delay: (40 * i).ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),
              ),
        loading: () => const ShimmerLoading(count: 4, height: 160),
        error: (e, _) => Center(child: Text(e.toString(), style: TextStyle(color: AppColors.error))),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final progress = project['progress_percent'] as int? ?? 0;
    final isFeatured = project['is_featured'] as bool? ?? false;

    return GestureDetector(
      onTap: () => context.go('/projects/${project['id']}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isFeatured ? AppColors.primary.withOpacity(0.4) : AppColors.darkBorder, width: isFeatured ? 1 : 0.5),
          gradient: LinearGradient(colors: [AppColors.darkCard, AppColors.primary.withOpacity(0.04)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.folder, color: AppColors.primary, size: 22)),
          const Spacer(),
          Text(project['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Inter', fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          if (project['short_description'] != null)
            Text(project['short_description'].toString(), style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Inter'), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress / 100, backgroundColor: AppColors.darkBorder, color: AppColors.primary, minHeight: 4)),
          const SizedBox(height: 4),
          Text('$progress% complete', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontFamily: 'Inter')),
        ]),
      ),
    );
  }
}

final _projectsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/projects/', queryParameters: {'page_size': 50});
  return (r.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});
