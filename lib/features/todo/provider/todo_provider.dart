import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/todo_model.dart';
import '../../../core/storage/storage_service.dart';

const _uuid = Uuid();

// Sort mode
enum SortMode { byTime, byPriority }

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden at startup');
});

/// Current sort mode
final sortModeProvider = StateProvider<SortMode>((ref) => SortMode.byTime);

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

/// Tab 1: 待办事项 — not started yet, not completed, not deleted
final pendingTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final sort = ref.watch(sortModeProvider);
  final list = todos.where((t) => !t.isCompleted && !t.isDeleted && !t.isStarted).toList();
  return _applySort(list, sort);
});

/// Tab 2: 正在处理 — started but not completed, not deleted
final inProgressTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final sort = ref.watch(sortModeProvider);
  final list = todos.where((t) => !t.isCompleted && !t.isDeleted && t.isStarted).toList();
  return _applySort(list, sort);
});

/// Tab 3: 已完成 — completed, not deleted
final completedTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final sort = ref.watch(sortModeProvider);
  final list = todos.where((t) => t.isCompleted && !t.isDeleted).toList();
  return _applySort(list, sort);
});

/// Tab 4: 已删除 — soft-deleted
final deletedTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final sort = ref.watch(sortModeProvider);
  final list = todos.where((t) => t.isDeleted).toList();
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

  Future<void> toggleComplete(String id) async {
    final todo = _storage.getTodo(id);
    if (todo == null) return;
    final nowCompleted = !todo.isCompleted;
    final updated = todo.copyWith(
      isCompleted: nowCompleted,
      completedAt: nowCompleted ? DateTime.now() : null,
    );
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
