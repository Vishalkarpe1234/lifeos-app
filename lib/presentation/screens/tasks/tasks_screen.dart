import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/tasks_provider.dart';
import 'package:lifeos/presentation/widgets/animations/shimmer_loading.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Tasks', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilter),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Today'),
            Tab(text: 'Pending'),
            Tab(text: 'Done'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
          dividerColor: AppColors.darkBorder,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TaskList(filter: null),
          _TaskList(filter: 'today'),
          _TaskList(filter: 'pending'),
          _TaskList(filter: 'done'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTask(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Task', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
            const SizedBox(height: 16),
            const Text('Priority', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Inter')),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['All', 'High', 'Medium', 'Low'].map((p) => FilterChip(
                label: Text(p, style: const TextStyle(fontFamily: 'Inter')),
                selected: false,
                onSelected: (_) {},
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTask(BuildContext context) {
    final titleCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('New Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
              decoration: const InputDecoration(labelText: 'Task title', hintText: 'What needs to be done?'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                await ref.read(tasksProvider.notifier).createTask(title: titleCtrl.text);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add Task', style: TextStyle(fontFamily: 'Inter')),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  final String? filter;
  const _TaskList({this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = filter == 'today'
        ? ref.watch(tasksProvider)
        : filter == 'pending'
            ? ref.watch(pendingTasksProvider)
            : filter == 'done'
                ? ref.watch(completedTasksProvider)
                : ref.watch(tasksProvider);

    return async.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, color: AppColors.textMuted, size: 56),
                const SizedBox(height: 16),
                Text('No tasks here', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (_, i) => _TaskTile(task: tasks[i], index: i).animate(delay: (30 * i).ms).fadeIn().slideX(begin: 0.05),
        );
      },
      loading: () => const ShimmerLoading(count: 8, height: 70),
      error: (e, _) => Center(child: Text(e.toString(), style: TextStyle(color: AppColors.error, fontFamily: 'Inter'))),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  final Map<String, dynamic> task;
  final int index;
  const _TaskTile({required this.task, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = task['is_completed'] as bool? ?? false;
    final priority = task['priority'] as String? ?? 'medium';
    final priorityColor = priority == 'high' ? AppColors.priorityHigh : priority == 'low' ? AppColors.priorityLow : AppColors.priorityMedium;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: GestureDetector(
          onTap: () => ref.read(tasksProvider.notifier).toggleComplete(task['id']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? AppColors.primary : Colors.transparent,
              border: Border.all(color: isCompleted ? AppColors.primary : AppColors.darkBorder, width: 1.5),
            ),
            child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
          ),
        ),
        title: Text(
          task['title'] ?? '',
          style: TextStyle(
            color: isCompleted ? AppColors.textMuted : Colors.white,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: task['due_date'] != null
            ? Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(task['due_date'].toString(), style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Inter')),
                ],
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: priorityColor)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => ref.read(tasksProvider.notifier).deleteTask(task['id']),
              child: Icon(Icons.delete_outline, color: AppColors.textMuted, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
