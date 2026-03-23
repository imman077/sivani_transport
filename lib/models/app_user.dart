
class AppUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String password;
  final String role; // Admin, Driver, etc.
  final String license;
  final String? image;
  final DateTime registrationDate;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    required this.role,
    this.license = '',
    this.image,
    required this.registrationDate,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? password,
    String? role,
    String? license,
    String? image,
    DateTime? registrationDate,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      license: license ?? this.license,
      image: image ?? this.image,
      registrationDate: registrationDate ?? this.registrationDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'role': role,
      'license': license,
      'image': image,
      'registrationDate': registrationDate.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? '',
      license: map['license'] ?? '',
      image: map['image'],
      registrationDate: map['registrationDate'] != null 
          ? DateTime.parse(map['registrationDate']) 
          : DateTime.now(),
    );
  }
}
