import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sivani_transport/pages/login_page.dart';
import 'package:sivani_transport/pages/main_page.dart';
import 'package:sivani_transport/pages/dashboard_page.dart';
import 'package:sivani_transport/pages/drivers_page.dart';
import 'package:sivani_transport/pages/vehicles_page.dart';
import 'package:sivani_transport/pages/trips_page.dart';
import 'package:sivani_transport/pages/profile_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainPage(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/drivers',
              builder: (context, state) => const DriversPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/vehicles',
              builder: (context, state) => const VehiclesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/trips',
              builder: (context, state) => const TripsPage(key: ValueKey('trips_v1')),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
