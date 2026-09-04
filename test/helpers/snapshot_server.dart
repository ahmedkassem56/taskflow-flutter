// Shared test harness: a mock backend with REAL server semantics.
//
// Why this exists: the app's production bugs (add-flicker, delete-delay,
// rename-revert) were all ONE class — a fetch that STARTED before a mutation
// committed but DELIVERED after, carrying pre-commit data (SQLite/WAL serves
// each reader a snapshot from when its read began). Naive mocks return
// "current truth" instantly, so they can never reproduce that.
//
// SnapshotServer mirrors the real todo-app API (position-0 inserts, done-group
// ordering, counts, toggle envelope with spawned, move_to ordinals, shares)
// and computes each response body AT REQUEST ARRIVAL, then holds delivery
// until a gate/latency releases it. A mutation that commits between arrival
// and release therefore leaves the in-flight response carrying the OLD state —
// exactly like the real server. Tests use gates to interleave deterministically.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

String _iso(DateTime dt) => dt.toUtc().toIso8601String().replaceFirst(
    RegExp(r'\.\d+'), ''); // server format: no micros

class Row {
  Row(this.data);
  Map<String, dynamic> data;
}

class SnapshotServer {
  SnapshotServer() {
    _seed();
  }

  // -- server state ----------------------------------------------------------
  final List<Map<String, dynamic>> lists = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> shares = <Map<String, dynamic>>[];
  int _nextListId = 1;
  int _nextItemId = 1;
  int _nextShare = 1;
  final DateTime _epoch = DateTime.utc(2026, 9, 1);

  // -- behavior knobs --------------------------------------------------------
  /// Global latency applied to every request before the response is delivered.
  Duration latency = Duration.zero;

  /// When non-null, EVERY request awaits this gate before delivering (body is
  /// already computed at arrival — so state mutated while the gate is held is
  /// NOT reflected). Tests complete it to release.
  Completer<void>? gate;

  /// Server commit lag (models the real backend, which commits in the
  /// FastAPI dependency teardown AFTER the response is sent). Mutations
  /// schedule their state change this far in the future, so a request that
  /// arrives right after a mutation's response still reads PRE-COMMIT state —
  /// the exact snapshot race that broke create/rename/delete on the device.
  /// Zero keeps behavior instant (existing tests unchanged).
  Duration commitLag = Duration.zero;

  void _apply(void Function() mutation) {
    if (commitLag > Duration.zero) {
      Future<void>.delayed(commitLag, mutation);
    } else {
      mutation();
    }
  }

  /// One-shot holds: the next matching GET is held until the returned
  /// completer is completed. Keyed by e.g. 'GET /api/lists', 'GET /api/items'.
  final Map<String, Completer<void>> _holds = <String, Completer<void>>{};

  /// Fail-once rules: 'METHOD path' → throws HTTP 500 when hit next.
  final List<String> _failOnce = <String>[];

  /// Full request log for assertions: 'METHOD path'.
  final List<String> log = <String>[];

  Completer<void> holdNext(String methodPath) {
    final Completer<void> c = Completer<void>();
    _holds[methodPath] = c;
    return c;
  }

  void failNext(String methodPath) => _failOnce.add(methodPath);

  // -- seeding helpers -------------------------------------------------------
  Map<String, dynamic> addList(String name) {
    final int id = _nextListId++;
    final String now = _iso(_epoch);
    final Map<String, dynamic> l = <String, dynamic>{
      'id': id, 'name': name, 'created_at': now, 'updated_at': now,
    };
    lists.add(l);
    return l;
  }

  Map<String, dynamic> addItem(int listId, String title,
      {bool done = false, String recurrence = 'none', int position = 0}) {
    final int id = _nextItemId++;
    final String now = _iso(_epoch);
    final Map<String, dynamic> i = <String, dynamic>{
      'id': id, 'list_id': listId, 'title': title, 'notes': null,
      'priority': 'none', 'due_date': null, 'quantity': 1, 'position': position,
      'done': done, 'recurrence': recurrence, 'recurrence_interval': null,
      'created_at': now, 'updated_at': now,
    };
    items.add(i);
    return i;
  }

  Map<String, dynamic> addShare(int listId, String permission) {
    final String token = 'tok${_nextShare++}';
    final Map<String, dynamic> s = <String, dynamic>{
      'token': token, 'list_id': listId, 'permission': permission,
      'created_at': _iso(_epoch),
    };
    shares.add(s);
    return s;
  }

  void _seed() {
    // Two lists, three items (one done), one share — tests can clear/extend.
    addList('Groceries');
    addList('Work');
    addItem(1, 'Milk');
    addItem(1, 'Eggs');
    addItem(1, 'Bread', done: true, position: 2);
    addItem(2, 'Report');
    addShare(2, 'edit');
  }

  // -- canonical ordering (mirrors server) -----------------------------------
  List<Map<String, dynamic>> _canonical(Iterable<Map<String, dynamic>> rows) {
    final List<Map<String, dynamic>> out = List<Map<String, dynamic>>.of(rows);
    out.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final bool ad = a['done'] as bool, bd = b['done'] as bool;
      if (ad != bd) return ad ? 1 : -1; // pending first
      final int ap = (a['position'] as num).toInt();
      final int bp = (b['position'] as num).toInt();
      if (ap != bp) return ap.compareTo(bp);
      return (a['id'] as int).compareTo(b['id'] as int);
    });
    return out;
  }

  int _pendingCount(int listId) =>
      items.where((Map<String, dynamic> i) =>
          i['list_id'] == listId && !(i['done'] as bool)).length;

  Map<String, dynamic> _listJson(Map<String, dynamic> l) {
    final int id = l['id'] as int;
    return <String, dynamic>{
      'id': id, 'name': l['name'],
      'item_count': items.where((i) => i['list_id'] == id).length,
      'pending_count': _pendingCount(id),
      'created_at': l['created_at'], 'updated_at': l['updated_at'],
    };
  }

  // -- the request handler ---------------------------------------------------
  Future<http.Response> handle(http.Request r) async {
    final String methodPath = '${r.method} ${r.url.path}';
    // Log with the query string so tests can assert server-side filters
    // (list_id/status/q) actually reached the wire.
    final String query = r.url.query;
    log.add(query.isEmpty ? methodPath : '$methodPath?$query');
    // Compute the response body NOW (snapshot at arrival).
    final http.Response? body = _compute(r);
    // Deliver later per knobs (state may have moved on — response stays stale).
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    final Completer<void>? hold = _holds.remove(methodPath);
    if (hold != null) await hold.future;
    final Completer<void>? gateAll = gate;
    if (gateAll != null) await gateAll.future;
    if (_failOnce.contains(methodPath)) {
      _failOnce.remove(methodPath);
      return http.Response('{"detail":"boom"}', 500,
          headers: <String, String>{'content-type': 'application/json'});
    }
    return body!;
  }

  http.Response _json(Object b, [int s = 200]) => http.Response(jsonEncode(b), s,
      headers: <String, String>{'content-type': 'application/json'});
  http.Response _noContent() => http.Response('', 204);

  http.Response? _compute(http.Request r) {
    final String m = r.method;
    final String p = r.url.path;
    final Map<String, String> q = r.url.queryParameters;

    // -- lists -------------------------------------------------------------
    if (m == 'GET' && p == '/api/lists') {
      return _json(<Object>[
        for (final Map<String, dynamic> l in lists) _listJson(l)
      ]);
    }
    if (m == 'POST' && p == '/api/lists') {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      final Map<String, dynamic> l = addList(body['name'] as String);
      return _json(_listJson(l), 201);
    }
    final RegExpMatch? listMatch = RegExp(r'^/api/lists/(\d+)$').firstMatch(p);
    if (listMatch != null) {
      final int id = int.parse(listMatch.group(1)!);
      final Map<String, dynamic>? l =
          lists.where((x) => x['id'] == id).firstOrNull;
      if (l == null) {
        return _json(<String, dynamic>{'detail': 'Not Found'}, 404);
      }
      if (m == 'PATCH') {
        final name = (jsonDecode(r.body) as Map<String, dynamic>)['name'];
        if (name is String) {
          l['name'] = name;
          l['updated_at'] = _iso(_epoch.add(Duration(seconds: _nextItemId)));
        }
        return _json(_listJson(l));
      }
      if (m == 'DELETE') {
        lists.removeWhere((x) => x['id'] == id);
        items.removeWhere((x) => x['list_id'] == id);
        shares.removeWhere((x) => x['list_id'] == id);
        return _noContent();
      }
    }

    // -- items --------------------------------------------------------------
    if (m == 'GET' && p == '/api/items') {
      Iterable<Map<String, dynamic>> out = items;
      final String? listId = q['list_id'];
      if (listId != null) {
        out = out.where((i) => i['list_id'] == int.parse(listId));
      }
      final String? status = q['status'];
      if (status == 'pending') {
        out = out.where((i) => !(i['done'] as bool));
      } else if (status == 'done') {
        out = out.where((i) => i['done'] as bool);
      }
      final String? search = q['q'];
      if (search != null && search.isNotEmpty) {
        final String needle = search.toLowerCase();
        out = out.where((i) =>
            (i['title'] as String).toLowerCase().contains(needle) ||
            ((i['notes'] as String?) ?? '').toLowerCase().contains(needle));
      }
      return _json(<Object>[..._canonical(out)]);
    }
    if (m == 'POST' && p == '/api/items') {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      final int listId = body['list_id'] as int;
      // New item at position 0; shift existing same-list items up.
      for (final Map<String, dynamic> i in items) {
        if (i['list_id'] == listId) {
          i['position'] = (i['position'] as num).toInt() + 1;
        }
      }
      final Map<String, dynamic> created = addItem(listId,
          body['title'] as String,
          recurrence: (body['recurrence'] as String?) ?? 'none');
      if (body['notes'] != null) created['notes'] = body['notes'];
      return _json(created, 201);
    }
    final RegExpMatch? itemMatch = RegExp(r'^/api/items/(\d+)$').firstMatch(p);
    if (itemMatch != null && m != 'GET') {
      final int id = int.parse(itemMatch.group(1)!);
      final Map<String, dynamic>? i =
          items.where((x) => x['id'] == id).firstOrNull;
      if (i == null) {
        return _json(<String, dynamic>{'detail': 'Not Found'}, 404);
      }
      if (m == 'DELETE') {
        _apply(() => items.removeWhere((x) => x['id'] == id));
        return _noContent();
      }
      if (m == 'PATCH') {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        if (body.containsKey('done')) {
          final bool done = body['done'] as bool;
          i['done'] = done;
          Map<String, dynamic>? spawned;
          if (done && i['recurrence'] != 'none') {
            // Spawn a repeat: fresh pending copy at top of its list.
            spawned = addItem(i['list_id'] as int, i['title'] as String,
                recurrence: i['recurrence'] as String, position: 0);
            for (final Map<String, dynamic> o in items) {
              if (o['list_id'] == i['list_id'] && o != spawned &&
                  !(o['done'] as bool)) {
                o['position'] = (o['position'] as num).toInt() + 1;
              }
            }
          }
          return _json(<String, dynamic>{
            'item': i,
            'spawned': ?spawned,
          });
        }
        if (body.containsKey('move_to')) {
          final int k = body['move_to'] as int;
          // Move within the item's done-group by ordinal.
          final bool done = i['done'] as bool;
          final List<Map<String, dynamic>> group = _canonical(items)
              .where((x) =>
                  x['list_id'] == i['list_id'] && x['done'] == done)
              .toList();
          final int oldIdx = group.indexWhere((x) => x['id'] == id);
          group.removeAt(oldIdx);
          final int clamped = min(max(k, 0), group.length);
          group.insert(clamped, i);
          for (int n = 0; n < group.length; n++) {
            group[n]['position'] = n;
          }
          return _json(<String, dynamic>{'item': i});
        }
        // Field merge (whitelist)
        for (final String key in <String>[
          'title', 'notes', 'priority', 'due_date', 'quantity',
          'recurrence', 'recurrence_interval',
        ]) {
          if (body.containsKey(key)) i[key] = body[key];
        }
        i['updated_at'] = _iso(_epoch.add(Duration(seconds: _nextItemId)));
        return _json(<String, dynamic>{'item': i});
      }
    }

    // -- shares -------------------------------------------------------------
    final RegExpMatch? shareCreate =
        RegExp(r'^/api/lists/(\d+)/shares$').firstMatch(p);
    if (shareCreate != null && m == 'POST') {
      final int listId = int.parse(shareCreate.group(1)!);
      final String permission =
          (jsonDecode(r.body) as Map<String, dynamic>)['permission'] as String;
      final Map<String, dynamic> s = addShare(listId, permission);
      return _json(<String, dynamic>{
        'token': s['token'], 'list_id': listId, 'permission': permission,
        'created_at': s['created_at'],
      }, 201);
    }
    final RegExpMatch? shareDel = RegExp(r'^/api/shares/([^/]+)$').firstMatch(p);
    if (shareDel != null && m == 'DELETE') {
      final String token = shareDel.group(1)!;
      shares.removeWhere((x) => x['token'] == token);
      return _noContent();
    }
    if (m == 'GET' && p.startsWith('/api/shared/')) {
      final String token = p.substring('/api/shared/'.length);
      if (p.endsWith('/items')) {
        final Map<String, dynamic>? s =
            shares.where((x) => x['token'] == token).firstOrNull;
        if (s == null) {
          return _json(<String, dynamic>{'detail': 'Not Found'}, 404);
        }
        return _json(<Object>[
          ..._canonical(items.where(
              (i) => i['list_id'] == s['list_id']))
        ]);
      }
      final Map<String, dynamic>? s =
          shares.where((x) => x['token'] == token).firstOrNull;
      if (s == null) {
        return _json(<String, dynamic>{'detail': 'Not Found'}, 404);
      }
      final Map<String, dynamic>? l =
          lists.where((x) => x['id'] == s['list_id']).firstOrNull;
      return _json(<String, dynamic>{
        'list': _listJson(l!),
        'permission': s['permission'],
      });
    }
    if (m == 'GET' && p == '/api/health') {
      return _json(<String, dynamic>{'status': 'ok', 'database': 'ok'});
    }
    return _json(<String, dynamic>{'detail': 'Not Found'}, 404);
  }
}
