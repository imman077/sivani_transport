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
  // Dates are managed via tripDraftProvider
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

  late TextEditingController _transporterAmountController;
  late TextEditingController _commissionController;
  late TextEditingController _driverSalaryController;

  String _selectedExpenseLeg = 'A to D'; // A to D, D to A

  String _totalKms = '0';
  String _mileage = '0.0';

  int? _editingExpenseIndex;
  int? _editingPaymentIndex;

  String? _outwardLoadError;
  String? _returnLoadError;

  @override
  void initState() {
    super.initState();
    // Initialize the draft in the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripDraftProvider.notifier).init(widget.trip);
      _syncControllersWithProvider();
    });

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
    _transporterAmountController = TextEditingController();
    _commissionController = TextEditingController();
    _driverSalaryController = TextEditingController();

    // Listeners to update the provider on every change
    _startKmController.addListener(() => _updateProvider());
    _endKmController.addListener(() => _updateProvider());
    _dieselController.addListener(() => _updateProvider());
    _initialCashController.addListener(() => _updateProvider());
    _vehicleController.addListener(() => _updateProvider());
    _driverController.addListener(() => _updateProvider());
    _transporterController.addListener(() => _updateProvider());
    _loadsController.addListener(() => _updateProvider());
    _returnLoadsController.addListener(() => _updateProvider());
    _transporterAmountController.addListener(() => _updateProvider());
    _commissionController.addListener(() => _updateProvider());
    _driverSalaryController.addListener(() => _updateProvider());
  }

  void _syncControllersWithProvider() {
    final trip = ref.read(tripDraftProvider);
    if (trip == null) return;

    _fromController.text = trip.from;
    _toController.text = trip.to;
    _vehicleController.text = trip.vehicle;
    _driverController.text = trip.driver;
    _selectedDriverId = trip.driverId;
    _transporterController.text = trip.transporter ?? '';
    _selectedTransporterId = trip.transporterId;
    _initialCashController.text = trip.initialCash == 0 ? '' : trip.initialCash.toString();
    _startKmController.text = trip.startKm == 0 ? '' : trip.startKm.toString();
    _endKmController.text = trip.endKm == 0 ? '' : trip.endKm.toString();
    _dieselController.text = trip.diesel == 0 ? '' : trip.diesel.toString();
    _loadsController.text = trip.outwardLoads == 0 ? '' : trip.outwardLoads.toString();
    _returnLoadsController.text = trip.returnLoads == 0 ? '' : trip.returnLoads.toString();
    _transporterAmountController.text = trip.transporterAmount == 0 ? '' : trip.transporterAmount.toString();
    _commissionController.text = trip.commission == 0 ? '' : trip.commission.toString();
    _driverSalaryController.text = trip.driverSalary == 0 ? '' : trip.driverSalary.toString();

    _stopControllers.clear();
    final stops = trip.stops.isNotEmpty ? trip.stops : [trip.from, trip.to];
    for (var stop in stops) {
       _stopControllers.add(TextEditingController(text: stop)..addListener(_updateProvider));
    }
    setState(() {});
  }

  void _updateProvider() {
    final state = ref.read(tripDraftProvider);
    final List<String> stops = _stopControllers.map((c) => c.text).toList();
    final String from = (stops.isNotEmpty && stops.first.isNotEmpty) ? stops.first : (state?.from ?? '');
    final String to = (stops.length > 1 && stops.last.isNotEmpty) ? stops.last : (state?.to ?? '');

    ref.read(tripDraftProvider.notifier).updateField(
      from: from,
      to: to,
      stops: stops,
      vehicle: _vehicleController.text,
      driver: _driverController.text,
      driverId: _selectedDriverId,
      transporter: _transporterController.text,
      transporterId: _selectedTransporterId,
      startKm: double.tryParse(_startKmController.text) ?? 0.0,
      endKm: double.tryParse(_endKmController.text) ?? 0.0,
      diesel: double.tryParse(_dieselController.text) ?? 0.0,
      initialCash: double.tryParse(_initialCashController.text) ?? 0.0,
      outwardLoads: double.tryParse(_loadsController.text) ?? 0.0,
      returnLoads: double.tryParse(_returnLoadsController.text) ?? 0.0,
      transporterAmount: double.tryParse(_transporterAmountController.text) ?? 0.0,
      commission: double.tryParse(_commissionController.text) ?? 0.0,
      driverSalary: double.tryParse(_driverSalaryController.text) ?? 0.0,
    );
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
    _transporterAmountController.dispose();
    _commissionController.dispose();
    _driverSalaryController.dispose();
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

    final vList = ref.read(vehicleProvider);
    final selV = vList.firstWhere(
      (v) => '${v.regNumber} (${v.model})' == _vehicleController.text,
      orElse: () => Vehicle(id: '', model: '', regNumber: '', fuelType: '', capacity: 0.0),
    );

    final double outLoad = double.tryParse(_loadsController.text) ?? 0;
    final double inLoad = double.tryParse(_returnLoadsController.text) ?? 0;

    if (mounted) {
      setState(() {
        _totalKms = total > 0 ? total.toStringAsFixed(0) : '0';
        _mileage = mil > 0 ? mil.toStringAsFixed(2) : '0.0';
        
        if (selV.capacity > 0) {
          _outwardLoadError = outLoad > selV.capacity ? 'Max (${selV.capacity} T)' : null;
          _returnLoadError = inLoad > selV.capacity ? 'Max (${selV.capacity} T)' : null;
        } else {
          _outwardLoadError = null;
          _returnLoadError = null;
        }
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
    final tripDraft = ref.read(tripDraftProvider);
    if (tripDraft == null) return;

    // 1. Mandatory Fields Validation
    if (tripDraft.from.isEmpty || tripDraft.to.isEmpty) {
      _showToast('Please enter Origin and Destination in Route Details!', isError: true);
      return;
    }
    if (tripDraft.startDate == null) {
      _showToast('Please select a Start Date!', isError: true);
      return;
    }
    if (tripDraft.vehicle.isEmpty) {
      _showToast('Please select a Vehicle!', isError: true);
      return;
    }
    if (tripDraft.driver.isEmpty) {
      _showToast('Please select a Driver!', isError: true);
      return;
    }
    if (tripDraft.outwardLoads <= 0) {
      _showToast('Please enter Outward Load amount!', isError: true);
      return;
    }

    // 2. Capacity Validation
    final vList = ref.read(vehicleProvider);
    final selV = vList.firstWhere(
      (v) => '${v.regNumber} (${v.model})' == tripDraft.vehicle,
      orElse: () => Vehicle(id: '', model: '', regNumber: '', fuelType: '', capacity: 0.0),
    );
    if (selV.capacity > 0) {
      if (tripDraft.outwardLoads > selV.capacity || (tripDraft.hasReturn && tripDraft.returnLoads > selV.capacity)) {
        _showToast('Load exceeds vehicle capacity (${selV.capacity} T)!', isError: true);
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final user = ref.read(authProvider);
      final userRole = user?.role ?? 'Admin';
      final tripNotifier = ref.read(tripProvider.notifier);

      if (widget.isEditing) {
        await tripNotifier.updateTrip(tripDraft, performedBy: userRole);
      } else {
        await tripNotifier.addTrip(tripDraft, performedBy: userRole);
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
    final draft = ref.read(tripDraftProvider);
    if (draft == null) return false;

    if (widget.isEditing && widget.trip != null) {
      final t = widget.trip!;

      bool stopsChanged = draft.stops.length != t.stops.length;
      if (!stopsChanged) {
        for (int i = 0; i < draft.stops.length; i++) {
          if (draft.stops[i] != t.stops[i]) {
            stopsChanged = true;
            break;
          }
        }
      }

      bool listsChanged = draft.expenseList.length != t.expenseList.length || 
                          draft.paymentList.length != t.paymentList.length;
      
      if (!listsChanged) {
        for (int i = 0; i < draft.expenseList.length; i++) {
          if (draft.expenseList[i]['amount'] != t.expenseList[i]['amount'] || 
              draft.expenseList[i]['title'] != t.expenseList[i]['title']) {
            listsChanged = true;
            break;
          }
        }
        if (!listsChanged) {
          for (int i = 0; i < draft.paymentList.length; i++) {
            if (draft.paymentList[i]['amount'] != t.paymentList[i]['amount'] || 
                draft.paymentList[i]['title'] != t.paymentList[i]['title']) {
              listsChanged = true;
              break;
            }
          }
        }
      }

      return stopsChanged ||
          draft.vehicle != t.vehicle ||
          draft.driver != t.driver ||
          draft.startDate != t.startDate ||
          draft.endDate != t.endDate ||
          draft.startKm != t.startKm ||
          draft.endKm != t.endKm ||
          draft.diesel != t.diesel ||
          draft.outwardLoads != t.outwardLoads ||
          draft.returnLoads != t.returnLoads ||
          draft.hasReturn != t.hasReturn ||
          draft.initialCash != t.initialCash ||
          listsChanged;
    } else {
      return draft.stops.any((s) => s.isNotEmpty) ||
          draft.vehicle.isNotEmpty ||
          draft.driver.isNotEmpty ||
          draft.startDate != null ||
          draft.expenseList.isNotEmpty ||
          draft.paymentList.isNotEmpty;
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
    final trip = ref.watch(tripDraftProvider);
    if (trip == null) return const Center(child: CircularProgressIndicator());

    switch (_currentStep) {
      case 'details':
        return _buildRouteDetailsView(detailsReadOnly, trip);
      case 'expenses':
        return _buildExpenseEditView(expensesReadOnly, trip);
      case 'payment':
        return _buildPaymentEditView(paymentsReadOnly, trip);
      default:
        return _buildSummaryView(isAdmin, isDriver);
    }
  }

  Widget _buildSummaryView(bool isAdmin, bool isDriver) {
    final trip = ref.watch(tripDraftProvider);
    if (trip == null) return const Center(child: CircularProgressIndicator());

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
                _buildRouteSummary(trip),
                const SizedBox(height: 20),
                _buildFinancialOverview(trip),
                const SizedBox(height: 20),
                _buildMetricCards(),
                const SizedBox(height: 24),
                _buildActionButtonSection(trip),
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

  Widget _buildRouteSummary(Trip trip) {
    final stops = trip.stops.isNotEmpty ? trip.stops : [trip.from, trip.to];
    final from = stops.first;
    final to = stops.last;
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
                Icon(Icons.description_outlined, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Finance Details', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey[800])),
                      const SizedBox(height: 4),
                      Text('Tptr: ₹${trip.transporterAmount} | Comm: ₹${trip.commission} | Salary: ₹${trip.driverSalary}', 
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
              ],
            ),
          ),
          const SizedBox(height: 12),
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

  Widget _buildFinancialOverview(Trip trip) {
    double expTotal = 0;
    for (var e in trip.expenseList) {
      expTotal += double.tryParse(e['amount']!.replaceAll('₹', '')) ?? 0;
    }
    
    double payTotal = 0;
    for (var p in trip.paymentList) {
      payTotal += double.tryParse(p['amount']!.replaceAll('₹', '')) ?? 0;
    }
    
    double initialCash = trip.initialCash.toDouble();
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

  Widget _buildActionButtonSection(Trip trip) {
    final double initialCashValue = trip.initialCash.toDouble();
    final bool hasCash = initialCashValue > 0 || trip.paymentList.isNotEmpty;

    return Column(
      children: [
        _buildMenuButton(
          'Expenses Management', 
          hasCash ? 'Add and manage trip expenses' : 'Please add payments/cash first', 
          Icons.receipt_long_outlined, 
          hasCash ? Colors.orange : Colors.grey, 
          () {
            if (hasCash) {
              _switchStep('expenses');
            } else {
              _showToast('Please enter Payments & Cash before adding expenses', isError: true);
            }
          }
        ),
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

  Widget _buildRouteDetailsView(bool isReadOnly, Trip trip) {
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
                  Expanded(
                    child: AppDatePicker(
                      label: 'Start Date',
                      hint: 'Select Date',
                      initialDate: trip.startDate,
                      firstDate: DateTime(2020),
                      onDateSelected: (d) {
                        ref.read(tripDraftProvider.notifier).updateField(startDate: d);
                      },
                      enabled: !isReadOnly
                    )
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppDatePicker(
                      label: 'End Date',
                      hint: 'Select Date',
                      initialDate: trip.endDate,
                      firstDate: trip.startDate ?? DateTime.now(),
                      onDateSelected: (d) => ref.read(tripDraftProvider.notifier).updateField(endDate: d),
                      enabled: !isReadOnly && trip.startDate != null
                    )
                  ),
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
                  onPressed: () => setState(() => _stopControllers.add(TextEditingController()..addListener(_updateProvider))),
                  icon: const Icon(Icons.add_location_alt_outlined, size: 20),
                  label: const Text('Add Another Stop'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary, textStyle: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
              const SizedBox(height: 16),
              () {
                final vehicles = ref.watch(vehicleProvider);
                return AppDropdown<String>(
                  label: 'Vehicle',
                  hint: vehicles.isEmpty ? 'No Vehicles Found' : 'Select Vehicle',
                  prefixIcon: Icons.local_shipping_outlined,
                  value: _vehicleController.text.isEmpty ? null : _vehicleController.text,
                  readOnly: isReadOnly || vehicles.isEmpty,
                  items: vehicles.isEmpty 
                    ? [const DropdownMenuItem(value: '', enabled: false, child: Text('No Vehicle Found', style: TextStyle(color: Colors.grey)))]
                    : vehicles.map((v) {
                        final value = '${v.regNumber} (${v.model})';
                        return DropdownMenuItem(value: value, child: Text(value));
                      }).toList(),
                  onChanged: (val) {
                    if (val != null && val.isNotEmpty) {
                      _vehicleController.text = val;
                      setState(() {});
                    }
                  },
                );
              }(),
              const SizedBox(height: 24),
              () {
                final drivers = ref.watch(driversStreamProvider).value ?? [];
                return AppDropdown<String>(
                  label: 'Driver Name',
                  hint: drivers.isEmpty ? 'No Drivers Found' : 'Select Driver',
                  prefixIcon: Icons.badge_outlined,
                  value: _selectedDriverId,
                  readOnly: isReadOnly || drivers.isEmpty,
                  items: drivers.isEmpty 
                    ? [const DropdownMenuItem(value: '', enabled: false, child: Text('No Driver Found', style: TextStyle(color: Colors.grey)))]
                    : drivers.map((d) {
                        return DropdownMenuItem(value: d.id, child: Text(d.name));
                      }).toList(),
                  onChanged: (val) {
                    if (val != null && val.isNotEmpty) {
                      final d = drivers.firstWhere((d) => d.id == val);
                      _selectedDriverId = val;
                      _driverController.text = d.name;
                      setState(() {});
                    }
                  },
                );
              }(),
              const SizedBox(height: 24),
              () {
                final transporters = ref.watch(transportersStreamProvider).value ?? [];
                return AppDropdown<String>(
                  label: 'Transporter Name',
                  hint: transporters.isEmpty ? 'No Transporters Found' : 'Select Transporter',
                  prefixIcon: Icons.business_outlined,
                  value: _selectedTransporterId,
                  readOnly: isReadOnly || transporters.isEmpty,
                  items: transporters.isEmpty 
                    ? [const DropdownMenuItem(value: '', enabled: false, child: Text('No Transporter Found', style: TextStyle(color: Colors.grey)))]
                    : transporters.map((t) {
                        return DropdownMenuItem(value: t.id, child: Text(t.name));
                      }).toList(),
                  onChanged: (val) {
                    if (val != null && val.isNotEmpty) {
                      final t = transporters.firstWhere((t) => t.id == val);
                      _selectedTransporterId = val;
                      _transporterController.text = t.name;
                      setState(() {});
                    }
                  },
                );
              }(),
              const SizedBox(height: 24),
              AppTextField(label: 'Transporter Amount (₹)', hint: '0.00', prefixIcon: Icons.currency_rupee_rounded, controller: _transporterAmountController, keyboardType: TextInputType.number, readOnly: isReadOnly),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: AppTextField(label: 'Commission (₹)', hint: '0.00', controller: _commissionController, keyboardType: TextInputType.number, readOnly: isReadOnly)),
                  const SizedBox(width: 16),
                  Expanded(child: AppTextField(label: 'Driver Salary (₹)', hint: '0.00', controller: _driverSalaryController, keyboardType: TextInputType.number, readOnly: isReadOnly)),
                ],
              ),
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
                    Expanded(child: AppTextField(label: 'Outward Load (T)', hint: '0.00', controller: _loadsController, keyboardType: TextInputType.number, readOnly: isReadOnly, errorText: _outwardLoadError)),
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
                AppTextField(label: 'Return Load (T)', hint: '0.00', controller: _returnLoadsController, keyboardType: TextInputType.number, readOnly: isReadOnly, errorText: _returnLoadError),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseEditView(bool isReadOnly, Trip trip) {
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
                _buildExpenseForm(isReadOnly, trip),
                const SizedBox(height: 32),
              ],
              _buildSectionLabel('Expense List'),
              const SizedBox(height: 16),
              if (trip.expenseList.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No expenses recorded yet', style: TextStyle(color: Colors.grey))))
              else
                ...List.generate(trip.expenseList.length, (index) {
                  final item = trip.expenseList[index];
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
                      AppDeleteConfirmation.show(context, title: 'Expense', itemName: item['title']!, onConfirm: () {
                         final newList = List<Map<String, String>>.from(trip.expenseList)..removeAt(index);
                         ref.read(tripDraftProvider.notifier).updateField(expenseList: newList);
                      });
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

  Widget _buildExpenseForm(bool isReadOnly, Trip trip) {
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

              final newAmount = double.tryParse(_expenseAmountController.text) ?? 0;
              
              // Calculate Total Available Cash (Initial Cash + Payments)
              double totalAvailable = trip.initialCash.toDouble();
              for (var p in trip.paymentList) {
                final amountStr = p['amount']?.replaceAll('₹', '').replaceAll(',', '') ?? '0';
                totalAvailable += double.tryParse(amountStr) ?? 0;
              }
              
              // Calculate Current Total Expenses (excluding the one being edited)
              double currentExpenses = 0;
              for (int i = 0; i < trip.expenseList.length; i++) {
                if (_editingExpenseIndex != i) {
                  final amountStr = trip.expenseList[i]['amount']?.replaceAll('₹', '').replaceAll(',', '') ?? '0';
                  currentExpenses += double.tryParse(amountStr) ?? 0;
                }
              }

              if (currentExpenses + newAmount > totalAvailable) {
                final remaining = totalAvailable - currentExpenses;
                AppToast.show(
                  context, 
                  'Insufficient balance! You only have ₹${remaining.toStringAsFixed(2)} remaining.', 
                  isError: true
                );
                return;
              }

              final newList = List<Map<String, String>>.from(trip.expenseList);
              if (_editingExpenseIndex == null) {
                int count = 0;
                for (var e in newList) {
                  if (e['leg'] == _selectedExpenseLeg && e['title']!.startsWith(_selectedExpenseCategory!)) {
                    count++;
                  }
                }
                newList.add({'title': '${_selectedExpenseCategory!} ${count+1}', 'amount': '₹${_expenseAmountController.text}', 'leg': _selectedExpenseLeg});
              } else {
                newList[_editingExpenseIndex!] = {'title': newList[_editingExpenseIndex!]['title']!, 'amount': '₹${_expenseAmountController.text}', 'leg': _selectedExpenseLeg};
                _editingExpenseIndex = null;
              }
              ref.read(tripDraftProvider.notifier).updateField(expenseList: newList);
              _expenseAmountController.clear();
              _selectedExpenseCategory = null;
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentEditView(bool isReadOnly, Trip trip) {
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
                  _buildPaymentForm(isReadOnly, trip),
                  const SizedBox(height: 24),
                ],
                if (trip.paymentList.isEmpty)
                  const Center(child: Text('No additional payments added yet', style: TextStyle(color: Colors.grey, fontSize: 12)))
                else
                  ...List.generate(trip.paymentList.length, (index) {
                    final item = trip.paymentList[index];
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
                        AppDeleteConfirmation.show(context, title: 'Payment', itemName: item['title']!, onConfirm: () {
                           final newList = List<Map<String, String>>.from(trip.paymentList)..removeAt(index);
                           ref.read(tripDraftProvider.notifier).updateField(paymentList: newList);
                        });
                      },
                    );
                  }),
                const SizedBox(height: 24),
                _buildFinalSummary(trip),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildPaymentForm(bool isReadOnly, Trip trip) {
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
                   for (var p in trip.paymentList) {
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
                 final newList = List<Map<String, String>>.from(trip.paymentList);
                 if(_editingPaymentIndex == null) {
                   newList.add({'title': _paymentDescController.text, 'amount': '₹${_paymentAmountController.text}'});
                 } else {
                   newList[_editingPaymentIndex!] = {'title': _paymentDescController.text, 'amount': '₹${_paymentAmountController.text}'};
                   _editingPaymentIndex = null;
                 }
                 ref.read(tripDraftProvider.notifier).updateField(paymentList: newList);
                 _paymentDescController.clear(); 
                 _paymentAmountController.clear(); 
                 _selectedPaymentCategory = null;
                 setState(() {});
               }
             },
           )
        ],
      ),
    );
  }

  Widget _buildFinalSummary(Trip trip) {
    double initial = trip.initialCash.toDouble();
    double add = 0;
    for (var p in trip.paymentList) {
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
