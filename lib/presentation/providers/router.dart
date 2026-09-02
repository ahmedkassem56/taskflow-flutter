import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/router/app_router.dart';

part 'router.g.dart';

/// The app's go_router instance (DESIGN.md §6), built once from
/// [buildAppRouter]. Consumed by `MaterialApp.router` in `lib/app.dart`.
@Riverpod(keepAlive: true)
class RouterProvider extends _$RouterProvider {
  @override
  GoRouter build() => buildAppRouter(ref);
}
