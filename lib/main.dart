import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/core/app_theme.dart';
import 'package:sivani_transport/core/app_router.dart';

void main() {
  usePathUrlStrategy();
  runApp(const ProviderScope(child: SivaniTransportApp()));
}

class SivaniTransportApp extends StatelessWidget {
  const SivaniTransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sivani Transport',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: goRouter,
    );
  }
}
