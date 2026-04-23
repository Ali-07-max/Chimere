import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task_item.dart';
import '../../providers/task_provider.dart';
import '../../widgets/section_card.dart';
import '../../widgets/task_tile.dart';
import 'add_edit_task_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool showCompleted = false;
  TaskCategory? categoryFilter;

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final base = showCompleted ? provider.completedTasks : provider.activeTasks;
        final filtered = categoryFilter == null
            ? base
            : base.where((task) => task.category == categoryFilter).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tasks'),
            actions: [
              IconButton(
                onPressed: () async {
                 final created = await Navigator.of(context).push<bool>(
  MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
);

if (created == true && context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Task saved successfully'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
                },
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
            final created = await Navigator.of(context).push<bool>(
  MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
);

if (created == true && context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Task saved successfully'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
            },
            label: const Text('Add task'),
            icon: const Icon(Icons.add),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    selected: !showCompleted,
                    label: const Text('Active'),
                    onSelected: (_) => setState(() => showCompleted = false),
                  ),
                  FilterChip(
                    selected: showCompleted,
                    label: const Text('Completed'),
                    onSelected: (_) => setState(() => showCompleted = true),
                  ),
                  ...TaskCategory.values.map(
                    (category) => FilterChip(
                      selected: categoryFilter == category,
                      label: Text(category.label),
                      onSelected: (value) {
                        setState(() {
                          categoryFilter = value ? category : null;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SectionCard(
                title: showCompleted ? 'Completed tasks' : 'Open tasks',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No tasks match this view yet.'),
                      )
                    : Column(
                        children: filtered.map((task) => TaskTile(task: task, showActions: true)).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
