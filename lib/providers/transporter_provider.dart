import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/models/transporter.dart';
import 'package:sivani_transport/providers/user_provider.dart';
import 'package:sivani_transport/services/firebase_service.dart';

// Stream provider for transporters
final transportersStreamProvider = StreamProvider<List<Transporter>>((ref) {
  return ref.watch(firebaseServiceProvider).getTransporters();
});

class TransporterNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseService _service;
  TransporterNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> saveTransporter(Transporter transporter) async {
    state = const AsyncValue.loading();
    try {
      await _service.saveTransporter(transporter);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTransporter(String id, String name) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteTransporter(id, name);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final transporterActionProvider = StateNotifierProvider<TransporterNotifier, AsyncValue<void>>((ref) {
  return TransporterNotifier(ref.watch(firebaseServiceProvider));
});
