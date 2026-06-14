import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/widgets/animations/shimmer_loading.dart';
import 'package:lifeos/services/api/api_client.dart';
import 'package:intl/intl.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_journalProvider);
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Journal', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)), actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showAdd(context, ref))]),
      body: async.when(
        data: (entries) => entries.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.book_outlined, size: 60, color: AppColors.textMuted), const SizedBox(height: 16), Text('No journal entries yet', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter'))]))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (_, i) {
                  final e = entries[i];
                  final mood = e['mood'] as String?;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkBorder, width: 0.5)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(e['date']?.toString() ?? '', style: TextStyle(color: AppColors.primary, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                        const Spacer(),
                        if (mood != null) Text(_moodEmoji(mood), style: const TextStyle(fontSize: 18)),
                      ]),
                      if (e['title'] != null) ...[const SizedBox(height: 6), Text(e['title'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 15))],
                      const SizedBox(height: 6),
                      Text(e['content']?.toString() ?? '', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter', fontSize: 13, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
                    ]),
                  );
                },
              ),
        loading: () => const ShimmerLoading(count: 5),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  String _moodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return '😊'; case 'sad': return '😢'; case 'excited': return '🎉';
      case 'tired': return '😴'; case 'stressed': return '😤'; case 'calm': return '😌';
      default: return '😐';
    }
  }

  void _showAdd(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text("Today's Entry", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
          const SizedBox(height: 12),
          TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'Title (optional)')),
          const SizedBox(height: 12),
          TextField(controller: contentCtrl, style: const TextStyle(color: Colors.white, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'What happened today?'), maxLines: 5),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (contentCtrl.text.isEmpty) return;
              final dio = ref.read(dioProvider);
              await dio.post('/api/v1/journal/', data: {
                if (titleCtrl.text.isNotEmpty) 'title': titleCtrl.text,
                'content': contentCtrl.text,
                'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
              });
              ref.invalidate(_journalProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save Entry', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}

final _journalProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/journal/', queryParameters: {'page_size': 30});
  return (r.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});
