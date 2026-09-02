/// go_router configuration (DESIGN.md §1, §6, §7).
///
/// Routes:
/// * `/` — [HomeShell] (app mode: All/list views with rail/drawer).
/// * `/share/:token` — [SharePage] (shared list, read or edit per token).
///
/// Share boot support: on web the app may be opened with the share token in
/// the URL *path* (`/share/<token>`) or in the *fragment* (`#/share/<token>`)
/// — the redirect below extracts either and routes to the share page
/// (DESIGN.md §5 "Share boot"). `buildAppRouter` is the single source of
/// route truth consumed by the `RouterProvider` (providers/router.dart).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/features/home/home_shell.dart';
import '../../presentation/features/share/share_view.dart';

/// Extracts a share token from a URL — path (`/share/<token>`) or fragment
/// (`#/share/<token>`). Returns null when the URL carries no share token.
String? shareTokenFromUri(Uri uri) {
  final List<String> segments = uri.pathSegments;
  if (segments.length >= 2 && segments[0] == 'share') {
    final String token = segments[1];
    if (token.isNotEmpty) return token;
  }
  final String fragment = uri.fragment;
  const String prefix = '/share/';
  if (fragment.startsWith(prefix)) {
    final String token = fragment.substring(prefix.length);
    if (token.isNotEmpty) return token;
  }
  return null;
}

/// Builds the app [GoRouter].
///
/// [ref] is provided so providers can integrate route-level state if needed;
/// the router itself stays side-effect free (share loads happen in
/// [SharePage]'s init).
GoRouter buildAppRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      // Boot-time share detection: opening the app with a share URL in the
      // address bar (path or hash fragment) lands on the shared list.
      if (state.matchedLocation == '/') {
        final String? token = shareTokenFromUri(Uri.base);
        if (token != null) {
          return '/share/$token';
        }
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'home',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeShell();
        },
      ),
      GoRoute(
        path: '/share/:token',
        name: 'share',
        builder: (BuildContext context, GoRouterState state) {
          final String token = state.pathParameters['token'] ?? '';
          return SharePage(token: token);
        },
      ),
    ],
  );
}
