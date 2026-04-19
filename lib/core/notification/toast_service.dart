import 'package:flutter/material.dart';
import 'package:win_toast/win_toast.dart';
import '../../features/todo/model/todo_model.dart';

/// Service for showing Windows Toast Notifications
class ToastService {
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      _initialized = await WinToast.instance().initialize(
        appName: 'Todo Desktop',
        productName: 'Todo Desktop',
        companyName: 'TodoDesktop',
      );
      debugPrint('[ToastService] Initialized: $_initialized');
    } catch (e) {
      debugPrint('[ToastService] Init failed: $e');
    }
  }

  /// Show a toast notification with the list of incomplete todos
  Future<void> showTodoNotification(List<Todo> incompleteTodos) async {
    if (!_initialized) return;
    if (incompleteTodos.isEmpty) return;

    try {
      final title = '你有 ${incompleteTodos.length} 项待办事项';
      final subtitle = _formatTodoSummary(incompleteTodos);

      await WinToast.instance().showToast(
        type: ToastType.text02,
        title: title,
        subtitle: subtitle,
      );
      debugPrint('[ToastService] Showed notification: ${incompleteTodos.length} todos');
    } catch (e) {
      debugPrint('[ToastService] Failed to show notification: $e');
    }
  }

  /// Format todos into a readable summary (max 5 items shown)
  String _formatTodoSummary(List<Todo> todos) {
    const maxItems = 5;
    final displayTodos = todos.take(maxItems).toList();
    final lines = displayTodos.asMap().entries.map((e) {
      final prefix = switch (e.value.priority) {
        Priority.high => '[!]',
        Priority.medium => '[-]',
        _ => '[ ]',
      };
      return '$prefix ${e.value.title}';
    }).join('\n');

    if (todos.length > maxItems) {
      return '$lines\n... 及其他 ${todos.length - maxItems} 项';
    }
    return lines;
  }
}
