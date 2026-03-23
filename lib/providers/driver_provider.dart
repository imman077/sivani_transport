import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/models/driver.dart';

import 'package:sivani_transport/providers/user_provider.dart';
import 'package:sivani_transport/services/firebase_service.dart';

// Stream provider for drivers
final driversStreamProvider = StreamProvider<List<Driver>>((ref) {
  return ref.watch(firebaseServiceProvider).getDrivers();
});

class DriverNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseService _service;
  DriverNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> saveDriver(Driver driver) async {
    state = const AsyncValue.loading();
    try {
      await _service.saveDriver(driver);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteDriver(String id, String name) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteDriver(id, name);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final driverActionProvider = StateNotifierProvider<DriverNotifier, AsyncValue<void>>((ref) {
  return DriverNotifier(ref.watch(firebaseServiceProvider));
});
