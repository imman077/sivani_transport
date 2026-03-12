import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/models/driver.dart';

class DriverNotifier extends StateNotifier<List<Driver>> {
  DriverNotifier() : super([
    Driver(
      id: '1',
      name: 'Johnathan Miller',
      phone: '+1 (555) 012-3456',
      license: 'DL-8829102',
      isAvailable: false,
      image: 'https://i.pravatar.cc/600?u=john',
    ),
    Driver(
      id: '2',
      name: 'Sarah Thompson',
      phone: '+1 (555) 045-8821',
      license: 'DL-1102934',
      isAvailable: true,
      image: 'https://i.pravatar.cc/600?u=sarah',
    ),
    Driver(
      id: '3',
      name: 'Michael Chen',
      phone: '+1 (555) 098-7744',
      license: 'DL-9920311',
      isAvailable: false,
      image: 'https://i.pravatar.cc/600?u=michael',
    ),
  ]);

  void addDriver(Driver driver) {
    state = [driver, ...state];
  }

  void updateDriver(Driver driver) {
    state = [
      for (final d in state)
        if (d.id == driver.id) driver else d
    ];
  }

  void deleteDriver(String id) {
    state = state.where((driver) => driver.id != id).toList();
  }
}

final driverProvider = StateNotifierProvider<DriverNotifier, List<Driver>>((ref) {
  return DriverNotifier();
});
