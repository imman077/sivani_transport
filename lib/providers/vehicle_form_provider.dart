import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sivani_transport/models/vehicle.dart';

class VehicleFormState {
  final String? id;
  final String model;
  final String regNumber;
  final String status;
  final String fuelType;
  final String capacityValue;
  final String? image;
  final XFile? pickedImage;
  final bool isLoading;

  VehicleFormState({
    this.id,
    this.model = '',
    this.regNumber = '',
    this.status = 'Idle',
    this.fuelType = 'Diesel',
    this.capacityValue = '',
    this.image,
    this.pickedImage,
    this.isLoading = false,
  });

  VehicleFormState copyWith({
    String? id,
    String? model,
    String? regNumber,
    String? status,
    String? fuelType,
    String? capacityValue,
    String? Function()? image,
    XFile? Function()? pickedImage,
    bool? isLoading,
  }) {
    return VehicleFormState(
      id: id ?? this.id,
      model: model ?? this.model,
      regNumber: regNumber ?? this.regNumber,
      status: status ?? this.status,
      fuelType: fuelType ?? this.fuelType,
      capacityValue: capacityValue ?? this.capacityValue,
      image: image != null ? image() : this.image,
      pickedImage: pickedImage != null ? pickedImage() : this.pickedImage,
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
        capacityValue: vehicle.capacity == 0.0 ? '' : vehicle.capacity.toString(),
        image: vehicle.image,
      );
    } else {
      state = VehicleFormState();
    }
  }

  void updateModel(String model) => state = state.copyWith(model: model);
  void updateRegNumber(String regNumber) => state = state.copyWith(regNumber: regNumber);
  void updateFuelType(String fuelType) => state = state.copyWith(fuelType: fuelType);
  void updateCapacity(String capacity) => state = state.copyWith(capacityValue: capacity);
  void updateImage(XFile? pickedImage, {String? image}) => 
    state = state.copyWith(
      pickedImage: () => pickedImage, 
      image: image != null ? () => image : null
    );
  void resetImage() => state = state.copyWith(
    pickedImage: () => null,
    image: () => null,
  );
  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
}

final vehicleFormProvider = StateNotifierProvider.autoDispose<VehicleFormNotifier, VehicleFormState>((ref) {
  return VehicleFormNotifier();
});
