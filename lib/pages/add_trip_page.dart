import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/models/trip.dart';
import 'package:sivani_transport/providers/trip_provider.dart';
import 'package:sivani_transport/providers/auth_provider.dart';
import 'package:sivani_transport/providers/vehicle_provider.dart';
import 'package:sivani_transport/providers/driver_provider.dart';
import 'package:sivani_transport/providers/transporter_provider.dart';
import 'package:sivani_transport/models/vehicle.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sivani_transport/widgets/app_components.dart';

class AddTripPage extends ConsumerStatefulWidget {
  final bool isEditing;
  final Trip? trip;
  final bool isReadOnly;
  const AddTripPage({
    super.key,
    this.isEditing = false,
    this.trip,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends ConsumerState<AddTripPage> {
  String _currentStep = 'summary'; // summary, details, expenses, payment
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;
  bool _isCompleting = false;
  bool _isReopening = false;
  String? _selectedDriverId;
  String? _selectedTransporterId;

  // Controllers for all fields
  late TextEditingController _startKmController;
  late TextEditingController _endKmController;
  late TextEditingController _dieselController;
  late TextEditingController _fromController;
  late TextEditingController _toController;
  late TextEditingController _vehicleController;
  late TextEditingController _driverController;
  late TextEditingController _transporterController;
  late TextEditingController _loadsController; // A to D
  late TextEditingController _returnLoadsController; // D to A
  bool _hasReturn = false;

  // Expenses Controllers
  late TextEditingController _expenseItemController;
  late TextEditingController _expenseAmountController;
  String? _selectedExpenseCategory;
  final List<String> _expenseCategories = [
    'Diesel', 'Toll', 'Parking', 'Loading', 'Unloading', 'RTO', 
    'Police', 'Weight Bridge', 'Driver Batta', 'Cleaner Batta', 'Meal', 'Repair', 'Others'
  ];

  // Payments & Cash Controllers
  late TextEditingController _initialCashController;
  late TextEditingController _paymentDescController;
  late TextEditingController _paymentAmountController;

  String _selectedExpenseLeg = 'A to D'; // A to D, D to A

  String _totalKms = '0';
  String _mileage = '0.0';

  List<Map<String, String>> _expenseList = [];
  List<Map<String, String>> _paymentList = [];

  int? _editingExpenseIndex;
  int? _editingPaymentIndex;

  @override
  void initState() {
    super.initState();
    _startKmController = TextEditingController();
    _endKmController = TextEditingController();
    _dieselController = TextEditingController();
    _fromController = TextEditingController();
    _toController = TextEditingController();
    _vehicleController = TextEditingController();
    _driverController = TextEditingController();
    _transporterController = TextEditingController();
    _loadsController = TextEditingController();
    _returnLoadsController = TextEditingController();
    _expenseItemController = TextEditingController();
    _expenseAmountController = TextEditingController();
    _initialCashController = TextEditingController();
    _paymentDescController = TextEditingController();
    _paymentAmountController = TextEditingController();

    if (widget.isEditing && widget.trip != null) {
      final trip = widget.trip!;

      _fromController.text = trip.from;
      _toController.text = trip.to;
      _vehicleController.text = trip.vehicle;
      _driverController.text = trip.driver;
      _selectedDriverId = trip.driverId;
      _transporterController.text = trip.transporter ?? '';
      _selectedTransporterId = trip.transporterId;

      _startDate = trip.startDate;
      _endDate = trip.endDate;

      _initialCashController.text = trip.initialCash.toInt() == 0 ? '' : trip.initialCash.toString();
      _startKmController.text = trip.startKm.toInt() == 0 ? '' : trip.startKm.toString();
      _endKmController.text = trip.endKm.toInt() == 0 ? '' : trip.endKm.toString();
      _dieselController.text = trip.diesel.toInt() == 0 ? '' : trip.diesel.toString();
      _loadsController.text = trip.outwardLoads.toInt() == 0 ? '' : trip.outwardLoads.toString();
      _returnLoadsController.text = trip.returnLoads.toInt() == 0 ? '' : trip.returnLoads.toString();
      _hasReturn = trip.hasReturn;

      _expenseList = List.from(
        trip.expenseList.map((e) => Map<String, String>.from(e)),
      );
      _paymentList = List.from(
        trip.paymentList.map((p) => Map<String, String>.from(p)),
      );

    }

    _startKmController.addListener(_calculateMetrics);
    _endKmController.addListener(_calculateMetrics);
    _dieselController.addListener(_calculateMetrics);
    _initialCashController.addListener(() => setState(() {}));
    _fromController.addListener(() => setState(() {}));
    _toController.addListener(() => setState(() {}));
    _vehicleController.addListener(() => setState(() {}));
    _driverController.addListener(() => setState(() {}));
    _transporterController.addListener(() => setState(() {}));
    _loadsController.addListener(() => setState(() {}));
    _returnLoadsController.addListener(() => setState(() {}));

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
    _transporterController.dispose();
    _loadsController.dispose();
    _returnLoadsController.dispose();
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

    if (mounted) {
      setState(() {
        _totalKms = total > 0 ? total.toStringAsFixed(0) : '0';
        _mileage = mil > 0 ? mil.toStringAsFixed(2) : '0.0';
      });
    }
  }

  void _switchStep(String step) {
    setState(() {
      _currentStep = step;
    });
  }

  Future<void> _onBackAction() async {
    // If not on summary, go back to summary first
    if (_currentStep != 'summary') {
      _switchStep('summary');
      return;
    }

    // If on summary and dirty, show confirmation
    if (_isDirty && !widget.isReadOnly) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text('You have unsaved changes. Are you sure you want to leave?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      
      if (confirm == true && mounted) {
        Navigator.pop(context);
      }
    } else {
      // Not dirty or read-only, just pop
      if (mounted) Navigator.pop(context);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    AppToast.show(context, message, isError: isError);
  }

  void _handleSaveTrip() async {
    final vList = ref.read(vehicleProvider);
    final selV = vList.firstWhere(
      (v) => '${v.regNumber} (${v.model})' == _vehicleController.text,
      orElse: () => Vehicle(id: '', model: '', regNumber: '', fuelType: '', capacity: 0.0),
    );
    if (selV.capacity > 0) {
      final outLoad = double.tryParse(_loadsController.text) ?? 0.0;
      final inLoad = double.tryParse(_returnLoadsController.text) ?? 0.0;
      if (outLoad > selV.capacity || inLoad > selV.capacity) {
        _showToast('Load exceeds vehicle capacity (${selV.capacity} T)!', isError: true);
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final tripNotifier = ref.read(tripProvider.notifier);

      final newTrip = Trip(
        id: widget.isEditing ? widget.trip!.id : '',
        from: _fromController.text,
        to: _toController.text,
        vehicle: _vehicleController.text,
        plate: 'ABC-1234',
        driver: _driverController.text,
        driverId: _selectedDriverId,
        transporter: _transporterController.text,
        transporterId: _selectedTransporterId,
        startDate: _startDate,
        endDate: _endDate,
        startKm: double.tryParse(_startKmController.text) ?? 0.0,
        endKm: double.tryParse(_endKmController.text) ?? 0.0,
        diesel: double.tryParse(_dieselController.text) ?? 0.0,
        outwardLoads: double.tryParse(_loadsController.text) ?? 0.0,
        returnLoads: double.tryParse(_returnLoadsController.text) ?? 0.0,
        hasReturn: _hasReturn,
        expenseList: _expenseList,
        paymentList: _paymentList,
        initialCash: double.tryParse(_initialCashController.text) ?? 0.0,
        status: widget.isEditing ? widget.trip!.status : 'Ongoing',
        statusColor: widget.isEditing ? widget.trip!.statusColor : Colors.blue,
      );

      if (widget.isEditing) {
        await tripNotifier.updateTrip(newTrip);
      } else {
        await tripNotifier.addTrip(newTrip);
      }
      _showToast(widget.isEditing ? 'Trip Updated' : 'Trip Added');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showToast('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleCompleteTrip() async {
    setState(() => _isCompleting = true);
    try {
      final tripNotifier = ref.read(tripProvider.notifier);
      final trip = widget.trip!;
      
      final completedTrip = trip.copyWith(
        status: 'Completed',
        statusColor: const Color(0xFF10B981), // Green
        endKm: double.tryParse(_endKmController.text) ?? trip.endKm,
        outwardLoads: double.tryParse(_loadsController.text) ?? trip.outwardLoads,
        returnLoads: double.tryParse(_returnLoadsController.text) ?? trip.returnLoads,
        hasReturn: _hasReturn,
      );

      await tripNotifier.updateTrip(completedTrip);
      _showToast('Trip Completed Successfully!');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showToast('Error completing trip: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  void _handleReopenTrip() async {
    setState(() => _isReopening = true);
    try {
      final tripNotifier = ref.read(tripProvider.notifier);
      final trip = widget.trip!;
      
      final reopenedTrip = trip.copyWith(
        status: 'Ongoing',
        statusColor: Colors.blue,
      );

      await tripNotifier.updateTrip(reopenedTrip);
      _showToast('Trip Reopened successfully');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showToast('Error reopening trip: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isReopening = false);
    }
  }

  bool get _isDirty {
    if (widget.isEditing && widget.trip != null) {
      final t = widget.trip!;
      return _fromController.text != t.from ||
          _toController.text != t.to ||
          _vehicleController.text != t.vehicle ||
          _driverController.text != t.driver ||
          _startDate != t.startDate ||
          _endDate != t.endDate ||
          (double.tryParse(_startKmController.text) ?? 0.0) != t.startKm ||
          (double.tryParse(_endKmController.text) ?? 0.0) != t.endKm ||
          (double.tryParse(_dieselController.text) ?? 0.0) != t.diesel ||
          (double.tryParse(_loadsController.text) ?? 0.0) != (t.outwardLoads) ||
          (double.tryParse(_returnLoadsController.text) ?? 0.0) != (t.returnLoads) ||
          _hasReturn != t.hasReturn ||
          (double.tryParse(_initialCashController.text) ?? 0.0) != t.initialCash ||
          _expenseList.length != t.expenseList.length ||
          _paymentList.length != t.paymentList.length;
    } else {
      return _fromController.text.isNotEmpty ||
          _toController.text.isNotEmpty ||
          _vehicleController.text.isNotEmpty ||
          _driverController.text.isNotEmpty ||
          _startDate != null ||
          _expenseList.isNotEmpty ||
          _paymentList.isNotEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isAdmin = (user?.role ?? '').toLowerCase() == 'admin';
    final isDriver = user?.role == 'Driver';

    final bool detailsReadOnly = widget.isReadOnly || isDriver;
    final bool expensesReadOnly = widget.isReadOnly;
    final bool paymentsReadOnly = widget.isReadOnly || isDriver;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBackAction();
      },
      child: _buildCurrentView(
        isAdmin,
        isDriver,
        detailsReadOnly,
        expensesReadOnly,
        paymentsReadOnly,
      ),
    );
  }

  Widget _buildCurrentView(
    bool isAdmin,
    bool isDriver,
    bool detailsReadOnly,
    bool expensesReadOnly,
    bool paymentsReadOnly,
  ) {
    switch (_currentStep) {
      case 'summary':
        return _buildSummaryView(isAdmin, isDriver);
      case 'details':
        return _buildDetailsEditView(detailsReadOnly);
      case 'expenses':
        return _buildExpensesEditView(expensesReadOnly);
      case 'payment':
        return _buildPaymentEditView(paymentsReadOnly);
      default:
        return _buildSummaryView(isAdmin, isDriver);
    }
  }

  Widget _buildSummaryView(bool isAdmin, bool isDriver) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isReadOnly ? 'Trip Details' : (widget.isEditing ? 'Edit Trip' : 'Add Trip'),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: _onBackAction,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppStepCard(
              title: 'Route Details',
              subtitle: (_fromController.text.isEmpty && _toController.text.isEmpty)
                  ? 'Select origin and destination'
                  : '${_fromController.text.isEmpty ? '?' : _fromController.text} ➔ ${_toController.text.isEmpty ? '?' : _toController.text}'  
                      '${_hasReturn ? ' • Round Trip' : ''}'  
                      '${_loadsController.text.isNotEmpty ? ' • ${_loadsController.text} T' : ''}',
              icon: Icons.info_outline,
              onTap: () => _switchStep('details'),
              isCompleted: _fromController.text.isNotEmpty && _toController.text.isNotEmpty,
            ),
            AppStepCard(
              title: 'Expenses',
              subtitle: () {
                if (_expenseList.isEmpty) return 'No expenses added';
                double outward = 0;
                double inward = 0;
                for (var e in _expenseList) {
                  final amt = double.tryParse((e['amount'] ?? '0').replaceAll('₹', '')) ?? 0;
                  if (e['leg'] == 'A to D') outward += amt;
                  else if (e['leg'] == 'D to A') inward += amt;
                }
                final total = '₹${_calculateTotal(_expenseList)}';
                if (_hasReturn && (outward > 0 || inward > 0)) {
                  return '${_expenseList.length} items • $total  (A➔D: ₹${outward.toStringAsFixed(0)} • D➔A: ₹${inward.toStringAsFixed(0)})';
                }
                return '${_expenseList.length} items • $total';
              }(),
              icon: Icons.receipt_long_outlined,
              onTap: () => _switchStep('expenses'),
              isCompleted: _expenseList.isNotEmpty,
            ),
            AppStepCard(
              title: 'Payments',
              subtitle: () {
                double initial = double.tryParse(_initialCashController.text) ?? 0;
                double additional = 0;
                for (var item in _paymentList) {
                  final amountStr = item['amount']?.replaceAll('₹', '').replaceAll(',', '') ?? '0';
                  additional += double.tryParse(amountStr) ?? 0;
                }
                double expenses = double.tryParse(_calculateTotal(_expenseList)) ?? 0;
                return 'Total: ₹${(initial + additional).toStringAsFixed(0)} • Bal: ₹${(initial + additional - expenses).toStringAsFixed(0)}';
              }(),
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => _switchStep('payment'),
              isCompleted: _initialCashController.text.isNotEmpty || _paymentList.isNotEmpty,
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.isReadOnly ? null : Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Row(
          children: [
            if (widget.isEditing && widget.trip!.status != 'Completed' && !isDriver)
              Expanded(
                child: AppButton(
                  label: 'Complete Trip',
                  icon: Icons.check_circle_outline_rounded,
                  backgroundColor: const Color(0xFF10B981),
                  onPressed: _showCompletionConfirmation,
                  isLoading: _isCompleting,
                ),
              )
            else if (widget.isEditing && widget.trip!.status == 'Completed' && isAdmin)
              Expanded(
                child: AppButton(
                  label: 'Reopen Trip',
                  icon: Icons.lock_open_rounded,
                  backgroundColor: Colors.blue,
                  onPressed: _showReopenConfirmation,
                  isLoading: _isReopening,
                ),
              ),
            if (widget.isEditing && ((widget.trip!.status != 'Completed' && !isDriver) || isAdmin))
              const SizedBox(width: 12),
            Expanded(
              flex: (widget.isEditing && ((widget.trip!.status != 'Completed' && !isDriver) || isAdmin)) ? 1 : 2,
              child: AppButton(
                label: widget.isEditing ? 'Update Trip' : 'Add Trip',
                onPressed: _handleSaveTrip,
                isLoading: _isSaving,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsEditView(bool isReadOnly) {
    final vList = ref.watch(vehicleProvider);
    final selV = vList.firstWhere(
      (v) => '${v.regNumber} (${v.model})' == _vehicleController.text,
      orElse: () => Vehicle(id: '', model: '', regNumber: '', fuelType: '', capacity: 0.0),
    );
    final capLimit = selV.capacity;
    final outVal = double.tryParse(_loadsController.text) ?? 0.0;
    final inVal = double.tryParse(_returnLoadsController.text) ?? 0.0;
    final outErr = (capLimit > 0 && outVal > capLimit) ? 'Exceeds capacity (${capLimit.toStringAsFixed(1)} T)' : null;
    final inErr = (capLimit > 0 && inVal > capLimit) ? 'Exceeds capacity (${capLimit.toStringAsFixed(1)} T)' : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Route & Details' : 'Add Route & Details',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: _onBackAction,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        enabled: _startDate != null && !isReadOnly,
                        firstDate: _startDate,
                        onDateSelected: (date) => setState(() => _endDate = date),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'From',
                        hint: 'Coimbatore',
                        controller: _fromController,
                        readOnly: isReadOnly,
                      ),
                    ),
                    if (!isReadOnly)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              final temp = _fromController.text;
                              _fromController.text = _toController.text;
                              _toController.text = temp;
                            });
                          },
                          icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                          tooltip: 'Swap Route',
                        ),
                      )
                    else
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
                        value: _vehicleController.text.isEmpty ? null : _vehicleController.text,
                        readOnly: isReadOnly,
                        items: ref.watch(vehicleProvider).map((v) {
                          final value = '${v.regNumber} (${v.model})';
                          return DropdownMenuItem(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _vehicleController.text = val);
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
                      data: (drivers) => AppDropdown<String>(
                        label: 'Driver Name',
                        hint: 'Select Driver',
                        prefixIcon: Icons.badge_outlined,
                        value: _selectedDriverId,
                        readOnly: isReadOnly,
                        items: drivers.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final driver = drivers.firstWhere((d) => d.id == val);
                            setState(() {
                              _selectedDriverId = val;
                              _driverController.text = driver.name;
                            });
                          }
                        },
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
                ref.watch(transportersStreamProvider).when(
                      data: (transporters) => AppDropdown<String>(
                        label: 'Transporter Name',
                        hint: 'Select Transporter',
                        prefixIcon: Icons.business_outlined,
                        value: _selectedTransporterId,
                        readOnly: isReadOnly,
                        items: transporters.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final transporter = transporters.firstWhere((t) => t.id == val);
                            setState(() {
                              _selectedTransporterId = val;
                              _transporterController.text = transporter.name;
                            });
                          }
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => AppTextField(
                        label: 'Transporter Name',
                        hint: 'Sivani Transport',
                        prefixIcon: Icons.business_outlined,
                        controller: _transporterController,
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
                        readOnly: isReadOnly,
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
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Diesel (Ltrs)',
                        hint: '0.0',
                        controller: _dieselController,
                        prefixIcon: Icons.gas_meter_outlined,
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: _hasReturn ? 'A to D Loads' : 'Number of Loads',
                        hint: '0',
                        controller: _loadsController,
                        prefixIcon: Icons.unarchive_outlined,
                        keyboardType: TextInputType.number,
                        onChanged: (val) => setState(() {}),
                        errorText: outErr,
                        readOnly: isReadOnly,
                      ),
                    ),
                  ],
                ),
                if (_hasReturn) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'D to A Loads',
                    hint: '0',
                    controller: _returnLoadsController,
                    prefixIcon: Icons.unarchive_outlined,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setState(() {}),
                    errorText: inErr,
                    readOnly: isReadOnly,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Include Return Trip (Back to Origin)?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _hasReturn ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _hasReturn,
                      activeTrackColor: AppColors.primary,
                      onChanged: isReadOnly ? null : (val) => setState(() => _hasReturn = val),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Total KMs',
                        hint: '0',
                        readOnly: true,
                        controller: TextEditingController(text: _totalKms),
                        prefixIcon: Icons.map_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Mileage (KM/L)',
                        hint: '0.0',
                        readOnly: true,
                        controller: TextEditingController(text: _mileage),
                        prefixIcon: Icons.auto_graph_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildExpensesEditView(bool isReadOnly) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Expenses' : 'Add Expenses',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: _onBackAction,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasReturn && !isReadOnly) ...[
                  const Text('Select Trip Leg', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildLegTab('A to D', _selectedExpenseLeg == 'A to D'),
                      const SizedBox(width: 8),
                      _buildLegTab('D to A', _selectedExpenseLeg == 'D to A'),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                _buildExpenseForm(isReadOnly),
                const SizedBox(height: 32),
                _buildSectionLabel('Direct Expenses List'),
                const SizedBox(height: 16),
                if (_expenseList.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('No expenses added yet', style: TextStyle(color: Colors.grey))))
                else
                  ...List.generate(_expenseList.length, (index) {
                    final item = _expenseList[index];
                    return AppListItem(
                      title: item['title']!,
                      amount: item['amount']!,
                      subtitle: item['leg'],
                      color: item['leg'] == 'A to D' ? Colors.blue : Colors.orange,
                      onEdit: isReadOnly ? null : () {
                        setState(() {
                          _editingExpenseIndex = index;
                          _selectedExpenseCategory = item['title']!.split(' ')[0]; // Basic recovery of category
                          _expenseAmountController.text = item['amount']!.replaceAll('₹', '');
                          _selectedExpenseLeg = item['leg'] ?? 'A to D';
                        });
                      },
                      onDelete: isReadOnly ? null : () {
                        AppDeleteConfirmation.show(
                          context,
                          title: 'Expense',
                          itemName: item['title']!,
                          onConfirm: () => setState(() => _expenseList.removeAt(index)),
                        );
                      },
                    );
                  }),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildExpenseForm(bool isReadOnly) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          AppDropdown<String>(
            label: 'Expense Category',
            hint: 'Select Category',
            prefixIcon: Icons.category_outlined,
            value: _selectedExpenseCategory,
            readOnly: isReadOnly,
            items: _expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) => setState(() => _selectedExpenseCategory = val),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Amount (₹)', 
            hint: '0', 
            controller: _expenseAmountController, 
            keyboardType: TextInputType.number, 
            readOnly: isReadOnly, 
            prefixIcon: Icons.currency_rupee,
          ),
          const SizedBox(height: 24),
          if (_editingExpenseIndex != null) 
            _buildCancelButton(() => setState(() { 
              _editingExpenseIndex = null; 
              _expenseAmountController.clear();
              _selectedExpenseCategory = null;
            })),
          AppButton(
            label: _editingExpenseIndex == null ? 'Add to List' : 'Update Item',
            onPressed: isReadOnly ? null : () {
              if (_selectedExpenseCategory == null || _expenseAmountController.text.isEmpty) {
                AppToast.show(context, 'Please select a category and enter amount!', isError: true);
                return;
              }

              final double initial = double.tryParse(_initialCashController.text) ?? 0;
              double additional = 0;
              for (var p in _paymentList) {
                additional += double.tryParse(p['amount']!.replaceAll('₹', '')) ?? 0;
              }

              if (initial + additional <= 0) {
                AppToast.show(context, 'Please add an Advance or Payment first!', isError: true);
                return;
              }

              setState(() {
                if (_editingExpenseIndex == null) {
                  // Calculate count for auto-increment
                  int count = 0;
                  for (var e in _expenseList) {
                    if (e['leg'] == _selectedExpenseLeg && e['title']!.startsWith(_selectedExpenseCategory!)) {
                      count++;
                    }
                  }
                  
                  final title = '${_selectedExpenseCategory!} ${count + 1}';
                  
                  _expenseList.add({
                    'title': title,
                    'amount': '₹${_expenseAmountController.text}',
                    'leg': _selectedExpenseLeg
                  });
                } else {
                  _expenseList[_editingExpenseIndex!] = {
                    'title': _expenseList[_editingExpenseIndex!]['title']!, // Keep original title on edit
                    'amount': '₹${_expenseAmountController.text}',
                    'leg': _selectedExpenseLeg
                  };
                  _editingExpenseIndex = null;
                }
                _expenseAmountController.clear();
                _selectedExpenseCategory = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentEditView(bool isReadOnly) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Payment & Cash' : 'Add Payment & Cash',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: _onBackAction,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Advance Received', hint: '0',
                  prefixIcon: Icons.payments_outlined, controller: _initialCashController,
                  keyboardType: TextInputType.number, readOnly: isReadOnly,
                ),
                const SizedBox(height: 32),
                if (!isReadOnly) ...[
                  _buildSectionLabel('Additional Payments'),
                  const SizedBox(height: 16),
                  _buildPaymentForm(isReadOnly),
                  const SizedBox(height: 24),
                ],
                if (_paymentList.isEmpty)
                  const Center(child: Text('No additional payments added yet', style: TextStyle(color: Colors.grey, fontSize: 12)))
                else
                  ...List.generate(_paymentList.length, (index) {
                    final item = _paymentList[index];
                    return AppListItem(
                      title: item['title']!,
                      amount: item['amount']!,
                      onEdit: isReadOnly ? null : () {
                        setState(() {
                          _editingPaymentIndex = index;
                          _paymentDescController.text = item['title']!;
                          _paymentAmountController.text = item['amount']!.replaceAll('₹', '');
                        });
                      },
                      onDelete: isReadOnly ? null : () {
                        AppDeleteConfirmation.show(
                          context,
                          title: 'Payment',
                          itemName: item['title']!,
                          onConfirm: () => setState(() => _paymentList.removeAt(index)),
                        );
                      },
                    );
                  }),
                const SizedBox(height: 24),
                _buildFinalSummary(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildPaymentForm(bool isReadOnly) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.blue.shade50)),
      child: Column(
        children: [
           AppTextField(label: 'Description', hint: 'Fuel Advance', controller: _paymentDescController, readOnly: isReadOnly),
           const SizedBox(height: 16),
           AppTextField(label: 'Amount', hint: '0.00', controller: _paymentAmountController, keyboardType: TextInputType.number, readOnly: isReadOnly),
           const SizedBox(height: 20),
           AppButton(
             label: _editingPaymentIndex == null ? 'Add Payment' : 'Save Changes',
             onPressed: isReadOnly ? null : () {
               if(_paymentDescController.text.isNotEmpty && _paymentAmountController.text.isNotEmpty) {
                 setState(() {
                   if(_editingPaymentIndex == null) {
                     _paymentList.add({'title': _paymentDescController.text, 'amount': '₹${_paymentAmountController.text}'});
                   } else {
                     _paymentList[_editingPaymentIndex!] = {'title': _paymentDescController.text, 'amount': '₹${_paymentAmountController.text}'};
                     _editingPaymentIndex = null;
                   }
                   _paymentDescController.clear(); _paymentAmountController.clear();
                 });
               }
             },
           )
        ],
      ),
    );
  }

  Widget _buildFinalSummary() {
    double initial = double.tryParse(_initialCashController.text) ?? 0;
    double add = 0;
    for (var p in _paymentList) {
      add += double.tryParse(p['amount']!.replaceAll('₹', '')) ?? 0;
    }
    double exp = double.tryParse(_calculateTotal(_expenseList)) ?? 0;
    final double balance = initial + add - exp;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          AppSummaryRow(
            label: 'Total Payments',
            value: '₹${(initial + add).toStringAsFixed(0)}',
            valueColor: const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          AppSummaryRow(
            label: 'Total Expenses',
            value: '₹${exp.toStringAsFixed(0)}',
            valueColor: const Color(0xFFEF4444),
          ),
          const Divider(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.05),
                  AppColors.primary.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Balance',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '₹${balance.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)));
  Widget _buildCancelButton(VoidCallback onTap) => TextButton.icon(onPressed: onTap, icon: const Icon(Icons.close, color: Colors.red), label: const Text('Cancel Edit', style: TextStyle(color: Colors.red)));
  String _calculateTotal(List<Map<String, String>> l) {
    double t = 0;
    for (var i in l) {
      t += double.tryParse(i['amount']!.replaceAll('₹', '')) ?? 0;
    }
    return t.toStringAsFixed(0);
  }

  void _showReopenConfirmation() {
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Reopen?'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')), TextButton(onPressed: () { Navigator.pop(context); _handleReopenTrip(); }, child: const Text('Yes'))]));
  }

  void _showCompletionConfirmation() {
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Complete?'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')), TextButton(onPressed: () { Navigator.pop(context); _handleCompleteTrip(); }, child: const Text('Yes'))]));
  }

  Widget _buildLegTab(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedExpenseLeg = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
