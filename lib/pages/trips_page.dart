import 'package:flutter/material.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/widgets/app_components.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  String _selectedStatus = 'Active';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _trips = [
    {
      'id': 'TRIP-4451',
      'date': 'Oct 24, 2023',
      'vehicle': 'Mercedes Sprinter',
      'plate': 'ABC-1234',
      'driver': 'Johnathan Miller',
      'status': 'Completed',
      'statusColor': Colors.green,
      'amount': r'$200.00',
      'route': 'Chicago • Detroit',
    },
    {
      'id': 'TRIP-4452',
      'date': 'Oct 25, 2023',
      'vehicle': 'Volvo FH16',
      'plate': 'XYZ-5678',
      'driver': 'Sarah Thompson',
      'status': 'Ongoing',
      'statusColor': Colors.blue,
      'amount': r'$350.00',
      'route': 'New York • Boston',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = 'Active';
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredTrips {
    final status = _selectedStatus;
    
    // Status Filter
    Iterable<Map<String, dynamic>> result = status == 'Active'
        ? _trips.where((trip) => trip['status'] != 'Completed')
        : _trips.where((trip) => trip['status'] == 'Completed');

    // Search Filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((trip) {
        final String id = (trip['id'] ?? '').toString().toLowerCase();
        final String driver = (trip['driver'] ?? '').toString().toLowerCase();
        final String vehicle = (trip['vehicle'] ?? '').toString().toLowerCase();
        final String route = (trip['route'] ?? '').toString().toLowerCase();
        
        return id.contains(_searchQuery) ||
               driver.contains(_searchQuery) ||
               vehicle.contains(_searchQuery) ||
               route.contains(_searchQuery);
      });
    }

    return result.toList();
  }

  void _showTripWizard({bool isEditing = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => TripWizardSheet(isEditing: isEditing),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        //   onPressed: () {},
        // ),
        title: const Text(
          'Trip Management',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 12),
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search trips by driver or vehicle',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Create New Trip Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _showTripWizard,
                icon: const Icon(Icons.add_task_outlined, size: 20),
                label: const Text(
                  'Create New Trip',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  minimumSize: Size.zero,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Premium Filter Tabs
            Container(
              height: 52,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterTab(
                      'Active',
                      Icons.local_shipping_rounded,
                    ),
                  ),
                  Expanded(
                    child: _buildFilterTab(
                      'Finished',
                      Icons.check_circle_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Section Header (Integrated with Padding)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_selectedStatus Trips (${_filteredTrips.length})',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Trip Cards
            ..._filteredTrips.map((trip) => _buildTripCard(trip)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, IconData icon) {
    final bool isSelected = _selectedStatus == label;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!isSelected) {
          setState(() => _selectedStatus = label);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutQuart,
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.blueGrey.shade400,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.blueGrey.shade700,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    Color(0xFF2563EB),
                  ],
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trip['id']?.toString() ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20), // More rounded for a pill look
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
                              trip['status']?.toString().toLowerCase() == 'finished'
                                  ? Icons.check_circle_rounded
                                  : Icons.fiber_manual_record,
                              size: 10,
                              color: trip['status']?.toString().toLowerCase() == 'finished'
                                  ? const Color(0xFFEF4444) // Brighter Red
                                  : const Color(0xFF10B981), // Brighter Emerald Green
                            ),
                            const SizedBox(width: 4),
                            Text(
                              trip['status']?.toString().toUpperCase() ?? '',
                              style: TextStyle(
                                color: trip['status']?.toString().toLowerCase() == 'finished'
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF10B981),
                                fontSize: 9,
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
                      const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (trip['route']?.toString().split('•').first ?? '').trim(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text('Departure', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded, color: Colors.white38, size: 16),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              (trip['route']?.toString().split('•').last ?? '').trim(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text('Destination', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Body Details
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL FREIGHT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trip['amount']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildModernAction(Icons.edit_rounded, AppColors.primary, () => _showTripWizard(isEditing: true)),
                  const SizedBox(width: 8),
                  _buildModernAction(Icons.delete_outline_rounded, Colors.redAccent, () {}),
                ],
              ),
            ),

            // 3. Attached Separate Detail Boxes
            Row(
              children: [
                _buildStatBox(Icons.event_note_rounded, 'Date', trip['date']?.toString() ?? '', isFirst: true),
                _buildStatBox(Icons.local_shipping_rounded, 'Vehicle', trip['vehicle']?.toString() ?? ''),
                _buildStatBox(Icons.face_rounded, 'Driver', trip['driver']?.toString().split(' ').first ?? '', isLast: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(IconData icon, String label, String value, {bool isFirst = false, bool isLast = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border(
            top: const BorderSide(color: Color(0xFFF1F5F9)),
            right: isLast ? BorderSide.none : const BorderSide(color: Color(0xFFF1F5F9)),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
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

class TripWizardSheet extends StatefulWidget {
  final bool isEditing;
  const TripWizardSheet({super.key, this.isEditing = false});

  @override
  State<TripWizardSheet> createState() => _TripWizardSheetState();
}

class _TripWizardSheetState extends State<TripWizardSheet> {
  String _currentStep = 'summary'; // summary, details, expenses, payment
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  void _handleSaveTrip() async {
    setState(() => _isLoading = true);
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing ? 'Trip updated successfully' : 'Trip added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Controllers for auto-calculation
  final TextEditingController _startKmController = TextEditingController(text: '27530');
  final TextEditingController _endKmController = TextEditingController(text: '27865');
  final TextEditingController _dieselController = TextEditingController(text: '147.19');

  String _totalKms = '335';
  String _mileage = '2.28';

  @override
  void initState() {
    super.initState();
    _startKmController.addListener(_calculateMetrics);
    _endKmController.addListener(_calculateMetrics);
    _dieselController.addListener(_calculateMetrics);
  }

  @override
  void dispose() {
    _startKmController.dispose();
    _endKmController.dispose();
    _dieselController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        child: _buildCurrentView(),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentStep) {
      case 'summary':
        return _buildSummaryView();
      case 'details':
        return _buildDetailsEditView();
      case 'expenses':
        return _buildExpensesEditView();
      case 'payment':
        return _buildPaymentEditView();
      default:
        return _buildSummaryView();
    }
  }

  // --- 1. Summary View ---
  Widget _buildSummaryView() {
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
                'Trip Details',
                'Route, Dates, Vehicle, Drivers & KM',
                Icons.info_outline,
                'details',
                isCompleted: true,
              ),
              _buildStepCard(
                'Expenses Details',
                'Diesel, Loading/Unloading, Tolls',
                Icons.receipt_long_outlined,
                'expenses',
                isCompleted: false,
              ),
              _buildStepCard(
                'Cash & Payment Details',
                'Hand Cash, G-Pay Settlement',
                Icons.account_balance_wallet_outlined,
                'payment',
                isCompleted: false,
              ),
              const SizedBox(height: 40),
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

  Widget _buildDetailsEditView() {
    return Column(
      children: [
        _buildHeader(
          widget.isEditing ? 'Edit Trip Details' : 'Trip Details',
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
                        onDateSelected: (date) {
                          setState(() {
                            _startDate = date;
                            // Reset end date if it's now before start date
                            if (_endDate != null && _endDate!.isBefore(_startDate!)) {
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
                        firstDate: _startDate, // This is the fix!
                        onDateSelected: (date) => setState(() => _endDate = date),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: AppTextField(label: 'From', hint: 'Coimbatore')),
                    const SizedBox(width: 12),
                    Expanded(child: AppTextField(label: 'To', hint: 'Madurai')),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Vehicle',
                  hint: 'TN-32 BB-1139',
                  prefixIcon: Icons.local_shipping_outlined,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Driver Name',
                  hint: 'P. Keerthivasan',
                  prefixIcon: Icons.badge_outlined,
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
                AppButton(
                  label: 'Save Details',
                  onPressed: () => _switchStep('summary'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesEditView() {
    return Column(
      children: [
        _buildHeader(
          widget.isEditing ? 'Edit Expenses Details' : 'Expenses Details',
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
                AppTextField(label: 'Item Name', hint: 'e.g. Loading Charges'),
                const SizedBox(height: 12),
                AppTextField(label: 'Amount', hint: '₹0.00', prefixIcon: Icons.currency_rupee),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add to List'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionLabel('CURRENT EXPENSE LIST'),
                const SizedBox(height: 16),
                _buildListItem('Diesel Filling', '₹12,727'),
                _buildListItem('Loading Charges', '₹500'),
                _buildListItem('Unloading Charges', '₹1,800'),
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
                      '₹15,027',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Save Expenses',
                  onPressed: () => _switchStep('summary'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentEditView() {
    return Column(
      children: [
        _buildHeader(
          widget.isEditing ? 'Edit Payment & Cash' : 'Payment & Cash Details',
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
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Amount',
                        hint: '₹0.00',
                        prefixIcon: Icons.add_circle_outline,
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Add Payment Entry',
                        onPressed: () {},
                        icon: Icons.add,
                        height: 48,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildListItem('G-Pay Settlement', '₹2,000'),
                _buildListItem('Extra for Tolls', '₹500'),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL AMOUNT',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '₹3,500',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Update Payment Details',
                  onPressed: () => _switchStep('summary'),
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
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
        trailing: Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
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

  Widget _buildListItem(String title, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Icon(Icons.edit_outlined, size: 16, color: Colors.blue.shade300),
        ],
      ),
    );
  }
}
