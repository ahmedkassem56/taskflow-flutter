import '../models/enums.dart';
import '../models/item_envelope.dart';
import '../models/shared_list.dart';
import '../models/share_link.dart';
import '../models/task_item.dart';
import '../models/task_list.dart';
import '../services/api_client.dart';

/// Thin typed wrapper over [ApiClient] — the only API surface the providers
/// call (DESIGN.md §6). Keeps raw request shapes out of the controllers and
/// gives mutation flows one place to sit. Whitelist enforcement for PATCH
/// bodies lives in [ApiClient.patchItem]/[ApiClient.patchSharedItem].
class TaskflowRepository {
  TaskflowRepository(this._api);

  final ApiClient _api;

  // -- Health -----------------------------------------------------------------

  Future<Map<String, dynamic>> health() => _api.health();

  // -- Lists ------------------------------------------------------------------

  Future<List<TaskList>> fetchLists() => _api.getLists();

  Future<TaskList> createList(String name) => _api.createList(name);

  Future<TaskList> renameList(int id, String name) => _api.renameList(id, name);

  Future<void> deleteList(int id) => _api.deleteList(id);

  // -- Items (app mode) -------------------------------------------------------

  Future<List<TaskItem>> fetchItems({
    int? listId,
    StatusFilter status = StatusFilter.all,
    String? q,
  }) {
    return _api.getItems(listId: listId, status: status, q: q);
  }

  Future<TaskItem> createItem({
    required int listId,
    required String title,
    String? notes,
    Priority priority = Priority.none,
    String? dueDate,
    num quantity = 1,
    Recurrence recurrence = Recurrence.none,
    int? recurrenceInterval,
  }) {
    return _api.createItem(
      listId: listId,
      title: title,
      notes: notes,
      priority: priority,
      dueDate: dueDate,
      quantity: quantity,
      recurrence: recurrence,
      recurrenceInterval: recurrenceInterval,
    );
  }

  /// Applies a partial patch (whitelist-checked by the client).
  Future<ItemEnvelope> patchItem(int id, Map<String, dynamic> fields) {
    return _api.patchItem(id, fields);
  }

  Future<ItemEnvelope> toggleDone(int id, {required bool done}) {
    return _api.patchItem(id, <String, dynamic>{'done': done});
  }

  Future<ItemEnvelope> moveItem(int id, {required String direction}) {
    return _api.patchItem(id, <String, dynamic>{'move': direction});
  }

  Future<ItemEnvelope> moveItemTo(int id, {required int ordinal}) {
    return _api.patchItem(id, <String, dynamic>{'move_to': ordinal});
  }

  Future<void> deleteItem(int id) => _api.deleteItem(id);

  // -- Shares (management) ----------------------------------------------------

  Future<ShareLink> createShare(int listId, {required String permission}) {
    return _api.createShare(listId, permission);
  }

  Future<void> revokeShare(String token) => _api.revokeShare(token);

  // -- Shared lists -----------------------------------------------------------

  Future<SharedList> fetchShared(String token) => _api.getShared(token);

  Future<TaskItem> createSharedItem(
    String token, {
    required String title,
    String? notes,
    Priority priority = Priority.none,
    String? dueDate,
    num quantity = 1,
    Recurrence recurrence = Recurrence.none,
    int? recurrenceInterval,
  }) {
    return _api.createSharedItem(
      token,
      title: title,
      notes: notes,
      priority: priority,
      dueDate: dueDate,
      quantity: quantity,
      recurrence: recurrence,
      recurrenceInterval: recurrenceInterval,
    );
  }

  /// Applies a partial patch on a shared item (whitelist-checked; `list_id`
  /// forbidden by construction).
  Future<ItemEnvelope> patchSharedItem(
    String token,
    int id,
    Map<String, dynamic> fields,
  ) {
    return _api.patchSharedItem(token, id, fields);
  }

  Future<ItemEnvelope> toggleSharedDone(String token, int id,
      {required bool done}) {
    return _api.patchSharedItem(
      token,
      id,
      <String, dynamic>{'done': done},
    );
  }

  Future<ItemEnvelope> moveSharedItem(String token, int id,
      {required String direction}) {
    return _api.patchSharedItem(
      token,
      id,
      <String, dynamic>{'move': direction},
    );
  }

  Future<ItemEnvelope> moveSharedItemTo(String token, int id,
      {required int ordinal}) {
    return _api.patchSharedItem(
      token,
      id,
      <String, dynamic>{'move_to': ordinal},
    );
  }

  Future<void> deleteSharedItem(String token, int id) =>
      _api.deleteSharedItem(token, id);
}
