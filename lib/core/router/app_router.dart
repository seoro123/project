import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/auth_gate.dart';
import '../../features/feed/presentation/screens/pinterest_home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      if (state.uri.queryParameters.containsKey('error') ||
          state.uri.fragment.contains('error=')) {
        return '/';
      }

      if (state.uri.path.isEmpty) {
        return '/';
      }

      return null;
    },
    errorBuilder: (BuildContext context, GoRouterState state) {
      return const AuthGate(child: PinterestHomeScreen());
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const AuthGate(child: PinterestHomeScreen());
        },
      ),
    ],
  );
});
