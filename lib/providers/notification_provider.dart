import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/models/app_notification.dart';
import 'package:sivani_transport/providers/auth_provider.dart';
import 'package:sivani_transport/services/firebase_service.dart';

final notificationProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value([]);
  
  final role = user.role == 'Driver' ? 'Driver' : 'Admin';
  return FirebaseService().getNotifications(role, user.id);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notes = ref.watch(notificationProvider).value ?? [];
  return notes.where((n) => !n.isRead).length;
});
