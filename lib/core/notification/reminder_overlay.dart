import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';
import '../../app.dart';
import '../../features/todo/model/todo_model.dart';
import '../../shared/theme.dart';

class ReminderOverlay {
  static final ReminderOverlay _instance = ReminderOverlay._();
  factory ReminderOverlay() => _instance;
  ReminderOverlay._();

  OverlayEntry? _overlayEntry;
  final List<_ReminderItem> _items = [];
  _ReminderOverlayState? _overlayState;

  void Function(String id)? onComplete;
  void Function(String id)? onDismiss;

  void show({
    required List<Todo> todos,
    String? title,
    void Function(String id)? onComplete,
    void Function(String id)? onDismiss,
  }) {
    // Get the overlay directly from the navigator state — avoids Overlay.of()
    // lookup which fails when context is the Navigator widget itself
    final overlay = TodoApp.navigatorKey.currentState?.overlay;
    if (overlay == null) {
      debugPrint('[ReminderOverlay] overlay not available yet');
      return;
    }

    this.onComplete = onComplete;
    this.onDismiss = onDismiss;

    for (final todo in todos) {
      if (!_items.any((i) => i.todoId == todo.id)) {
        _items.add(_ReminderItem(
          todoId: todo.id,
          title: todo.title,
          priority: todo.priority,
          category: todo.category,
          startTime: todo.startTime,
          remark: todo.remark,
        ));
      }
    }

    if (_overlayEntry != null) {
      _overlayState?.refresh();
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => _ReminderOverlayWidget(
        items: _items,
        title: title,
        onInit: (state) => _overlayState = state,
        onClose: (id) {
          _items.removeWhere((i) => i.todoId == id);
          this.onDismiss?.call(id);
          if (_items.isEmpty) _removeOverlay();
          _overlayState?.refresh();
        },
        onComplete: (id) {
          _items.removeWhere((i) => i.todoId == id);
          this.onComplete?.call(id);
          if (_items.isEmpty) _removeOverlay();
          _overlayState?.refresh();
        },
        onCloseAll: () {
          _items.clear();
          _removeOverlay();
        },
      ),
    );

    overlay.insert(_overlayEntry!);
    debugPrint('[ReminderOverlay] overlay inserted successfully');
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _overlayState = null;
    // Release always-on-top when overlay is dismissed
    windowManager.setAlwaysOnTop(false);
  }

  void dismiss() {
    _items.clear();
    _removeOverlay();
  }

  bool get isShowing => _overlayEntry != null;
}

class _ReminderItem {
  final String todoId;
  final String title;
  final Priority priority;
  final TodoCategory category;
  final DateTime? startTime;
  final String remark;

  _ReminderItem({
    required this.todoId,
    required this.title,
    required this.priority,
    required this.category,
    this.startTime,
    this.remark = '',
  });
}

class _ReminderOverlayWidget extends StatefulWidget {
  final List<_ReminderItem> items;
  final String? title;
  final void Function(String) onClose;
  final void Function(String) onComplete;
  final VoidCallback onCloseAll;
  final void Function(_ReminderOverlayState) onInit;

  const _ReminderOverlayWidget({
    required this.items,
    this.title,
    required this.onClose,
    required this.onComplete,
    required this.onCloseAll,
    required this.onInit,
  });

  @override
  State<_ReminderOverlayWidget> createState() => _ReminderOverlayState();
}

class _ReminderOverlayState extends State<_ReminderOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    widget.onInit(this);

    // Slide-in animation
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    // Pulsing bell icon animation (repeats to draw attention)
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();

    return Positioned(
      right: 20,
      bottom: 20,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            elevation: 0,
            color: Colors.transparent,
            child: Container(
              width: 380,
              constraints: const BoxConstraints(maxHeight: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.shadowLg,
                border: Border.all(color: AppTheme.border.withOpacity(0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusLg),
                      ),
                    ),
                    child: Row(
                      children: [
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.notifications_active_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title ?? '待办提醒',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${items.length} 项待处理',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: widget.onCloseAll,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // List
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 18,
                        endIndent: 18,
                        color: AppTheme.divider,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _ReminderCard(
                          item: item,
                          onClose: () => widget.onClose(item.todoId),
                          onComplete: () => widget.onComplete(item.todoId),
                        );
                      },
                    ),
                  ),
                  // Footer
                  if (items.length > 1)
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.divider),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onCloseAll,
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('全部关闭'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textSecondary,
                                side: const BorderSide(color: AppTheme.border),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                textStyle: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
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
}

class _ReminderCard extends StatefulWidget {
  final _ReminderItem item;
  final VoidCallback onClose;
  final VoidCallback onComplete;

  const _ReminderCard({
    required this.item,
    required this.onClose,
    required this.onComplete,
  });

  @override
  State<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<_ReminderCard> {
  bool _isHovered = false;

  Color _priorityColor() {
    switch (widget.item.priority) {
      case Priority.high:
        return AppTheme.priorityHigh;
      case Priority.medium:
        return AppTheme.priorityMedium;
      case Priority.low:
        return AppTheme.priorityLow;
    }
  }

  Color _categoryColor() {
    switch (widget.item.category) {
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

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MM/dd HH:mm');
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _isHovered ? AppTheme.surface : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            // Priority bar
            Container(
              width: 3,
              height: 36,
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
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _categoryColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          item.category == TodoCategory.work
                              ? '工作'
                              : item.category == TodoCategory.personal
                                  ? '个人'
                                  : item.category == TodoCategory.study
                                      ? '学习'
                                      : item.category == TodoCategory.health
                                          ? '健康'
                                          : '其他',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _categoryColor(),
                          ),
                        ),
                      ),
                      if (item.startTime != null) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.schedule_rounded,
                            size: 11, color: AppTheme.textTertiary),
                        const SizedBox(width: 3),
                        Text(
                          df.format(item.startTime!),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            AnimatedOpacity(
              opacity: _isHovered ? 1.0 : 0.6,
              duration: const Duration(milliseconds: 120),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAction(
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.success,
                    tooltip: '标记完成',
                    onTap: widget.onComplete,
                  ),
                  const SizedBox(width: 4),
                  _buildAction(
                    icon: Icons.close_rounded,
                    color: AppTheme.textTertiary,
                    tooltip: '关闭',
                    onTap: widget.onClose,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: _isHovered ? color.withOpacity(0.1) : Colors.transparent,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
