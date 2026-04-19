import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:local_notifier/local_notifier.dart';
import '../../features/todo/model/todo_model.dart';
import '../../app.dart';
import '../storage/storage_service.dart';
import '../notification/reminder_overlay.dart';

/// Schedules reminders based on Todo startTime and daily summary.
class SchedulerService {
  final StorageService _storage;
  Timer? _checkTimer;
  final Set<String> _triggeredIds = {};
  bool _dailyTriggeredToday = false;

  /// Called when user marks a todo complete via the reminder overlay.
  void Function(String id)? onMarkComplete;

  SchedulerService(this._storage);

  /// Send a Windows native toast notification (visible even when minimized).
  Future<void> _sendSystemNotification({
    required String title,
    required String body,
  }) async {
    try {
      final notification = LocalNotification(
        title: title,
        body: body,
      );
      await notification.show();
    } catch (e) {
      debugPrint('[SchedulerService] System notification failed: $e');
    }
  }

  /// Resolve a valid BuildContext from the navigator key.
  /// This context is below MaterialApp / Navigator, so Overlay.of works.
  BuildContext? get _overlayContext =>
      TodoApp.navigatorKey.currentContext;

  void start({void Function(String)? onMarkComplete}) {
    this.onMarkComplete = onMarkComplete;

    // Check every 30 seconds
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());

    // Run first check after a short delay so the navigator is ready
    Future.delayed(const Duration(milliseconds: 500), _tick);
    debugPrint('[SchedulerService] Started');
  }

  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
    debugPrint('[SchedulerService] Stopped');
  }

  void _tick() {
    final ctx = _overlayContext;
    if (ctx == null || !ctx.mounted) return;
    final now = DateTime.now();

    // --- 1. StartTime reminders ---
    _checkStartTimeReminders(now);

    // --- 2. Daily reminder at 9:00 ---
    _checkDailyReminder(now);
  }

  /// Bring window to the foreground so the user cannot miss the reminder.
  Future<void> _bringWindowToFront() async {
    try {
      final isVisible = await windowManager.isVisible();
      if (!isVisible) {
        await windowManager.show();
      }
      // Flash taskbar icon to draw attention
      await windowManager.setAlwaysOnTop(true);
      await Future.delayed(const Duration(milliseconds: 300));
      await windowManager.setAlwaysOnTop(false);
      await windowManager.focus();
    } catch (_) {}
  }

  void _checkStartTimeReminders(DateTime now) {
    final ctx = _overlayContext;
    if (ctx == null || !ctx.mounted) return;

    final todos = _storage.getIncompleteTodos();
    final toRemind = <Todo>[];

    for (final todo in todos) {
      if (todo.startTime == null) continue;
      if (_triggeredIds.contains(todo.id)) continue;

      // Trigger for ALL todos whose startTime has passed (including old ones)
      // This ensures reminders show on every app restart
      if (!todo.startTime!.isAfter(now)) {
        toRemind.add(todo);
        _triggeredIds.add(todo.id);
      }
    }

    if (toRemind.isNotEmpty) {
      debugPrint('[SchedulerService] Showing reminders for ${toRemind.length} todos');

      // Always send native notification (works even when minimized)
      final body = toRemind.length == 1
          ? toRemind.first.title
          : toRemind.map((t) => '• ${t.title}').join('\n');
      _sendSystemNotification(title: '⏰ 待办提醒', body: body);

      _bringWindowToFront();
      ReminderOverlay().show(
        ctx,
        todos: toRemind,
        title: '⏰ 待办提醒',
        onComplete: (id) {
          onMarkComplete?.call(id);
        },
      );
    }
  }

  void _checkDailyReminder(DateTime now) {
    // Trigger daily reminder at 9:00
    if (now.hour == 9 && now.minute < 1 && !_dailyTriggeredToday) {
      _triggerDailyReminder();
      _dailyTriggeredToday = true;
    }

    // Reset flag if it's past 9:01
    if (now.hour != 9 || now.minute > 0) {
      // Reset for next day after 9:01
      if (_dailyTriggeredToday && now.hour >= 9 && now.minute >= 1) {
        // Keep triggered for today
      }
    }

    // Reset at midnight for next day
    if (now.hour == 0 && now.minute == 0) {
      _dailyTriggeredToday = false;
    }

    // Also check if we haven't shown the daily reminder yet today
    final lastReminder = _storage.getLastDailyReminder();
    if (lastReminder == null ||
        lastReminder.day != now.day ||
        lastReminder.month != now.month ||
        lastReminder.year != now.year) {
      // If it's after 9:00 and we haven't triggered today
      if (now.hour >= 9 && !_dailyTriggeredToday) {
        _triggerDailyReminder();
        _dailyTriggeredToday = true;
      }
    }
  }

  void _triggerDailyReminder() {
    final ctx = _overlayContext;
    final todos = _storage.getIncompleteTodos();
    if (todos.isEmpty) return;
    if (ctx == null || !ctx.mounted) return;

    _storage.setLastDailyReminder(DateTime.now());

    // Always send native notification (works even when minimized)
    final body = todos.length == 1
        ? todos.first.title
        : '你有 ${todos.length} 项待办事项需要处理';
    _sendSystemNotification(title: '🌅 每日待办提醒', body: body);

    _bringWindowToFront();
    ReminderOverlay().show(
      ctx,
      todos: todos,
      title: '🌅 每日待办提醒',
      onComplete: (id) {
        onMarkComplete?.call(id);
      },
    );

    debugPrint('[SchedulerService] Daily reminder triggered with ${todos.length} todos');
  }

  /// Manually trigger daily reminder (for testing)
  void triggerDailyReminderNow() {
    _triggerDailyReminder();
  }

  /// Clear triggered cache for a specific todo (when it's edited)
  void clearTriggered(String id) {
    _triggeredIds.remove(id);
  }
}
