/// List-level actions shared by the sidebar overflow menu and the app-view
/// header popup: rename, delete, share (DESIGN.md §7).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/task_list.dart';
import '../../../common/confirm_dialog.dart';
import '../../../providers/lists.dart';
import '../../share/share_dialog.dart';

/// Prompts for a name and renames the list. Shows errors via SnackBar.
Future<void> renameListFlow(
  BuildContext context,
  WidgetRef ref,
  TaskList list,
) async {
  final String? name = await _promptForName(
    context,
    title: 'Rename list',
    confirmLabel: 'Save',
    hint: 'List name',
    initial: list.name,
  );
  if (name == null || name.trim().isEmpty) return;
  try {
    await ref.read(listsControllerProvider.notifier).renameList(
          list.id,
          name.trim(),
        );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$error')),
    );
  }
}

/// Confirms and deletes the list (deleting the current list returns the app
/// to the All view — handled by the controller).
Future<void> deleteListFlow(
  BuildContext context,
  WidgetRef ref,
  TaskList list,
) async {
  final bool confirmed = await showConfirmDialog(
    context,
    title: 'Delete list?',
    message: '"${list.name}" and its tasks will be permanently deleted.',
  );
  if (!confirmed) return;
  try {
    await ref.read(listsControllerProvider.notifier).deleteList(list.id);
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$error')),
    );
  }
}

/// Opens the share dialog for a list.
Future<void> shareListFlow(
  BuildContext context,
  WidgetRef ref,
  TaskList list,
) async {
  await showShareDialog(
    context,
    listName: list.name,
    onCreate: (String permission) {
      // ADAPT(ListsController): share creation routed through the lists
      // controller so list state can be refreshed afterwards.
      return ref
          .read(listsControllerProvider.notifier)
          .createShare(list.id, permission);
    },
    onRevoke: (String token) {
      // ADAPT(ListsController): revoke share by token.
      return ref.read(listsControllerProvider.notifier).revokeShare(token);
    },
  );
}

/// Prompts for a name; returns the trimmed value or null when cancelled.
Future<String?> _promptForName(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required String hint,
  String? initial,
}) async {
  final TextEditingController controller = TextEditingController(
    text: initial ?? '',
  );
  final String? result = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          key: const Key('list-name-field'),
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          textInputAction: TextInputAction.done,
          onSubmitted: (String value) {
            Navigator.of(dialogContext).pop(value.trim());
          },
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              controller.text.trim(),
            ),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result;
}

/// Prompts for a new list name (sidebar "New list").
Future<void> createListFlow(
  BuildContext context,
  WidgetRef ref,
) async {
  final String? name = await _promptForName(
    context,
    title: 'New list',
    confirmLabel: 'Create',
    hint: 'List name',
  );
  if (name == null || name.trim().isEmpty) return;
  try {
    await ref.read(listsControllerProvider.notifier).createList(name.trim());
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$error')),
    );
  }
}
