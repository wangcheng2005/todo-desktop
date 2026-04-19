import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_manager/window_manager.dart';
import 'package:intl/intl.dart';

import '../../shared/theme.dart';

/// 独立提醒弹窗 App，运行在独立的 Flutter Engine 中。
/// 通过 desktop_multi_window 创建，完全不影响主窗口。
class ReminderPopupApp extends StatelessWidget {
  final Map<String, dynamic> args;

  const ReminderPopupApp({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primary),
        useMaterial3: true,
      ),
      home: _ReminderPopupHome(args: args),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _PopupItem {
  final String id;
  final String title;
  final int priority; // 0=low, 1=medium, 2=high
  final int category; // 0=work,1=personal,2=study,3=health,4=other
  final DateTime? startTime;
  final String remark;

  _PopupItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.category,
    this.startTime,
    this.remark = '',
  });

  factory _PopupItem.fromMap(Map<dynamic, dynamic> m) => _PopupItem(
        id: m['id'] as String,
        title: m['title'] as String,
        priority: (m['priority'] as num).toInt(),
        category: (m['category'] as num).toInt(),
        startTime: m['startTime'] != null
            ? DateTime.tryParse(m['startTime'] as String)
            : null,
        remark: (m['remark'] as String?) ?? '',
      );
}

// ── Main popup widget ──────────────────────────────────────────────────────────

class _ReminderPopupHome extends StatefulWidget {
  final Map<String, dynamic> args;

  const _ReminderPopupHome({required this.args});

  @override
  State<_ReminderPopupHome> createState() => _ReminderPopupHomeState();
}

class _ReminderPopupHomeState extends State<_ReminderPopupHome>
    with TickerProviderStateMixin {
  late List<_PopupItem> _items;
  late String _title;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const _reminderChannel = WindowMethodChannel(
    'todo_reminder_channel',
    mode: ChannelMode.unidirectional,
  );

  @override
  void initState() {
    super.initState();
    _title = (widget.args['windowTitle'] as String?) ?? '待办提醒';
    final raw = widget.args['todos'] as List? ?? [];
    _items = raw.map((t) => _PopupItem.fromMap(t as Map)).toList();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    if (_items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _closeWindow());
      return;
    }

    // Configure and show the window after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupWindow());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Window setup ────────────────────────────────────────────────────────────

  Future<void> _setupWindow() async {
    try {
      // Dynamic height based on number of items (no native titlebar needed)
      const w = 380.0;
      const headerH = 60.0;
      const itemH = 76.0;
      const footerH = 56.0;
      final contentH =
          headerH + _items.length * itemH + (_items.length > 1 ? footerH : 12.0);
      final totalH = contentH.clamp(150.0, 600.0);

      // Hide native title bar → toast look; skip taskbar → not in taskbar
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setSkipTaskbar(true);
      await windowManager.setResizable(false);
      await windowManager.setSize(Size(w, totalH));
      await windowManager.setAlignment(Alignment.bottomRight);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.show();
      await windowManager.focus();
    } catch (e) {
      debugPrint('[ReminderPopup] _setupWindow error: $e');
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _closeWindow() async {
    try {
      await windowManager.close();
    } catch (e) {
      debugPrint('[ReminderPopup] close error: $e');
    }
  }

  Future<void> _onComplete(String id) async {
    // Notify main window to mark todo as complete via IPC channel
    try {
      await _reminderChannel.invokeMethod('markComplete', id);
    } catch (e) {
      debugPrint('[ReminderPopup] markComplete IPC error: $e');
    }
    setState(() => _items.removeWhere((i) => i.id == id));
    if (_items.isEmpty) await _closeWindow();
  }

  void _onDismiss(String id) {
    setState(() => _items.removeWhere((i) => i.id == id));
    if (_items.isEmpty) _closeWindow();
  }

  Future<void> _closeAll() => _closeWindow();

  // ── Color helpers ───────────────────────────────────────────────────────────

  static Color _priorityColor(int p) {
    if (p == 2) return AppTheme.priorityHigh;
    if (p == 1) return AppTheme.priorityMedium;
    return AppTheme.priorityLow;
  }

  static Color _catColor(int c) {
    const colors = [
      AppTheme.catWork,
      AppTheme.catPersonal,
      AppTheme.catStudy,
      AppTheme.catHealth,
      AppTheme.catOther,
    ];
    return c >= 0 && c < colors.length ? colors[c] : AppTheme.catOther;
  }

  static String _catLabel(int c) {
    const labels = ['工作', '个人', '学习', '健康', '其他'];
    return c >= 0 && c < labels.length ? labels[c] : '其他';
  }

  // ── Build ───────────────────────────────────────────────────────────────────

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
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
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
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
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
        height: 1,
        indent: 18,
        endIndent: 18,
        color: AppTheme.divider,
      ),
      itemBuilder: (_, i) {
        final item = _items[i];
        return _ItemCard(
          item: item,
          priorityColor: _priorityColor(item.priority),
          catColor: _catColor(item.category),
          catLabel: _catLabel(item.category),
          onComplete: () => _onComplete(item.id),
          onDismiss: () => _onDismiss(item.id),
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

// ── Item card ─────────────────────────────────────────────────────────────────

class _ItemCard extends StatefulWidget {
  final _PopupItem item;
  final Color priorityColor;
  final Color catColor;
  final String catLabel;
  final VoidCallback onComplete;
  final VoidCallback onDismiss;

  const _ItemCard({
    required this.item,
    required this.priorityColor,
    required this.catColor,
    required this.catLabel,
    required this.onComplete,
    required this.onDismiss,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  bool _hovered = false;

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
            Container(
              width: 3,
              height: 38,
              decoration: BoxDecoration(
                color: widget.priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: widget.catColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          widget.catLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: widget.catColor,
                          ),
                        ),
                      ),
                      if (item.startTime != null) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.schedule_rounded,
                          size: 11,
                          color: AppTheme.textTertiary,
                        ),
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
                  if (item.remark.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.remark,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: _hovered ? 1.0 : 0.6,
              duration: const Duration(milliseconds: 120),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _action(
                    Icons.check_circle_rounded,
                    AppTheme.success,
                    '标记完成',
                    widget.onComplete,
                  ),
                  const SizedBox(width: 4),
                  _action(
                    Icons.close_rounded,
                    AppTheme.textTertiary,
                    '关闭',
                    widget.onDismiss,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(
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
