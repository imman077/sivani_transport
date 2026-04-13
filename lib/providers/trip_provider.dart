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

// Manage a single trip being edited/added
final tripDraftProvider = StateNotifierProvider<TripDraftNotifier, Trip?>((ref) => TripDraftNotifier());

class TripDraftNotifier extends StateNotifier<Trip?> {
  TripDraftNotifier() : super(null);

  void init(Trip? trip) {
    state = trip ?? Trip(
      id: '',
      from: '',
      to: '',
      vehicle: '',
      plate: '',
      driver: '',
      startDate: DateTime.now(),
      status: 'Ongoing',
    );
  }

  void reset() => state = null;

  // Single function to manage all fields
  void updateField({
    String? from,
    String? to,
    List<String>? stops,
    String? vehicle,
    String? driver,
    String? driverId,
    String? transporter,
    String? transporterId,
    DateTime? startDate,
    DateTime? endDate,
    double? startKm,
    double? endKm,
    double? diesel,
    double? initialCash,
    num? transporterAmount,
    num? commission,
    num? driverSalary,
    double? outwardLoads,
    double? returnLoads,
    bool? hasReturn,
    List<Map<String, String>>? expenseList,
    List<Map<String, String>>? paymentList,
    String? status,
  }) {
    if (state == null) return;
    state = state!.copyWith(
      from: from,
      to: to,
      stops: stops,
      vehicle: vehicle,
      driver: driver,
      driverId: driverId,
      transporter: transporter,
      transporterId: transporterId,
      startDate: startDate,
      endDate: endDate,
      startKm: startKm,
      endKm: endKm,
      diesel: diesel,
      initialCash: initialCash,
      transporterAmount: transporterAmount,
      commission: commission,
      driverSalary: driverSalary,
      outwardLoads: outwardLoads,
      returnLoads: returnLoads,
      hasReturn: hasReturn,
      expenseList: expenseList,
      paymentList: paymentList,
      status: status,
    );
  }
}
