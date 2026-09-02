/// Display formatting shared by the presentation layer.
///
/// Mirrors the JS client's labels/formatting (todo-app `static/app.js`):
/// short dates like "Sep 5" (+ ", 2026" when not the current year), "Today" /
/// "Overdue" due kinds, integer-safe quantity rendering, and chip labels for
/// priority/recurrence. `due_date` stays a plain `YYYY-MM-DD` string — we
/// compare lexicographically (DESIGN.md §3) and never parse it as a time.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/enums.dart';
import '../../data/services/api_client.dart';
import '../../theme.dart';

/// Local calendar date for "now", formatted `YYYY-MM-DD`.
String todayIso() => DateFormat('yyyy-MM-dd').format(DateTime.now());

/// 'overdue' | 'today' | 'future' — lexicographic compare, no tz math.
String dueKind(String? iso) {
  if (iso == null || iso.isEmpty) return 'future';
  final String today = todayIso();
  if (iso.compareTo(today) < 0) return 'overdue';
  if (iso == today) return 'today';
  return 'future';
}

bool isOverdue(String? iso) => dueKind(iso) == 'overdue';

bool isDueToday(String? iso) => dueKind(iso) == 'today';

/// "Sep 5" or "Sep 5, 2026" (year only when it differs from the current one).
String formatShortDate(String iso) {
  final DateTime parsed = DateTime.parse(iso);
  final String base = DateFormat('MMM d').format(parsed);
  if (parsed.year == DateTime.now().year) return base;
  return '$base, ${parsed.year}';
}

/// JS `dueLabel`: "Today" / "Overdue" / "Due Sep 5".
String dueLabel(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final String kind = dueKind(iso);
  if (kind == 'today') return 'Today';
  if (kind == 'overdue') return 'Overdue';
  return 'Due ${formatShortDate(iso)}';
}

/// JS `fmtQty`: never renders "1.0"; keeps fractions ("0.5").
String formatQuantity(num quantity) {
  if (quantity == quantity.roundToDouble()) {
    return quantity.toInt().toString();
  }
  return quantity.toString();
}

/// Priority display label; `null` for `none`.
String? priorityLabel(Priority priority) {
  switch (priority) {
    case Priority.low:
      return 'Low';
    case Priority.medium:
      return 'Medium';
    case Priority.high:
      return 'High';
    case Priority.none:
      return null;
  }
}

/// Priority chip color; `null` for `none`.
Color? priorityChipColor(Priority priority) => priorityColor(priority.name);

/// Recurrence display label — "Every N days" for custom.
String recurrenceLabel(Recurrence recurrence, int? customInterval) {
  switch (recurrence) {
    case Recurrence.daily:
      return 'Daily';
    case Recurrence.weekly:
      return 'Weekly';
    case Recurrence.monthly:
      return 'Monthly';
    case Recurrence.custom:
      final int n = (customInterval == null || customInterval < 1)
          ? 1
          : customInterval;
      return n == 1 ? 'Every day' : 'Every $n days';
    case Recurrence.none:
      return '';
  }
}

/// Status filter display label.
String statusLabel(StatusFilter status) {
  switch (status) {
    case StatusFilter.all:
      return 'All';
    case StatusFilter.pending:
      return 'Pending';
    case StatusFilter.done:
      return 'Done';
  }
}

/// "3 of 10 done" / "No tasks yet" subtitle, JS `renderShareIdentity` parity.
String progressLabel(int total, int done) {
  if (total == 0) return 'No tasks yet';
  return '$done of $total done';
}

/// Maps a caught error to a user-presentable message.
///
/// Backend errors carry a `detail` string (DESIGN.md §2.2 error rows) which
/// the UI shows verbatim in a SnackBar or error state — never raw exceptions.
String friendlyErrorMessage(Object error, {String fallback = 'Something went wrong'}) {
  if (error is ApiException && error.detail.isNotEmpty) return error.detail;
  return fallback;
}
