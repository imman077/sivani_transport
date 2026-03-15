import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/models/app_user.dart';
import 'package:sivani_transport/services/firebase_service.dart';

// Create a provider for the Firebase Service
final firebaseServiceProvider = Provider((ref) => FirebaseService());

// Real-time stream of users from Firestore
final userListStreamProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(firebaseServiceProvider).getUsers();
});

class UserNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseService _service;
  UserNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> registerUser(AppUser user) async {
    state = const AsyncValue.loading();
    try {
      await _service.registerUser(user);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Note: Delete functionality should also be added here to be linked with Firebase
}

// Provider to handle the ACTIONS (like adding a user)
final userActionProvider = StateNotifierProvider<UserNotifier, AsyncValue<void>>((ref) {
  return UserNotifier(ref.watch(firebaseServiceProvider));
});

final userSearchProvider = StateProvider<String>((ref) => '');
