// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TodoAdapter extends TypeAdapter<Todo> {
  @override
  final int typeId = 1;

  @override
  Todo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Todo(
      id: fields[0] as String,
      title: fields[1] as String,
      startTime: fields[2] as DateTime?,
      endTime: fields[3] as DateTime?,
      priority: fields[4] as Priority,
      remark: fields[5] as String,
      isCompleted: fields[6] as bool,
      createdAt: fields[7] as DateTime?,
      category: fields[8] as TodoCategory? ?? TodoCategory.work,
      completedAt: fields[9] as DateTime?,
      isDeleted: fields[10] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Todo obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.remark)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.completedAt)
      ..writeByte(10)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PriorityAdapter extends TypeAdapter<Priority> {
  @override
  final int typeId = 0;

  @override
  Priority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Priority.low;
      case 1:
        return Priority.medium;
      case 2:
        return Priority.high;
      default:
        return Priority.medium;
    }
  }

  @override
  void write(BinaryWriter writer, Priority obj) {
    switch (obj) {
      case Priority.low:
        writer.writeByte(0);
        break;
      case Priority.medium:
        writer.writeByte(1);
        break;
      case Priority.high:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TodoCategoryAdapter extends TypeAdapter<TodoCategory> {
  @override
  final int typeId = 2;

  @override
  TodoCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TodoCategory.work;
      case 1:
        return TodoCategory.personal;
      case 2:
        return TodoCategory.study;
      case 3:
        return TodoCategory.health;
      case 4:
        return TodoCategory.other;
      default:
        return TodoCategory.work;
    }
  }

  @override
  void write(BinaryWriter writer, TodoCategory obj) {
    switch (obj) {
      case TodoCategory.work:
        writer.writeByte(0);
        break;
      case TodoCategory.personal:
        writer.writeByte(1);
        break;
      case TodoCategory.study:
        writer.writeByte(2);
        break;
      case TodoCategory.health:
        writer.writeByte(3);
        break;
      case TodoCategory.other:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
