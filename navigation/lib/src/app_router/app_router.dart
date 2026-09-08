import 'package:features/features.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

Page<dynamic> _fade(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation, Widget child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class AppRouter {
  GoRouter get router => _router;

  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  final GoRouter _router = GoRouter(
    navigatorKey: _navigatorKey,
    initialLocation: '/menu',
    routes: <RouteBase>[
      GoRoute(
        path: '/menu',
        name: 'menu',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fade(context, state, const MenuScreen()),
      ),
      GoRoute(
        path: '/game',
        name: 'game',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fade(context, state, const GameScreen()),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fade(context, state, const SettingsScreen()),
      ),
    ],
  );
}
