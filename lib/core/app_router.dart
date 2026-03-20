import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sivani_transport/pages/login_page.dart';
import 'package:sivani_transport/pages/main_page.dart';
import 'package:sivani_transport/pages/dashboard_page.dart';
import 'package:sivani_transport/pages/drivers_page.dart';
import 'package:sivani_transport/pages/add_driver_page.dart';
import 'package:sivani_transport/pages/vehicles_page.dart';
import 'package:sivani_transport/pages/trips_page.dart';
import 'package:sivani_transport/pages/add_transporter_page.dart';
import 'package:sivani_transport/pages/transporters_page.dart';
import 'package:sivani_transport/pages/profile_page.dart';
import 'package:sivani_transport/models/transporter.dart';
import 'package:sivani_transport/models/driver.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfilePage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainPage(navigationShell: navigationShell);
      },
      branches: [
        // 0: Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
          ],
        ),
        // 1: Drivers
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/drivers',
              builder: (context, state) => const DriversPage(),
              routes: [
                GoRoute(
                  path: 'add',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final driver = state.extra as Driver?;
                    return AddDriverPage(driver: driver);
                  },
                ),
              ],
            ),
          ],
        ),
        // 2: Vehicles
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/vehicles',
              builder: (context, state) => const VehiclesPage(),
            ),
          ],
        ),
        // 3: Trips
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/trips',
              builder: (context, state) => const TripsPage(key: ValueKey('trips_v1')),
            ),
          ],
        ),
        // 4: Transporters
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transporters',
              builder: (context, state) => const TransportersPage(),
              routes: [
                GoRoute(
                  path: 'add',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final transporter = state.extra as Transporter?;
                    return AddTransporterPage(transporter: transporter);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
