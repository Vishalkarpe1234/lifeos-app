import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/project_provider.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});
  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectProvider.notifier).fetch();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return C.success;
      case 'completed': return C.primary;
      case 'on_hold': return C.warning;
      default: return C.textSub;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active': return 'Active';
      case 'completed': return 'Completed';
      case 'on_hold': return 'On Hold';
      default: return status;
    }
  }

  void _showAddProject() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final githubCtrl = TextEditingController();
    final liveCtrl = TextEditingController();
    final techCtrl = TextEditingController();
    String status = 'active';
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('New Project', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 18, color: C.text)),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Project title *'), style: const TextStyle(fontFamily: 'Inter')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description'), style: const TextStyle(fontFamily: 'Inter')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active', style: TextStyle(fontFamily: 'Inter'))),
                DropdownMenuItem(value: 'completed', child: Text('Completed', style: TextStyle(fontFamily: 'Inter'))),
                DropdownMenuItem(value: 'on_hold', child: Text('On Hold', style: TextStyle(fontFamily: 'Inter'))),
              ],
              onChanged: (v) => setS(() => status = v ?? 'active'),
            ),
            const SizedBox(height: 12),
            TextField(controller: githubCtrl, decoration: const InputDecoration(labelText: 'GitHub URL', prefixIcon: Icon(Icons.code_rounded)), style: const TextStyle(fontFamily: 'Inter')),
            const SizedBox(height: 12),
            TextField(controller: liveCtrl, decoration: const InputDecoration(labelText: 'Live URL', prefixIcon: Icon(Icons.link_rounded)), style: const TextStyle(fontFamily: 'Inter')),
            const SizedBox(height: 12),
            TextField(controller: techCtrl, decoration: const InputDecoration(labelText: 'Tech Stack (comma separated)', hintText: 'Flutter, FastAPI, PostgreSQL'), style: const TextStyle(fontFamily: 'Inter')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: saving ? null : () async {
                  if (titleCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Title is required'), backgroundColor: C.error));
                    return;
                  }
                  setS(() => saving = true);
                  final tech = techCtrl.text.trim().isEmpty ? null : techCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                  final ok = await ref.read(projectProvider.notifier).create(
                    titleCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    status: status,
                    githubUrl: githubCtrl.text.trim().isEmpty ? null : githubCtrl.text.trim(),
                    liveUrl: liveCtrl.text.trim().isEmpty ? null : liveCtrl.text.trim(),
                    techStack: tech,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Project created!' : 'Failed'), backgroundColor: ok ? C.success : C.error));
                  }
                },
                child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Create Project', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectProvider);

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Projects')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: C.error, size: 40),
                  const SizedBox(height: 12),
                  Text(state.error!, style: const TextStyle(color: C.textSub, fontFamily: 'Inter')),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => ref.read(projectProvider.notifier).fetch(), child: const Text('Retry')),
                ]))
              : state.projects.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: () => ref.read(projectProvider.notifier).fetch(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: state.projects.length,
                        itemBuilder: (_, i) => _ProjectCard(
                          project: state.projects[i],
                          statusColor: _statusColor(state.projects[i].status),
                          statusLabel: _statusLabel(state.projects[i].status),
                          onDelete: () => ref.read(projectProvider.notifier).delete(state.projects[i].id),
                        ),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProject,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Project', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        backgroundColor: C.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: C.primary.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.folder_open_rounded, color: C.primary, size: 40)),
    const SizedBox(height: 16),
    const Text('No projects yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.text, fontFamily: 'Inter')),
    const SizedBox(height: 8),
    const Text('Create your first project', style: TextStyle(fontSize: 13, color: C.textSub, fontFamily: 'Inter')),
  ]));
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onDelete;

  const _ProjectCard({required this.project, required this.statusColor, required this.statusLabel, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final progress = project.progressPercent.clamp(0.0, 100.0) / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(project.title, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: C.text))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(statusLabel, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
          ),
          IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.delete_outline_rounded, color: C.error, size: 18), onPressed: onDelete),
        ]),
        if (project.description?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(project.description!, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: C.textSub), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, backgroundColor: C.border, valueColor: AlwaysStoppedAnimation<Color>(statusColor), minHeight: 6),
          )),
          const SizedBox(width: 8),
          Text('${project.progressPercent.toInt()}%', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
        ]),
        if (project.techStack.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 4, children: project.techStack.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: C.border)),
            child: Text(t, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textSub)),
          )).toList()),
        ],
        if (project.githubUrl != null || project.liveUrl != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            if (project.githubUrl != null) _linkChip(context, Icons.code_rounded, 'GitHub', project.githubUrl!),
            if (project.liveUrl != null) ...[
              const SizedBox(width: 8),
              _linkChip(context, Icons.link_rounded, 'Live', project.liveUrl!),
            ],
          ]),
        ],
      ]),
    );
  }

  Widget _linkChip(BuildContext context, IconData icon, String label, String url) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label URL copied!'), backgroundColor: C.success, duration: const Duration(seconds: 1)));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: C.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: C.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: C.primary)),
        ]),
      ),
    );
  }
}
