import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/models/app_user.dart';
import 'package:sivani_transport/services/firebase_service.dart';

class AuthNotifier extends StateNotifier<AppUser?> {
  AuthNotifier() : super(
    AppUser(
      id: 'ADM-001',
      name: 'Immanuvel A',
      phone: '+91 98765 43210',
      email: 'admin@sivanitransport.com',
      password: 'admin',
      role: 'Admin',
      registrationDate: DateTime(2023, 1, 1),
    ),
  );

  final FirebaseService _firebaseService = FirebaseService();

  void login(AppUser user) {
    state = user;
  }

  Future<void> updateProfile(AppUser user) async {
    await _firebaseService.updateUserProfile(user);
    state = user;
  }

  void logout() {
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AppUser?>((ref) {
  return AuthNotifier();
});
