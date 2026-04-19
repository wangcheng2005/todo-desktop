import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/todo/model/todo_model.dart';
import '../notification/toast_service.dart';

/// Manages todo notifications via Windows Toast.
/// Shows a notification on startup, when a new todo is created,
/// and every 10 minutes if there are incomplete todos.
class SchedulerService {
  final ToastService _toast;
  Timer? _periodicTimer;
  List<Todo> _currentTodos = [];

  SchedulerService({required ToastService toast}) : _toast = toast;

  Future<void> start({required List<Todo> initialTodos}) async {
    _currentTodos = initialTodos;

    // Show startup reminder after a short delay
    if (initialTodos.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 2));
      await _toast.showTodoNotification(initialTodos);
    }

    // Start periodic timer (every 10 minutes)
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _onPeriodicTick(),
    );
    debugPrint('[Scheduler] Started, ${initialTodos.length} todos, periodic=10min');
  }

  void stop() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Update the cached todo list (called by main.dart on every change)
  void updateTodos(List<Todo> incompleteTodos) {
    _currentTodos = incompleteTodos;
  }

  /// Called when a new todo is created — show notification immediately
  Future<void> onTodoCreated(List<Todo> allIncompleteTodos) async {
    _currentTodos = allIncompleteTodos;
    await _toast.showTodoNotification(allIncompleteTodos);
    debugPrint('[Scheduler] New todo notification, ${allIncompleteTodos.length} items');
  }

  /// Periodic tick — show notification if there are incomplete todos
  Future<void> _onPeriodicTick() async {
    if (_currentTodos.isEmpty) return;
    await _toast.showTodoNotification(_currentTodos);
    debugPrint('[Scheduler] Periodic notification, ${_currentTodos.length} items');
  }
}