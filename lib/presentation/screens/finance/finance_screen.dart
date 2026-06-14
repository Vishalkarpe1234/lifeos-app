import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/widgets/animations/shimmer_loading.dart';
import 'package:lifeos/presentation/widgets/common/glass_card.dart';
import 'package:lifeos/services/api/api_client.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Finance', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddExpense(context))],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Expenses'), Tab(text: 'Goals')],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          dividerColor: AppColors.darkBorder,
          labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        _FinanceOverview(),
        _ExpensesList(),
        _GoalsList(),
      ]),
    );
  }

  void _showAddExpense(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String type = 'expense';

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Add Transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: GestureDetector(onTap: () => setS(() => type = 'expense'), child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: type == 'expense' ? AppColors.error.withOpacity(0.2) : AppColors.darkCardElevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: type == 'expense' ? AppColors.error : AppColors.darkBorder)),
                child: Center(child: Text('Expense', style: TextStyle(color: type == 'expense' ? AppColors.error : AppColors.textMuted, fontFamily: 'Inter', fontWeight: FontWeight.w500))),
              ))),
              const SizedBox(width: 8),
              Expanded(child: GestureDetector(onTap: () => setS(() => type = 'income'), child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: type == 'income' ? AppColors.success.withOpacity(0.2) : AppColors.darkCardElevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: type == 'income' ? AppColors.success : AppColors.darkBorder)),
                child: Center(child: Text('Income', style: TextStyle(color: type == 'income' ? AppColors.success : AppColors.textMuted, fontFamily: 'Inter', fontWeight: FontWeight.w500))),
              ))),
            ]),
            const SizedBox(height: 12),
            TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            TextField(controller: amountCtrl, style: const TextStyle(color: Colors.white, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ '), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
                final dio = ref.read(dioProvider);
                await dio.post('/api/v1/finance/expenses', data: {
                  'title': titleCtrl.text, 'amount': double.parse(amountCtrl.text),
                  'type': type, 'date': DateTime.now().toIso8601String().split('T')[0],
                });
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(_financeStatsProvider);
                ref.invalidate(_expensesProvider);
              },
              child: const Text('Add', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FinanceOverview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_financeStatsProvider);
    return async.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GradientCard(
            colors: [AppColors.primary, AppColors.primaryDark],
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Balance', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontFamily: 'Inter')),
              const SizedBox(height: 8),
              Text('₹${stats['balance']?.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, fontFamily: 'Inter', letterSpacing: -1)),
              const SizedBox(height: 16),
              Row(children: [
                _BalanceStat('Income', '₹${stats['income']?.toStringAsFixed(0)}', AppColors.success),
                const SizedBox(width: 24),
                _BalanceStat('Expenses', '₹${stats['expense']?.toStringAsFixed(0)}', AppColors.error),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          if ((stats['by_category'] as List?)?.isNotEmpty ?? false) ...[
            const Text('By Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
            const SizedBox(height: 12),
            ...(stats['by_category'] as List).map((c) {
              final cat = c as Map<String, dynamic>;
              final total = cat['total'] as double? ?? 0;
              final expTotal = (stats['expense'] as double? ?? 1);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkBorder, width: 0.5)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(cat['category'] ?? 'Uncategorized', style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: expTotal > 0 ? (total / expTotal) : 0, backgroundColor: AppColors.darkBorder, color: AppColors.primary, minHeight: 4)),
                  ])),
                  const SizedBox(width: 12),
                  Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                ]),
              );
            }),
          ],
        ]),
      ),
      loading: () => const ShimmerLoading(count: 4),
      error: (e, _) => Center(child: Text(e.toString(), style: TextStyle(color: AppColors.error))),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _BalanceStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 4), Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontFamily: 'Inter'))]),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
  ]);
}

class _ExpensesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_expensesProvider);
    return async.when(
      data: (items) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final e = items[i];
          final isExpense = e['type'] == 'expense';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkBorder, width: 0.5)),
            child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: (isExpense ? AppColors.error : AppColors.success).withOpacity(0.12), shape: BoxShape.circle), child: Icon(isExpense ? Icons.arrow_downward : Icons.arrow_upward, color: isExpense ? AppColors.error : AppColors.success, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Inter')),
                Text(e['date']?.toString() ?? '', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Inter')),
              ])),
              Text('${isExpense ? '-' : '+'}₹${e['amount']}', style: TextStyle(color: isExpense ? AppColors.error : AppColors.success, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
            ]),
          ).animate(delay: (30 * i).ms).fadeIn();
        },
      ),
      loading: () => const ShimmerLoading(count: 8, height: 60),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}

class _GoalsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_goalsProvider);
    return async.when(
      data: (goals) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: goals.length,
        itemBuilder: (_, i) {
          final g = goals[i];
          final current = (g['current_value'] as num?)?.toDouble() ?? 0;
          final target = (g['target_value'] as num?)?.toDouble() ?? 1;
          final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
          return GlassCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(g['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 14))),
                if (g['is_completed'] == true) const Icon(Icons.check_circle, color: AppColors.success, size: 18),
              ]),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: progress, backgroundColor: AppColors.darkBorder, color: AppColors.primary, minHeight: 6)),
              const SizedBox(height: 6),
              Text('$current / $target ${g['unit'] ?? ''}', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Inter')),
            ]),
          );
        },
      ),
      loading: () => const ShimmerLoading(count: 4),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}

final _financeStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/finance/stats');
  return Map<String, dynamic>.from(r.data as Map);
});

final _expensesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/finance/expenses', queryParameters: {'page_size': 100});
  return (r.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

final _goalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/finance/goals');
  return (r.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final EdgeInsetsGeometry? padding;
  const GradientCard({super.key, required this.child, this.colors, this.padding});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(colors: colors ?? [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
      boxShadow: [BoxShadow(color: (colors?.first ?? AppColors.primary).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
    ),
    child: child,
  );
}
