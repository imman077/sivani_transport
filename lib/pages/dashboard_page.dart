import 'package:flutter/material.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/widgets/stat_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // App Bar Area
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.local_shipping, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Transport Admin',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Stack(
                        children: [
                          Icon(Icons.notifications_none_rounded, color: Colors.grey.shade600),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              height: 8,
                              width: 8,
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.orange.shade100,
                        child: const Icon(Icons.person, color: Colors.orange, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for drivers, vehicles, or trip IDs..',
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Overview Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Last 24 Hours', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats Grid (vertical as per user image)
                  const StatCard(
                    title: 'Total Drivers',
                    value: '124',
                    percentage: '+5.2%',
                    isPositive: true,
                    icon: Icons.people_outline,
                    iconBg: Color(0xFFE3F2FD),
                    iconColor: Colors.blue,
                  ),
                  const StatCard(
                    title: 'Total Vehicles',
                    value: '86',
                    percentage: '-2.1%',
                    isPositive: false,
                    icon: Icons.directions_car_outlined,
                    iconBg: Color(0xFFE3F2FD),
                    iconColor: Colors.blue,
                  ),
                  const StatCard(
                    title: 'Active Trips',
                    value: '24',
                    percentage: '+12.4%',
                    isPositive: true,
                    icon: Icons.route_outlined,
                    iconBg: Color(0xFFE3F2FD),
                    iconColor: Colors.blue,
                  ),
                  const StatCard(
                    title: 'Today\'s Expenses',
                    value: '\$1,240',
                    percentage: '+8.1%',
                    isPositive: true,
                    icon: Icons.account_balance_wallet_outlined,
                    iconBg: Color(0xFFE3F2FD),
                    iconColor: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
