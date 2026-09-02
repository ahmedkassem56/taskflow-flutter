// Model parsing tests (DESIGN.md §3): timestamps with 'Z'+micros, null
// dates/notes, int vs float quantity, unknown JSON keys ignored, unknown
// enum fallback, due_date preserved as a plain string.

import 'package:flutter_test/flutter_test.dart';

import 'package:taskflow_app/data/models/enums.dart';
import 'package:taskflow_app/data/models/item_envelope.dart';
import 'package:taskflow_app/data/models/shared_list.dart';
import 'package:taskflow_app/data/models/share_link.dart';
import 'package:taskflow_app/data/models/task_item.dart';
import 'package:taskflow_app/data/models/task_list.dart';

import 'fixtures.dart';

Map<String, dynamic> _fullItemJson() => itemJson(
      id: 7,
      listId: 3,
      title: 'Buy milk',
      done: false,
      position: 2,
      priority: 'high',
      notes: '2% please',
      dueDate: '2026-09-05',
      quantity: 2,
      recurrence: 'weekly',
      recurrenceInterval: null,
    );

void main() {
  group('TaskItem.fromJson', () {
    test('parses a full item with snake_case keys and UTC timestamps', () {
      final TaskItem item = TaskItem.fromJson(_fullItemJson());

      expect(item.id, 7);
      expect(item.listId, 3);
      expect(item.title, 'Buy milk');
      expect(item.notes, '2% please');
      expect(item.priority, Priority.high);
      expect(item.dueDate, '2026-09-05');
      expect(item.quantity, 2);
      expect(item.position, 2);
      expect(item.done, isFalse);
      expect(item.recurrence, Recurrence.weekly);
      expect(item.recurrenceInterval, isNull);
      // Timestamps parse as UTC (handles Z + microseconds).
      expect(item.createdAt, DateTime.utc(2026, 9, 2, 10));
      expect(item.updatedAt, DateTime.utc(2026, 9, 2, 10));
      expect(item.createdAt.isUtc, isTrue);
    });

    test('quantity stays num: int for 2, double for 0.5', () {
      final TaskItem intItem =
          TaskItem.fromJson(_fullItemJson()..['quantity'] = 2);
      final TaskItem doubleItem =
          TaskItem.fromJson(_fullItemJson()..['quantity'] = 0.5);

      expect(intItem.quantity, 2);
      expect(intItem.quantity is int, isTrue);
      expect(doubleItem.quantity, 0.5);
      expect(doubleItem.quantity is double, isTrue);
    });

    test('due_date is preserved verbatim as a string (never DateTime)',
        () {
      final TaskItem item = TaskItem.fromJson(_fullItemJson());
      expect(item.dueDate, isA<String>());
      expect(item.dueDate, '2026-09-05');
    });

    test('null notes / due_date / recurrence_interval are nullable', () {
      final TaskItem item = TaskItem.fromJson(_fullItemJson()
        ..['notes'] = null
        ..['due_date'] = null);
      expect(item.notes, isNull);
      expect(item.dueDate, isNull);
      expect(item.recurrenceInterval, isNull);
    });

    test('unknown enum wire values fall back to none (defensive)', () {
      final TaskItem item = TaskItem.fromJson(_fullItemJson()
        ..['priority'] = 'urgent'
        ..['recurrence'] = 'yearly');
      expect(item.priority, Priority.none);
      expect(item.recurrence, Recurrence.none);
    });

    test('unknown JSON keys are ignored on read', () {
      final TaskItem item =
          TaskItem.fromJson(_fullItemJson()..['future_field'] = 'x');
      expect(item.title, 'Buy milk');
    });

    test('copyWith produces an updated copy', () {
      final TaskItem item = TaskItem.fromJson(_fullItemJson());
      final TaskItem done = item.copyWith(done: true);
      expect(done.done, isTrue);
      expect(done.id, item.id);
      expect(identical(item, done), isFalse);
    });

    test('equality is structural', () {
      final TaskItem a = TaskItem.fromJson(_fullItemJson());
      final TaskItem b = TaskItem.fromJson(_fullItemJson());
      expect(a, b);
    });
  });

  group('TaskList.fromJson', () {
    test('parses counts and timestamps', () {
      final TaskList list = TaskList.fromJson(listJson(5, 'Groceries',
          total: 3, pending: 2));
      expect(list.id, 5);
      expect(list.name, 'Groceries');
      expect(list.itemCount, 3);
      expect(list.pendingCount, 2);
      expect(list.createdAt, DateTime.utc(2026, 9, 1, 10));
    });
  });

  group('SharedList.fromJson', () {
    test('parses list + items + permission with canEdit', () {
      final SharedList shared = SharedList.fromJson(<String, dynamic>{
        'list': listJson(5, 'Groceries'),
        'items': <Object>[
          _fullItemJson(),
          itemJson(
              id: 8,
              listId: 5,
              title: 'Eggs',
              done: true,
              position: 3),
        ],
        'permission': 'edit',
      });

      expect(shared.list.id, 5);
      expect(shared.items, hasLength(2));
      expect(shared.items.first.priority, Priority.high);
      expect(shared.canEdit, isTrue);
    });

    test('canEdit is false for read-only shares', () {
      final SharedList shared = SharedList.fromJson(<String, dynamic>{
        'list': listJson(5, 'Groceries'),
        'items': <Object>[],
        'permission': 'read',
      });
      expect(shared.canEdit, isFalse);
    });
  });

  group('ShareLink.fromJson', () {
    test('parses token/permission/url/created_at', () {
      final ShareLink link = ShareLink.fromJson(<String, dynamic>{
        'token': 'abc123',
        'permission': 'edit',
        'url': 'http://127.0.0.1:8000/share/abc123',
        'created_at': iso(4),
      });
      expect(link.token, 'abc123');
      expect(link.permission, 'edit');
      expect(link.url, 'http://127.0.0.1:8000/share/abc123');
      expect(link.createdAt, DateTime.utc(2026, 9, 4, 10));
    });
  });

  group('ItemEnvelope.fromJson', () {
    test('non-move PATCH envelope: {item, spawned:null}', () {
      final ItemEnvelope envelope =
          ItemEnvelope.fromJson(envelopeJson(_fullItemJson()));
      expect(envelope.item.id, 7);
      expect(envelope.spawned, isNull);
      expect(envelope.swapped, isNull);
    });

    test('toggle envelope with a spawned occurrence', () {
      final Map<String, dynamic> spawnedJson = itemJson(
          id: 99, listId: 3, title: 'Buy milk', done: false, position: 0);
      final ItemEnvelope envelope =
          ItemEnvelope.fromJson(envelopeJson(_fullItemJson(), spawned: spawnedJson));
      expect(envelope.spawned, isNotNull);
      expect(envelope.spawned!.id, 99);
      expect(envelope.spawned!.done, isFalse);
    });

    test('move envelope: {item, swapped} (no spawned key)', () {
      final Map<String, dynamic> swappedJson = itemJson(
          id: 8, listId: 3, title: 'Eggs', done: false, position: 1);
      final ItemEnvelope envelope = ItemEnvelope.fromJson(<String, dynamic>{
        'item': _fullItemJson(),
        'swapped': swappedJson,
      });
      expect(envelope.swapped, isNotNull);
      expect(envelope.swapped!.id, 8);
      expect(envelope.spawned, isNull);
    });
  });

  group('enums', () {
    test('wire values are lowercase names', () {
      expect(Priority.high.wire, 'high');
      expect(Recurrence.custom.wire, 'custom');
      expect(StatusFilter.pending.wire, 'pending');
    });

    test('fromWire round-trips and falls back', () {
      expect(Priority.fromWire('low'), Priority.low);
      expect(Priority.fromWire('urgent'), Priority.none);
      expect(Priority.fromWire(null), Priority.none);
      expect(Recurrence.fromWire('daily'), Recurrence.daily);
      expect(Recurrence.fromWire('bogus'), Recurrence.none);
      expect(StatusFilter.fromWire('done'), StatusFilter.done);
      expect(StatusFilter.fromWire('??'), StatusFilter.all);
      expect(StatusFilter.fromWire(null), StatusFilter.all);
    });
  });
}
