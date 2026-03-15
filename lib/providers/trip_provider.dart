import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/models/trip.dart';
import 'package:sivani_transport/services/firebase_service.dart';

class TripNotifier extends StateNotifier<List<Trip>> {
  final FirebaseService _firebaseService = FirebaseService();

  TripNotifier() : super([]) {
    _listenToTrips();
  }

  void _listenToTrips() {
    _firebaseService.getTrips().listen((trips) {
      state = trips;
    });
  }

  Future<void> addTrip(Trip trip) async {
    await _firebaseService.saveTrip(trip);
  }

  Future<void> updateTrip(Trip trip) async {
    await _firebaseService.saveTrip(trip);
  }

  Future<void> deleteTrip(String id) async {
    await _firebaseService.deleteTrip(id);
  }
}

final tripProvider = StateNotifierProvider<TripNotifier, List<Trip>>((ref) {
  return TripNotifier();
});
