import 'package:flutter/material.dart';

class Trip {
  final String id;
  final String from;
  final String to;
  final String vehicle;
  final String plate;
  final String driver;
  final String? driverId;
  final DateTime? startDate;
  final DateTime? endDate;
  final double startKm;
  final double endKm;
  final double diesel;
  final List<Map<String, String>> expenseList;
  final List<Map<String, String>> paymentList;
  final double initialCash;
  final String status;
  final Color statusColor;

  Trip({
    required this.id,
    required this.from,
    required this.to,
    required this.vehicle,
    required this.plate,
    required this.driver,
    this.driverId,
    this.startDate,
    this.endDate,
    this.startKm = 0,
    this.endKm = 0,
    this.diesel = 0,
    this.expenseList = const [],
    this.paymentList = const [],
    this.initialCash = 0,
    this.status = 'Ongoing',
    this.statusColor = Colors.blue,
  });

  String get route => '$from • $to';
  double get totalKms => endKm - startKm;
  double get mileage => (diesel > 0 && totalKms > 0) ? (totalKms / diesel) : 0;

  double get totalExpenses {
    double total = 0;
    for (var item in expenseList) {
      final amountStr = item['amount']?.replaceAll('₹', '').replaceAll(',', '') ?? '0';
      total += double.tryParse(amountStr) ?? 0;
    }
    return total;
  }

  double get totalPayments {
    double total = initialCash;
    for (var item in paymentList) {
      final amountStr = item['amount']?.replaceAll('₹', '').replaceAll(',', '') ?? '0';
      total += double.tryParse(amountStr) ?? 0;
    }
    return total;
  }

  Trip copyWith({
    String? id,
    String? from,
    String? to,
    String? vehicle,
    String? plate,
    String? driver,
    String? driverId,
    DateTime? startDate,
    DateTime? endDate,
    double? startKm,
    double? endKm,
    double? diesel,
    List<Map<String, String>>? expenseList,
    List<Map<String, String>>? paymentList,
    double? initialCash,
    String? status,
    Color? statusColor,
  }) {
    return Trip(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      vehicle: vehicle ?? this.vehicle,
      plate: plate ?? this.plate,
      driver: driver ?? this.driver,
      driverId: driverId ?? this.driverId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startKm: startKm ?? this.startKm,
      endKm: endKm ?? this.endKm,
      diesel: diesel ?? this.diesel,
      expenseList: expenseList ?? this.expenseList,
      paymentList: paymentList ?? this.paymentList,
      initialCash: initialCash ?? this.initialCash,
      status: status ?? this.status,
      statusColor: statusColor ?? this.statusColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'vehicle': vehicle,
      'plate': plate,
      'driver': driver,
      'driverId': driverId,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'startKm': startKm,
      'endKm': endKm,
      'diesel': diesel,
      'expenseList': expenseList,
      'paymentList': paymentList,
      'initialCash': initialCash,
      'status': status,
      'statusColor': statusColor.toARGB32(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] ?? '',
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      vehicle: map['vehicle'] ?? '',
      plate: map['plate'] ?? '',
      driver: map['driver'] ?? '',
      driverId: map['driverId'],
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      startKm: (map['startKm'] ?? 0.0).toDouble(),
      endKm: (map['endKm'] ?? 0.0).toDouble(),
      diesel: (map['diesel'] ?? 0.0).toDouble(),
      expenseList: List<Map<String, dynamic>>.from(map['expenseList'] ?? [])
          .map((e) => Map<String, String>.from(e))
          .toList(),
      paymentList: List<Map<String, dynamic>>.from(map['paymentList'] ?? [])
          .map((p) => Map<String, String>.from(p))
          .toList(),
      initialCash: (map['initialCash'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Ongoing',
      statusColor: Color(map['statusColor'] ?? Colors.blue.toARGB32()),
    );
  }
}
