import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/models/trip.dart';
import 'package:sivani_transport/providers/auth_provider.dart';
import 'package:sivani_transport/providers/driver_provider.dart';
import 'package:sivani_transport/providers/vehicle_provider.dart';
import 'package:sivani_transport/providers/trip_provider.dart';
import 'package:sivani_transport/widgets/stat_card.dart';
import 'package:sivani_transport/widgets/app_components.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final bool isAdmin = user?.role == 'Admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Top Area (Branded Header)
            const BrandedHeader(),
            const SizedBox(height: 8),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner / Greeting Section
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -10,
                            bottom: -20,
                            child: Icon(
                              isAdmin ? Icons.local_shipping_rounded : Icons.person_rounded,
                              color: Colors.white.withValues(alpha: 0.1),
                              size: 100,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_getGreeting()}, ${user?.name.split(' ').first ?? 'User'}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isAdmin ? 'SYSTEM ADMINISTRATOR' : 'AUTHORIZED DRIVER',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Overview Section (Admin only) or Active Section (Driver only)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isAdmin) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'OVERVIEW',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  'Last 30 Days',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blueGrey.shade300,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (!isAdmin) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'ACTIVE TRIPS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildActiveTripCard(ref, user?.id),
                            const SizedBox(height: 32),
                            const Text(
                              'TRIP STATISTICS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Premium Stats List
                          Column(
                            children: isAdmin 
                              ? _buildAdminStats(ref)
                              : _buildDriverStats(ref, user?.id),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAdminStats(WidgetRef ref) {
    final drivers = ref.watch(driversStreamProvider).value ?? [];
    final vehicles = ref.watch(vehicleProvider);
    final trips = ref.watch(tripProvider);

    // Calculate monthly revenue (sum of payments in current month)
    final now = DateTime.now();
    double monthlyPayments = 0;
    for (var trip in trips) {
      if (trip.startDate != null && 
          trip.startDate!.month == now.month && 
          trip.startDate!.year == now.year) {
        monthlyPayments += trip.totalPayments;
      }
    }

    return [
      StatCard(
        title: 'Drivers',
        value: drivers.length.toString(),
        icon: Icons.person_pin_rounded,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1976D2),
        trend: 'Total Registered',
        isPositive: true,
      ),
      const SizedBox(height: 16),
      StatCard(
        title: 'Vehicles',
        value: vehicles.length.toString(),
        icon: Icons.local_shipping_rounded,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFF57C00),
        trend: 'Fleet Size',
        isPositive: true,
      ),
      const SizedBox(height: 16),
      StatCard(
        title: 'Total Trips',
        value: trips.length.toString(),
        icon: Icons.auto_graph_rounded,
        iconBg: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF388E3C),
        trend: 'Lifetime Trips',
        isPositive: true,
      ),
      const SizedBox(height: 16),
      StatCard(
        title: 'Monthly Payments',
        value: '₹${monthlyPayments.toStringAsFixed(0)}',
        icon: Icons.payments_rounded,
        iconBg: const Color(0xFFF3E5F5),
        iconColor: const Color(0xFF7B1FA2),
        trend: 'This Month',
        isPositive: true,
      ),
    ];
  }

  List<Widget> _buildDriverStats(WidgetRef ref, String? driverId) {
    final trips = ref.watch(tripProvider);
    final driverTrips = trips.where((t) => t.driverId == driverId).toList();
    
    final ongoingCount = driverTrips.where((t) => t.status == 'Ongoing').length;
    final scheduledCount = driverTrips.where((t) => t.status == 'Scheduled').length;
    final completedCount = driverTrips.where((t) => t.status == 'Completed').length;

    return [
      StatCard(
        title: 'Ongoing Trips',
        value: ongoingCount.toString().padLeft(2, '0'),
        icon: Icons.pending_actions_rounded,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFF57C00),
        trend: 'Live Tracking',
        isPositive: ongoingCount > 0,
      ),
      const SizedBox(height: 16),
      StatCard(
        title: 'Trip History',
        value: completedCount.toString().padLeft(2, '0'),
        icon: Icons.history_rounded,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1976D2),
        trend: 'Completed Trips',
        isPositive: true,
      ),
      const SizedBox(height: 16),
      StatCard(
        title: 'Scheduled Trips',
        value: scheduledCount.toString().padLeft(2, '0'),
        icon: Icons.event_available_rounded,
        iconBg: const Color(0xFFF3E5F5),
        iconColor: const Color(0xFF7B1FA2),
        trend: 'Upcoming',
        isPositive: true,
      ),
    ];
  }

  Widget _buildActiveTripCard(WidgetRef ref, String? driverId) {
    final trips = ref.watch(tripProvider);
    final activeTrip = trips.firstWhere(
      (t) => t.driverId == driverId && t.status == 'Ongoing',
      orElse: () => Trip(id: '', from: '', to: '', vehicle: '', plate: '', driver: '', status: 'None'),
    );

    if (activeTrip.id.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 40),
            SizedBox(height: 12),
            Text(
              'No active trips currenty',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'You are all caught up!',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeTrip.plate,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      activeTrip.vehicle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'IN TRANSIT',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activeTrip.from,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward_rounded,
                    color: AppColors.textSecondary, size: 14),
              ),
              const Icon(Icons.navigation_rounded, color: Color(0xFF6366F1), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activeTrip.to,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
