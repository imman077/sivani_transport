import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/models/vehicle.dart';

class VehicleNotifier extends StateNotifier<List<Vehicle>> {
  VehicleNotifier() : super([
    Vehicle(
      id: '1',
      model: 'Mercedes-Benz Sprinter',
      regNumber: 'ABC-1234',
      driver: 'Johnathan Miller',
      fuelType: 'Diesel',
      status: 'Busy',
      statusColor: Colors.redAccent,
      isAvailable: false,
      image: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&q=80',
      capacity: 2.5,
    ),
    Vehicle(
      id: '2',
      model: 'Volvo FH16 Globetrotter',
      regNumber: 'XYZ-5678',
      driver: 'Sarah Thompson',
      fuelType: 'Diesel',
      status: 'Active',
      statusColor: Colors.green,
      isAvailable: true,
      image: 'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?w=800&q=80',
      capacity: 15.0,
    ),
    Vehicle(
      id: '3',
      model: 'Freightliner Cascadia',
      regNumber: 'PQR-9876',
      driver: 'Michael Chen',
      fuelType: 'Diesel',
      status: 'Busy',
      statusColor: Colors.redAccent,
      isAvailable: false,
      image: 'https://images.unsplash.com/photo-1586191582151-f737704250c6?w=800&q=80',
      capacity: 12.0,
    ),
  ]);

  void addVehicle(Vehicle vehicle) {
    state = [vehicle, ...state];
  }

  void updateVehicle(Vehicle vehicle) {
    state = [
      for (final v in state)
        if (v.id == vehicle.id) vehicle else v
    ];
  }

  void deleteVehicle(String id) {
    state = state.where((v) => v.id != id).toList();
  }
}

final vehicleProvider = StateNotifierProvider<VehicleNotifier, List<Vehicle>>((ref) {
  return VehicleNotifier();
});
