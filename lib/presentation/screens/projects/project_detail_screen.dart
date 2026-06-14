import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final int projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_projectDetailProvider(projectId));

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: async.when(
        data: (p) => CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.darkBg,
            title: Text(p['title'] ?? '', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate([
              _buildHeader(p),
              const SizedBox(height: 16),
              _buildDescription(p),
              const SizedBox(height: 16),
              if ((p['technologies'] as List?)?.isNotEmpty ?? false) _buildTech(p),
              const SizedBox(height: 16),
              _buildLinks(p),
            ])),
          ),
        ]),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> p) {
    final progress = p['progress_percent'] as int? ?? 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Text(p['status'] ?? 'active', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w500))),
      const SizedBox(height: 12),
      ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: progress / 100, backgroundColor: AppColors.darkBorder, color: AppColors.primary, minHeight: 8)),
      const SizedBox(height: 4),
      Text('$progress% complete', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Inter')),
    ]);
  }

  Widget _buildDescription(Map<String, dynamic> p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkBorder, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Description', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
        const SizedBox(height: 8),
        Text(p['description'] ?? 'No description', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter', height: 1.6, fontSize: 14)),
      ]),
    );
  }

  Widget _buildTech(Map<String, dynamic> p) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Technologies', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: (p['technologies'] as List).map((t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.accent.withOpacity(0.25))),
        child: Text(t.toString(), style: const TextStyle(color: AppColors.accent, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
      )).toList()),
    ]);
  }

  Widget _buildLinks(Map<String, dynamic> p) {
    return Column(children: [
      if (p['github_url'] != null) _LinkTile('GitHub', p['github_url'].toString(), Icons.code, AppColors.textSecondary),
      if (p['live_url'] != null) _LinkTile('Live Demo', p['live_url'].toString(), Icons.open_in_new, AppColors.primary),
      if (p['documentation_url'] != null) _LinkTile('Documentation', p['documentation_url'].toString(), Icons.description_outlined, AppColors.accent),
    ]);
  }
}

class _LinkTile extends StatelessWidget {
  final String label;
  final String url;
  final IconData icon;
  final Color color;
  const _LinkTile(this.label, this.url, this.icon, this.color);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkBorder, width: 0.5)),
      child: Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 12), Text(label, style: TextStyle(color: color, fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500)), const Spacer(), Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18)]),
    ),
  );
}

final _projectDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/projects/$id');
  return Map<String, dynamic>.from(r.data as Map);
});
