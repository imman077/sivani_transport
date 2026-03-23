import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/models/vehicle.dart';
import 'package:sivani_transport/services/firebase_service.dart';

class VehicleNotifier extends StateNotifier<List<Vehicle>> {
  final FirebaseService _firebaseService = FirebaseService();

  VehicleNotifier() : super([]) {
    _listenToVehicles();
  }

  void _listenToVehicles() {
    _firebaseService.getVehicles().listen((vehicles) {
      state = vehicles;
    });
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    await _firebaseService.saveVehicle(vehicle);
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await _firebaseService.saveVehicle(vehicle);
  }

  Future<void> deleteVehicle(String id, String regNumber) async {
    await _firebaseService.deleteVehicle(id, regNumber);
  }
}

final vehicleProvider = StateNotifierProvider<VehicleNotifier, List<Vehicle>>((ref) {
  return VehicleNotifier();
});
