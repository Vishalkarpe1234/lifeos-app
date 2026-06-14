import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';
import 'package:intl/intl.dart';

final _healthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final res = await dio.get('/api/v1/health/today');
    return Map<String, dynamic>.from(res.data as Map);
  } catch (_) { return {}; }
});

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  @override
  Widget build(BuildContext context) {
    final healthAsync = ref.watch(_healthProvider);
    return Scaffold(
      backgroundColor: AppStyle.bg(context),
      appBar: AppBar(
        backgroundColor: AppStyle.surface(context),
        elevation: 0,
        title: Text('Health', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, color: AppStyle.text(context))),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () => _showLogHealth(context),
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(color: AppStyle.border(context), height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: healthAsync.when(
          data: (data) => _buildContent(context, data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildContent(context, {}),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTodayCard(context, data),
        const SizedBox(height: 20),
        Text("Today's Metrics", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppStyle.text(context), fontFamily: 'Inter')),
        const SizedBox(height: 12),
        _buildMetricsGrid(context, data),
        const SizedBox(height: 20),
        _buildMoodSelector(context, data),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildTodayCard(BuildContext context, Map<String, dynamic> data) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFEC4899)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Text('Health Today', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(DateFormat('MMM d').format(now), style: TextStyle(color: Colors.white.withOpacity(0.8), fontFamily: 'Inter', fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Stay healthy, stay productive!', style: TextStyle(color: Colors.white.withOpacity(0.9), fontFamily: 'Inter', fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, Map<String, dynamic> data) {
    final metrics = [
      _Metric('Water', '${data['water_ml'] ?? 0} ml', Icons.water_drop_rounded, const Color(0xFF3B82F6), data['water_ml'] != null ? (data['water_ml'] as num) / 2500 : 0),
      _Metric('Sleep', '${data['sleep_hours'] ?? 0}h', Icons.bedtime_rounded, const Color(0xFF8B5CF6), data['sleep_hours'] != null ? (data['sleep_hours'] as num) / 8 : 0),
      _Metric('Steps', '${data['steps'] ?? 0}', Icons.directions_walk_rounded, AppColors.success, data['steps'] != null ? (data['steps'] as num) / 10000 : 0),
      _Metric('Calories', '${data['calories'] ?? 0}', Icons.local_fire_department_rounded, AppColors.warning, data['calories'] != null ? (data['calories'] as num) / 2000 : 0),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.3),
      itemCount: metrics.length,
      itemBuilder: (_, i) => _MetricCard(metric: metrics[i]),
    );
  }

  Widget _buildMoodSelector(BuildContext context, Map<String, dynamic> data) {
    final moods = ['😞', '😕', '😐', '😊', '😄'];
    final currentMood = (data['mood'] as int? ?? 3) - 1;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyle.cardDecor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Mood", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppStyle.text(context), fontFamily: 'Inter')),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: moods.asMap().entries.map((e) => GestureDetector(
              onTap: () => _logMood(e.key + 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: e.key == currentMood ? AppColors.primary.withOpacity(0.15) : AppStyle.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: e.key == currentMood ? AppColors.primary : AppStyle.border(context), width: e.key == currentMood ? 2 : 0.5),
                ),
                child: Center(child: Text(e.value, style: const TextStyle(fontSize: 26))),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _logMood(int mood) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/v1/health', data: {'mood': mood, 'date': DateFormat('yyyy-MM-dd').format(DateTime.now())});
      ref.invalidate(_healthProvider);
    } catch (_) {}
  }

  void _showLogHealth(BuildContext context) {
    final waterCtrl = TextEditingController();
    final sleepCtrl = TextEditingController();
    final stepsCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppStyle.card(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log Health Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppStyle.text(context), fontFamily: 'Inter')),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _quickField(ctx, waterCtrl, 'Water (ml)', TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _quickField(ctx, sleepCtrl, 'Sleep (h)', TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _quickField(ctx, stepsCtrl, 'Steps', TextInputType.number)),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final dio = ref.read(dioProvider);
                    await dio.post('/api/v1/health', data: {
                      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      if (waterCtrl.text.isNotEmpty) 'water_ml': int.tryParse(waterCtrl.text),
                      if (sleepCtrl.text.isNotEmpty) 'sleep_hours': double.tryParse(sleepCtrl.text),
                      if (stepsCtrl.text.isNotEmpty) 'steps': int.tryParse(stepsCtrl.text),
                    });
                    ref.invalidate(_healthProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (_) {}
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: const Text('Save', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _quickField(BuildContext context, TextEditingController ctrl, String label, TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: TextStyle(color: AppStyle.text(context), fontFamily: 'Inter', fontSize: 14),
      decoration: InputDecoration(labelText: label, filled: true, fillColor: AppStyle.surface(context), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppStyle.border(context))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppStyle.border(context)))),
    );
  }
}

class _Metric { final String label, value; final IconData icon; final Color color; final double progress;
  const _Metric(this.label, this.value, this.icon, this.color, this.progress); }

class _MetricCard extends StatelessWidget {
  final _Metric metric;
  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyle.cardDecor(context, accent: metric.color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: metric.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(metric.icon, color: metric.color, size: 18)),
              const Spacer(),
              Text('${(metric.progress.clamp(0, 1) * 100).toInt()}%', style: TextStyle(fontSize: 11, color: AppStyle.textMuted(context), fontFamily: 'Inter')),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metric.value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppStyle.text(context), fontFamily: 'Inter')),
              Text(metric.label, style: TextStyle(fontSize: 12, color: AppStyle.textSub(context), fontFamily: 'Inter')),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: metric.progress.clamp(0, 1), backgroundColor: metric.color.withOpacity(0.12), valueColor: AlwaysStoppedAnimation<Color>(metric.color), minHeight: 4)),
            ],
          ),
        ],
      ),
    );
  }
}
