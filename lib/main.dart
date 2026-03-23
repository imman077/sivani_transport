import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/core/app_theme.dart';
import 'package:sivani_transport/core/app_router.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:sivani_transport/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDLGz_Q9PRa9RsUximbevGF0J_ARXEitiQ",
        appId: "1:555619822264:web:b4e933d5a80f5228ba624d", // Manual fallback for web
        messagingSenderId: "555619822264",
        projectId: "sivanitransport-89f41",
        storageBucket: "sivanitransport-89f41.firebasestorage.app",
      ),
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  await SystemNotificationService.initialize();
  await SystemNotificationService.requestPermission();
  SystemNotificationService.initForegroundTask();

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
