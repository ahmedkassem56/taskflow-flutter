import 'package:freezed_annotation/freezed_annotation.dart';

import 'task_item.dart';
import 'task_list.dart';

part 'shared_list.freezed.dart';
part 'shared_list.g.dart';

/// `GET /api/shared/{token}` response: the shared list with ALL its items
/// (canonical `(done, position, id)` order) plus the token's permission.
/// Status/query filtering of `items` happens client-side (the shared
/// endpoint has no such params — DESIGN.md §5.1).
@freezed
abstract class SharedList with _$SharedList {
  /// Private constructor so the generated class *extends* this one, letting
  /// custom members ([canEdit]) be inherited (freezed 4 semantics).
  const SharedList._();

  const factory SharedList({
    required TaskList list,
    required List<TaskItem> items,
    required String permission,
  }) = _SharedList;

  factory SharedList.fromJson(Map<String, dynamic> json) =>
      _$SharedListFromJson(json);

  /// True when the share token grants write access (`permission == 'edit'`).
  bool get canEdit => permission == 'edit';
}
