import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/models/vehicle.dart';

class VehicleFormState {
  final String? id;
  final String model;
  final String regNumber;
  final String status;
  final String fuelType;
  final double capacity;
  final bool isLoading;

  VehicleFormState({
    this.id,
    this.model = '',
    this.regNumber = '',
    this.status = 'Idle',
    this.fuelType = 'Diesel',
    this.capacity = 0.0,
    this.isLoading = false,
  });

  VehicleFormState copyWith({
    String? id,
    String? model,
    String? regNumber,
    String? status,
    String? fuelType,
    double? capacity,
    bool? isLoading,
  }) {
    return VehicleFormState(
      id: id ?? this.id,
      model: model ?? this.model,
      regNumber: regNumber ?? this.regNumber,
      status: status ?? this.status,
      fuelType: fuelType ?? this.fuelType,
      capacity: capacity ?? this.capacity,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class VehicleFormNotifier extends StateNotifier<VehicleFormState> {
  VehicleFormNotifier() : super(VehicleFormState());

  void init(Vehicle? vehicle) {
    if (vehicle != null) {
      state = VehicleFormState(
        id: vehicle.id,
        model: vehicle.model,
        regNumber: vehicle.regNumber,
        status: vehicle.status,
        fuelType: vehicle.fuelType,
        capacity: vehicle.capacity,
      );
    } else {
      state = VehicleFormState();
    }
  }

  void updateModel(String model) => state = state.copyWith(model: model);
  void updateRegNumber(String regNumber) => state = state.copyWith(regNumber: regNumber);
  void updateFuelType(String fuelType) => state = state.copyWith(fuelType: fuelType);
  void updateCapacity(String capacity) {
    final double? val = double.tryParse(capacity);
    if (val != null) {
      state = state.copyWith(capacity: val);
    }
  }
  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
}

final vehicleFormProvider = StateNotifierProvider.autoDispose<VehicleFormNotifier, VehicleFormState>((ref) {
  return VehicleFormNotifier();
});
