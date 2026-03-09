import 'package:flutter/material.dart';
import 'package:sivani_transport/core/app_theme.dart';
import 'package:sivani_transport/pages/login_page.dart';
import 'package:sivani_transport/pages/main_page.dart';

void main() {
  runApp(const SivaniTransportApp());
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
      },
    );
  }
}
