/// Share dialog: create a read/edit link for a list, show the URL, revoke.
///
/// Network work is delegated through callbacks so app-mode wiring stays in
/// the caller (DESIGN.md §5.3 — share ops are awaited, no optimism).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/share_link.dart';

/// One share link created in this dialog session, with revoke support.
class _CreatedShare {
  const _CreatedShare(this.link, this.revoking);

  final ShareLink link;
  final bool revoking;
}

/// Opens the share dialog for [listName].
///
/// [onCreate] is called with the chosen permission and must return the
/// created [ShareLink] (throwing on failure). [onRevoke] deletes an existing
/// link by token. Created links are listed with a copy affordance and a
/// revoke action, mirroring the JS client.
Future<void> showShareDialog(
  BuildContext context, {
  required String listName,
  required Future<ShareLink> Function(String permission) onCreate,
  required Future<void> Function(String token) onRevoke,
}) async {
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return _ShareDialog(
        listName: listName,
        onCreate: onCreate,
        onRevoke: onRevoke,
      );
    },
  );
}

class _ShareDialog extends StatefulWidget {
  const _ShareDialog({
    required this.listName,
    required this.onCreate,
    required this.onRevoke,
  });

  final String listName;
  final Future<ShareLink> Function(String permission) onCreate;
  final Future<void> Function(String token) onRevoke;

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  String _permission = 'edit';
  bool _creating = false;
  List<_CreatedShare> _created = const <_CreatedShare>[];

  Future<void> _create() async {
    setState(() {
      _creating = true;
    });
    try {
      final ShareLink link = await widget.onCreate(_permission);
      if (!mounted) return;
      setState(() {
        _created = <_CreatedShare>[
          ..._created,
          _CreatedShare(link, false),
        ];
        _creating = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _creating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create share link')),
      );
    }
  }

  Future<void> _revoke(ShareLink link) async {
    final int index = _created.indexWhere(
      (_CreatedShare s) => s.link.token == link.token,
    );
    if (index < 0) return;
    setState(() {
      _created[index] = _CreatedShare(link, true);
    });
    try {
      await widget.onRevoke(link.token);
      if (!mounted) return;
      setState(() {
        _created = <_CreatedShare>[
          for (final _CreatedShare s in _created)
            if (s.link.token != link.token) s,
        ];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share link revoked')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _created[index] = _CreatedShare(link, false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not revoke share link')),
      );
    }
  }

  Future<void> _copy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Share list'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Anyone with the link can view "${widget.listName}".',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'read',
                    label: Text('Can view'),
                  ),
                  ButtonSegment<String>(
                    value: 'edit',
                    label: Text('Can edit'),
                  ),
                ],
                selected: <String>{_permission},
                onSelectionChanged: (Set<String> selection) {
                  setState(() {
                    _permission = selection.first;
                  });
                },
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('share-create-button'),
                  onPressed: _creating ? null : _create,
                  icon: _creating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link, size: 18),
                  label: const Text('Create share link'),
                ),
              ),
              if (_created.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 4),
                for (final _CreatedShare entry in _created)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Chip(
                                label: Text(
                                  entry.link.permission == 'edit'
                                      ? 'Can edit'
                                      : 'Can view',
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.link.url,
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy link',
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () => _copy(entry.link.url),
                        ),
                        IconButton(
                          tooltip: 'Revoke link',
                          icon: entry.revoking
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.delete_outline, size: 18),
                          onPressed: entry.revoking
                              ? null
                              : () => _revoke(entry.link),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
