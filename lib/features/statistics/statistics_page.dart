import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../todo/model/todo_model.dart';
import '../todo/provider/todo_provider.dart';
import '../../shared/theme.dart';

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final allTodos = ref.watch(todoListProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          _buildTopBar(context),
          _buildMonthNav(),
          _buildWeekdayHeader(),
          const Divider(height: 1),
          Expanded(
            child: _buildCalendarGrid(allTodos),
          ),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 12),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceDim,
              foregroundColor: AppTheme.textSecondary,
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            '统计',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNav() {
    final monthNames = [
      '', '1月', '2月', '3月', '4月', '5月', '6月',
      '7月', '8月', '9月', '10月', '11月', '12月'
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNavButton(Icons.chevron_left_rounded, _prevMonth),
          const SizedBox(width: 20),
          Text(
            '${_currentMonth.year}年 ${monthNames[_currentMonth.month]}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 20),
          _buildNavButton(Icons.chevron_right_rounded, _nextMonth),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDim,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const days = ['一', '二', '三', '四', '五', '六', '日'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: days.map((d) {
          final isWeekend = d == '六' || d == '日';
          return Expanded(
            child: Center(
              child: Text(
                d,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isWeekend ? AppTheme.danger.withOpacity(0.7) : AppTheme.textTertiary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(List<Todo> allTodos) {
    // Filter non-deleted todos for this month
    final monthTodos = allTodos.where((t) {
      if (t.isDeleted) return false;
      final date = t.startTime ?? t.createdAt;
      return date.year == _currentMonth.year && date.month == _currentMonth.month;
    }).toList();

    // Build a map from day -> todos
    final Map<int, List<Todo>> dayMap = {};
    for (final t in monthTodos) {
      final date = t.startTime ?? t.createdAt;
      dayMap.putIfAbsent(date.day, () => []).add(t);
    }

    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    // weekday of first day (1=Mon, 7=Sun)
    final firstWeekday = _currentMonth.weekday;
    // leading empty cells
    final leadingBlanks = firstWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: List.generate(rows, (row) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNumber = cellIndex - leadingBlanks + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return Expanded(child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDim.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ));
                }
                final todos = dayMap[dayNumber] ?? [];
                final isToday = today.year == _currentMonth.year &&
                    today.month == _currentMonth.month &&
                    today.day == dayNumber;
                return Expanded(
                  child: _buildDayCell(dayNumber, todos, isToday),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayCell(int day, List<Todo> todos, bool isToday) {
    const maxVisible = 3;
    final visible = todos.take(maxVisible).toList();
    final extra = todos.length - maxVisible;

    return Container(
      margin: const EdgeInsets.all(3),
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        color: isToday ? AppTheme.primarySurface : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday ? AppTheme.primary.withOpacity(0.4) : AppTheme.border,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 5, 6, 3),
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                color: isToday ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ),
          ...visible.map((t) => _buildTodoChip(t)),
          if (extra > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 2, 5, 4),
              child: Text(
                '+$extra 更多',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textTertiary,
                ),
              ),
            ),
          if (todos.isEmpty) const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildTodoChip(Todo todo) {
    final color = _todoColor(todo);
    return Tooltip(
      message: _todoStatusLabel(todo),
      child: Container(
        margin: const EdgeInsets.fromLTRB(4, 2, 4, 0),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                todo.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                  decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _todoColor(Todo todo) {
    if (todo.isCompleted) return AppTheme.success;
    if (todo.isOverdue) return AppTheme.danger;
    if (todo.isStarted) return AppTheme.primary;
    final now = DateTime.now();
    if (todo.startTime != null && todo.startTime!.isAfter(now)) {
      return AppTheme.textTertiary; // not started yet (future)
    }
    return AppTheme.warning; // pending
  }

  String _todoStatusLabel(Todo todo) {
    if (todo.isCompleted) return '已完成: ${todo.title}';
    if (todo.isOverdue) return '已逾期: ${todo.title}';
    if (todo.isStarted) return '进行中: ${todo.title}';
    final now = DateTime.now();
    if (todo.startTime != null && todo.startTime!.isAfter(now)) {
      return '未开始: ${todo.title}';
    }
    return '待办: ${todo.title}';
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('未开始', AppTheme.textTertiary),
          const SizedBox(width: 16),
          _buildLegendItem('待办', AppTheme.warning),
          const SizedBox(width: 16),
          _buildLegendItem('进行中', AppTheme.primary),
          const SizedBox(width: 16),
          _buildLegendItem('已完成', AppTheme.success),
          const SizedBox(width: 16),
          _buildLegendItem('已逾期', AppTheme.danger),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
