import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/models/trip.dart';

class TripNotifier extends StateNotifier<List<Trip>> {
  TripNotifier() : super([
    Trip(
      id: 'TRIP-4451',
      from: 'Chicago',
      to: 'Detroit',
      vehicle: 'Mercedes Sprinter',
      plate: 'ABC-1234',
      status: 'Completed',
      statusColor: Colors.green,
      driver: 'Johnathan Miller',
      initialCash: 1000,
      startDate: DateTime(2023, 10, 24),
      endDate: DateTime(2023, 10, 25),
    ),
    Trip(
      id: 'TRIP-4452',
      from: 'New York',
      to: 'Boston',
      vehicle: 'Volvo FH16',
      plate: 'XYZ-5678',
      driver: 'Sarah Thompson',
      status: 'Ongoing',
      statusColor: Colors.blue,
      initialCash: 1000,
      startDate: DateTime(2023, 10, 25),
      endDate: DateTime(2023, 10, 26),
    ),
  ]);

  void addTrip(Trip trip) {
    state = [trip, ...state];
  }

  void updateTrip(Trip trip) {
    state = [
      for (final t in state)
        if (t.id == trip.id) trip else t
    ];
  }

  void deleteTrip(String id) {
    state = state.where((trip) => trip.id != id).toList();
  }
}

final tripProvider = StateNotifierProvider<TripNotifier, List<Trip>>((ref) {
  return TripNotifier();
});
