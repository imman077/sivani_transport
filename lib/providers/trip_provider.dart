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

  Future<void> addTrip(Trip trip, {String performedBy = 'Admin'}) async {
    await _firebaseService.saveTrip(trip, performedBy: performedBy);
  }

  Future<void> updateTrip(Trip trip, {String performedBy = 'Admin'}) async {
    await _firebaseService.saveTrip(trip, performedBy: performedBy);
  }

  Future<void> deleteTrip(String id, String route) async {
    await _firebaseService.deleteTrip(id, route);
  }
}

final tripProvider = StateNotifierProvider<TripNotifier, List<Trip>>((ref) {
  return TripNotifier();
});
