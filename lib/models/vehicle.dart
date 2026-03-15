import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Vehicle {
  final String id;
  final String model;
  final String regNumber;
  final String fuelType;
  final String status;
  final Color statusColor;
  final bool isAvailable;
  final String? image;
  final XFile? pickedImage;
  final double capacity;

  Vehicle({
    required this.id,
    required this.model,
    required this.regNumber,
    required this.fuelType,
    this.status = 'Idle',
    this.statusColor = Colors.orange,
    this.isAvailable = true,
    this.image,
    this.pickedImage,
    this.capacity = 0.0,
  });

  Vehicle copyWith({
    String? id,
    String? model,
    String? regNumber,
    String? fuelType,
    String? status,
    Color? statusColor,
    bool? isAvailable,
    String? image,
    XFile? pickedImage,
    double? capacity,
  }) {
    return Vehicle(
      id: id ?? this.id,
      model: model ?? this.model,
      regNumber: regNumber ?? this.regNumber,
      fuelType: fuelType ?? this.fuelType,
      status: status ?? this.status,
      statusColor: statusColor ?? this.statusColor,
      isAvailable: isAvailable ?? this.isAvailable,
      image: image ?? this.image,
      pickedImage: pickedImage ?? this.pickedImage,
      capacity: capacity ?? this.capacity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model': model,
      'regNumber': regNumber,
      'fuelType': fuelType,
      'status': status,
      'statusColor': statusColor.toARGB32(),
      'isAvailable': isAvailable,
      'image': image,
      'capacity': capacity,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] ?? '',
      model: map['model'] ?? '',
      regNumber: map['regNumber'] ?? '',
      fuelType: map['fuelType'] ?? 'Diesel',
      status: map['status'] ?? 'Idle',
      statusColor: Color(map['statusColor'] ?? Colors.orange.toARGB32()),
      isAvailable: map['isAvailable'] ?? true,
      image: map['image'],
      capacity: (map['capacity'] ?? 0.0).toDouble(),
    );
  }
}
