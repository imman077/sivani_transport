import 'package:image_picker/image_picker.dart';

class Driver {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String password;
  final String license;
  final bool isAvailable;
  final String? image; // URL or File path
  final XFile? pickedImage;
  final DateTime registrationDate;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.password = '',
    required this.license,
    this.isAvailable = true,
    this.image,
    this.pickedImage,
    DateTime? registrationDate,
  }) : registrationDate = registrationDate ?? DateTime.now();

  Driver copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? password,
    String? license,
    bool? isAvailable,
    String? image,
    XFile? pickedImage,
    DateTime? registrationDate,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      license: license ?? this.license,
      isAvailable: isAvailable ?? this.isAvailable,
      image: image ?? this.image,
      pickedImage: pickedImage ?? this.pickedImage,
      registrationDate: registrationDate ?? this.registrationDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'license': license,
      'isAvailable': isAvailable,
      'image': image,
      'role': 'Driver',
      'registrationDate': registrationDate.toIso8601String(),
    };
  }

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      license: map['license'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      image: map['image'],
      registrationDate: map['registrationDate'] != null 
          ? DateTime.parse(map['registrationDate']) 
          : DateTime.now(),
    );
  }
}
