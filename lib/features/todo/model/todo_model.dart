import 'package:hive/hive.dart';

part 'todo_model.g.dart';

@HiveType(typeId: 0)
enum Priority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

@HiveType(typeId: 2)
enum TodoCategory {
  @HiveField(0)
  work,
  @HiveField(1)
  personal,
  @HiveField(2)
  study,
  @HiveField(3)
  health,
  @HiveField(4)
  other,
}

@HiveType(typeId: 1)
class Todo extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime? startTime;

  @HiveField(3)
  DateTime? endTime;

  @HiveField(4)
  Priority priority;

  @HiveField(5)
  String remark;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  TodoCategory category;

  @HiveField(9)
  DateTime? completedAt;

  @HiveField(10)
  bool isDeleted;

  @HiveField(11)
  bool isStarted;

  Todo({
    required this.id,
    required this.title,
    this.startTime,
    this.endTime,
    this.priority = Priority.medium,
    this.remark = '',
    this.isCompleted = false,
    DateTime? createdAt,
    this.category = TodoCategory.work,
    this.completedAt,
    this.isDeleted = false,
    this.isStarted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Todo copyWith({
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    Priority? priority,
    String? remark,
    bool? isCompleted,
    TodoCategory? category,
    DateTime? completedAt,
    bool? isDeleted,
    bool? isStarted,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      priority: priority ?? this.priority,
      remark: remark ?? this.remark,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      category: category ?? this.category,
      completedAt: completedAt ?? this.completedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isStarted: isStarted ?? this.isStarted,
    );
  }

  String get priorityLabel {
    switch (priority) {
      case Priority.low:
        return '低';
      case Priority.medium:
        return '中';
      case Priority.high:
        return '高';
    }
  }

  String get categoryLabel {
    switch (category) {
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

  bool get isOverdue {
    if (isCompleted) return false;
    if (endTime == null) return false;
    return DateTime.now().isAfter(endTime!);
  }

  /// In progress = manually started, not completed, not deleted
  bool get isInProgress {
    if (isCompleted || isDeleted) return false;
    return isStarted;
  }

  /// Pending = not started, not completed, not deleted
  bool get isPending {
    if (isCompleted || isDeleted) return false;
    return !isStarted;
  }
}
