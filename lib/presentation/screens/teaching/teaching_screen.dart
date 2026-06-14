import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/widgets/animations/shimmer_loading.dart';
import 'package:lifeos/services/api/api_client.dart';

class TeachingScreen extends ConsumerWidget {
  const TeachingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_subjectsProvider);
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Teaching Center', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)), actions: [IconButton(icon: const Icon(Icons.add), onPressed: () {})]),
      body: async.when(
        data: (subjects) => subjects.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.school_outlined, size: 60, color: AppColors.textMuted), const SizedBox(height: 16), Text('No subjects yet', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter'))])) :
          ListView.builder(padding: const EdgeInsets.all(16), itemCount: subjects.length, itemBuilder: (_, i) {
            final s = subjects[i];
            return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.darkBorder, width: 0.5)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 15)), if (s['code'] != null) Text(s['code'].toString(), style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Inter'))]));
          }),
        loading: () => const ShimmerLoading(count: 5),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}
final _subjectsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/teaching/subjects');
  return (r.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});
