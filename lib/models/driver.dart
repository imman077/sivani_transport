import 'package:image_picker/image_picker.dart';

class Driver {
  final String id;
  final String name;
  final String phone;
  final String license;
  final bool isAvailable;
  final String? image; // URL or File path
  final XFile? pickedImage;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.license,
    this.isAvailable = true,
    this.image,
    this.pickedImage,
  });

  Driver copyWith({
    String? id,
    String? name,
    String? phone,
    String? license,
    bool? isAvailable,
    String? image,
    XFile? pickedImage,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      license: license ?? this.license,
      isAvailable: isAvailable ?? this.isAvailable,
      image: image ?? this.image,
      pickedImage: pickedImage ?? this.pickedImage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'license': license,
      'isAvailable': isAvailable,
      'image': image,
    };
  }

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      license: map['license'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      image: map['image'],
    );
  }
}
