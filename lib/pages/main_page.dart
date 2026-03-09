import 'package:flutter/material.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/pages/dashboard_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const Scaffold(body: Center(child: Text('Drivers List'))),
    const Scaffold(body: Center(child: Text('Vehicles Fleet'))),
    const Scaffold(body: Center(child: Text('Trips History'))),
    const Scaffold(body: Center(child: Text('Profile Settings'))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.grid_view_rounded, 'DASHBOARD'),
              _buildNavItem(1, Icons.badge_outlined, 'DRIVERS'),
              _buildNavItem(2, Icons.local_shipping_outlined, 'VEHICLES'),
              _buildNavItem(3, Icons.map_outlined, 'TRIPS'),
              _buildNavItem(4, Icons.person_outline, 'PROFILE'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.6),
              size: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.6),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
