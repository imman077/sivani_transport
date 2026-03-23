import 'package:flutter/material.dart';

class Trip {
  final String id;
  final String from;
  final String to;
  final String vehicle;
  final String plate;
  final String driver;
  final String? driverId;
  final String? transporter;
  final String? transporterId;
  final DateTime? startDate;
  final DateTime? endDate;
  final num startKm;
  final num endKm;
  final num diesel;
  final num? _outwardLoads;
  final num? _returnLoads;
  final bool? _hasReturn;
  final List<Map<String, String>> expenseList;
  final List<Map<String, String>> paymentList;
  final num initialCash;
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
    this.transporter,
    this.transporterId,
    this.startDate,
    this.endDate,
    this.startKm = 0.0,
    this.endKm = 0.0,
    this.diesel = 0.0,
    num? outwardLoads = 0.0,
    num? returnLoads = 0.0,
    bool? hasReturn = false,
    this.expenseList = const [],
    this.paymentList = const [],
    this.initialCash = 0,
    this.status = 'Ongoing',
    this.statusColor = Colors.blue,
  })  : _outwardLoads = outwardLoads,
        _returnLoads = returnLoads,
        _hasReturn = hasReturn;

  double get outwardLoads => _outwardLoads?.toDouble() ?? 0.0;
  double get returnLoads => _returnLoads?.toDouble() ?? 0.0;
  bool get hasReturn => _hasReturn ?? false;

  double get totalLoads => outwardLoads + (hasReturn ? returnLoads : 0.0);
  // Keep 'loads' getter for backward compatibility with existing UI if needed
  double get loads => outwardLoads;

  String get route => '$from • $to';
  double get totalKms => endKm.toDouble() - startKm.toDouble();
  double get mileage => (diesel > 0.0 && totalKms > 0.0) ? (totalKms / diesel.toDouble()) : 0.0;

  double get totalExpenses {
    double total = 0.0;
    for (var item in expenseList) {
      final amountStr = item['amount']?.replaceAll('₹', '').replaceAll(',', '') ?? '0.0';
      total += double.tryParse(amountStr) ?? 0.0;
    }
    return total;
  }

  double _getLegTotalExpenses(String leg) {
    double total = 0.0;
    for (var item in expenseList) {
      if (item['leg'] == leg) {
        final amountStr = item['amount']?.replaceAll('₹', '').replaceAll(',', '') ?? '0.0';
        total += double.tryParse(amountStr) ?? 0.0;
      }
    }
    return total;
  }

  double get totalOutwardExpenses => _getLegTotalExpenses('A to D');
  double get totalReturnExpenses => _getLegTotalExpenses('D to A');
  double get totalGeneralExpenses {
    double total = 0.0;
    for (var item in expenseList) {
      if (item['leg'] == null || item['leg'] == 'General' || (item['leg'] != 'A to D' && item['leg'] != 'D to A')) {
        final amountStr = item['amount']?.replaceAll('₹', '').replaceAll(',', '') ?? '0.0';
        total += double.tryParse(amountStr) ?? 0.0;
      }
    }
    return total;
  }

  double get totalPayments {
    double total = initialCash.toDouble();
    for (var item in paymentList) {
      final amountStr = item['amount']?.replaceAll('₹', '').replaceAll(',', '') ?? '0.0';
      total += double.tryParse(amountStr) ?? 0.0;
    }
    return total;
  }

  double get netBalance => totalPayments - totalExpenses;

  Trip copyWith({
    String? id,
    String? from,
    String? to,
    String? vehicle,
    String? plate,
    String? driver,
    String? driverId,
    String? transporter,
    String? transporterId,
    DateTime? startDate,
    DateTime? endDate,
    num? startKm,
    num? endKm,
    num? diesel,
    num? outwardLoads,
    num? returnLoads,
    bool? hasReturn,
    List<Map<String, String>>? expenseList,
    List<Map<String, String>>? paymentList,
    num? initialCash,
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
      transporter: transporter ?? this.transporter,
      transporterId: transporterId ?? this.transporterId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startKm: startKm ?? this.startKm,
      endKm: endKm ?? this.endKm,
      diesel: diesel ?? this.diesel,
      outwardLoads: outwardLoads ?? this.outwardLoads,
      returnLoads: returnLoads ?? this.returnLoads,
      hasReturn: hasReturn ?? this.hasReturn,
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
      'transporter': transporter,
      'transporterId': transporterId,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'startKm': startKm,
      'endKm': endKm,
      'diesel': diesel,
      'outwardLoads': outwardLoads,
      'returnLoads': returnLoads,
      'hasReturn': hasReturn,
      'expenseList': expenseList,
      'paymentList': paymentList,
      'initialCash': initialCash,
      'status': status,
      'statusColor': statusColor.toARGB32(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    num parseNum(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Trip(
      id: map['id'] ?? '',
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      vehicle: map['vehicle'] ?? '',
      plate: map['plate'] ?? '',
      driver: map['driver'] ?? '',
      driverId: map['driverId'],
      transporter: map['transporter'],
      transporterId: map['transporterId'],
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      startKm: parseNum(map['startKm']),
      endKm: parseNum(map['endKm']),
      diesel: parseNum(map['diesel']),
      outwardLoads: parseNum(map['outwardLoads'] ?? map['loads']), // Fallback to old field
      returnLoads: parseNum(map['returnLoads']),
      hasReturn: map['hasReturn'] ?? false,
      expenseList: List<Map<String, dynamic>>.from(map['expenseList'] ?? [])
          .map((e) => Map<String, String>.from(e))
          .toList(),
      paymentList: List<Map<String, dynamic>>.from(map['paymentList'] ?? [])
          .map((p) => Map<String, String>.from(p))
          .toList(),
      initialCash: parseNum(map['initialCash']),
      status: map['status'] ?? 'Ongoing',
      statusColor: Color(map['statusColor'] ?? Colors.blue.toARGB32()),
    );
  }
}
