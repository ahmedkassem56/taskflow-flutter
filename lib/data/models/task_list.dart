import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_list.freezed.dart';
part 'task_list.g.dart';

@freezed
abstract class TaskList with _$TaskList {
  const factory TaskList({
    required int id,
    required String name,
    @JsonKey(name: 'item_count') required int itemCount,
    @JsonKey(name: 'pending_count') required int pendingCount,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _TaskList;

  factory TaskList.fromJson(Map<String, dynamic> json) => _$TaskListFromJson(json);
}
