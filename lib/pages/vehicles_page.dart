import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/models/vehicle.dart';
import 'package:sivani_transport/providers/vehicle_form_provider.dart';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AddVehicleSheet(vehicle: vehicle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehicleProvider);
    final searchQuery = ref.watch(vehicleSearchProvider);
    final selectedFilter = ref.watch(vehicleFilterProvider);
    final filteredVehicles = _getFilteredVehicles(vehicles, searchQuery, selectedFilter);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Vehicles',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.blueGrey.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    height: 52,
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => ref.read(vehicleSearchProvider.notifier).state = val,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        hintText: 'Search vehicles',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Add Vehicle',
                    onPressed: _showAddVehicleForm,
                    icon: Icons.add,
                    height: 46,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildFilterTab('All', vehicles.length, Icons.inventory_2_rounded)),
                        Expanded(child: _buildFilterTab('Active', vehicles.where((v) => v.isAvailable).length, Icons.check_circle_rounded)),
                        Expanded(child: _buildFilterTab('Busy', vehicles.where((v) => !v.isAvailable).length, Icons.timer_rounded)),
                      ],
                    ),
                  ),
                ],
              ),
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

  Widget _buildFilterTab(String label, int count, IconData icon) {
    final selectedFilter = ref.watch(vehicleFilterProvider);
    final bool isSelected = selectedFilter == label;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(vehicleFilterProvider.notifier).state = label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.blueGrey.shade400,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.blueGrey.shade700,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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
              ref.read(vehicleProvider.notifier).deleteVehicle(vehicle.id);
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

class AddVehicleSheet extends ConsumerStatefulWidget {
  final Vehicle? vehicle;
  const AddVehicleSheet({super.key, this.vehicle});

  @override
  ConsumerState<AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends ConsumerState<AddVehicleSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vehicleFormProvider.notifier).init(widget.vehicle);
    });
  }

  void _handleSaveVehicle() async {
    final formState = ref.read(vehicleFormProvider);
    if (formState.model.trim().isEmpty || formState.regNumber.trim().isEmpty) {
      AppToast.show(context, 'Please fill in all required fields', isError: true);
      return;
    }

    ref.read(vehicleFormProvider.notifier).setLoading(true);

    try {
      final newVehicle = Vehicle(
        id: formState.id ?? '',
        model: formState.model,
        regNumber: formState.regNumber,
        fuelType: formState.fuelType,
        capacity: double.tryParse(formState.capacityValue) ?? 0.0,
        status: widget.vehicle?.status ?? 'Active',
        isAvailable: widget.vehicle?.isAvailable ?? true,
        image: formState.image,
        pickedImage: formState.pickedImage,
        statusColor: widget.vehicle?.isAvailable ?? true ? Colors.green : Colors.redAccent,
      );

      if (formState.id == null) {
        await ref.read(vehicleProvider.notifier).addVehicle(newVehicle);
      } else {
        await ref.read(vehicleProvider.notifier).updateVehicle(newVehicle);
      }

      if (mounted) {
        ref.read(vehicleFormProvider.notifier).setLoading(false);
        Navigator.pop(context);
        AppToast.show(context, formState.id == null ? 'Vehicle added successfully' : 'Vehicle updated successfully');
      }
    } catch (e) {
      if (mounted) {
        ref.read(vehicleFormProvider.notifier).setLoading(false);
        AppToast.show(context, 'Error saving vehicle: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(vehicleFormProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Text(
                  formState.id == null ? 'Add Vehicle' : 'Edit Vehicle',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
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
                  AppImagePicker(
                    pickedImage: formState.pickedImage,
                    imageUrl: formState.image,
                    placeholderIcon: Icons.local_shipping_rounded,
                    onImagePicked: (file) => ref.read(vehicleFormProvider.notifier).updateImage(file),
                    onImageDeleted: () => ref.read(vehicleFormProvider.notifier).updateImage(null),
                  ),
                  const SizedBox(height: 32),
                  const Text('Vehicle Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Model Name',
                    hint: 'e.g. Tata Prima',
                    initialValue: formState.model,
                    onChanged: ref.read(vehicleFormProvider.notifier).updateModel,
                    prefixIcon: Icons.local_shipping_outlined,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Registration Number',
                    hint: 'e.g. MH 12 AB 1234',
                    initialValue: formState.regNumber,
                    onChanged: ref.read(vehicleFormProvider.notifier).updateRegNumber,
                    prefixIcon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Capacity (Tons)',
                    hint: 'e.g. 15.5',
                    initialValue: formState.capacityValue,
                    onChanged: ref.read(vehicleFormProvider.notifier).updateCapacity,
                    prefixIcon: Icons.monitor_weight_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 24),
                  const Text('Energy Source', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: ['Diesel', 'Petrol', 'CNG', 'Electric'].map((type) {
                      final isSelected = formState.fuelType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (_) => ref.read(vehicleFormProvider.notifier).updateFuelType(type),
                        selectedColor: AppColors.primary.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.grey.shade600,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 48),
                  AppButton(
                    label: formState.id == null ? 'Register Vehicle' : 'Update Vehicle',
                    onPressed: _handleSaveVehicle,
                    isLoading: formState.isLoading,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
