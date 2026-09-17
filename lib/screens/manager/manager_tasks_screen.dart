import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/tasks_provider.dart';
import '../common/empty_state.dart';

class ManagerTasksScreen extends StatefulWidget {
  const ManagerTasksScreen({super.key});

  @override
  State<ManagerTasksScreen> createState() => _ManagerTasksScreenState();
}

class _ManagerTasksScreenState extends State<ManagerTasksScreen> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksProvider>().fetchTasks();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleAddTask() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final tasksProv = context.read<TasksProvider>();
    final success = await tasksProv.addTask(text);
    if (success) {
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksProv = context.watch<TasksProvider>();
    final tasks = tasksProv.tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operational To-Dos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => tasksProv.fetchTasks(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick add task input
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Add a new team task...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (_) => _handleAddTask(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleAddTask,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.add_rounded, size: 24),
                ),
              ],
            ),
          ),

          // Task List
          Expanded(
            child: tasksProv.isLoading && tasks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : tasks.isEmpty
                    ? const EmptyState(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'All caught up!',
                        message: 'No operational tasks currently pending.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: tasks.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final task = tasks[i];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ListTile(
                              leading: Checkbox(
                                value: task.done,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) {
                                  if (val != null) {
                                    tasksProv.toggleTask(task.id, val);
                                  }
                                },
                              ),
                              title: Text(
                                task.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: task.done ? TextDecoration.lineThrough : null,
                                  color: task.done ? AppColors.textMuted : AppColors.textPrimary,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.textMuted),
                                onPressed: () => tasksProv.deleteTask(task.id),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
