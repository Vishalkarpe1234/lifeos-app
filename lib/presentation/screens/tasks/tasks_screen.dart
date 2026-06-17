import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/task_provider.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});
  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskProvider.notifier).fetch();
    });
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'high': return C.error;
      case 'medium': return C.warning;
      default: return C.success;
    }
  }

  List<Task> _filtered(List<Task> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_filter) {
      case 'today':
        return all.where((t) {
          if (t.dueDate == null) return false;
          try {
            final d = DateTime.parse(t.dueDate!);
            return d.year == today.year && d.month == today.month && d.day == today.day;
          } catch (_) { return false; }
        }).toList();
      case 'overdue':
        return all.where((t) {
          if (t.isCompleted || t.dueDate == null) return false;
          try {
            final d = DateTime.parse(t.dueDate!);
            return d.isBefore(today);
          } catch (_) { return false; }
        }).toList();
      default:
        return all;
    }
  }

  void _showAddTask() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'medium';
    String? dueDate;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Add Task', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 18, color: C.text)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Task title *', hintText: 'What needs to be done?'),
              style: const TextStyle(fontFamily: 'Inter'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              style: const TextStyle(fontFamily: 'Inter'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Priority', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.textSub)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  items: [
                    DropdownMenuItem(value: 'high', child: Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.error, shape: BoxShape.circle)), const SizedBox(width: 8), const Text('High', style: TextStyle(fontFamily: 'Inter'))])),
                    DropdownMenuItem(value: 'medium', child: Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.warning, shape: BoxShape.circle)), const SizedBox(width: 8), const Text('Medium', style: TextStyle(fontFamily: 'Inter'))])),
                    DropdownMenuItem(value: 'low', child: Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.success, shape: BoxShape.circle)), const SizedBox(width: 8), const Text('Low', style: TextStyle(fontFamily: 'Inter'))])),
                  ],
                  onChanged: (v) => setS(() => priority = v ?? 'medium'),
                ),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Due Date', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.textSub)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (d != null) setS(() => dueDate = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: C.textSub),
                      const SizedBox(width: 8),
                      Text(dueDate ?? 'Pick date', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: C.textSub)),
                    ]),
                  ),
                ),
              ])),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saving ? null : () async {
                  if (titleCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Title is required'), backgroundColor: C.error));
                    return;
                  }
                  setS(() => saving = true);
                  final ok = await ref.read(taskProvider.notifier).create(
                    titleCtrl.text.trim(),
                    priority: priority,
                    dueDate: dueDate,
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok ? 'Task created!' : 'Failed to create task'),
                      backgroundColor: ok ? C.success : C.error,
                    ));
                  }
                },
                child: saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add Task', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
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
    final state = ref.watch(taskProvider);
    final all = _filtered(state.tasks);
    final pending = all.where((t) => !t.isCompleted).toList();
    final completed = all.where((t) => t.isCompleted).toList();

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddTask,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: ['all', 'today', 'overdue'].map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f[0].toUpperCase() + f.substring(1), style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 12, color: _filter == f ? Colors.white : C.textSub)),
                  selected: _filter == f,
                  selectedColor: C.primary,
                  backgroundColor: Colors.white,
                  onSelected: (_) => setState(() => _filter = f),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              )).toList()),
            ),
          ),
        ),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: C.error, size: 40),
                  const SizedBox(height: 12),
                  Text(state.error!, textAlign: TextAlign.center, style: const TextStyle(color: C.textSub, fontFamily: 'Inter')),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => ref.read(taskProvider.notifier).fetch(), child: const Text('Retry')),
                ]))
              : all.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: () => ref.read(taskProvider.notifier).fetch(),
                      child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
                        // Stats row
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                            _statBadge('${state.tasks.where((t) => t.isCompleted).length}', 'Completed', C.success),
                            Container(width: 1, height: 32, color: C.border),
                            _statBadge('${state.tasks.where((t) => !t.isCompleted).length}', 'Pending', C.warning),
                            Container(width: 1, height: 32, color: C.border),
                            _statBadge('${state.tasks.length}', 'Total', C.primary),
                          ]),
                        ),

                        if (pending.isNotEmpty) ...[
                          _sectionHeader('PENDING (${pending.length})'),
                          ...pending.map((t) => _TaskCard(task: t,
                            onToggle: () => ref.read(taskProvider.notifier).toggleComplete(t.id),
                            onDelete: () => ref.read(taskProvider.notifier).delete(t.id),
                            priorityColor: _priorityColor(t.priority),
                          )),
                        ],

                        if (completed.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _sectionHeader('COMPLETED (${completed.length})'),
                          ...completed.map((t) => _TaskCard(task: t,
                            onToggle: () => ref.read(taskProvider.notifier).toggleComplete(t.id),
                            onDelete: () => ref.read(taskProvider.notifier).delete(t.id),
                            priorityColor: _priorityColor(t.priority),
                          )),
                        ],
                      ]),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTask,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        backgroundColor: C.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _sectionHeader(String t) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8, left: 2),
    child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.textMuted, fontFamily: 'Inter', letterSpacing: 0.5)),
  );

  Widget _statBadge(String value, String label, Color color) => Column(children: [
    Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textSub)),
  ]);

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: C.primary.withOpacity(0.1), shape: BoxShape.circle),
      child: const Icon(Icons.task_alt_rounded, color: C.primary, size: 40)),
    const SizedBox(height: 16),
    const Text('No tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.text, fontFamily: 'Inter')),
    const SizedBox(height: 8),
    const Text('Tap + to add your first task', style: TextStyle(fontSize: 13, color: C.textSub, fontFamily: 'Inter')),
  ]));
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Color priorityColor;

  const _TaskCard({required this.task, required this.onToggle, required this.onDelete, required this.priorityColor});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('task_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: C.error, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: task.isCompleted ? C.border : priorityColor.withOpacity(0.2)),
        ),
        child: Row(children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: task.isCompleted ? C.success : C.border, width: 2),
                color: task.isCompleted ? C.success : Colors.transparent,
              ),
              child: task.isCompleted ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 6, height: 6, decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              task.title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: task.isCompleted ? C.textMuted : C.text,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(task.description!, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.textSub), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
            if (task.dueDate != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 11, color: C.textMuted),
                const SizedBox(width: 3),
                Text(_fmtDate(task.dueDate!), style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textMuted)),
              ]),
            ],
          ])),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.delete_outline_rounded, color: C.error, size: 18),
            onPressed: onDelete,
          ),
        ]),
      ),
    );
  }

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) { return d; }
  }
}
