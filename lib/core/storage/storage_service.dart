import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/todo/model/todo_model.dart';

class StorageService {
  static const String _todoBoxName = 'todos';
  static const String _settingsBoxName = 'settings';
  late Box<Todo> _todoBox;
  late Box _settingsBox;
  late String _storagePath;

  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    _storagePath = dir.path;
    await Hive.initFlutter(_storagePath);
    Hive.registerAdapter(PriorityAdapter());
    Hive.registerAdapter(TodoAdapter());
    Hive.registerAdapter(TodoCategoryAdapter());
    _todoBox = await _openBoxSafe<Todo>(_todoBoxName);
    _settingsBox = await _openBoxSafe(_settingsBoxName);
  }

  /// Open a Hive box; if it fails due to a stale lock file, delete the lock
  /// and retry once.
  Future<Box<T>> _openBoxSafe<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } on PathAccessException catch (e) {
      debugPrint('[StorageService] Box "$name" locked, clearing lock: $e');
      final lockFile = File('$_storagePath/$name.lock');
      if (await lockFile.exists()) {
        await lockFile.delete();
      }
      return await Hive.openBox<T>(name);
    }
  }

  Box<Todo> get todoBox => _todoBox;
  Box get settingsBox => _settingsBox;

  List<Todo> getAllTodos() => _todoBox.values.toList();

  List<Todo> getIncompleteTodos() =>
      _todoBox.values.where((t) => !t.isCompleted && !t.isDeleted).toList();

  List<Todo> getCompletedTodos() =>
      _todoBox.values.where((t) => t.isCompleted).toList();

  Future<void> addTodo(Todo todo) async {
    await _todoBox.put(todo.id, todo);
  }

  Future<void> updateTodo(Todo todo) async {
    await _todoBox.put(todo.id, todo);
  }

  Future<void> deleteTodo(String id) async {
    await _todoBox.delete(id);
  }

  Todo? getTodo(String id) => _todoBox.get(id);

  // Settings helpers
  DateTime? getLastDailyReminder() {
    final val = _settingsBox.get('lastDailyReminder');
    return val is DateTime ? val : null;
  }

  Future<void> setLastDailyReminder(DateTime dt) async {
    await _settingsBox.put('lastDailyReminder', dt);
  }
}
