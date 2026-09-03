/// Responsive app shell (DESIGN.md §7).
///
/// Wide layouts (>= 1000 px) get an extended rail column on the left; narrow
/// layouts get an AppBar with a hamburger + drawer hosting the same
/// [ListSidebar]. The AppBar (brand + theme toggle) is always present; the
/// FAB opens the "new task" sheet. Share mode never renders this shell — it
/// has its own page (see share_view.dart), so no FAB leaks into read-only
/// shared lists.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme.dart';
import 'app_view.dart';
import 'widgets/list_sidebar.dart';

/// Width breakpoint: >= [kRailBreakpoint] uses the rail, otherwise drawer.
const double kRailBreakpoint = 1000;

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.dark_mode_outlined;
      case ThemeMode.dark:
        return Icons.light_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  String _themeTooltip(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Switch to dark theme';
      case ThemeMode.dark:
        return 'Switch to light theme';
      case ThemeMode.system:
        return 'Theme: system — switch to light';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeControllerProvider);
    // ADAPT(ThemeController): cycles light -> dark -> system (DESIGN.md §9).
    void cycleTheme() {
      ref.read(themeControllerProvider.notifier).cycleTheme();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= kRailBreakpoint;
        final ColorScheme scheme = Theme.of(context).colorScheme;

        final Widget? rail = wide
            ? Container(
                width: 264,
                color: scheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.check_circle_outline,
                              size: 22, color: scheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Taskflow',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListSidebar(
                        onNavigate: () {
                          // Drawer is not used in wide mode; no-op keeps the
                          // callback contract uniform.
                        },
                      ),
                    ),
                  ],
                ),
              )
            : null;

        final AppBar appBar = AppBar(
          leading: wide
              ? null
              : Builder(
                  builder: (BuildContext context) {
                    return IconButton(
                      key: const Key('drawer-button'),
                      tooltip: 'Open navigation',
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    );
                  },
                ),
          title: Text(
            'Taskflow',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          actions: <Widget>[
            IconButton(
              key: const Key('theme-toggle'),
              tooltip: _themeTooltip(themeMode),
              icon: Icon(_themeIcon(themeMode)),
              onPressed: cycleTheme,
            ),
          ],
        );

        final Widget drawer = Drawer(
          child: SafeArea(
            child: ListSidebar(
              onNavigate: () => Navigator.of(context).pop(),
            ),
          ),
        );

        return Scaffold(
          appBar: appBar,
          drawer: wide ? null : drawer,
          body: Row(
            children: <Widget>[
              ?rail,
              if (wide) const VerticalDivider(width: 1),
              const Expanded(child: AppView()),
            ],
          ),
        );
      },
    );
  }
}
