import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sivani_transport/models/driver.dart';

class DriverFormState {
  final String? id;
  final String name;
  final String phone;
  final String license;
  final XFile? pickedImage;
  final String? existingImageUrl;
  final bool isLoading;

  DriverFormState({
    this.id,
    this.name = '',
    this.phone = '',
    this.license = '',
    this.pickedImage,
    this.existingImageUrl,
    this.isLoading = false,
  });

  DriverFormState copyWith({
    String? id,
    String? name,
    String? phone,
    String? license,
    XFile? pickedImage,
    String? existingImageUrl,
    bool? isLoading,
  }) {
    return DriverFormState(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      license: license ?? this.license,
      pickedImage: pickedImage ?? this.pickedImage,
      existingImageUrl: existingImageUrl ?? this.existingImageUrl,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DriverFormNotifier extends StateNotifier<DriverFormState> {
  DriverFormNotifier() : super(DriverFormState());

  void init(Driver? driver) {
    if (driver != null) {
      state = DriverFormState(
        id: driver.id,
        name: driver.name,
        phone: driver.phone,
        license: driver.license,
        existingImageUrl: driver.image,
        pickedImage: driver.pickedImage,
      );
    } else {
      state = DriverFormState();
    }
  }

  void updateName(String name) => state = state.copyWith(name: name);
  void updatePhone(String phone) => state = state.copyWith(phone: phone);
  void updateLicense(String license) => state = state.copyWith(license: license);
  void updateImage(XFile? image) => state = state.copyWith(pickedImage: image);
  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
  
  void resetImage() => state = state.copyWith(pickedImage: null, existingImageUrl: null);
}

final driverFormProvider = StateNotifierProvider.autoDispose<DriverFormNotifier, DriverFormState>((ref) {
  return DriverFormNotifier();
});
