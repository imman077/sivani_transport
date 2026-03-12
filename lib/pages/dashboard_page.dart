import 'package:flutter/material.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/widgets/stat_card.dart';
import 'package:sivani_transport/widgets/app_components.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
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
                              Icons.local_shipping_rounded,
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
                                '${_getGreeting()}, Admin',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Overview Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

                          // Premium Stats List
                          Column(
                            children: const [
                              StatCard(
                                title: 'Drivers',
                                value: '124',
                                icon: Icons.person_pin_rounded,
                                iconBg: Color(0xFFE3F2FD),
                                iconColor: Color(0xFF1976D2),
                                trend: '+12%',
                                isPositive: true,
                              ),
                              SizedBox(height: 16),
                              StatCard(
                                title: 'Vehicles',
                                value: '86',
                                icon: Icons.local_shipping_rounded,
                                iconBg: Color(0xFFFFF3E0),
                                iconColor: Color(0xFFF57C00),
                                trend: '+4%',
                                isPositive: true,
                              ),
                              SizedBox(height: 16),
                              StatCard(
                                title: 'Trips',
                                value: '24',
                                icon: Icons.auto_graph_rounded,
                                iconBg: Color(0xFFE8F5E9),
                                iconColor: Color(0xFF388E3C),
                                trend: '-2%',
                                isPositive: false,
                              ),
                              SizedBox(height: 16),
                              StatCard(
                                title: 'Revenue',
                                value: r'$1,240',
                                icon: Icons.payments_rounded,
                                iconBg: Color(0xFFF3E5F5),
                                iconColor: Color(0xFF7B1FA2),
                                trend: '+8%',
                                isPositive: true,
                              ),
                            ],
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
}
