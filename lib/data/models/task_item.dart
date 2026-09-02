import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'task_item.freezed.dart';
part 'task_item.g.dart';

/// A task item, mirroring the backend row serializer 1:1 (DESIGN.md §3).
///
/// Parsing rules:
/// * `due_date` stays a `YYYY-MM-DD` **string** — never parse it as a time
///   (date-only parses as local midnight on web; lexicographic compare is the
///   safe due-kind test). Null when no due date.
/// * `created_at` / `updated_at` are UTC timestamps with `Z` + microseconds —
///   `DateTime.parse` handles them natively and returns UTC.
/// * `quantity` stays `num` (`2` decodes as int, `0.5` as double).
/// * Unknown JSON keys are ignored on read; unknown enum strings fall back
///   to `none` (defensive, DESIGN.md §3).
/// * `toJson` exists only for Freezed serialization — outbound request bodies
///   are whitelists built by `ApiClient`, never whole-item echoes.
@freezed
abstract class TaskItem with _$TaskItem {
  const factory TaskItem({
    required int id,
    @JsonKey(name: 'list_id') required int listId,
    required String title,
    String? notes,
    @JsonKey(unknownEnumValue: Priority.none) required Priority priority,
    @JsonKey(name: 'due_date') String? dueDate,
    required num quantity,
    required int position,
    required bool done,
    @JsonKey(unknownEnumValue: Recurrence.none) required Recurrence recurrence,
    @JsonKey(name: 'recurrence_interval') int? recurrenceInterval,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _TaskItem;

  factory TaskItem.fromJson(Map<String, dynamic> json) =>
      _$TaskItemFromJson(json);
}
