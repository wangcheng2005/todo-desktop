import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/todo_model.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/scheduler/scheduler_service.dart';

const _uuid = Uuid();

// Sort mode
enum SortMode { byTime, byPriority }

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden at startup');
});

final schedulerServiceProvider = Provider<SchedulerService>((ref) {
  throw UnimplementedError('SchedulerService must be overridden at startup');
});

/// Current sort mode
final sortModeProvider = StateProvider<SortMode>((ref) => SortMode.byTime);

/// Data retention days — completed/deleted items older than this are hidden
final dataRetentionDaysProvider = StateProvider<int>((ref) => 30);

final todoListProvider =
    StateNotifierProvider<TodoListNotifier, List<Todo>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return TodoListNotifier(storage);
});

List<Todo> _applySort(List<Todo> list, SortMode sortMode) {
  list.sort((a, b) {
    if (sortMode == SortMode.byPriority) {
      final pa = a.priority.index;
      final pb = b.priority.index;
      if (pa != pb) return pb.compareTo(pa); // high first
      final sa = a.startTime ?? DateTime(2099);
      final sb = b.startTime ?? DateTime(2099);
      return sa.compareTo(sb);
    } else {
      // by time
      final sa = a.startTime ?? a.createdAt;
      final sb = b.startTime ?? b.createdAt;
      return sa.compareTo(sb);
    }
  });
  return list;
}

/// Tab 1: 未开始 — start time is in the future, not manually started, not completed, not deleted
final notStartedTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final sort = ref.watch(sortModeProvider);
  final now = DateTime.now();
  final list = todos
      .where((t) =>
          !t.isCompleted &&
          !t.isDeleted &&
          !t.isStarted &&
          t.startTime != null &&
          t.startTime!.isAfter(now))
      .toList();
  return _applySort(list, sort);
});

/// Tab 2: 待办事项 — no start time or start time reached, not manually started, not completed, not deleted
final pendingTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final sort = ref.watch(sortModeProvider);
  final now = DateTime.now();
  final list = todos
      .where((t) =>
          !t.isCompleted &&
          !t.isDeleted &&
          !t.isStarted &&
          (t.startTime == null || !t.startTime!.isAfter(now)))
      .toList();
  return _applySort(list, sort);
});

/// Tab 3: 正在处理 — manually started, not completed, not deleted
final inProgressTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final sort = ref.watch(sortModeProvider);
  final list = todos.where((t) => !t.isCompleted && !t.isDeleted && t.isStarted).toList();
  return _applySort(list, sort);
});

/// Tab 4: 已完成 — completed, not deleted, within retention window
final completedTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final sort = ref.watch(sortModeProvider);
  final retentionDays = ref.watch(dataRetentionDaysProvider);
  final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
  final list = todos
      .where((t) =>
          t.isCompleted &&
          !t.isDeleted &&
          (t.completedAt == null || t.completedAt!.isAfter(cutoff)))
      .toList();
  return _applySort(list, sort);
});

/// Tab 5: 已删除 — soft-deleted, within retention window
final deletedTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final sort = ref.watch(sortModeProvider);
  final retentionDays = ref.watch(dataRetentionDaysProvider);
  final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
  // Use completedAt if available (deleted after completion), otherwise createdAt
  final list = todos
      .where((t) =>
          t.isDeleted &&
          (t.completedAt ?? t.createdAt).isAfter(cutoff))
      .toList();
  return _applySort(list, sort);
});

/// All non-deleted incomplete (used by stats row)
final incompleteTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  return todos.where((t) => !t.isCompleted && !t.isDeleted).toList();
});

class TodoListNotifier extends StateNotifier<List<Todo>> {
  final StorageService _storage;

  TodoListNotifier(this._storage) : super([]) {
    _loadTodos();
  }

  void _loadTodos() {
    state = _storage.getAllTodos();
  }

  Future<void> addTodo({
    required String title,
    DateTime? startTime,
    DateTime? endTime,
    Priority priority = Priority.medium,
    String remark = '',
    TodoCategory category = TodoCategory.work,
  }) async {
    final todo = Todo(
      id: _uuid.v4(),
      title: title,
      startTime: startTime,
      endTime: endTime,
      priority: priority,
      remark: remark,
      category: category,
    );
    await _storage.addTodo(todo);
    state = [...state, todo];
  }

  Future<void> toggleComplete(String id, {String completionNote = ''}) async {
    final todo = _storage.getTodo(id);
    if (todo == null) return;
    final nowCompleted = !todo.isCompleted;
    final updated = todo.copyWith(
      isCompleted: nowCompleted,
      completedAt: nowCompleted ? DateTime.now() : null,
      completionNote: nowCompleted ? completionNote : '',
    );
    await _storage.updateTodo(updated);
    state = [
      for (final t in state)
        if (t.id == id) updated else t,
    ];
  }

  /// Toggle isStarted (move between 待办 and 进行中)
  Future<void> toggleStarted(String id) async {
    final todo = _storage.getTodo(id);
    if (todo == null) return;
    final updated = todo.copyWith(isStarted: !todo.isStarted);
    await _storage.updateTodo(updated);
    state = [
      for (final t in state)
        if (t.id == id) updated else t,
    ];
  }

  Future<void> updateTodo(String id, {String? title, String? remark, Priority? priority, DateTime? startTime, DateTime? endTime, TodoCategory? category}) async {
    final todo = _storage.getTodo(id);
    if (todo == null) return;
    final updated = todo.copyWith(
      title: title,
      remark: remark,
      priority: priority,
      startTime: startTime,
      endTime: endTime,
      category: category,
    );
    await _storage.updateTodo(updated);
    state = [
      for (final t in state)
        if (t.id == id) updated else t,
    ];
  }

  /// Soft delete — mark as deleted but keep in storage
  Future<void> softDeleteTodo(String id) async {
    final todo = _storage.getTodo(id);
    if (todo == null) return;
    final updated = todo.copyWith(isDeleted: true);
    await _storage.updateTodo(updated);
    state = [
      for (final t in state)
        if (t.id == id) updated else t,
    ];
  }

  /// Restore from deleted
  Future<void> restoreTodo(String id) async {
    final todo = _storage.getTodo(id);
    if (todo == null) return;
    final updated = todo.copyWith(isDeleted: false);
    await _storage.updateTodo(updated);
    state = [
      for (final t in state)
        if (t.id == id) updated else t,
    ];
  }

  /// Permanently delete
  Future<void> deleteTodo(String id) async {
    await _storage.deleteTodo(id);
    state = state.where((t) => t.id != id).toList();
  }

  void refresh() {
    _loadTodos();
  }
}
