import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/todo_model.dart';
import '../../../../shared/theme.dart';

class TodoListTile extends StatefulWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onToggleStarted;

  const TodoListTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    this.onToggleStarted,
  });

  @override
  State<TodoListTile> createState() => _TodoListTileState();
}

class _TodoListTileState extends State<TodoListTile> {
  bool _isHovered = false;

  Color _priorityColor() {
    switch (widget.todo.priority) {
      case Priority.high:
        return AppTheme.priorityHigh;
      case Priority.medium:
        return AppTheme.priorityMedium;
      case Priority.low:
        return AppTheme.priorityLow;
    }
  }

  Color _categoryColor() {
    switch (widget.todo.category) {
      case TodoCategory.work:
        return AppTheme.catWork;
      case TodoCategory.personal:
        return AppTheme.catPersonal;
      case TodoCategory.study:
        return AppTheme.catStudy;
      case TodoCategory.health:
        return AppTheme.catHealth;
      case TodoCategory.other:
        return AppTheme.catOther;
    }
  }

  IconData _categoryIcon() {
    switch (widget.todo.category) {
      case TodoCategory.work:
        return Icons.work_rounded;
      case TodoCategory.personal:
        return Icons.person_rounded;
      case TodoCategory.study:
        return Icons.school_rounded;
      case TodoCategory.health:
        return Icons.favorite_rounded;
      case TodoCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final df = DateFormat('MM/dd HH:mm');
    final isOverdue = todo.isOverdue;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.primarySurface.withOpacity(0.4) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isOverdue
                ? AppTheme.danger.withOpacity(0.3)
                : _isHovered
                    ? AppTheme.primary.withOpacity(0.2)
                    : AppTheme.border,
            width: 1,
          ),
          boxShadow: _isHovered ? AppTheme.shadowSm : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onEdit,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: todo.isCompleted,
                        onChanged: (_) => widget.onToggle(),
                        activeColor: AppTheme.success,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Priority indicator bar
                  Container(
                    width: 3,
                    height: 44,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: _priorityColor(),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                todo.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: todo.isCompleted
                                      ? AppTheme.textTertiary
                                      : AppTheme.textPrimary,
                                  decoration: todo.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: AppTheme.textTertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Tags row
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildTag(
                              icon: _categoryIcon(),
                              label: todo.categoryLabel,
                              color: _categoryColor(),
                            ),
                            _buildTag(
                              label: todo.priorityLabel,
                              color: _priorityColor(),
                              filled: todo.priority == Priority.high,
                            ),
                            if (isOverdue)
                              _buildTag(
                                icon: Icons.warning_amber_rounded,
                                label: '已逾期',
                                color: AppTheme.danger,
                                filled: true,
                              ),
                          ],
                        ),
                        // Time info
                        if (todo.startTime != null || todo.endTime != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 13, color: AppTheme.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                '${todo.startTime != null ? df.format(todo.startTime!) : '-'}'
                                ' → '
                                '${todo.endTime != null ? df.format(todo.endTime!) : '-'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOverdue
                                      ? AppTheme.danger
                                      : AppTheme.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Remark
                        if (todo.remark.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.notes_rounded,
                                  size: 13, color: AppTheme.textTertiary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  todo.remark,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Actions (show on hover)
                  AnimatedOpacity(
                    opacity: _isHovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onToggleStarted != null && !todo.isCompleted)
                          _buildIconAction(
                            todo.isStarted
                                ? Icons.pause_circle_outline_rounded
                                : Icons.play_circle_outline_rounded,
                            todo.isStarted ? '移回待办' : '开始处理',
                            todo.isStarted ? AppTheme.warning : AppTheme.primary,
                            widget.onToggleStarted!,
                          ),
                        if (widget.onToggleStarted != null && !todo.isCompleted)
                          const SizedBox(width: 4),
                        _buildIconAction(
                          Icons.edit_outlined,
                          '编辑',
                          AppTheme.primary,
                          widget.onEdit,
                        ),
                        const SizedBox(width: 4),
                        _buildIconAction(
                          Icons.delete_outline_rounded,
                          '删除',
                          AppTheme.danger,
                          () => _confirmDelete(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag({
    IconData? icon,
    required String label,
    required Color color,
    bool filled = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: filled ? Colors.white : color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconAction(
    IconData icon,
    String tooltip,
    Color color,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: color.withOpacity(0.08),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确认删除「${widget.todo.title}」？可在回收站中恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete();
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
