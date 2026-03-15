import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/models/trip.dart';
import 'package:sivani_transport/providers/trip_provider.dart';
import 'package:sivani_transport/providers/search_provider.dart';
import 'package:sivani_transport/providers/auth_provider.dart';
import 'package:sivani_transport/providers/vehicle_provider.dart';
import 'package:sivani_transport/providers/driver_provider.dart';
import 'package:sivani_transport/widgets/app_components.dart';

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
    _searchController = TextEditingController(text: ref.read(tripSearchProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Trip> _getFilteredTrips(List<Trip> trips, String searchQuery, String selectedStatus) {
    // Status Filter
    Iterable<Trip> result = selectedStatus == 'Active'
        ? trips.where((trip) => trip.status != 'Completed')
        : trips.where((trip) => trip.status == 'Completed');

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
            child: Icon(
              icon,
              size: 64,
              color: Colors.grey.shade400,
            ),
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
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showTripWizard({bool isEditing = false, Trip? trip, bool isReadOnly = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: !isReadOnly,
      enableDrag: !isReadOnly,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          TripWizardSheet(key: ValueKey(trip?.id ?? 'new_trip'), isEditing: isEditing, trip: trip, isReadOnly: isReadOnly),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(tripProvider);
    final searchQuery = ref.watch(tripSearchProvider);
    final selectedStatus = ref.watch(tripFilterProvider);
    final filteredTrips = _getFilteredTrips(trips, searchQuery, selectedStatus);
    
    final user = ref.watch(authProvider);
    final isAdmin = user?.role == 'Admin';

    final displayTrips = isAdmin
        ? filteredTrips
        : filteredTrips.where((trip) {
            final userId = user?.id;
            final userName = user?.name.toLowerCase() ?? '';
            final tripDriverId = trip.driverId;
            final tripDriverName = trip.driver.toLowerCase();
            
            // Priority: Filter by ID if available, otherwise by name
            if (tripDriverId != null && userId != null) {
              return tripDriverId == userId;
            }
            return tripDriverName.contains(userName);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Trip Management',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(
        //       Icons.notifications_none_rounded,
        //       color: AppColors.textPrimary,
        //     ),
        //     onPressed: () {},
        //   ),
        // ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Header Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blueGrey.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    height: 46,
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => ref.read(tripSearchProvider.notifier).state = val,
                      decoration: const InputDecoration(
                        hintText: 'Search trips by driver or vehicle',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Create New Trip Button (Admin Only)
                  if (isAdmin) ...[
                    AppButton(
                      label: 'Create New Trip',
                      onPressed: _showTripWizard,
                      icon: Icons.add_task_outlined,
                      height: 46,
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Premium Filter Tabs
                  Container(
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blueGrey.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildFilterTab(
                            'Active',
                            Icons.local_shipping_rounded,
                            trips.where((t) => t.status != 'Completed').length,
                          ),
                        ),
                        Expanded(
                          child: _buildFilterTab(
                            'Completed',
                            Icons.check_circle_rounded,
                            trips.where((t) => t.status == 'Completed').length,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable List Section
            Expanded(
              child: displayTrips.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: displayTrips.length,
                      itemBuilder: (context, index) {
                        return _buildTripCard(displayTrips[index], isAdmin);
                      },
                    )
                  : _buildEmptyState(
                      icon: Icons.route_outlined,
                      title: 'No trips found',
                      subtitle: 'Try adjusting your filters or create a new trip.',
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, IconData icon, int count) {
    final selectedStatus = ref.watch(tripFilterProvider);
    final bool isSelected = selectedStatus == label;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!isSelected) {
          ref.read(tripFilterProvider.notifier).state = label;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.blueGrey.shade400,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.blueGrey.shade700,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.blueGrey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.blueGrey.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(Trip trip, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // 1. Blue Primary Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF2563EB)],
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
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trip.id,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              trip.status.toLowerCase() == 'completed'
                                  ? Icons.check_circle_rounded
                                  : Icons.fiber_manual_record,
                              size: 8,
                              color: trip.status.toLowerCase() == 'completed'
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              trip.status.toUpperCase(),
                              style: TextStyle(
                                color: trip.status.toLowerCase() == 'completed'
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.from,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Departure',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white38,
                          size: 16,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              trip.to,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Destination',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.flag_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL CASH',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹${trip.totalPayments.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAdmin) ...[
                    _buildModernAction(
                      Icons.edit_rounded,
                      AppColors.primary,
                      () => _showTripWizard(isEditing: true, trip: trip),
                    ),
                    if (trip.status != 'Completed') ...[
                      const SizedBox(width: 8),
                      _buildModernAction(
                        Icons.delete_outline_rounded,
                        Colors.redAccent,
                        () {
                          _showDeleteConfirmation(trip.id);
                        },
                      ),
                    ],
                  ] else ...[
                    _buildModernAction(
                      Icons.visibility_rounded,
                      AppColors.primary,
                      () => _showTripWizard(
                        isEditing: true,
                        trip: trip,
                        isReadOnly: false,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 3. Attached Separate Detail Boxes
            Row(
              children: [
                _buildStatBox(
                  Icons.event_note_rounded,
                  'Date',
                  trip.startDate != null
                      ? '${trip.startDate!.day}/${trip.startDate!.month}/${trip.startDate!.year}'
                      : '',
                  isFirst: true,
                ),
                _buildStatBox(
                  Icons.local_shipping_rounded,
                  'Vehicle',
                  trip.vehicle,
                ),
                _buildStatBox(
                  Icons.face_rounded,
                  'Driver',
                  trip.driver.split(' ').first,
                  isLast: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String tripId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(tripProvider.notifier).deleteTrip(tripId);
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
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border(
            top: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.08)),
            right: isLast
                ? BorderSide.none
                : BorderSide(color: Colors.blueGrey.withValues(alpha: 0.12)),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 11, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Container(
            //   margin: const EdgeInsets.symmetric(vertical: 6),
            //   width: 30,
            //   height: 1.5,
            //   decoration: BoxDecoration(
            //     color: AppColors.primary.withValues(alpha: 0.15),
            //     borderRadius: BorderRadius.circular(1),
            //   ),
            // ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
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

class TripWizardSheet extends ConsumerStatefulWidget {
  final bool isEditing;
  final Trip? trip;
  final bool isReadOnly;
  const TripWizardSheet({
    super.key,
    this.isEditing = false,
    this.trip,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<TripWizardSheet> createState() => _TripWizardSheetState();
}

class _TripWizardSheetState extends ConsumerState<TripWizardSheet> {
  String _currentStep = 'summary'; // summary, details, expenses, payment
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String? _selectedDriverId;

  void _handleSaveTrip() async {
    setState(() => _isLoading = true);

    try {
      final tripNotifier = ref.read(tripProvider.notifier);

      final newTrip = Trip(
        id: widget.isEditing
            ? widget.trip!.id
            : '', // Let Firebase service generate the ID
        from: _fromController.text,
        to: _toController.text,
        vehicle: _vehicleController.text,
        plate: 'ABC-1234', // Mock plate or pull from some vehicle data
        driver: _driverController.text,
        driverId: _selectedDriverId,
        startDate: _startDate,
        endDate: _endDate,
        startKm: double.tryParse(_startKmController.text) ?? 0,
        endKm: double.tryParse(_endKmController.text) ?? 0,
        diesel: double.tryParse(_dieselController.text) ?? 0,
        expenseList: _expenseList,
        paymentList: _paymentList,
        initialCash: double.tryParse(_initialCashController.text) ?? 0,
        status: widget.isEditing ? widget.trip!.status : 'Ongoing',
        statusColor: widget.isEditing ? widget.trip!.statusColor : Colors.blue,
      );

      if (widget.isEditing) {
        await tripNotifier.updateTrip(newTrip);
      } else {
        await tripNotifier.addTrip(newTrip);
      }

      if (mounted) {
        AppToast.show(
          context,
          widget.isEditing
              ? 'Trip updated successfully'
              : 'Trip added successfully',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, 'Error saving trip: $e', isError: true);
      }
    }
  }

  // Controllers for all fields
  final TextEditingController _startKmController = TextEditingController();
  final TextEditingController _endKmController = TextEditingController();
  final TextEditingController _dieselController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _driverController = TextEditingController();

  // Expenses Controllers
  final TextEditingController _expenseItemController = TextEditingController();
  final TextEditingController _expenseAmountController =
      TextEditingController();

  // Payment Controllers
  final TextEditingController _initialCashController = TextEditingController();
  final TextEditingController _paymentDescController = TextEditingController();
  final TextEditingController _paymentAmountController =
      TextEditingController();

  String _totalKms = '0';
  String _mileage = '0.0';

  List<Map<String, String>> _expenseList = [];
  List<Map<String, String>> _paymentList = [];

  int? _editingExpenseIndex;
  int? _editingPaymentIndex;

  @override
  void initState() {
    super.initState();

    if (widget.isEditing && widget.trip != null) {
      final trip = widget.trip!;

      _fromController.text = trip.from;
      _toController.text = trip.to;
      _vehicleController.text = trip.vehicle;
      _driverController.text = trip.driver;
      _selectedDriverId = trip.driverId;

      _startDate = trip.startDate;
      _endDate = trip.endDate;

      _startKmController.text = trip.startKm.toString();
      _endKmController.text = trip.endKm.toString();
      _dieselController.text = trip.diesel.toString();

      _expenseList = List.from(
        trip.expenseList.map((e) => Map<String, String>.from(e)),
      );
      _paymentList = List.from(
        trip.paymentList.map((p) => Map<String, String>.from(p)),
      );

      _initialCashController.text = trip.initialCash.toString();
    } else {
      // Clear fields for Add flow
      _fromController.clear();
      _toController.clear();
      _vehicleController.clear();
      _driverController.clear();
      _startKmController.clear();
      _endKmController.clear();
      _dieselController.clear();

      _expenseList = [];
      _paymentList = [];
      _initialCashController.clear();

      _totalKms = '0';
      _mileage = '0.0';
      _startDate = null;
      _endDate = null;
    }

    _startKmController.addListener(_calculateMetrics);
    _endKmController.addListener(_calculateMetrics);
    _dieselController.addListener(_calculateMetrics);
    _initialCashController.addListener(() => setState(() {}));

    // Initial calculation
    _calculateMetrics();
  }

  @override
  void dispose() {
    _startKmController.dispose();
    _endKmController.dispose();
    _dieselController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _vehicleController.dispose();
    _driverController.dispose();
    _expenseItemController.dispose();
    _expenseAmountController.dispose();
    _initialCashController.dispose();
    _paymentDescController.dispose();
    _paymentAmountController.dispose();
    super.dispose();
  }

  void _calculateMetrics() {
    final double start = double.tryParse(_startKmController.text) ?? 0;
    final double end = double.tryParse(_endKmController.text) ?? 0;
    final double diesel = double.tryParse(_dieselController.text) ?? 0;

    final double total = end - start;
    final double mil = (diesel > 0 && total > 0) ? (total / diesel) : 0;

    setState(() {
      _totalKms = total > 0 ? total.toStringAsFixed(0) : '0';
      _mileage = mil > 0 ? mil.toStringAsFixed(2) : '0.0';
    });
  }

  void _switchStep(String step) {
    setState(() {
      _currentStep = step;
    });
  }

  void _saveAndContinue(String step, String message) {
    AppToast.show(context, message);
    _switchStep(step);
  }

  void _showToast(String message, {bool isError = false}) {
    AppToast.show(context, message, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isAdmin = user?.role == 'Admin';
    final isDriver = user?.role == 'Driver';
    
    // Determine effective read-only state for different sections
    final bool detailsReadOnly = widget.isReadOnly || isDriver;
    final bool expensesReadOnly = widget.isReadOnly;
    final bool paymentsReadOnly = widget.isReadOnly || isDriver;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _buildCurrentView(isAdmin, detailsReadOnly, expensesReadOnly, paymentsReadOnly)),
    );
  }

  Widget _buildCurrentView(bool isAdmin, bool detailsReadOnly, bool expensesReadOnly, bool paymentsReadOnly) {
    switch (_currentStep) {
      case 'summary':
        return _buildSummaryView(isAdmin);
      case 'details':
        return _buildDetailsEditView(detailsReadOnly);
      case 'expenses':
        return _buildExpensesEditView(expensesReadOnly);
      case 'payment':
        return _buildPaymentEditView(paymentsReadOnly);
      default:
        return _buildSummaryView(isAdmin);
    }
  }

  // --- 1. Summary View ---
  Widget _buildSummaryView(bool isAdmin) {
    return Column(
      children: [
        _buildHeader(
          widget.isEditing ? 'Edit Trip' : 'Add Trip',
          onBack: () => Navigator.pop(context),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildStepCard(
                widget.isEditing ? 'Edit Trip Details' : 'Add Trip Details',
                'Route, Dates, Vehicle, Drivers & KM',
                Icons.info_outline,
                'details',
                isCompleted: widget.isEditing,
              ),
              _buildStepCard(
                widget.isEditing
                    ? 'Edit Expenses Details'
                    : 'Add Expenses Details',
                'Diesel, Loading/Unloading, Tolls',
                Icons.receipt_long_outlined,
                'expenses',
                isCompleted: widget.isEditing,
              ),
              _buildStepCard(
                widget.isEditing
                    ? 'Edit Cash & Payment Details'
                    : 'Add Cash & Payment Details',
                'Hand Cash, G-Pay Settlement',
                Icons.account_balance_wallet_outlined,
                'payment',
                isCompleted: widget.isEditing,
              ),
              const SizedBox(height: 40),
              if (!widget.isReadOnly)
                AppButton(
                  label: widget.isEditing ? 'Update Trip' : 'Add Trip',
                  onPressed: _handleSaveTrip,
                  isLoading: _isLoading,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsEditView(bool isReadOnly) {
    return Column(
      children: [
        _buildHeader(
          widget.isEditing ? 'Edit Trip Details' : 'Add Trip Details',
          onBack: () => _switchStep('summary'),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppDatePicker(
                        label: 'Start Date',
                        hint: 'Select Date',
                        initialDate: _startDate,
                        enabled: !isReadOnly,
                        onDateSelected: (date) {
                          setState(() {
                            _startDate = date;
                            // Reset end date if it's now before start date
                            if (_endDate != null &&
                                _endDate!.isBefore(_startDate!)) {
                              _endDate = null;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppDatePicker(
                        label: 'End Date',
                        hint: 'Select Date',
                        initialDate: _endDate,
                        enabled: _startDate != null && !widget.isReadOnly,
                        firstDate: _startDate,
                        onDateSelected: (date) =>
                            setState(() => _endDate = date),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'From',
                        hint: 'Coimbatore',
                        controller: _fromController,
                        readOnly: isReadOnly,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'To',
                        hint: 'Madurai',
                        controller: _toController,
                        readOnly: isReadOnly,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ref.watch(vehicleProvider).isNotEmpty
                    ? AppDropdown<String>(
                        label: 'Vehicle',
                        hint: 'Select Vehicle',
                        prefixIcon: Icons.local_shipping_outlined,
                        value: _vehicleController.text.isEmpty
                            ? null
                            : _vehicleController.text,
                        readOnly: isReadOnly,
                        items: ref.watch(vehicleProvider).map((v) {
                          final value = '${v.regNumber} (${v.model})';
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _vehicleController.text = val);
                          }
                        },
                      )
                    : AppTextField(
                        label: 'Vehicle',
                        hint: 'TN-32 BB-1139',
                        prefixIcon: Icons.local_shipping_outlined,
                        controller: _vehicleController,
                        readOnly: isReadOnly,
                      ),
                const SizedBox(height: 16),
                ref.watch(driversStreamProvider).when(
                      data: (drivers) => drivers.isNotEmpty
                          ? AppDropdown<String>(
                              label: 'Driver Name',
                              hint: 'Select Driver',
                              prefixIcon: Icons.badge_outlined,
                              value: _selectedDriverId,
                              readOnly: isReadOnly,
                              items: drivers.map((d) {
                                return DropdownMenuItem(
                                  value: d.id,
                                  child: Text(d.name),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  final driver = drivers.firstWhere((d) => d.id == val);
                                  setState(() {
                                    _selectedDriverId = val;
                                    _driverController.text = driver.name;
                                  });
                                }
                              },
                            )
                          : AppTextField(
                              label: 'Driver Name',
                              hint: 'P. Keerthivasan',
                              prefixIcon: Icons.badge_outlined,
                              controller: _driverController,
                              readOnly: isReadOnly,
                            ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => AppTextField(
                        label: 'Driver Name',
                        hint: 'P. Keerthivasan',
                        prefixIcon: Icons.badge_outlined,
                        controller: _driverController,
                        readOnly: isReadOnly,
                      ),
                    ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Starting KMs',
                        hint: '0',
                        controller: _startKmController,
                        prefixIcon: Icons.speed,
                        keyboardType: TextInputType.number,
                        readOnly: widget.isReadOnly,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Closing KMs',
                        hint: '0',
                        controller: _endKmController,
                        prefixIcon: Icons.speed,
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Diesel (Ltrs)',
                  hint: '0.0',
                  controller: _dieselController,
                  prefixIcon: Icons.gas_meter_outlined,
                  keyboardType: TextInputType.number,
                  readOnly: isReadOnly,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Total KMs',
                        hint: '0',
                        initialValue: _totalKms,
                        prefixIcon: Icons.speed,
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Mileage (km/L)',
                        hint: '0.0',
                        initialValue: _mileage,
                        prefixIcon: Icons.local_gas_station_outlined,
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (!isReadOnly)
                  AppButton(
                    label: 'Save Details',
                    onPressed: () =>
                        _saveAndContinue('summary', 'Trip details saved locally'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesEditView(bool isReadOnly) {
    return Column(
      children: [
        _buildHeader(
          widget.isEditing ? 'Edit Expenses Details' : 'Add Expenses Details',
          onBack: () => _switchStep('summary'),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('ADD NEW EXPENSE'),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Item Name',
                  hint: 'e.g. Loading Charges',
                  controller: _expenseItemController,
                  readOnly: isReadOnly,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Amount',
                  hint: '₹0.00',
                  prefixIcon: Icons.currency_rupee,
                  controller: _expenseAmountController,
                  keyboardType: TextInputType.number,
                  readOnly: isReadOnly,
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: _editingExpenseIndex == null
                      ? 'Add to List'
                      : 'Update Item',
                  onPressed: isReadOnly
                      ? null
                      : () {
                          if (_expenseItemController.text.isNotEmpty &&
                              _expenseAmountController.text.isNotEmpty) {
                            setState(() {
                              if (_editingExpenseIndex == null) {
                                _expenseList.add({
                                  'title': _expenseItemController.text,
                                  'amount': '₹${_expenseAmountController.text}',
                                });
                                _showToast('Expense added to list');
                              } else {
                                _expenseList[_editingExpenseIndex!] = {
                                  'title': _expenseItemController.text,
                                  'amount': '₹${_expenseAmountController.text}',
                                };
                                _editingExpenseIndex = null;
                                _showToast('Expense item updated');
                              }
                              _expenseItemController.clear();
                              _expenseAmountController.clear();
                            });
                          } else {
                            _showToast('Please fill all fields', isError: true);
                          }
                        },
                  icon: _editingExpenseIndex == null ? Icons.add : Icons.check,
                  height: 48,
                ),
                if (_editingExpenseIndex != null && !isReadOnly)
                  _buildCancelButton(() {
                    setState(() {
                      _editingExpenseIndex = null;
                      _expenseItemController.clear();
                      _expenseAmountController.clear();
                    });
                  }),
                const SizedBox(height: 32),
                _buildSectionLabel('CURRENT EXPENSE LIST'),
                const SizedBox(height: 16),
                if (_expenseList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No expenses added yet',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  )
                else
                  ...List.generate(_expenseList.length, (index) {
                    final item = _expenseList[index];
                    return _buildListItem(
                      item['title']!,
                      item['amount']!,
                      onEdit: isReadOnly
                          ? null
                          : () {
                              setState(() {
                                _editingExpenseIndex = index;
                                _expenseItemController.text = item['title']!;
                                _expenseAmountController.text = item['amount']!
                                    .replaceAll('₹', '');
                              });
                            },
                      onDelete: isReadOnly
                          ? null
                          : () {
                              setState(() {
                                _expenseList.removeAt(index);
                                if (_editingExpenseIndex == index) {
                                  _editingExpenseIndex = null;
                                  _expenseItemController.clear();
                                  _expenseAmountController.clear();
                                }
                              });
                            },
                    );
                  }),
                const Divider(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL EXPENSES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '₹${_calculateTotal(_expenseList)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (!isReadOnly)
                  AppButton(
                    label: 'Save Expenses',
                    onPressed: () =>
                        _saveAndContinue('summary', 'Expense list updated'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentEditView(bool isReadOnly) {
    return Column(
      children: [
        _buildHeader(
          widget.isEditing
              ? 'Edit Payment & Cash Details'
              : 'Add Payment & Cash Details',
          onBack: () => _switchStep('summary'),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Initial Cash Paid (Owner)',
                  hint: '1,000',
                  prefixIcon: Icons.payments_outlined,
                  controller: _initialCashController,
                  keyboardType: TextInputType.number,
                  readOnly: isReadOnly,
                ),
                const SizedBox(height: 32),
                _buildSectionLabel('ADDITIONAL PAYMENTS / ADVANCE'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Description',
                        hint: 'e.g. Fuel Advance / G-Pay',
                        controller: _paymentDescController,
                        readOnly: isReadOnly,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Amount',
                        hint: '₹0.00',
                        prefixIcon: Icons.add_circle_outline,
                        controller: _paymentAmountController,
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: _editingPaymentIndex == null
                            ? 'Add Payment Entry'
                            : 'Update Payment Entry',
                        onPressed: isReadOnly
                            ? null
                            : () {
                                if (_paymentDescController.text.isNotEmpty &&
                                    _paymentAmountController.text.isNotEmpty) {
                                  setState(() {
                                    if (_editingPaymentIndex == null) {
                                      _paymentList.add({
                                        'title': _paymentDescController.text,
                                        'amount':
                                            '₹${_paymentAmountController.text}',
                                      });
                                      _showToast('Payment entry added');
                                    } else {
                                      _paymentList[_editingPaymentIndex!] = {
                                        'title': _paymentDescController.text,
                                        'amount':
                                            '₹${_paymentAmountController.text}',
                                      };
                                      _editingPaymentIndex = null;
                                      _showToast('Payment entry updated');
                                    }
                                    _paymentDescController.clear();
                                    _paymentAmountController.clear();
                                  });
                                } else {
                                  _showToast(
                                      'Please fill all fields', isError: true);
                                }
                              },
                        icon: _editingPaymentIndex == null
                            ? Icons.add
                            : Icons.check,
                        height: 48,
                      ),
                      if (_editingPaymentIndex != null && !isReadOnly)
                        _buildCancelButton(() {
                          setState(() {
                            _editingPaymentIndex = null;
                            _paymentDescController.clear();
                            _paymentAmountController.clear();
                          });
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_paymentList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No additional payments added yet',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  )
                else
                  ...List.generate(_paymentList.length, (index) {
                    final item = _paymentList[index];
                    return _buildListItem(
                      item['title']!,
                      item['amount']!,
                      onEdit: isReadOnly
                          ? null
                          : () {
                              setState(() {
                                _editingPaymentIndex = index;
                                _paymentDescController.text = item['title']!;
                                _paymentAmountController.text = item['amount']!
                                    .replaceAll('₹', '');
                              });
                            },
                      onDelete: isReadOnly
                          ? null
                          : () {
                              setState(() {
                                _paymentList.removeAt(index);
                                if (_editingPaymentIndex == index) {
                                  _editingPaymentIndex = null;
                                  _paymentDescController.clear();
                                  _paymentAmountController.clear();
                                }
                              });
                            },
                    );
                  }),
                const Divider(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL PAYMENTS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '₹${_calculateTotal(_paymentList)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (!isReadOnly)
                  AppButton(
                    label: widget.isEditing
                        ? 'Update Payment Details'
                        : 'Add Payment Details',
                    onPressed: () => _saveAndContinue(
                      'summary',
                      widget.isEditing
                          ? 'Payment details updated'
                          : 'Payment details added',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Reusable Components ---

  Widget _buildHeader(String title, {required VoidCallback onBack}) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: onBack,
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 48), // Balances the back button
            ],
          ),
        ),
      ],
    );
  }

  // --- Helper Methods ---

  Widget _buildStepCard(
    String title,
    String subtitle,
    IconData icon,
    String step, {
    bool isCompleted = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _switchStep(step),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isCompleted ? Colors.green : AppColors.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 20,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildListItem(
    String title,
    String amount, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              title.toLowerCase().contains('diesel')
                  ? Icons.local_gas_station
                  : Icons.receipt_long,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Recorded entry',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          if (!widget.isReadOnly)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSmallIconButton(
                  Icons.edit_rounded,
                  Colors.blue.shade600,
                  onEdit,
                ),
                const SizedBox(width: 8),
                _buildSmallIconButton(
                  Icons.delete_outline_rounded,
                  Colors.red.shade600,
                  onDelete,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSmallIconButton(
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  String _calculateTotal(List<Map<String, String>> list) {
    double total = 0;
    for (var item in list) {
      final amountStr =
          item['amount']?.replaceAll('₹', '').replaceAll(',', '') ?? '0';
      total += double.tryParse(amountStr) ?? 0;
    }
    return total.toStringAsFixed(0);
  }


  Widget _buildCancelButton(VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
          label: const Text(
            'Cancel Edit',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            backgroundColor: Colors.red.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.red.withValues(alpha: 0.15)),
            ),
          ),
        ),
      ),
    );
  }
}
