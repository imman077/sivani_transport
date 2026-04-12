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

  final List<TextEditingController> _stopControllers = [];

  // Expenses Controllers
  late TextEditingController _expenseItemController;
  late TextEditingController _expenseAmountController;
  String? _selectedExpenseCategory;
  final List<String> _expenseCategories = [
    'Diesel', 'Toll', 'Parking', 'Loading', 'Unloading', 'RTO', 
    'Police', 'Weight Bridge', 'Driver Batta', 'Cleaner Batta', 'Meal', 'Repair', 'Others'
  ];

  String? _selectedPaymentCategory;
  final List<String> _paymentCategories = ['Fuel', 'Extra'];

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

      if (trip.stops.isNotEmpty) {
        for (var stop in trip.stops) {
          _stopControllers.add(TextEditingController(text: stop)..addListener(() => setState(() {})));
        }
      } else {
        // Fallback for old trips
        _stopControllers.add(TextEditingController(text: trip.from)..addListener(() => setState(() {})));
        _stopControllers.add(TextEditingController(text: trip.to)..addListener(() => setState(() {})));
      }

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

    if (_stopControllers.isEmpty) {
      _stopControllers.add(TextEditingController()..addListener(() => setState(() {})));
      _stopControllers.add(TextEditingController()..addListener(() => setState(() {})));
    }

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
    for (var controller in _stopControllers) {
      controller.dispose();
    }
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
      final user = ref.read(authProvider);
      final userRole = user?.role ?? 'Admin';
      final tripNotifier = ref.read(tripProvider.notifier);

      final newTrip = Trip(
        id: widget.isEditing ? widget.trip!.id : '',
        from: _stopControllers.isNotEmpty ? _stopControllers.first.text : _fromController.text,
        to: _stopControllers.isNotEmpty ? _stopControllers.last.text : _toController.text,
        stops: _stopControllers.map((c) => c.text).where((s) => s.isNotEmpty).toList(),
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
        await tripNotifier.updateTrip(newTrip, performedBy: userRole);
      } else {
        await tripNotifier.addTrip(newTrip, performedBy: userRole);
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
      final user = ref.read(authProvider);
      final userRole = user?.role ?? 'Admin';
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

      await tripNotifier.updateTrip(completedTrip, performedBy: userRole);
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
      final user = ref.read(authProvider);
      final userRole = user?.role ?? 'Admin';
      final tripNotifier = ref.read(tripProvider.notifier);
      final trip = widget.trip!;
      
      final reopenedTrip = trip.copyWith(
        status: 'Ongoing',
        statusColor: Colors.blue,
      );

      await tripNotifier.updateTrip(reopenedTrip, performedBy: userRole);
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

      // Compare Stops
      final currentStops = _stopControllers.map((c) => c.text).toList();
      final originalStops = t.stops.isNotEmpty ? t.stops : [t.from, t.to];
      
      bool stopsChanged = currentStops.length != originalStops.length;
      if (!stopsChanged) {
        for (int i = 0; i < currentStops.length; i++) {
          if (currentStops[i] != originalStops[i]) {
            stopsChanged = true;
            break;
          }
        }
      }

      // Check Expenses & Payments Deeply
      bool listsChanged = _expenseList.length != t.expenseList.length || 
                          _paymentList.length != t.paymentList.length;
      if (!listsChanged) {
        for (int i = 0; i < _expenseList.length; i++) {
          if (_expenseList[i]['amount'] != t.expenseList[i]['amount'] || 
              _expenseList[i]['title'] != t.expenseList[i]['title']) {
            listsChanged = true;
            break;
          }
        }
        if (!listsChanged) {
          for (int i = 0; i < _paymentList.length; i++) {
            if (_paymentList[i]['amount'] != t.paymentList[i]['amount'] || 
                _paymentList[i]['title'] != t.paymentList[i]['title']) {
              listsChanged = true;
              break;
            }
          }
        }
      }

      return stopsChanged ||
          _vehicleController.text != t.vehicle ||
          _driverController.text != t.driver ||
          _startDate != t.startDate ||
          _endDate != t.endDate ||
          (double.tryParse(_startKmController.text) ?? 0.0) != t.startKm ||
          (double.tryParse(_endKmController.text) ?? 0.0) != t.endKm ||
          (double.tryParse(_dieselController.text) ?? 0.0) != t.diesel ||
          (double.tryParse(_loadsController.text) ?? 0.0) != t.outwardLoads ||
          (double.tryParse(_returnLoadsController.text) ?? 0.0) != t.returnLoads ||
          _hasReturn != t.hasReturn ||
          (double.tryParse(_initialCashController.text) ?? 0.0) != t.initialCash ||
          listsChanged;
    } else {
      bool hasStopsText = _stopControllers.any((c) => c.text.isNotEmpty);
      return hasStopsText ||
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

    final bool detailsReadOnly = widget.isReadOnly;
    final bool expensesReadOnly = widget.isReadOnly;
    final bool paymentsReadOnly = widget.isReadOnly;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBackAction();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: _buildCurrentStep(detailsReadOnly, expensesReadOnly, paymentsReadOnly, isAdmin, isDriver),
      ),
    );
  }

  Widget _buildCurrentStep(bool detailsReadOnly, bool expensesReadOnly, bool paymentsReadOnly, bool isAdmin, bool isDriver) {
    switch (_currentStep) {
      case 'details':
        return _buildRouteDetailsView(detailsReadOnly);
      case 'expenses':
        return _buildExpenseEditView(expensesReadOnly);
      case 'payment':
        return _buildPaymentEditView(paymentsReadOnly);
      default:
        return _buildSummaryView(isAdmin, isDriver);
    }
  }

  Widget _buildSummaryView(bool isAdmin, bool isDriver) {
    return Column(
      children: [
        _buildAppBar('Trip Summary'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusSection(),
                const SizedBox(height: 24),
                _buildRouteSummary(isAdmin),
                const SizedBox(height: 20),
                _buildFinancialOverview(),
                const SizedBox(height: 20),
                _buildMetricCards(),
                const SizedBox(height: 24),
                _buildActionButtonSection(isAdmin, isDriver),
              ],
            ),
          ),
        ),
        _buildBottomActions(isAdmin),
      ],
    );
  }

  Widget _buildAppBar(String title) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 16, left: 8, right: 16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: _onBackAction),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          const Spacer(),
          if (widget.isEditing)
             Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text('EDIT MODE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blue, letterSpacing: 0.5)),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    final status = widget.isEditing ? widget.trip!.status : 'Ongoing';
    final color = widget.isEditing ? widget.trip!.statusColor : Colors.blue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.local_shipping_outlined, color: color, size: 24)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Status', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500])),
              Text(status, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSummary(bool isAdmin) {
    final from = _stopControllers.first.text;
    final to = _stopControllers.last.text;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLocationLabel('ORIGIN', from, Icons.trip_origin_rounded, Colors.blue),
              Icon(Icons.arrow_forward_rounded, color: Colors.grey[300], size: 20),
              _buildLocationLabel('DESTINATION', to, Icons.location_on_rounded, Colors.redAccent),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          InkWell(
            onTap: widget.isReadOnly ? null : () => _switchStep('details'),
            child: Row(
              children: [
                Icon(Icons.map_outlined, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('Manage Route Details & Stops', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationLabel(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: label == 'ORIGIN' ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[400])),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label == 'ORIGIN') Icon(icon, size: 14, color: color),
              if (label == 'ORIGIN') const SizedBox(width: 6),
              Flexible(child: Text(value.isEmpty ? 'Not set' : value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)), overflow: TextOverflow.ellipsis)),
              if (label != 'ORIGIN') const SizedBox(width: 6),
              if (label != 'ORIGIN') Icon(icon, size: 14, color: color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialOverview() {
    double expTotal = 0;
    for (var e in _expenseList) {
      expTotal += double.tryParse(e['amount']!.replaceAll('₹', '')) ?? 0;
    }
    
    double payTotal = 0;
    for (var p in _paymentList) {
      payTotal += double.tryParse(p['amount']!.replaceAll('₹', '')) ?? 0;
    }
    
    double initialCash = double.tryParse(_initialCashController.text) ?? 0;
    double netTotal = (initialCash + payTotal) - expTotal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2563EB)], 
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight
        ), 
        borderRadius: BorderRadius.circular(28), 
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25), 
            blurRadius: 20, 
            offset: const Offset(0, 10)
          )
        ]
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMoneyLabel(
              'AVAILABLE CASH', 
              '₹${netTotal.toStringAsFixed(0)}', 
              Colors.white, 
              Colors.white.withValues(alpha: 0.7)
            ),
          ),
          Container(
            height: 48, 
            width: 2, 
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _buildMoneyLabel(
                'TOTAL EXPENSES', 
                '₹${expTotal.toStringAsFixed(0)}', 
                const Color(0xFFFFD56B), 
                Colors.white.withValues(alpha: 0.7)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyLabel(String label, String value, Color valueColor, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label, 
          style: GoogleFonts.inter(
            fontSize: 10, 
            fontWeight: FontWeight.w800, 
            color: labelColor, 
            letterSpacing: 0.5
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value, 
          style: GoogleFonts.outfit(
            fontSize: 22, 
            fontWeight: FontWeight.w800, 
            color: valueColor
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMetricCards() {
    return Row(
      children: [
        _buildSmallMetric('Total KM', _totalKms, Icons.speed_outlined, Colors.blue),
        const SizedBox(width: 12),
        _buildSmallMetric('Mileage', '$_mileage km/l', Icons.local_gas_station_outlined, Colors.green),
      ],
    );
  }

  Widget _buildSmallMetric(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(24), 
          border: Border.all(color: const Color(0xFFF1F5F9))
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8), 
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), 
                borderRadius: BorderRadius.circular(12)
              ), 
              child: Icon(icon, color: color, size: 18)
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label, 
                    style: GoogleFonts.inter(
                      fontSize: 10, 
                      fontWeight: FontWeight.w600, 
                      color: Colors.grey[500]
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value, 
                    style: GoogleFonts.outfit(
                      fontSize: 14, 
                      fontWeight: FontWeight.w700, 
                      color: const Color(0xFF1E293B)
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonSection(bool isAdmin, bool isDriver) {
    return Column(
      children: [
        _buildMenuButton('Expenses Management', 'Add and manage trip expenses', Icons.receipt_long_outlined, Colors.orange, () => _switchStep('expenses')),
        const SizedBox(height: 12),
        _buildMenuButton('Payments & Cash', 'Manage advances and payments', Icons.payments_outlined, Colors.green, () => _switchStep('payment')),
      ],
    );
  }

  Widget _buildMenuButton(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: widget.isReadOnly ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(bool isAdmin) {
    if (widget.isReadOnly) return const SizedBox.shrink();
    
    final isTripCompleted = widget.isEditing && widget.trip!.status == 'Completed';

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(color: Colors.white, border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, -5))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (isAdmin && widget.isEditing) ...[
                Expanded(
                  child: AppButton(
                    label: isTripCompleted ? 'REOPEN TRIP' : 'COMPLETE TRIP',
                    backgroundColor: isTripCompleted ? Colors.orange : const Color(0xFF10B981),
                    onPressed: isTripCompleted ? _handleReopenTrip : _handleCompleteTrip,
                    height: 54,
                    isLoading: isTripCompleted ? _isReopening : _isCompleting,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: AppButton(
                  label: widget.isEditing ? 'SAVE CHANGES' : 'START TRIP',
                  onPressed: _handleSaveTrip,
                  height: 54,
                  isLoading: _isSaving,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteDetailsView(bool isReadOnly) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Route & Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: _onBackAction),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: AppDatePicker(label: 'Start Date', hint: 'Select Date', initialDate: _startDate, onDateSelected: (d) => setState(() => _startDate = d), enabled: !isReadOnly)),
                  const SizedBox(width: 16),
                  Expanded(child: AppDatePicker(label: 'End Date', hint: 'Select Date', initialDate: _endDate, onDateSelected: (d) => setState(() => _endDate = d), enabled: !isReadOnly)),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Route Stops', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _stopControllers.length,
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 23),
                      Container(height: 16, width: 2, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(1))),
                    ],
                  ),
                ),
                itemBuilder: (context, index) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: index == 0 ? 'Origin' : (index == _stopControllers.length - 1 ? 'Destination' : 'Stop ${index + 1}'),
                          hint: 'Enter location',
                          controller: _stopControllers[index],
                          readOnly: isReadOnly,
                          prefixIcon: index == 0 ? Icons.trip_origin_rounded : (index == _stopControllers.length - 1 ? Icons.location_on_rounded : Icons.fiber_manual_record_outlined),
                        ),
                      ),
                      if (!isReadOnly && _stopControllers.length > 2)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _stopControllers[index].dispose();
                                _stopControllers.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (!isReadOnly) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _stopControllers.add(TextEditingController()..addListener(() => setState(() {})))),
                  icon: const Icon(Icons.add_location_alt_outlined, size: 20),
                  label: const Text('Add Another Stop'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary, textStyle: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
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
                        if (val != null) {
                          _vehicleController.text = val;
                          setState(() {});
                        }
                      },
                    )
                  : AppTextField(label: 'Vehicle', hint: 'Truck Number', controller: _vehicleController, prefixIcon: Icons.local_shipping_outlined, readOnly: isReadOnly),
              const SizedBox(height: 24),
              () {
                final drivers = ref.watch(driversStreamProvider).value ?? [];
                return drivers.isNotEmpty
                    ? AppDropdown<String>(
                        label: 'Driver Name',
                        hint: 'Select Driver',
                        prefixIcon: Icons.badge_outlined,
                        value: _selectedDriverId,
                        readOnly: isReadOnly,
                        items: drivers.map((d) {
                          return DropdownMenuItem(value: d.id, child: Text(d.name));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final d = drivers.firstWhere((d) => d.id == val);
                            _selectedDriverId = val;
                            _driverController.text = d.name;
                            setState(() {});
                          }
                        },
                      )
                    : AppTextField(label: 'Driver Name', hint: 'John Doe', controller: _driverController, prefixIcon: Icons.badge_outlined, readOnly: isReadOnly);
              }(),
              const SizedBox(height: 24),
              () {
                final transporters = ref.watch(transportersStreamProvider).value ?? [];
                return transporters.isNotEmpty
                    ? AppDropdown<String>(
                        label: 'Transporter Name',
                        hint: 'Select Transporter',
                        prefixIcon: Icons.business_outlined,
                        value: _selectedTransporterId,
                        readOnly: isReadOnly,
                        items: transporters.map((t) {
                          return DropdownMenuItem(value: t.id, child: Text(t.name));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final t = transporters.firstWhere((t) => t.id == val);
                            _selectedTransporterId = val;
                            _transporterController.text = t.name;
                            setState(() {});
                          }
                        },
                      )
                    : AppTextField(label: 'Transporter Name', hint: 'Company ABC', controller: _transporterController, prefixIcon: Icons.business_outlined, readOnly: isReadOnly);
              }(),
              const SizedBox(height: 32),
              const Text('Journey Metrics', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: AppTextField(label: 'Opening KM', hint: '0', prefixIcon: Icons.speed_outlined, controller: _startKmController, keyboardType: TextInputType.number, readOnly: isReadOnly)),
                  const SizedBox(width: 16),
                  Expanded(child: AppTextField(label: 'Closing KM', hint: '0', prefixIcon: Icons.flag_outlined, controller: _endKmController, keyboardType: TextInputType.number, readOnly: isReadOnly)),
                ],
              ),
              const SizedBox(height: 24),
              AppTextField(label: 'Total Diesel (Litres)', hint: '0.00', prefixIcon: Icons.local_gas_station_outlined, controller: _dieselController, keyboardType: TextInputType.number, readOnly: isReadOnly),
              const SizedBox(height: 24),
              Row(
                  children:[
                    Expanded(child: AppTextField(label: 'Outward Load (T)', hint: '0.00', controller: _loadsController, keyboardType: TextInputType.number, readOnly: isReadOnly)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Has Return?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(_hasReturn ? 'YES' : 'NO', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            value: _hasReturn,
                            onChanged: isReadOnly ? null : (v) => setState(() => _hasReturn = v),
                          ),
                        ],
                      ),
                    ),
                  ]
              ),
              if (_hasReturn) ...[
                const SizedBox(height: 24),
                AppTextField(label: 'Return Load (T)', hint: '0.00', controller: _returnLoadsController, keyboardType: TextInputType.number, readOnly: isReadOnly),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseEditView(bool isReadOnly) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Trip Expenses', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)), backgroundColor: Colors.white, surfaceTintColor: Colors.white, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: _onBackAction), bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isReadOnly) ...[
                _buildSectionLabel('Add Expense'),
                const SizedBox(height: 16),
                _buildExpenseForm(isReadOnly),
                const SizedBox(height: 32),
              ],
              _buildSectionLabel('Expense List'),
              const SizedBox(height: 16),
              if (_expenseList.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No expenses recorded yet', style: TextStyle(color: Colors.grey))))
              else
                ...List.generate(_expenseList.length, (index) {
                  final item = _expenseList[index];
                  return AppListItem(
                    title: item['title']!,
                    amount: item['amount']!,
                    subtitle: 'Direction: ${item['leg']}',
                    onEdit: isReadOnly ? null : () {
                      setState(() {
                         _editingExpenseIndex = index;
                         _expenseAmountController.text = item['amount']!.replaceAll('₹', '');
                         _selectedExpenseLeg = item['leg']!;
                      });
                    },
                    onDelete: isReadOnly ? null : () {
                      AppDeleteConfirmation.show(context, title: 'Expense', itemName: item['title']!, onConfirm: () => setState(() => _expenseList.removeAt(index)));
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.blue.shade50)),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                flex: 11,
                child: AppDropdown<String>(
                  label: 'Category', hint: 'Select', items: _expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                  value: _selectedExpenseCategory, onChanged: (val) => setState(() => _selectedExpenseCategory = val), readOnly: isReadOnly,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 10,
                child: AppDropdown<String>(
                  label: 'Direction', hint: 'Select', items: ['A to D', 'D to A'].map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 12)))).toList(),
                  value: _selectedExpenseLeg, onChanged: (val) => setState(() => _selectedExpenseLeg = val!), readOnly: isReadOnly,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Amount (₹)', hint: '0.00', controller: _expenseAmountController, keyboardType: TextInputType.number, readOnly: isReadOnly),
          const SizedBox(height: 20),
          AppButton(
            label: _editingExpenseIndex == null ? 'ADD EXPENSE' : 'SAVE CHANGES',
            onPressed: isReadOnly ? null : () {
              if (_selectedExpenseCategory == null || _expenseAmountController.text.isEmpty) {
                AppToast.show(context, 'Please fill category and amount', isError: true);
                return;
              }
              setState(() {
                if (_editingExpenseIndex == null) {
                  int count = 0;
                  for (var e in _expenseList) {
                    if (e['leg'] == _selectedExpenseLeg && e['title']!.startsWith(_selectedExpenseCategory!)) {
                      count++;
                    }
                  }
                  _expenseList.add({'title': '${_selectedExpenseCategory!} ${count+1}', 'amount': '₹${_expenseAmountController.text}', 'leg': _selectedExpenseLeg});
                } else {
                  _expenseList[_editingExpenseIndex!] = {'title': _expenseList[_editingExpenseIndex!]['title']!, 'amount': '₹${_expenseAmountController.text}', 'leg': _selectedExpenseLeg};
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
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Payment & Cash' : 'Add Payment & Cash', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)), backgroundColor: Colors.white, surfaceTintColor: Colors.white, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: _onBackAction), bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1))),
      body: SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(label: 'Advance Received', hint: '0', prefixIcon: Icons.payments_outlined, controller: _initialCashController, keyboardType: TextInputType.number, readOnly: isReadOnly),
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
                          final title = item['title']!;
                          _paymentDescController.text = title;
                          _paymentAmountController.text = item['amount']!.replaceAll('₹', '');
                          if (title.startsWith('Fuel')) {
                            _selectedPaymentCategory = 'Fuel';
                          } else if (title.startsWith('Extra')) {
                            _selectedPaymentCategory = 'Extra';
                          } else {
                            _selectedPaymentCategory = null;
                          }
                        });
                      },
                      onDelete: isReadOnly ? null : () {
                        AppDeleteConfirmation.show(context, title: 'Payment', itemName: item['title']!, onConfirm: () => setState(() => _paymentList.removeAt(index)));
                      },
                    );
                  }),
                const SizedBox(height: 24),
                _buildFinalSummary(),
                const SizedBox(height: 20),
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
           AppDropdown<String>(
             label: 'Payment Category', hint: 'Select category', value: _selectedPaymentCategory, readOnly: isReadOnly,
             items: _paymentCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
             onChanged: (val) {
               if (val != null) {
                 setState(() {
                   _selectedPaymentCategory = val;
                   int count = 0;
                   for (var p in _paymentList) {
                     if (p['title']!.startsWith(val)) {
                       count++;
                     }
                   }
                   _paymentDescController.text = '$val ${count + 1}';
                 });
               }
             },
           ),
           const SizedBox(height: 16),
           AppTextField(label: 'Description', hint: 'Auto-generated name', controller: _paymentDescController, readOnly: true),
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
                    _paymentDescController.clear(); _paymentAmountController.clear(); _selectedPaymentCategory = null;
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
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total Cash Available', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey[600])),
          Text('₹${(initial + add).toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: 0.5));
  }
}
