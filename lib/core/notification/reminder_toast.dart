import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';

import '../../features/todo/model/todo_model.dart';
import '../../shared/theme.dart';
import '../../app.dart';

/// A persistent, overlay-based toast that floats at the bottom-right of the
/// main window. It does NOT create a separate window, does NOT appear in the
/// taskbar, and stays visible until the user manually dismisses each item or
/// closes all at once.
///
/// Usage:
///   ReminderToast.instance.show(todos: [...], title: '...', onComplete: ...);
class ReminderToast {
  ReminderToast._();
  static final instance = ReminderToast._();

  OverlayEntry? _entry;
  final _items = <_ToastItem>[];
  String _title = '';
  void Function(String id)? _onComplete;
  _ReminderToastWidgetState? _widgetState;

  bool get isShowing => _entry != null;

  /// Show (or append to) the reminder toast.
  Future<void> show({
    required List<Todo> todos,
    required String title,
    void Function(String id)? onComplete,
  }) async {
    if (todos.isEmpty) return;

    // Make sure the window is visible so the overlay can be seen.
    await _ensureWindowVisible();

    final newItems = todos.map((t) => _ToastItem(
          id: t.id,
          title: t.title,
          priority: t.priority,
          category: t.category,
          startTime: t.startTime,
          remark: t.remark,
        ));

    _onComplete = onComplete ?? _onComplete;
    _title = title;

    if (_entry != null) {
      // Append to existing toast
      _items.addAll(newItems);
      _widgetState?._refresh();
      return;
    }

    // First time → create overlay entry
    _items
      ..clear()
      ..addAll(newItems);

    _entry = OverlayEntry(builder: (_) => _ReminderToastWidget(toast: this));

    final overlay = TodoApp.navigatorKey.currentState?.overlay;
    if (overlay == null) {
      debugPrint('[ReminderToast] Overlay not available');
      _entry = null;
      return;
    }
    overlay.insert(_entry!);
  }

  void _removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    if (_items.isEmpty) {
      _close();
    } else {
      _widgetState?._refresh();
    }
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    _items.clear();
    _widgetState = null;
  }

  Future<void> _ensureWindowVisible() async {
    try {
      if (!await windowManager.isVisible()) {
        await windowManager.show();
      }
      await windowManager.focus();
    } catch (_) {}
  }
}

// ── Data class ──────────────────────────────────────────────────────────────

class _ToastItem {
  final String id;
  final String title;
  final Priority priority;
  final TodoCategory category;
  final DateTime? startTime;
  final String remark;

  _ToastItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.category,
    this.startTime,
    this.remark = '',
  });
}

// ── Toast overlay widget ────────────────────────────────────────────────────

class _ReminderToastWidget extends StatefulWidget {
  final ReminderToast toast;
  const _ReminderToastWidget({required this.toast});

  @override
  State<_ReminderToastWidget> createState() => _ReminderToastWidgetState();
}

class _ReminderToastWidgetState extends State<_ReminderToastWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    widget.toast._widgetState = this;

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onComplete(String id) {
    widget.toast._onComplete?.call(id);
    widget.toast._removeItem(id);
  }

  void _onDismiss(String id) {
    widget.toast._removeItem(id);
  }

  void _closeAll() {
    widget.toast._close();
  }

  List<_ToastItem> get _items => widget.toast._items;
  String get _title => widget.toast._title;

  @override
  Widget build(BuildContext context) {
    // Dynamic height
    const headerH = 56.0;
    const itemH = 72.0;
    const footerH = 48.0;
    final contentH =
        headerH + _items.length * itemH + (_items.length > 1 ? footerH : 8);
    final height = contentH.clamp(120.0, 500.0);

    return Positioned(
      right: 16,
      bottom: 16,
      width: 360,
      height: height,
      child: SlideTransition(
        position: _slideAnim,
        child: Material(
          elevation: 12,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildList()),
              if (_items.length > 1) _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.notifications_active_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text('${_items.length} 项待处理',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 11)),
              ],
            ),
          ),
          InkWell(
            onTap: _closeAll,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(
          height: 1, indent: 16, endIndent: 16, color: AppTheme.divider),
      itemBuilder: (_, i) {
        final item = _items[i];
        return _ToastCard(
          item: item,
          onComplete: () => _onComplete(item.id),
          onDismiss: () => _onDismiss(item.id),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: SizedBox(
        height: 32,
        child: OutlinedButton.icon(
          onPressed: _closeAll,
          icon: const Icon(Icons.close_rounded, size: 14),
          label: const Text('全部关闭'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
            side: const BorderSide(color: AppTheme.border),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            textStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

// ── Individual card ─────────────────────────────────────────────────────────

class _ToastCard extends StatefulWidget {
  final _ToastItem item;
  final VoidCallback onComplete;
  final VoidCallback onDismiss;

  const _ToastCard({
    required this.item,
    required this.onComplete,
    required this.onDismiss,
  });

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> {
  bool _hovered = false;

  Color get _priorityColor {
    switch (widget.item.priority) {
      case Priority.high:
        return AppTheme.priorityHigh;
      case Priority.medium:
        return AppTheme.priorityMedium;
      case Priority.low:
        return AppTheme.priorityLow;
    }
  }

  Color get _catColor {
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

  String get _catLabel {
    switch (widget.item.category) {
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

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MM/dd HH:mm');
    final item = widget.item;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovered ? AppTheme.surface : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 34,
              decoration: BoxDecoration(
                color: _priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: _catColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(_catLabel,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _catColor)),
                      ),
                      if (item.startTime != null) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.schedule_rounded,
                            size: 10, color: AppTheme.textTertiary),
                        const SizedBox(width: 2),
                        Text(df.format(item.startTime!),
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.textTertiary)),
                      ],
                    ],
                  ),
                  if (item.remark.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(item.remark,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textTertiary)),
                  ],
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: _hovered ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 120),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _btn(Icons.check_circle_rounded, AppTheme.success, '完成',
                      widget.onComplete),
                  const SizedBox(width: 2),
                  _btn(Icons.close_rounded, AppTheme.textTertiary, '关闭',
                      widget.onDismiss),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(
      IconData icon, Color color, String tip, VoidCallback onTap) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: _hovered ? color.withOpacity(0.1) : Colors.transparent,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
