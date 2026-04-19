import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/todo_model.dart';
import '../../provider/todo_provider.dart';
import '../widgets/todo_list_tile.dart';
import '../widgets/add_todo_dialog.dart';
import '../../../../shared/theme.dart';
import '../../../settings/settings_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final incomplete = ref.watch(incompleteTodosProvider);
    final pending = ref.watch(pendingTodosProvider);
    final inProgress = ref.watch(inProgressTodosProvider);
    final completed = ref.watch(completedTodosProvider);
    final deleted = ref.watch(deletedTodosProvider);
    final allTodos = ref.watch(todoListProvider);
    final sortMode = ref.watch(sortModeProvider);

    final overdueCount = incomplete.where((t) => t.isOverdue).length;
    final todayCount = incomplete.where((t) {
      final now = DateTime.now();
      return t.startTime != null &&
          t.startTime!.year == now.year &&
          t.startTime!.month == now.month &&
          t.startTime!.day == now.day;
    }).length;
    final activeCount = allTodos.where((t) => !t.isDeleted).length;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          _buildTopBar(),
          _buildStatsRow(
            total: activeCount,
            pending: pending.length,
            inProgress: inProgress.length,
            overdue: overdueCount,
            today: todayCount,
            done: completed.length,
            sortMode: sortMode,
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: [
                _buildTab(Icons.inbox_rounded, '待办', pending.length),
                _buildTab(Icons.play_circle_outline_rounded, '进行中', inProgress.length),
                _buildTab(Icons.task_alt_rounded, '已完成', completed.length),
                _buildTab(Icons.delete_outline_rounded, '已删除', deleted.length),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodoList(pending, emptyIcon: Icons.inbox_rounded, emptyText: '暂无待办事项', emptyHint: '点击右下角按钮创建新待办'),
                _buildTodoList(inProgress, emptyIcon: Icons.timer_outlined, emptyText: '暂无进行中事项', emptyHint: '在待办列表中点击开始处理按钮'),
                _buildCompletedList(completed),
                _buildDeletedList(deleted),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTodoDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('新建待办'),
      ),
    );
  }

  Tab _buildTab(IconData icon, String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 5),
          Text('$label ($count)'),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Todo Desktop',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          _buildTopBarAction(
            icon: Icons.add_rounded,
            label: '新建',
            onTap: () => _showAddTodoDialog(context),
          ),
          const SizedBox(width: 8),
          _buildTopBarIconAction(
            icon: Icons.settings_rounded,
            tooltip: '设置',
            onTap: () => _showSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarIconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDim,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildTopBarAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primarySurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow({
    required int total,
    required int pending,
    required int inProgress,
    required int overdue,
    required int today,
    required int done,
    required SortMode sortMode,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 12),
      color: Colors.white,
      child: Row(
        children: [
          _buildStatChip('全部', total, AppTheme.textSecondary),
          const SizedBox(width: 8),
          _buildStatChip('待办', pending, AppTheme.primary),
          const SizedBox(width: 8),
          _buildStatChip('进行中', inProgress, AppTheme.warning),
          const SizedBox(width: 8),
          if (overdue > 0) ...[
            _buildStatChip('逾期', overdue, AppTheme.danger),
            const SizedBox(width: 8),
          ],
          _buildStatChip('今日', today, AppTheme.catStudy),
          const SizedBox(width: 8),
          _buildStatChip('完成', done, AppTheme.success),
          const Spacer(),
          _buildSortToggle(sortMode),
        ],
      ),
    );
  }

  Widget _buildSortToggle(SortMode sortMode) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDim,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSortButton(
            icon: Icons.schedule_rounded,
            label: '时间',
            isActive: sortMode == SortMode.byTime,
            onTap: () => ref.read(sortModeProvider.notifier).state = SortMode.byTime,
          ),
          const SizedBox(width: 2),
          _buildSortButton(
            icon: Icons.flag_rounded,
            label: '优先级',
            isActive: sortMode == SortMode.byPriority,
            onTap: () => ref.read(sortModeProvider.notifier).state = SortMode.byPriority,
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? AppTheme.shadowSm : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isActive ? AppTheme.primary : AppTheme.textTertiary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.primary : AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList(List<Todo> todos, {
    required IconData emptyIcon,
    required String emptyText,
    required String emptyHint,
  }) {
    if (todos.isEmpty) {
      return _buildEmptyState(emptyIcon, emptyText, emptyHint);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TodoListTile(
            todo: todo,
            onToggle: () =>
                ref.read(todoListProvider.notifier).toggleComplete(todo.id),
            onDelete: () =>
                ref.read(todoListProvider.notifier).softDeleteTodo(todo.id),
            onEdit: () => _showEditDialog(context, todo),
            onToggleStarted: () =>
                ref.read(todoListProvider.notifier).toggleStarted(todo.id),
          ),
        );
      },
    );
  }

  Widget _buildCompletedList(List<Todo> todos) {
    if (todos.isEmpty) {
      return _buildEmptyState(Icons.task_alt_rounded, '暂无已完成事项', '完成的待办会出现在这里');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TodoListTile(
            todo: todo,
            onToggle: () =>
                ref.read(todoListProvider.notifier).toggleComplete(todo.id),
            onDelete: () =>
                ref.read(todoListProvider.notifier).softDeleteTodo(todo.id),
            onEdit: () => _showEditDialog(context, todo),
          ),
        );
      },
    );
  }

  Widget _buildDeletedList(List<Todo> todos) {
    if (todos.isEmpty) {
      return _buildEmptyState(Icons.delete_outline_rounded, '回收站为空', '删除的待办会出现在这里');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildDeletedTile(todo),
        );
      },
    );
  }

  Widget _buildDeletedTile(Todo todo) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textTertiary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${todo.categoryLabel} · ${todo.priorityLabel}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
          Tooltip(
            message: '恢复',
            child: InkWell(
              onTap: () => ref.read(todoListProvider.notifier).restoreTodo(todo.id),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: AppTheme.success.withOpacity(0.08),
                ),
                child: const Icon(Icons.restore_rounded, size: 18, color: AppTheme.success),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: '永久删除',
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('永久删除'),
                    content: Text('确认永久删除「${todo.title}」？此操作不可恢复。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(todoListProvider.notifier).deleteTodo(todo.id);
                        },
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                );
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: AppTheme.danger.withOpacity(0.08),
                ),
                child: const Icon(Icons.delete_forever_rounded, size: 18, color: AppTheme.danger),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String text, String hint) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDim,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 40, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    final storage = ref.read(storageServiceProvider);
    final scheduler = ref.read(schedulerServiceProvider);
    showDialog(
      context: context,
      builder: (_) => SettingsDialog(
        storage: storage,
        scheduler: scheduler,
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AddTodoDialog(),
    );
  }

  void _showEditDialog(BuildContext context, Todo todo) {
    showDialog(
      context: context,
      builder: (_) => AddTodoDialog(editTodo: todo),
    );
  }
}