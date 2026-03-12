import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/core/app_theme.dart';
import 'package:sivani_transport/pages/login_page.dart';
import 'package:sivani_transport/pages/main_page.dart';
import 'package:sivani_transport/pages/dashboard_page.dart';
import 'package:sivani_transport/pages/drivers_page.dart';
import 'package:sivani_transport/pages/vehicles_page.dart';
import 'package:sivani_transport/pages/trips_page.dart';
import 'package:sivani_transport/pages/profile_page.dart';

void main() {
  runApp(const ProviderScope(child: SivaniTransportApp()));
}

class SivaniTransportApp extends StatelessWidget {
  const SivaniTransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sivani Transport',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/main': (context) => const MainPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/drivers': (context) => const DriversPage(),
        '/vehicles': (context) => const VehiclesPage(),
        '/trips': (context) => const TripsPage(),
        '/profile': (context) => const ProfilePage(),
      },
      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
  }
}
