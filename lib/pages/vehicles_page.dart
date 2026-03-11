import 'package:flutter/material.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/widgets/app_components.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _vehicles = [
    {
      'model': 'Mercedes-Benz Sprinter',
      'regNumber': 'ABC-1234',
      'driver': 'Johnathan Miller',
      'fuelType': 'Diesel',
      'status': 'Active • En Route',
      'statusColor': Colors.green,
      'isAvailable': false,
      'image':
          'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&q=80',
    },
    {
      'model': 'Volvo FH16 Globetrotter',
      'regNumber': 'XYZ-5678',
      'driver': 'Sarah Thompson',
      'fuelType': 'Diesel',
      'status': 'Idle • Maintenance',
      'statusColor': Colors.orange,
      'isAvailable': true,
      'image':
          'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?w=800&q=80',
    },
    {
      'model': 'Freightliner Cascadia',
      'regNumber': 'PQR-9876',
      'driver': 'Michael Chen',
      'fuelType': 'Diesel',
      'status': 'Active • Loading',
      'isAvailable': false,
      'statusColor': Colors.blue,
      'image':
          'https://images.unsplash.com/photo-1586191582151-f737704250c6?w=800&q=80',
    },
  ];

  List<Map<String, dynamic>> get _filteredVehicles {
    return _vehicles.where((v) {
      if (v['model'] == null) return false;

      // Filter by search query (model or registration number)
      final modelMatch = (v['model'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      final regMatch = (v['regNumber'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      // Filter by status tab
      final isAvailable = (v['isAvailable'] as bool?) ?? true;
      final statusMatch = _selectedFilter == 'All' ||
          (_selectedFilter == 'Available' && isAvailable) ||
          (_selectedFilter == 'Busy' && !isAvailable);

      return (modelMatch || regMatch) && statusMatch;
    }).toList();
  }

  void _showAddVehicleForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddVehicleSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {},
        ),
        title: const Text(
          'Vehicle Management',
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
        child: Column(
          children: [
            // Fixed Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F6F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Search vehicles by model',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Add Vehicle Button
                  AppButton(
                    label: 'Add New Vehicle',
                    onPressed: _showAddVehicleForm,
                    icon: Icons.add,
                    height: 48,
                  ),
                  const SizedBox(height: 20),
                  // Premium Filter Tabs
                  Container(
                    height: 52,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blueGrey.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildFilterTab('All')),
                        Expanded(child: _buildFilterTab('Available')),
                        Expanded(child: _buildFilterTab('Busy')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Vehicles (${_filteredVehicles.length})',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // Scrollable Vehicle List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: _filteredVehicles.length,
                itemBuilder: (context, index) {
                  return _buildVehicleCard(_filteredVehicles[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final bool isSelected = _selectedFilter == label;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutQuart,
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
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.blueGrey.shade700,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              fontSize: 13,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Increased height for better clarity
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              vehicle['image']?.toString() ?? '',
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 140,
                width: double.infinity,
                alignment: Alignment.center,
                color: Colors.grey.shade100,
                child: Icon(
                  Icons.local_shipping_rounded,
                  size: 60,
                  color: Colors.grey.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          // Tightened Vehicle Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle['model']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.tag_rounded, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Plate: ${vehicle['regNumber']?.toString() ?? ''}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.gas_meter_rounded, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            vehicle['fuelType']?.toString() ?? '',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Driver: ${vehicle['driver']?.toString() ?? ''}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: (vehicle['statusColor'] as Color?) ?? Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            vehicle['status']?.toString() ?? 'Unknown',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    _buildActionButton(
                      Icons.edit_rounded,
                      const Color(0xFFE3F2FD),
                      AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      Icons.delete_outline_rounded,
                      const Color(0xFFFFEBEE),
                      Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Icon(icon, size: 18, color: iconColor),
    );
  }
}

class AddVehicleSheet extends StatefulWidget {
  const AddVehicleSheet({super.key});

  @override
  State<AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends State<AddVehicleSheet> {
  String _selectedFuel = 'Diesel';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Add Vehicle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vehicle Info',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the vehicle details below.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    label: 'Vehicle Number',
                    hint: 'e.g. ABC-1234',
                    prefixIcon: Icons.numbers_outlined,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Model',
                    hint: 'e.g. Toyota Camry',
                    prefixIcon: Icons.directions_car_outlined,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Fuel Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      _buildFuelOption('Diesel', Icons.gas_meter_outlined),
                      const SizedBox(width: 12),
                      _buildFuelOption(
                        'Petrol',
                        Icons.local_gas_station_outlined,
                      ),
                      const SizedBox(width: 12),
                      _buildFuelOption('Electric', Icons.bolt_outlined),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // _buildLabel('Primary Driver Assignment'),
                  // DropdownButtonFormField<String>(
                  //   decoration: InputDecoration(
                  //     prefixIcon: const Icon(Icons.person_outline),
                  //     fillColor: Colors.white,
                  //     filled: true,
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //       borderSide: BorderSide(color: Colors.grey.shade200),
                  //     ),
                  //     enabledBorder: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //       borderSide: BorderSide(color: Colors.grey.shade200),
                  //     ),
                  //   ),
                  //   hint: const Text('Select a driver'),
                  //   items:
                  //       ['Johnathan Miller', 'Sarah Thompson', 'Michael Chen']
                  //           .map(
                  //             (e) => DropdownMenuItem(value: e, child: Text(e)),
                  //           )
                  //           .toList(),
                  //   onChanged: (v) {},
                  // ),
                  // const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'This vehicle will be added to the fleet immediately.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Add Vehicle',
                    onPressed: () => Navigator.pop(context),
                    icon: Icons.app_registration_outlined,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelOption(String label, IconData icon) {
    final bool isSelected = _selectedFuel == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFuel = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
