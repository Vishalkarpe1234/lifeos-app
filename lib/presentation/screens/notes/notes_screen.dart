import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/notes_provider.dart';
import 'package:lifeos/presentation/widgets/animations/shimmer_loading.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Notes', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sticky_note_2_outlined, color: AppColors.textMuted, size: 64),
                  const SizedBox(height: 16),
                  Text('No notes yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontFamily: 'Inter')),
                  const SizedBox(height: 8),
                  Text('Tap + to create your first note', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontFamily: 'Inter')),
                ],
              ),
            );
          }
          return _isGridView ? _buildGrid(notes) : _buildList(notes);
        },
        loading: () => ShimmerLoading(count: 8, height: 120),
        error: (e, _) => Center(child: Text(e.toString(), style: TextStyle(color: AppColors.error))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/notes/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Note', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> notes) {
    final colors = [
      AppColors.primary.withOpacity(0.15),
      AppColors.accent.withOpacity(0.15),
      AppColors.success.withOpacity(0.15),
      AppColors.warning.withOpacity(0.15),
      const Color(0xFF8B5CF6).withOpacity(0.15),
    ];
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85,
      ),
      itemCount: notes.length,
      itemBuilder: (_, i) {
        final note = notes[i];
        return GestureDetector(
          onTap: () => context.go('/notes/${note['id']}'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder, width: 0.5),
              gradient: LinearGradient(
                colors: [AppColors.darkCard, colors[i % colors.length]],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note['is_pinned'] == true) ...[
                  Icon(Icons.push_pin, color: AppColors.primary, size: 14),
                  const SizedBox(height: 6),
                ],
                Text(
                  note['title'] ?? 'Untitled',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Inter'),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    note['content'] ?? '',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontFamily: 'Inter', height: 1.4),
                    maxLines: 6, overflow: TextOverflow.fade,
                  ),
                ),
                const SizedBox(height: 8),
                if (note['updated_at'] != null)
                  Text(
                    timeago.format(DateTime.parse(note['updated_at'].toString())),
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'Inter'),
                  ),
              ],
            ),
          ).animate(delay: (30 * i).ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),
        );
      },
    );
  }

  Widget _buildList(List<Map<String, dynamic>> notes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (_, i) {
        final note = notes[i];
        return GestureDetector(
          onTap: () => context.go('/notes/${note['id']}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.darkBorder, width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note['title'] ?? 'Untitled', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (note['content'] != null) ...[
                        const SizedBox(height: 4),
                        Text(note['content'].toString(), style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}
