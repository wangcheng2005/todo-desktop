import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/todo/model/todo_model.dart';

class StorageService {
  static const String _todoBoxName = 'todos';
  static const String _settingsBoxName = 'settings';
  late Box<Todo> _todoBox;
  late Box _settingsBox;

  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    await Hive.initFlutter(dir.path);
    Hive.registerAdapter(PriorityAdapter());
    Hive.registerAdapter(TodoAdapter());
    Hive.registerAdapter(TodoCategoryAdapter());
    _todoBox = await Hive.openBox<Todo>(_todoBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  Box<Todo> get todoBox => _todoBox;
  Box get settingsBox => _settingsBox;

  List<Todo> getAllTodos() => _todoBox.values.toList();

  List<Todo> getIncompleteTodos() =>
      _todoBox.values.where((t) => !t.isCompleted).toList();

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
