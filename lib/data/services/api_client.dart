import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config.dart';
import '../models/enums.dart';
import '../models/item_envelope.dart';
import '../models/shared_list.dart';
import '../models/share_link.dart';
import '../models/task_item.dart';
import '../models/task_list.dart';

/// Error surfaced to the UI for every failed request (DESIGN.md §4).
///
/// `detail` is the backend's `{"detail": "<string>"}` payload shown verbatim
/// in a SnackBar / error state — never a raw exception. Transport failures
/// (timeout / unreachable) carry `status == 0` with a connection message.
class ApiException implements Exception {
  const ApiException(this.status, this.detail);

  final int status;
  final String detail;

  @override
  String toString() => 'ApiException($status): $detail';
}

/// Shared transport-failure message (DESIGN.md §4).
const String apiUnreachableMessage = 'Cannot reach the server. Check your connection.';

/// HTTP client for the Taskflow backend (DESIGN.md §4).
///
/// One method per endpoint in the §2.2 table. Request bodies are built from
/// strict whitelists (never echo `id`/`position`/timestamps/counts — the
/// backend is `extra="forbid"` and rejects them with 422). `http.Client` is
/// injectable (`http/testing` MockClient in tests).
class ApiClient {
  ApiClient(String baseUrl, {http.Client? client})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;

  final http.Client _client;
  final String _baseUrl;

  static const int _noContent = 204;

  /// Allowed keys in a PATCH to `/api/items/{id}` (ItemPatch schema).
  static const Set<String> patchWhitelist = <String>{
    'title',
    'notes',
    'priority',
    'due_date',
    'quantity',
    'recurrence',
    'recurrence_interval',
    'done',
    'move',
    'move_to',
    'list_id',
  };

  /// Allowed keys in a PATCH to `/api/shared/{token}/items/{id}`
  /// (SharedItemPatch schema — `list_id` is forbidden by construction).
  static const Set<String> sharedPatchWhitelist = <String>{
    'title',
    'notes',
    'priority',
    'due_date',
    'quantity',
    'recurrence',
    'recurrence_interval',
    'done',
    'move',
    'move_to',
  };

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$_baseUrl$path').replace(
      queryParameters:
          (query == null || query.isEmpty) ? null : query,
    );
  }

  /// Sends [method] to [path] and returns the decoded JSON body (or null for
  /// empty/204 responses). Non-2xx responses throw [ApiException] carrying
  /// the backend `detail` string. Transport errors map to
  /// `ApiException(0, apiUnreachableMessage)`.
  Future<Object?> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final Uri uri = _uri(path, query);
    http.Response response;
    try {
      final Map<String, String> headers = <String, String>{
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
      };
      final String? encoded = body == null ? null : jsonEncode(body);
      response = switch (method) {
        'GET' => await _client
            .get(uri, headers: headers)
            .timeout(requestTimeout),
        'POST' => await _client
            .post(uri, headers: headers, body: encoded)
            .timeout(requestTimeout),
        'PATCH' => await _client
            .patch(uri, headers: headers, body: encoded)
            .timeout(requestTimeout),
        _ => await _client
            .delete(uri, headers: headers)
            .timeout(requestTimeout),
      };
    } on TimeoutException {
      throw const ApiException(0, apiUnreachableMessage);
    } on http.ClientException {
      throw const ApiException(0, apiUnreachableMessage);
    }

    final bool success =
        response.statusCode >= 200 && response.statusCode < 300;

    // 204 (and any other empty body) is never decoded.
    if (response.statusCode == _noContent || response.body.isEmpty) {
      if (success) return null;
      throw ApiException(
        response.statusCode,
        'Request failed (${response.statusCode})',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }
    if (success) return decoded;

    throw ApiException(response.statusCode, _detailOf(decoded, response.statusCode));
  }

  static String _detailOf(Object? decoded, int status) {
    if (decoded is Map<String, dynamic>) {
      final Object? detail = decoded['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    }
    return 'Request failed ($status)';
  }

  static Map<String, dynamic> _asObject(Object? decoded, String what) {
    final Object? value = decoded;
    if (value is Map<String, dynamic>) return value;
    throw ApiException(0, 'Unexpected response for $what');
  }

  static List<dynamic> _asList(Object? decoded, String what) {
    final Object? value = decoded;
    if (value is List<dynamic>) return value;
    throw ApiException(0, 'Unexpected response for $what');
  }

  // ---------------------------------------------------------------------------
  // Health
  // ---------------------------------------------------------------------------

  /// `GET /api/health` → `{"status": "ok", "database": "ok"}`.
  Future<Map<String, dynamic>> health() async {
    return _asObject(await _request('GET', '/api/health'), 'health');
  }

  // ---------------------------------------------------------------------------
  // Lists
  // ---------------------------------------------------------------------------

  /// `GET /api/lists` → `[List, ...]` (name COLLATE NOCASE).
  Future<List<TaskList>> getLists() async {
    return _asList(await _request('GET', '/api/lists'), 'lists')
        .map((Object? e) => TaskList.fromJson(e! as Map<String, dynamic>))
        .toList();
  }

  /// `POST /api/lists` (201) — body is the single whitelist key `name`.
  Future<TaskList> createList(String name) async {
    return TaskList.fromJson(
      _asObject(
        await _request('POST', '/api/lists', body: <String, dynamic>{'name': name}),
        'list',
      ),
    );
  }

  /// `PATCH /api/lists/{id}` (rename) — body is the single whitelist key
  /// `name`.
  Future<TaskList> renameList(int id, String name) async {
    return TaskList.fromJson(
      _asObject(
        await _request(
          'PATCH',
          '/api/lists/$id',
          body: <String, dynamic>{'name': name},
        ),
        'list',
      ),
    );
  }

  /// `DELETE /api/lists/{id}` → 204 (never decoded).
  Future<void> deleteList(int id) async {
    await _request('DELETE', '/api/lists/$id');
  }

  // ---------------------------------------------------------------------------
  // Items (app mode)
  // ---------------------------------------------------------------------------

  /// `GET /api/items` with server-side filters (DESIGN.md §5.1):
  /// * `list_id` only when a specific list view is active (omitted = All),
  /// * `status` only when ≠ `all`,
  /// * `q` only when non-empty.
  /// Response is the canonical `(done, position, id)` order; an unknown
  /// `list_id` yields `200 []`, never 404.
  Future<List<TaskItem>> getItems({
    int? listId,
    StatusFilter status = StatusFilter.all,
    String? q,
  }) async {
    final String? trimmed = q?.trim();
    final Map<String, String> query = <String, String>{
      if (listId != null) 'list_id': '$listId',
      if (status != StatusFilter.all) 'status': status.wire,
      if (trimmed != null && trimmed.isNotEmpty) 'q': trimmed,
    };
    return _asList(await _request('GET', '/api/items', query: query), 'items')
        .map((Object? e) => TaskItem.fromJson(e! as Map<String, dynamic>))
        .toList();
  }

  /// `POST /api/items` (201) → bare Item (no envelope). Body is the create
  /// whitelist: `list_id`, `title`, `notes`, `priority`, `due_date`,
  /// `quantity`, `recurrence`, `recurrence_interval` — nothing else.
  Future<TaskItem> createItem({
    required int listId,
    required String title,
    String? notes,
    Priority priority = Priority.none,
    String? dueDate,
    num quantity = 1,
    Recurrence recurrence = Recurrence.none,
    int? recurrenceInterval,
  }) async {
    return TaskItem.fromJson(
      _asObject(
        await _request(
          'POST',
          '/api/items',
          body: _createBody(
            title: title,
            notes: notes,
            priority: priority,
            dueDate: dueDate,
            quantity: quantity,
            recurrence: recurrence,
            recurrenceInterval: recurrenceInterval,
          )..['list_id'] = listId,
        ),
        'item',
      ),
    );
  }

  /// `PATCH /api/items/{id}` → `{item, spawned}` (non-move) or
  /// `{item, swapped}` (`move`). [fields] must be a whitelist of changed
  /// keys only (see [patchWhitelist]) — server-owned fields
  /// (`id`, `position`, timestamps) throw [ArgumentError] here.
  Future<ItemEnvelope> patchItem(int id, Map<String, dynamic> fields) async {
    _assertPatchFields(fields, patchWhitelist);
    return ItemEnvelope.fromJson(
      _asObject(
        await _request('PATCH', '/api/items/$id', body: fields),
        'item envelope',
      ),
    );
  }

  /// `DELETE /api/items/{id}` → 204.
  Future<void> deleteItem(int id) async {
    await _request('DELETE', '/api/items/$id');
  }

  // ---------------------------------------------------------------------------
  // Shares (management)
  // ---------------------------------------------------------------------------

  /// `POST /api/lists/{id}/shares` (201) → ShareLink
  /// (`{token, permission, url, created_at}` — no list_id key).
  Future<ShareLink> createShare(int listId, String permission) async {
    return ShareLink.fromJson(
      _asObject(
        await _request(
          'POST',
          '/api/lists/$listId/shares',
          body: <String, dynamic>{'permission': permission},
        ),
        'share link',
      ),
    );
  }

  /// `DELETE /api/shares/{token}` → 204.
  Future<void> revokeShare(String token) async {
    await _request('DELETE', '/api/shares/$token');
  }

  // ---------------------------------------------------------------------------
  // Shared lists
  // ---------------------------------------------------------------------------

  /// `GET /api/shared/{token}` → `{list, items, permission}` (all items, no
  /// status/q params exist server-side).
  Future<SharedList> getShared(String token) async {
    return SharedList.fromJson(
      _asObject(await _request('GET', '/api/shared/$token'), 'shared list'),
    );
  }

  /// `POST /api/shared/{token}/items` (201) → bare Item. Same create
  /// whitelist as app mode minus `list_id` (forbidden on shared writes).
  Future<TaskItem> createSharedItem(
    String token, {
    required String title,
    String? notes,
    Priority priority = Priority.none,
    String? dueDate,
    num quantity = 1,
    Recurrence recurrence = Recurrence.none,
    int? recurrenceInterval,
  }) async {
    return TaskItem.fromJson(
      _asObject(
        await _request(
          'POST',
          '/api/shared/$token/items',
          body: _createBody(
            title: title,
            notes: notes,
            priority: priority,
            dueDate: dueDate,
            quantity: quantity,
            recurrence: recurrence,
            recurrenceInterval: recurrenceInterval,
          ),
        ),
        'item',
      ),
    );
  }

  /// `PATCH /api/shared/{token}/items/{id}` → envelope. [fields] must be a
  /// whitelist of changed keys only (see [sharedPatchWhitelist]) and must
  /// never contain `list_id`.
  Future<ItemEnvelope> patchSharedItem(
    String token,
    int id,
    Map<String, dynamic> fields,
  ) async {
    _assertPatchFields(fields, sharedPatchWhitelist);
    return ItemEnvelope.fromJson(
      _asObject(
        await _request('PATCH', '/api/shared/$token/items/$id', body: fields),
        'item envelope',
      ),
    );
  }

  /// `DELETE /api/shared/{token}/items/{id}` → 204.
  Future<void> deleteSharedItem(String token, int id) async {
    await _request('DELETE', '/api/shared/$token/items/$id');
  }

  // ---------------------------------------------------------------------------
  // Whitelist body builders
  // ---------------------------------------------------------------------------

  /// Create-request body — the create-only whitelist (DESIGN.md §4). Never
  /// includes server-owned fields. `notes`/`due_date`/`recurrence_interval`
  /// are included as null when unset (legal on create); the caller must pass
  /// a non-null [recurrenceInterval] when [recurrence] is `custom`.
  static Map<String, dynamic> _createBody({
    required String title,
    String? notes,
    required Priority priority,
    String? dueDate,
    required num quantity,
    required Recurrence recurrence,
    int? recurrenceInterval,
  }) {
    if (recurrence == Recurrence.custom && recurrenceInterval == null) {
      throw ArgumentError(
        'recurrenceInterval is required when recurrence is custom',
      );
    }
    if (recurrence != Recurrence.custom && recurrenceInterval != null) {
      throw ArgumentError(
        'recurrenceInterval must be null unless recurrence is custom',
      );
    }
    return <String, dynamic>{
      'title': title,
      'notes': notes,
      'priority': priority.wire,
      'due_date': dueDate,
      'quantity': quantity,
      'recurrence': recurrence.wire,
      'recurrence_interval': recurrenceInterval,
    };
  }

  static void _assertPatchFields(
    Map<String, dynamic> fields,
    Set<String> whitelist,
  ) {
    for (final String key in fields.keys) {
      if (!whitelist.contains(key)) {
        throw ArgumentError(
          'Field "$key" is not a valid PATCH field '
          '(allowed: ${whitelist.join(', ')})',
        );
      }
    }
    if (fields.isEmpty) {
      throw ArgumentError('PATCH body must not be empty');
    }
  }
}
