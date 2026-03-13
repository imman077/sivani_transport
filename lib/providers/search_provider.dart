import 'package:flutter_riverpod/flutter_riverpod.dart';

final driverSearchProvider = StateProvider<String>((ref) => '');
final driverFilterProvider = StateProvider<String>((ref) => 'All');

final vehicleSearchProvider = StateProvider<String>((ref) => '');
final vehicleFilterProvider = StateProvider<String>((ref) => 'All');

final tripSearchProvider = StateProvider<String>((ref) => '');
final tripFilterProvider = StateProvider<String>((ref) => 'Active');
