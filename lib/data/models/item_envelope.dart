import 'package:freezed_annotation/freezed_annotation.dart';

import 'task_item.dart';

part 'item_envelope.freezed.dart';
part 'item_envelope.g.dart';

/// PATCH item response envelope — shape differs per op (DESIGN.md §2.2):
/// * non-move PATCH (incl. `move_to` and toggle): `{"item": Item, "spawned": Item|null}`
/// * `move` (up/down):                              `{"item": Item, "swapped": Item|null}`
///
/// `spawned` / `swapped` are plain optional fields: whichever key the server
/// sent is parsed, the other stays null. The envelope is used only for the
/// optimistic toggle's `spawned` handling — reorder ops are reconciled by a
/// full silent refresh and never trust the envelope as final state.
@freezed
abstract class ItemEnvelope with _$ItemEnvelope {
  const factory ItemEnvelope({
    required TaskItem item,
    TaskItem? spawned,
    TaskItem? swapped,
  }) = _ItemEnvelope;

  factory ItemEnvelope.fromJson(Map<String, dynamic> json) =>
      _$ItemEnvelopeFromJson(json);
}
