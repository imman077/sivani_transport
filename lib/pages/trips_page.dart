import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/models/trip.dart';
import 'package:sivani_transport/providers/trip_provider.dart';
import 'package:sivani_transport/providers/search_provider.dart';
import 'package:sivani_transport/providers/auth_provider.dart';
import 'package:sivani_transport/models/app_user.dart';
import 'package:sivani_transport/widgets/app_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class TripsPage extends ConsumerStatefulWidget {
  const TripsPage({super.key});

  @override
  ConsumerState<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends ConsumerState<TripsPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(tripSearchProvider),
    );

    // Fetch profile if name is missing for a logged in driver
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider);
      if (user != null && user.role == 'Driver' && user.name.isEmpty) {
        ref.read(authProvider.notifier).fetchProfile(user.email);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Trip> _getFilteredTrips(
    List<Trip> trips,
    String searchQuery,
    String selectedStatus,
  ) {
    // Status Filter
    Iterable<Trip> result = trips;
    if (selectedStatus == 'Active') {
      result = trips.where((trip) => trip.status != 'Completed');
    } else if (selectedStatus == 'Completed') {
      result = trips.where((trip) => trip.status == 'Completed');
    }

    // Search Filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((trip) {
        final String id = trip.id.toLowerCase();
        final String driver = trip.driver.toLowerCase();
        final String vehicle = trip.vehicle.toLowerCase();
        final String route = trip.route.toLowerCase();

        return id.contains(query) ||
            driver.contains(query) ||
            vehicle.contains(query) ||
            route.contains(query);
      });
    }

    return result.toList();
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  void _showTripWizard({
    bool isEditing = false,
    Trip? trip,
    bool isReadOnly = false,
  }) {
    context.push('/trips/add', extra: {'trip': trip, 'isReadOnly': isReadOnly});
  }

  void _showToast(String message) {
    AppToast.show(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(tripProvider);
    final searchQuery = ref.watch(tripSearchProvider);
    final selectedStatus = ref.watch(tripFilterProvider);

    final user = ref.watch(authProvider);
    final isAdmin = (user?.role ?? '').trim().toLowerCase() == 'admin';

    // 1. Role-based Visibility (Admin see all, Driver see assigned by name)
    final visibilityFilteredTrips = isAdmin
        ? trips
        : trips.where((t) => t.driver.trim().toLowerCase() == (user?.name ?? '').trim().toLowerCase()).toList();

    // 2. Interactive Filter (Status + Search) applied to visibility
    final displayTrips = _getFilteredTrips(visibilityFilteredTrips, searchQuery, selectedStatus);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          MasterPageHeader(
            searchController: _searchController,
            searchHint: 'Search trips...',
            onSearchChanged: (val) {
              ref.read(tripSearchProvider.notifier).state = val;
              setState(() {});
            },
            onSearchCleared: () {
              _searchController.clear();
              ref.read(tripSearchProvider.notifier).state = '';
              setState(() {});
            },
            showAddButton: isAdmin,
            addButtonLabel: 'Create New Trip',
            onAddPressed: () => _showTripWizard(),
            selectedFilter: selectedStatus,
            onFilterChanged: (val) =>
                ref.read(tripFilterProvider.notifier).state = val,
            filters: [
              FilterTabItem(
                label: 'All',
                count: visibilityFilteredTrips.length,
                icon: Icons.all_inbox_rounded,
              ),
              FilterTabItem(
                label: 'Active',
                count: visibilityFilteredTrips.where((t) => t.status != 'Completed').length,
                icon: Icons.local_shipping_rounded,
              ),
              FilterTabItem(
                label: 'Completed',
                count: visibilityFilteredTrips.where((t) => t.status == 'Completed').length,
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
          // Scrollable List Section
          Expanded(
            child: displayTrips.isNotEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: displayTrips.length,
                    itemBuilder: (context, index) {
                      return _buildTripCard(displayTrips[index], isAdmin, user);
                    },
                  )
                : _buildEmptyState(
                    icon: Icons.route_outlined,
                    title: 'No trips found',
                    subtitle:
                        'Try adjusting your filters or create a new trip.',
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Trip trip, bool isAdmin, AppUser? user) {
    final bool isCompleted = trip.status.toLowerCase() == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // 1. Primary Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCompleted
                      ? [const Color(0xFF64748B), const Color(0xFF475569)]
                      : [AppColors.primary, const Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          trip.id.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.local_shipping_rounded,
                              size: 14,
                              color: isCompleted
                                  ? const Color(0xFF10B981)
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              trip.status.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: isCompleted
                                    ? const Color(0xFF10B981)
                                    : AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.route,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Planned Route Path',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Financials Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NET BALANCE',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.6,
                            ),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${trip.netBalance.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAdmin || trip.driverId == user?.id) ...[
                    _buildModernAction(
                      Icons.edit_rounded,
                      AppColors.primary,
                      () => _showTripWizard(isEditing: true, trip: trip),
                    ),
                    const SizedBox(width: 12),
                    _buildModernAction(
                      Icons.delete_rounded,
                      const Color(0xFFEF4444),
                      () => _showDeleteConfirmation(trip.id, '${trip.from} to ${trip.to}'),
                    ),
                  ] else ...[
                    _buildModernAction(
                      Icons.visibility_rounded,
                      AppColors.primary,
                      () => _showTripWizard(
                        isEditing: true,
                        trip: trip,
                        isReadOnly: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 3. Stats Section
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(
                    color: Colors.blueGrey.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Row(
                children: [
                  _buildStatBox(
                    Icons.calendar_today_rounded,
                    'Date',
                    trip.startDate != null
                        ? '${trip.startDate!.day}/${trip.startDate!.month}'
                        : '-',
                  ),
                  _buildStatBox(
                    Icons.local_shipping_rounded,
                    'Vehicle',
                    trip.plate.isNotEmpty ? trip.plate : trip.vehicle,
                  ),
                  _buildStatBox(
                    Icons.face_rounded,
                    'Driver',
                    trip.driver.split(' ').first,
                  ),
                  _buildStatBox(
                    Icons.grid_view_rounded,
                    'Loads',
                    trip.loads.toString(),
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showDeleteConfirmation(String tripId, String route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text('Are you sure you want to delete the trip: $route?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(tripProvider.notifier).deleteTrip(tripId, route);
              Navigator.pop(context);
              _showToast('Trip deleted successfully');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            right: isLast
                ? BorderSide.none
                : BorderSide(color: Colors.blueGrey.withValues(alpha: 0.1)),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 14,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
