/// Filter bar: status SegmentedButton + debounced search field.
///
/// The debounce itself is owned by the parent: keystrokes flow up through
/// [onQueryChanged] immediately (so reorder affordances can be gated on
/// non-empty text without waiting), and the fetch layer re-queries on its own
/// 300 ms debounce (DESIGN.md §5.1). Search is hidden entirely in contexts
/// that render no search (e.g. read-only share headers) via [showSearch].
library;

import 'package:flutter/material.dart';

import '../../../../data/models/enums.dart';
import '../../../common/format.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.status,
    required this.onStatusChanged,
    required this.searchController,
    required this.onQueryChanged,
    this.showSearch = true,
  });

  final StatusFilter status;
  final ValueChanged<StatusFilter> onStatusChanged;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final bool showSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: <Widget>[
          SegmentedButton<StatusFilter>(
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll<TextStyle>(
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            segments: <ButtonSegment<StatusFilter>>[
              for (final StatusFilter f in StatusFilter.values)
                ButtonSegment<StatusFilter>(
                  value: f,
                  label: Text(statusLabel(f)),
                ),
            ],
            selected: <StatusFilter>{status},
            onSelectionChanged: (Set<StatusFilter> selection) {
              onStatusChanged(selection.first);
            },
          ),
          if (showSearch) ...<Widget>[
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const Key('filter-search'),
                controller: searchController,
                onChanged: onQueryChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search tasks',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            searchController.clear();
                            onQueryChanged('');
                          },
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
