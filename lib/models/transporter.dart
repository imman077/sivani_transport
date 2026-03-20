import 'package:image_picker/image_picker.dart';

class Transporter {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? image;
  final XFile? pickedImage;
  final bool isAvailable;

  Transporter({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.image,
    this.pickedImage,
    this.isAvailable = true,
  });

  Transporter copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? image,
    XFile? pickedImage,
    bool? isAvailable,
  }) {
    return Transporter(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      image: image ?? this.image,
      pickedImage: pickedImage ?? this.pickedImage,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'image': image,
      'isAvailable': isAvailable,
    };
  }

  factory Transporter.fromMap(Map<String, dynamic> map) {
    return Transporter(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      address: map['address'],
      image: map['image'],
      isAvailable: map['isAvailable'] ?? true,
    );
  }
}
