/// Root application widget (DESIGN.md §6 `lib/app.dart`).
///
/// Wires the theme (from [ThemeController]) and the go_router instance (from
/// the RouterProvider) into a Material 3 `MaterialApp.router`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'presentation/providers/router.dart';
import 'presentation/providers/theme.dart';
import 'theme.dart';

class TaskflowApp extends ConsumerWidget {
  const TaskflowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeControllerProvider);
    // ADAPT(RouterProvider): generated instance name for
    // `@riverpod class RouterProvider ...` is `routerProviderProvider`
    // (verified against riverpod_generator 4.0.8 output).
    final GoRouter router = ref.watch(routerProviderProvider);

    return MaterialApp.router(
      title: 'Taskflow',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
