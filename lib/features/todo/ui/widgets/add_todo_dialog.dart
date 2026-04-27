import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import '../../model/todo_model.dart';
import '../../provider/todo_provider.dart';
import '../../../../shared/theme.dart';

class AddTodoDialog extends ConsumerStatefulWidget {
  final Todo? editTodo;

  const AddTodoDialog({super.key, this.editTodo});

  @override
  ConsumerState<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends ConsumerState<AddTodoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _remarkCtrl;
  DateTime? _startTime;
  DateTime? _endTime;
  Priority _priority = Priority.medium;
  TodoCategory _category = TodoCategory.work;

  @override
  void initState() {
    super.initState();
    final todo = widget.editTodo;
    _titleCtrl = TextEditingController(text: todo?.title ?? '');
    _remarkCtrl = TextEditingController(text: todo?.remark ?? '');
    final now = DateTime.now();
    _startTime = todo?.startTime ?? DateTime(now.year, now.month, now.day);
    _endTime = todo?.endTime;
    _priority = todo?.priority ?? Priority.medium;
    _category = todo?.category ?? TodoCategory.work;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final result = await showOmniDateTimePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      is24HourMode: true,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      constraints: const BoxConstraints(maxWidth: 350, maxHeight: 580),
      type: OmniDateTimePickerType.dateAndTime,
    );
    return result;
  }

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.high:
        return AppTheme.priorityHigh;
      case Priority.medium:
        return AppTheme.priorityMedium;
      case Priority.low:
        return AppTheme.priorityLow;
    }
  }

  Color _categoryColor(TodoCategory c) {
    switch (c) {
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

  IconData _categoryIcon(TodoCategory c) {
    switch (c) {
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

  String _categoryLabel(TodoCategory c) {
    switch (c) {
      case TodoCategory.work:
        return '工作';
      case TodoCategory.personal:
        return '个人';
      case TodoCategory.study:
        return '学习';
      case TodoCategory.health:
        return '健康';
      case TodoCategory.other:
        return '其他';
    }
  }

  String _priorityLabel(Priority p) {
    switch (p) {
      case Priority.low:
        return '低';
      case Priority.medium:
        return '中';
      case Priority.high:
        return '高';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editTodo != null;
    final df = DateFormat('yyyy-MM-dd HH:mm');

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.border),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_rounded : Icons.add_task_rounded,
                      size: 20,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? '编辑待办' : '新建待办',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close_rounded,
                          size: 20, color: AppTheme.textTertiary),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      _buildLabel('名称', required: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          hintText: '输入待办名称...',
                        ),
                        style: const TextStyle(fontSize: 15),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? '请输入名称' : null,
                        autofocus: !isEdit,
                      ),
                      const SizedBox(height: 18),
                      // Category selector
                      _buildLabel('分类'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: TodoCategory.values.map((c) {
                          final selected = _category == c;
                          final color = _categoryColor(c);
                          return InkWell(
                            onTap: () => setState(() => _category = c),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? color.withOpacity(0.12)
                                    : AppTheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selected
                                      ? color.withOpacity(0.4)
                                      : AppTheme.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_categoryIcon(c),
                                      size: 16,
                                      color:
                                          selected ? color : AppTheme.textTertiary),
                                  const SizedBox(width: 6),
                                  Text(
                                    _categoryLabel(c),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: selected
                                          ? color
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      // Priority & Time row
                      Row(
                        children: [
                          // Priority
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('紧急度'),
                                const SizedBox(height: 8),
                                Row(
                                  children: Priority.values.map((p) {
                                    final selected = _priority == p;
                                    final color = _priorityColor(p);
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: InkWell(
                                        onTap: () =>
                                            setState(() => _priority = p),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 150),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? color.withOpacity(0.12)
                                                : AppTheme.surface,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: selected
                                                  ? color.withOpacity(0.4)
                                                  : AppTheme.border,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _priorityLabel(p),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: selected
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                  color: selected
                                                      ? color
                                                      : AppTheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Time pickers
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimePicker(
                              label: '开始时间',
                              value: _startTime,
                              df: df,
                              onPick: () async {
                                final dt = await _pickDateTime(_startTime);
                                if (dt != null) {
                                  setState(() => _startTime = dt);
                                }
                              },
                              onClear: () =>
                                  setState(() => _startTime = null),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTimePicker(
                              label: '结束时间',
                              value: _endTime,
                              df: df,
                              onPick: () async {
                                final dt = await _pickDateTime(_endTime);
                                if (dt != null) {
                                  setState(() => _endTime = dt);
                                }
                              },
                              onClear: () =>
                                  setState(() => _endTime = null),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Remark
                      _buildLabel('备注'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _remarkCtrl,
                        decoration: const InputDecoration(
                          hintText: '添加备注信息...',
                        ),
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.border),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: Icon(
                      isEdit ? Icons.save_rounded : Icons.add_rounded,
                      size: 18,
                    ),
                    label: Text(isEdit ? '保存更改' : '创建待办'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        if (required)
          const Text(' *',
              style: TextStyle(color: AppTheme.danger, fontSize: 13)),
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required DateTime? value,
    required DateFormat df,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 15, color: AppTheme.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value != null ? df.format(value) : '点击选择',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          value != null ? AppTheme.textPrimary : AppTheme.textTertiary,
                    ),
                  ),
                ),
                if (value != null)
                  InkWell(
                    onTap: onClear,
                    child: Icon(Icons.close_rounded,
                        size: 16, color: AppTheme.textTertiary),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(todoListProvider.notifier);
    if (widget.editTodo != null) {
      notifier.updateTodo(
        widget.editTodo!.id,
        title: _titleCtrl.text.trim(),
        remark: _remarkCtrl.text.trim(),
        priority: _priority,
        startTime: _startTime,
        endTime: _endTime,
        category: _category,
      );
    } else {
      notifier.addTodo(
        title: _titleCtrl.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        priority: _priority,
        remark: _remarkCtrl.text.trim(),
        category: _category,
      );
    }
    Navigator.pop(context);
  }
}
