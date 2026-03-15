import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sivani_transport/models/driver.dart';

class DriverFormState {
  final String? id;
  final String name;
  final String phone;
  final String email;
  final String password;
  final String license;
  final XFile? pickedImage;
  final String? existingImageUrl;
  final bool isLoading;

  DriverFormState({
    this.id,
    this.name = '',
    this.phone = '',
    this.email = '',
    this.password = '',
    this.license = '',
    this.pickedImage,
    this.existingImageUrl,
    this.isLoading = false,
  });

  DriverFormState copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? password,
    String? license,
    XFile? Function()? pickedImage,
    String? Function()? existingImageUrl,
    bool? isLoading,
  }) {
    return DriverFormState(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      license: license ?? this.license,
      pickedImage: pickedImage != null ? pickedImage() : this.pickedImage,
      existingImageUrl: existingImageUrl != null ? existingImageUrl() : this.existingImageUrl,
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
        email: driver.email,
        password: driver.password,
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
  void updateEmail(String email) => state = state.copyWith(email: email);
  void updatePassword(String password) => state = state.copyWith(password: password);
  void updateLicense(String license) => state = state.copyWith(license: license);
  void updateImage(XFile? image) => state = state.copyWith(pickedImage: () => image);
  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
  
  void resetImage() => state = state.copyWith(
    pickedImage: () => null,
    existingImageUrl: () => null,
  );
}

final driverFormProvider = StateNotifierProvider.autoDispose<DriverFormNotifier, DriverFormState>((ref) {
  return DriverFormNotifier();
});
