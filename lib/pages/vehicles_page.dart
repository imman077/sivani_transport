import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/models/vehicle.dart';
import 'package:sivani_transport/providers/vehicle_provider.dart';
import 'package:sivani_transport/providers/search_provider.dart';
import 'package:sivani_transport/widgets/app_components.dart';

class VehiclesPage extends ConsumerStatefulWidget {
  const VehiclesPage({super.key});

  @override
  ConsumerState<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends ConsumerState<VehiclesPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(vehicleSearchProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Vehicle> _getFilteredVehicles(List<Vehicle> vehicles, String searchQuery, String selectedFilter) {
    return vehicles.where((v) {
      final modelMatch = v.model.toLowerCase().contains(searchQuery.toLowerCase());
      final regMatch = v.regNumber.toLowerCase().contains(searchQuery.toLowerCase());

      final statusMatch = selectedFilter == 'All' ||
          (selectedFilter == 'Active' && v.isAvailable) ||
          (selectedFilter == 'Busy' && !v.isAvailable);

      return (modelMatch || regMatch) && statusMatch;
    }).toList();
  }

  void _showAddVehicleForm({Vehicle? vehicle}) {
    context.push('/vehicles/add', extra: vehicle);
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehicleProvider);
    final searchQuery = ref.watch(vehicleSearchProvider);
    final selectedFilter = ref.watch(vehicleFilterProvider);
    final filteredVehicles = _getFilteredVehicles(vehicles, searchQuery, selectedFilter);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
            MasterPageHeader(
              searchController: _searchController,
              searchHint: 'Search vehicles',
              onSearchChanged: (val) {
                ref.read(vehicleSearchProvider.notifier).state = val;
                setState(() {});
              },
              onSearchCleared: () {
                _searchController.clear();
                ref.read(vehicleSearchProvider.notifier).state = '';
                setState(() {});
              },
              addButtonLabel: 'Add Vehicle',
              onAddPressed: () => _showAddVehicleForm(),
              selectedFilter: selectedFilter,
              onFilterChanged: (val) => ref.read(vehicleFilterProvider.notifier).state = val,
              filters: [
                FilterTabItem(label: 'All', count: vehicles.length, icon: Icons.inventory_2_rounded),
                FilterTabItem(label: 'Active', count: vehicles.where((v) => v.isAvailable).length, icon: Icons.check_circle_rounded),
                FilterTabItem(label: 'Busy', count: vehicles.where((v) => !v.isAvailable).length, icon: Icons.timer_rounded),
              ],
            ),
            Expanded(
              child: filteredVehicles.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: filteredVehicles.length,
                      itemBuilder: (context, index) => _buildVehicleCard(filteredVehicles[index]),
                    )
                  : _buildEmptyState(
                      icon: Icons.local_shipping_outlined,
                      title: 'No vehicles found',
                      subtitle: 'Try adjusting your filters or add a new vehicle.',
                    ),
            ),
          ],
        ),
    );
  }

  Widget _buildStatusBadge(bool isAvailable) {
    final baseColor = isAvailable ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: baseColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: baseColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isAvailable ? 'Active' : 'Busy',
            style: TextStyle(
              color: baseColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildVehicleCard(Vehicle vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 16 / 7,
                    child: AppImageWidget(
                      source: vehicle.image,
                      placeholder: Container(
                        color: Colors.grey.shade100,
                        child: Icon(Icons.local_shipping_rounded, size: 60, color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildStatusBadge(vehicle.isAvailable),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.model,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.tag_rounded, size: 13, color: Colors.blueGrey.shade300),
                            const SizedBox(width: 6),
                            Text(
                              'Plate: ${vehicle.regNumber}',
                              style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.monitor_weight_rounded, size: 13, color: Colors.blueGrey.shade300),
                            const SizedBox(width: 6),
                            Text(
                              '${vehicle.capacity} Tons',
                              style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              vehicle.fuelType == 'Electric' ? Icons.bolt_rounded : Icons.local_gas_station_rounded,
                              size: 13,
                              color: Colors.blueGrey.shade300,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              vehicle.fuelType,
                              style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12, fontWeight: FontWeight.w600),
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
                        const Color(0xFFEFF6FF),
                        const Color(0xFF2563EB),
                        () => _showAddVehicleForm(vehicle: vehicle),
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        Icons.delete_outline_rounded,
                        const Color(0xFFFFF1F2),
                        const Color(0xFFE11D48),
                        () => _showDeleteConfirmation(vehicle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(icon, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Are you sure you want to delete ${vehicle.model}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(vehicleProvider.notifier).deleteVehicle(vehicle.id, vehicle.regNumber);
              Navigator.pop(context);
              AppToast.show(context, 'Vehicle removed successfully');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

