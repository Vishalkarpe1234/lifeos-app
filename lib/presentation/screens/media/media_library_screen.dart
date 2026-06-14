import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/widgets/animations/shimmer_loading.dart';
import 'package:lifeos/services/api/api_client.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MediaLibraryScreen extends ConsumerStatefulWidget {
  const MediaLibraryScreen({super.key});

  @override
  ConsumerState<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends ConsumerState<MediaLibraryScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_mediaProvider(_filter));

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Media Library', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            color: AppColors.darkCard,
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (_) => ['all', 'image', 'video', 'pdf', 'document'].map((t) => PopupMenuItem(value: t, child: Text(t.toUpperCase(), style: const TextStyle(color: Colors.white, fontFamily: 'Inter')))).toList(),
          ),
        ],
      ),
      body: async.when(
        data: (files) => files.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.perm_media_outlined, size: 60, color: AppColors.textMuted), const SizedBox(height: 16), Text('No files', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter'))]))
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
                itemCount: files.length,
                itemBuilder: (_, i) {
                  final f = files[i];
                  final isImage = f['file_type'] == 'image';
                  return Container(
                    decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(10)),
                    child: isImage && f['file_url'] != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: f['file_url'].toString(), fit: BoxFit.cover, placeholder: (_, __) => Container(color: AppColors.darkCard)))
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(_fileIcon(f['file_type'].toString()), color: AppColors.primary, size: 28),
                            const SizedBox(height: 4),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(f['original_filename']?.toString() ?? '', style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontFamily: 'Inter'), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                          ]),
                  );
                },
              ),
        loading: () => GridView.count(crossAxisCount: 3, padding: const EdgeInsets.all(12), mainAxisSpacing: 8, crossAxisSpacing: 8, children: List.generate(9, (_) => Container(decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(10))))),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  IconData _fileIcon(String type) {
    switch (type) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'video': return Icons.videocam_outlined;
      case 'audio': return Icons.audiotrack_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }
}

final _mediaProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, filter) async {
  final dio = ref.watch(dioProvider);
  final params = <String, dynamic>{'page_size': 100};
  if (filter != 'all') params['file_type'] = filter;
  final r = await dio.get('/api/v1/media/', queryParameters: params);
  return (r.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});
