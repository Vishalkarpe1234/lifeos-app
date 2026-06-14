import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/research_provider.dart';
import 'package:lifeos/presentation/widgets/animations/shimmer_loading.dart';
import 'package:lifeos/presentation/widgets/common/glass_card.dart';

class ResearchScreen extends ConsumerStatefulWidget {
  const ResearchScreen({super.key});

  @override
  ConsumerState<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends ConsumerState<ResearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(researchStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Research Center', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.go('/research/new')),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Publications'), Tab(text: 'Conferences'), Tab(text: 'Stats')],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          dividerColor: AppColors.darkBorder,
          labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PublicationsList(),
          _ConferencesList(),
          _StatsView(),
        ],
      ),
    );
  }
}

class _PublicationsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(publicationsProvider);
    return async.when(
      data: (pubs) {
        if (pubs.isEmpty) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.article_outlined, color: AppColors.textMuted, size: 60),
              const SizedBox(height: 16),
              Text('No publications yet', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => context.go('/research/new'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Publication', style: TextStyle(fontFamily: 'Inter')),
              ),
            ],
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pubs.length,
          itemBuilder: (_, i) => _PublicationCard(pub: pubs[i]).animate(delay: (40 * i).ms).fadeIn().slideX(begin: 0.05),
        );
      },
      loading: () => const ShimmerLoading(count: 6),
      error: (e, _) => Center(child: Text(e.toString(), style: TextStyle(color: AppColors.error))),
    );
  }
}

class _PublicationCard extends ConsumerWidget {
  final Map<String, dynamic> pub;
  const _PublicationCard({required this.pub});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIndexed = pub['is_indexed'] as bool? ?? false;
    final isFeatured = pub['is_featured'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isFeatured ? AppColors.primary.withOpacity(0.4) : AppColors.darkBorder, width: isFeatured ? 1 : 0.5),
        gradient: isFeatured ? LinearGradient(colors: [AppColors.darkCard, AppColors.primary.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(pub['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter', height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
              ),
              if (isFeatured) const Icon(Icons.star, color: AppColors.warning, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          if (pub['journal_name'] != null || pub['conference_name'] != null)
            Text(pub['journal_name'] ?? pub['conference_name'] ?? '', style: TextStyle(color: AppColors.primary, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              if (pub['year'] != null) _Tag(pub['year'].toString(), AppColors.textMuted),
              const SizedBox(width: 6),
              if (isIndexed) _Tag(pub['index_type'] ?? 'Indexed', AppColors.success),
              const SizedBox(width: 6),
              if (pub['doi'] != null) _Tag('DOI', AppColors.accent),
              const SizedBox(width: 6),
              if ((pub['citation_count'] as int? ?? 0) > 0) _Tag('${pub['citation_count']} citations', AppColors.warning),
              const Spacer(),
              GestureDetector(
                onTap: () => ref.read(publicationsProvider.notifier).delete(pub['id']),
                child: Icon(Icons.delete_outline, color: AppColors.textMuted, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
    );
  }
}

class _ConferencesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(conferencesProvider);
    return async.when(
      data: (confs) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: confs.length,
        itemBuilder: (_, i) {
          final c = confs[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.darkBorder, width: 0.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 14)),
                const SizedBox(height: 6),
                if (c['paper_title'] != null) Text(c['paper_title'].toString(), style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Inter')),
                const SizedBox(height: 6),
                Row(children: [
                  if (c['start_date'] != null) _Tag(c['start_date'].toString(), AppColors.textMuted),
                  const SizedBox(width: 6),
                  _Tag(c['status'] ?? 'presented', AppColors.success),
                  const SizedBox(width: 6),
                  _Tag(c['presentation_type'] ?? 'oral', AppColors.primary),
                ]),
              ],
            ),
          ).animate(delay: (40 * i).ms).fadeIn();
        },
      ),
      loading: () => const ShimmerLoading(count: 5),
      error: (e, _) => Center(child: Text(e.toString(), style: TextStyle(color: AppColors.error))),
    );
  }
}

class _StatsView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(researchStatsProvider);
    return async.when(
      data: (stats) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatRow('Total Publications', '${stats['total_publications']}', Icons.article_outlined, AppColors.primary),
            _StatRow('Total Conferences', '${stats['total_conferences']}', Icons.people_outline, AppColors.accent),
            _StatRow('Total Citations', '${stats['total_citations']}', Icons.format_quote_outlined, AppColors.warning),
            _StatRow('Indexed Publications', '${stats['indexed_publications']}', Icons.verified_outlined, AppColors.success),
          ],
        ),
      ),
      loading: () => const ShimmerLoading(count: 4, height: 70),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatRow(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Inter', letterSpacing: -1)),
            Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Inter')),
          ]),
        ],
      ),
    );
  }
}
