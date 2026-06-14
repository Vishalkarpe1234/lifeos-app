import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/widgets/animations/shimmer_loading.dart';
import 'package:lifeos/services/api/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_bookmarksProvider);
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Bookmarks', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showAdd(context, ref))],
      ),
      body: async.when(
        data: (items) => items.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.bookmark_outline, size: 60, color: AppColors.textMuted), const SizedBox(height: 16), Text('No bookmarks', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter'))]))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final b = items[i];
                  return GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(b['url'].toString());
                      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.darkBorder, width: 0.5)),
                      child: Row(children: [
                        Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.bookmark, color: AppColors.primary, size: 18)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(b['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(b['url']?.toString() ?? '', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        Icon(Icons.open_in_new, color: AppColors.textMuted, size: 16),
                      ]),
                    ),
                  );
                },
              ),
        loading: () => const ShimmerLoading(count: 8, height: 64),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  void _showAdd(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Add Bookmark', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
          const SizedBox(height: 12),
          TextField(controller: urlCtrl, style: const TextStyle(color: Colors.white, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'URL *'), keyboardType: TextInputType.url),
          const SizedBox(height: 12),
          TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (urlCtrl.text.isEmpty) return;
              final dio = ref.read(dioProvider);
              await dio.post('/api/v1/bookmarks/', data: {'title': titleCtrl.text.isEmpty ? urlCtrl.text : titleCtrl.text, 'url': urlCtrl.text});
              ref.invalidate(_bookmarksProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}

final _bookmarksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/bookmarks/', queryParameters: {'page_size': 100});
  return (r.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});
