/// Taskflow Flutter client entry point.
///
/// Bootstrap (DESIGN.md §6): `ProviderScope` wraps `TaskflowApp`, which
/// renders `MaterialApp.router` with the theme + router providers.
/// SharedPreferences persistence is handled inside the theme/view
/// controllers with an in-memory fallback, so no plugin setup is required
/// here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TaskflowApp()));
}
