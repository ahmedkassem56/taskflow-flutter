import 'package:json_annotation/json_annotation.dart';

/// Wire-level enums (DESIGN.md §3). All wire values are lowercase and equal
/// to the Dart enum name. Parsing is defensive: an unknown wire value falls
/// back to the neutral value instead of throwing (DESIGN.md §3 / §10).
///
/// NOTE: no `part 'enums.g.dart'` here — the enum decode maps are emitted
/// into each model library's own `.g.dart` via [JsonEnum].

/// Item priority; wire value is the lowercase name.
///
/// Unknown wire values fall back to [Priority.none] via the field-level
/// `@JsonKey(unknownEnumValue:)` on models (json_serializable).
enum Priority {
  none,
  low,
  medium,
  high;

  String get wire => name;

  static Priority fromWire(String? value) {
    for (final p in Priority.values) {
      if (p.wire == value) return p;
    }
    return Priority.none;
  }
}

/// Item recurrence; wire value is the lowercase name.
enum Recurrence {
  none,
  daily,
  weekly,
  monthly,
  custom;

  String get wire => name;

  static Recurrence fromWire(String? value) {
    for (final r in Recurrence.values) {
      if (r.wire == value) return r;
    }
    return Recurrence.none;
  }
}

/// Client-side status filter. Maps onto the server's `status` query param
/// (`all` is omitted from the request). Unknown values fall back to `all`.
enum StatusFilter {
  all,
  pending,
  done;

  String get wire => name;

  static StatusFilter fromWire(String? value) {
    for (final s in StatusFilter.values) {
      if (s.wire == value) return s;
    }
    return StatusFilter.all;
  }
}
