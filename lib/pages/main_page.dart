import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/providers/auth_provider.dart';
import 'dart:math' as math;

class MainPage extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainPage({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    if (_isMenuOpen) _toggleMenu();
  }

  void _toggleMenu() {
    if (_animationController == null) return;
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _animationController!.forward();
      } else {
        _animationController!.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_animationController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = ref.watch(authProvider);
    final isAdmin = (user?.role ?? '').trim().toLowerCase() == 'admin';

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          widget.navigationShell,
          
          // Scrim effect with Blur
          if (_isMenuOpen)
            GestureDetector(
              onTap: _toggleMenu,
              child: AnimatedBuilder(
                animation: _animationController!,
                builder: (context, child) => Container(
                  color: Colors.black.withValues(alpha: 0.6 * _animationController!.value),
                ),
              ),
            ),

          // Master Menu Items (Circular Floating Bubbles)
          if (isAdmin)
            ...[
              _buildFloatingBubble(
                index: 4,
                icon: Icons.business_outlined,
                label: 'Transporters',
                color: const Color(0xFFF59E0B),
                angle: 2.5, // Wider Left
                distance: 110,
              ),
              _buildFloatingBubble(
                index: 2,
                icon: Icons.local_shipping_outlined,
                label: 'Vehicles',
                color: const Color(0xFF10B981),
                angle: math.pi / 2, // Straight Top
                distance: 120, // Higher for center to avoid overlap
              ),
              _buildFloatingBubble(
                index: 1,
                icon: Icons.badge_outlined,
                label: 'Drivers',
                color: const Color(0xFF3B82F6),
                angle: 0.7, // Wider Right
                distance: 95,
              ),
            ],
        ],
      ),
      floatingActionButton: isAdmin
          ? AnimatedBuilder(
              animation: _animationController!,
              builder: (context, child) {
                final rotation = _animationController!.value * math.pi / 4;
                return Transform.rotate(
                  angle: rotation,
                  child: FloatingActionButton(
                    onPressed: _toggleMenu,
                    elevation: 10,
                    highlightElevation: 15,
                    backgroundColor: _isMenuOpen ? const Color(0xFFEF4444) : AppColors.primary,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 36),
                  ),
                );
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 12,
          color: Colors.white,
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.grid_view_rounded, 'DASHBOARD'),
              const SizedBox(width: 60), // Space for FAB
              _buildNavItem(3, Icons.map_outlined, 'TRIPS'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBubble({
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    required double angle,
    required double distance,
  }) {
    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        final double value = _animationController!.value;
        if (value == 0) return const SizedBox.shrink();

        final double dx = math.cos(angle) * distance * value;
        final double dy = math.sin(angle) * distance * value;

        return Positioned(
          bottom: 35 + dy, // Slightly adjusted base
          left: (MediaQuery.of(context).size.width / 2 - 27) + dx, // Centered adjust
          child: Opacity(
            opacity: value,
            child: Transform.scale(
              scale: value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _onItemTapped(index),
                    child: Container(
                      height: 54, // Slightly smaller bubble
                      width: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = widget.navigationShell.currentIndex == index;
    return InkWell(
      onTap: () {
        if (_isMenuOpen) _toggleMenu();
        _onItemTapped(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary.withValues(alpha: 0.4),
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.4),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
