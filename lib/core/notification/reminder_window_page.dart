import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';
import '../../features/todo/model/todo_model.dart';
import '../../shared/theme.dart';

/// Shows the reminder list as a standalone, always-on-top small window.
/// When it is showing, the main window is resized to popup dimensions and
/// repositioned to the bottom-right of the screen.
/// When dismissed, the window is restored to its previous size and position.
class ReminderWindowPage extends StatefulWidget {
  final List<Todo> todos;
  final String title;
  final void Function(String id)? onComplete;

  const ReminderWindowPage({
    super.key,
    required this.todos,
    required this.title,
    this.onComplete,
  });

  /// Whether a reminder window is currently active (used to suppress tray-hide).
  static bool isShowing = false;

  @override
  State<ReminderWindowPage> createState() => _ReminderWindowPageState();
}

class _ReminderWindowPageState extends State<ReminderWindowPage>
    with TickerProviderStateMixin, WindowListener {
  late List<_RItem> _items;
  Size? _prevSize;
  Offset? _prevPosition;
  bool _prevResizable = true;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ── Window setup ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    ReminderWindowPage.isShowing = true;

    _items = widget.todos
        .map((t) => _RItem(
              id: t.id,
              title: t.title,
              priority: t.priority,
              category: t.category,
              startTime: t.startTime,
              remark: t.remark,
            ))
        .toList();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseCtrl.repeat(reverse: true);

    windowManager.addListener(this);
    _setupWindow();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _pulseCtrl.dispose();
    ReminderWindowPage.isShowing = false;
    super.dispose();
  }

  /// Intercept minimize while reminder is showing – bring window back immediately.
  @override
  void onWindowMinimize() {
    windowManager.show();
    windowManager.focus();
  }

  Future<void> _setupWindow() async {
    try {
      _prevSize = await windowManager.getSize();
      _prevPosition = await windowManager.getPosition();
      _prevResizable = await windowManager.isResizable();

      const popupSize = Size(420, 560);
      await windowManager.setResizable(false);
      await windowManager.setSize(popupSize);
      // Position to bottom-right of usable screen area (above taskbar)
      await windowManager.setAlignment(Alignment.bottomRight);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.show();
      await windowManager.focus();
    } catch (e) {
      debugPrint('[ReminderWindowPage] _setupWindow error: $e');
    }
  }

  Future<void> _restoreWindow() async {
    try {
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setResizable(_prevResizable);
      if (_prevSize != null) await windowManager.setSize(_prevSize!);
      if (_prevPosition != null) await windowManager.setPosition(_prevPosition!);
    } catch (e) {
      debugPrint('[ReminderWindowPage] _restoreWindow error: $e');
    }
  }

  // ── Dismiss logic ─────────────────────────────────────────────────────────

  void _onComplete(String id) {
    widget.onComplete?.call(id);
    setState(() => _items.removeWhere((i) => i.id == id));
    if (_items.isEmpty) _closeAll();
  }

  void _onClose(String id) {
    setState(() => _items.removeWhere((i) => i.id == id));
    if (_items.isEmpty) _closeAll();
  }

  Future<void> _closeAll() async {
    await _restoreWindow();
    if (mounted) Navigator.of(context).pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildList()),
          if (_items.length > 1) _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
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
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${_items.length} 项待处理',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _closeAll,
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
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(
          height: 1, indent: 18, endIndent: 18, color: AppTheme.divider),
      itemBuilder: (context, index) {
        final item = _items[index];
        return _ReminderCard(
          item: item,
          onClose: () => _onClose(item.id),
          onComplete: () => _onComplete(item.id),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: OutlinedButton.icon(
        onPressed: _closeAll,
        icon: const Icon(Icons.close_rounded, size: 16),
        label: const Text('全部关闭'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textSecondary,
          side: const BorderSide(color: AppTheme.border),
          minimumSize: const Size(double.infinity, 36),
          textStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _RItem {
  final String id;
  final String title;
  final Priority priority;
  final TodoCategory category;
  final DateTime? startTime;
  final String remark;

  _RItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.category,
    this.startTime,
    this.remark = '',
  });
}

// ── Reminder card ─────────────────────────────────────────────────────────────

class _ReminderCard extends StatefulWidget {
  final _RItem item;
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
  bool _hovered = false;

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

  String _categoryLabel() {
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
        color: _hovered ? AppTheme.surface : Colors.transparent,
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
                          _categoryLabel(),
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
                              fontSize: 11, color: AppTheme.textTertiary),
                        ),
                      ],
                    ],
                  ),
                  if (item.remark.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.remark,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
            // Actions
            AnimatedOpacity(
              opacity: _hovered ? 1.0 : 0.6,
              duration: const Duration(milliseconds: 120),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAction(Icons.check_circle_rounded, AppTheme.success,
                      '标记完成', widget.onComplete),
                  const SizedBox(width: 4),
                  _buildAction(Icons.close_rounded, AppTheme.textTertiary,
                      '关闭', widget.onClose),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(
      IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: _hovered ? color.withOpacity(0.1) : Colors.transparent,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
