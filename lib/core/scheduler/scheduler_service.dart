import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/todo/model/todo_model.dart';
import '../storage/storage_service.dart';
import '../notification/reminder_toast.dart';

/// Schedules reminders based on Todo startTime and daily summary.
class SchedulerService {
  final StorageService _storage;
  Timer? _checkTimer;
  final Set<String> _triggeredIds = {};
  bool _dailyTriggeredToday = false;

  void Function(String id)? onMarkComplete;

  SchedulerService(this._storage);

  void start({void Function(String)? onMarkComplete}) {
    this.onMarkComplete = onMarkComplete;

    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());

    // Show startup reminder after navigator/overlay is ready
    Future.delayed(const Duration(seconds: 2), _showStartupReminder);
    debugPrint('[SchedulerService] Started');
  }

  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  void _tick() {
    final now = DateTime.now();
    _checkStartTimeReminders(now);
    _checkDailyReminder(now);
  }

  void _showReminder({required List<Todo> todos, required String title}) {
    ReminderToast.instance.show(
      todos: todos,
      title: title,
      onComplete: (id) => onMarkComplete?.call(id),
    );
  }

  void _showStartupReminder() {
    final todos = _storage.getIncompleteTodos();
    if (todos.isEmpty) {
      debugPrint('[SchedulerService] No pending todos at startup');
      _tick();
      return;
    }
    debugPrint('[SchedulerService] Startup: ${todos.length} todos');
    for (final t in todos) {
      _triggeredIds.add(t.id);
    }
    _showReminder(todos: todos, title: '待办事项提醒');
    _tick();
  }

  void _checkStartTimeReminders(DateTime now) {
    final todos = _storage.getIncompleteTodos();
    final toRemind = <Todo>[];
    for (final todo in todos) {
      if (todo.startTime == null) continue;
      if (_triggeredIds.contains(todo.id)) continue;
      if (!todo.startTime!.isAfter(now)) {
        toRemind.add(todo);
        _triggeredIds.add(todo.id);
      }
    }
    if (toRemind.isNotEmpty) {
      debugPrint('[SchedulerService] startTime: ${toRemind.length} todos');
      _showReminder(todos: toRemind, title: '待办提醒');
    }
  }

  void _checkDailyReminder(DateTime now) {
    if (now.hour == 9 && now.minute < 1 && !_dailyTriggeredToday) {
      _triggerDailyReminder();
      _dailyTriggeredToday = true;
    }
    if (now.hour == 0 && now.minute == 0) {
      _dailyTriggeredToday = false;
    }
    final lastReminder = _storage.getLastDailyReminder();
    if (lastReminder == null ||
        lastReminder.day != now.day ||
        lastReminder.month != now.month ||
        lastReminder.year != now.year) {
      if (now.hour >= 9 && !_dailyTriggeredToday) {
        _triggerDailyReminder();
        _dailyTriggeredToday = true;
      }
    }
  }

  void _triggerDailyReminder() {
    final todos = _storage.getIncompleteTodos();
    if (todos.isEmpty) return;
    _storage.setLastDailyReminder(DateTime.now());
    _showReminder(todos: todos, title: '每日待办提醒');
  }

  void triggerDailyReminderNow() => _triggerDailyReminder();

  void clearTriggered(String id) => _triggeredIds.remove(id);
}