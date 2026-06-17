import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/goal_provider.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});
  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(goalProvider.notifier).fetch();
    });
  }

  final _categories = {
    'academic': (const Color(0xFF6366F1), Icons.school_rounded),
    'career': (C.primary, Icons.work_rounded),
    'health': (C.success, Icons.favorite_rounded),
    'personal': (const Color(0xFF8B5CF6), Icons.person_rounded),
    'skill': (C.warning, Icons.star_rounded),
  };

  void _showAddGoal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'personal';
    String? targetDate;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Add Goal', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 18, color: C.text)),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Goal title *'), style: const TextStyle(fontFamily: 'Inter')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description (optional)'), style: const TextStyle(fontFamily: 'Inter')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.keys.map((k) => DropdownMenuItem(value: k, child: Text(k[0].toUpperCase() + k.substring(1), style: const TextStyle(fontFamily: 'Inter')))).toList(),
                onChanged: (v) => setS(() => category = v ?? 'personal'),
              )),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 5)));
                  if (d != null) setS(() => targetDate = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: C.textSub),
                    const SizedBox(width: 8),
                    Text(targetDate ?? 'Target date', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: C.textSub)),
                  ]),
                ),
              )),
            ]),
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
                  final ok = await ref.read(goalProvider.notifier).create(titleCtrl.text.trim(), category: category, description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), targetDate: targetDate);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Goal created!' : 'Failed'), backgroundColor: ok ? C.success : C.error));
                  }
                },
                child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add Goal', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
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
    final state = ref.watch(goalProvider);
    final grouped = <String, List<Goal>>{};
    for (final g in state.goals) {
      grouped.putIfAbsent(g.category, () => []).add(g);
    }

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Goals')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: C.error, size: 40),
                  const SizedBox(height: 12),
                  Text(state.error!, style: const TextStyle(color: C.textSub, fontFamily: 'Inter')),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => ref.read(goalProvider.notifier).fetch(), child: const Text('Retry')),
                ]))
              : state.goals.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: () => ref.read(goalProvider.notifier).fetch(),
                      child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
                        // Summary
                        Container(
                          padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                            _badge('${state.goals.where((g) => g.status == 'active').length}', 'Active', C.primary),
                            Container(width: 1, height: 30, color: C.border),
                            _badge('${state.goals.where((g) => g.status == 'completed').length}', 'Completed', C.success),
                            Container(width: 1, height: 30, color: C.border),
                            _badge('${state.goals.length}', 'Total', C.textSub),
                          ]),
                        ),
                        for (final cat in grouped.keys) ...[
                          _categoryHeader(cat),
                          ...grouped[cat]!.map((g) => _GoalCard(goal: g, catColor: _categories[g.category]?.$1 ?? C.primary, catIcon: _categories[g.category]?.$2 ?? Icons.flag_rounded, onDelete: () => ref.read(goalProvider.notifier).delete(g.id))),
                        ],
                      ]),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGoal,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Goal', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        backgroundColor: C.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _badge(String value, String label, Color color) => Column(children: [
    Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textSub)),
  ]);

  Widget _categoryHeader(String cat) {
    final info = _categories[cat];
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: (info?.$1 ?? C.primary).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(info?.$2 ?? Icons.flag_rounded, size: 14, color: info?.$1 ?? C.primary)),
        const SizedBox(width: 8),
        Text(cat[0].toUpperCase() + cat.substring(1), style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: info?.$1 ?? C.primary)),
      ]),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: C.primary.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.flag_rounded, color: C.primary, size: 40)),
    const SizedBox(height: 16),
    const Text('No goals yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.text, fontFamily: 'Inter')),
    const SizedBox(height: 8),
    const Text('Set goals to track your progress', style: TextStyle(fontSize: 13, color: C.textSub, fontFamily: 'Inter')),
  ]));
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final Color catColor;
  final IconData catIcon;
  final VoidCallback onDelete;

  const _GoalCard({required this.goal, required this.catColor, required this.catIcon, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final progress = goal.progressPercent.clamp(0.0, 100.0) / 100;
    final isCompleted = goal.status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: catColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(catIcon, color: catColor, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(goal.title, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: C.text)),
            if (goal.description?.isNotEmpty == true)
              Text(goal.description!, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.textSub), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: isCompleted ? C.success.withOpacity(0.1) : catColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(isCompleted ? 'Done' : 'Active', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: isCompleted ? C.success : catColor)),
          ),
          IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.delete_outline_rounded, color: C.error, size: 18), onPressed: onDelete),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, backgroundColor: C.border, valueColor: AlwaysStoppedAnimation<Color>(catColor), minHeight: 6),
          )),
          const SizedBox(width: 10),
          Text('${goal.progressPercent.toInt()}%', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: catColor)),
        ]),
        if (goal.targetDate != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 11, color: C.textMuted),
            const SizedBox(width: 4),
            Text(_fmtDate(goal.targetDate!), style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textMuted)),
          ]),
        ],
      ]),
    );
  }

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) { return d; }
  }
}
