import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
      // Filter by search query (model or registration number)
      final modelMatch = v.model.toLowerCase().contains(
            searchQuery.toLowerCase(),
          );
      final regMatch = v.regNumber.toLowerCase().contains(
            searchQuery.toLowerCase(),
          );

      // Filter by status tab
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
          'Vehicle Management',
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
                      onChanged: (val) => ref.read(vehicleSearchProvider.notifier).state = val,
                      decoration: const InputDecoration(
                        hintText: 'Search vehicles by model',
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
                  // Add Vehicle Button
                  AppButton(
                    label: 'Add New Vehicle',
                    onPressed: _showAddVehicleForm,
                    icon: Icons.add,
                    height: 46,
                  ),
                  const SizedBox(height: 20),
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
                        Expanded(child: _buildFilterTab('All', vehicles.length, Icons.inventory_2_rounded)),
                        Expanded(child: _buildFilterTab('Active', vehicles.where((v) => v.isAvailable).length, Icons.check_circle_rounded)),
                        Expanded(child: _buildFilterTab('Busy', vehicles.where((v) => !v.isAvailable).length, Icons.timer_rounded)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable Vehicle List
            Expanded(
              child: filteredVehicles.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: filteredVehicles.length,
                      itemBuilder: (context, index) {
                        return _buildVehicleCard(filteredVehicles[index]);
                      },
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
    final baseColor =
        isAvailable ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
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
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: vehicle.image != null
                      ? _buildVehicleImage(vehicle.image!)
                      : _buildPlaceholderImage(),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildStatusBadge(vehicle.isAvailable),
                ),
              ],
            ),
            // Info Section
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
                            Icon(Icons.tag_rounded,
                                size: 13, color: Colors.blueGrey.shade300),
                            const SizedBox(width: 6),
                            Text(
                              'Plate: ${vehicle.regNumber}',
                              style: TextStyle(
                                color: Colors.blueGrey.shade400,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.monitor_weight_rounded,
                                size: 13, color: Colors.blueGrey.shade300),
                            const SizedBox(width: 6),
                            Text(
                              '${vehicle.capacity} Tons',
                              style: TextStyle(
                                color: Colors.blueGrey.shade400,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              vehicle.fuelType == 'Electric'
                                  ? Icons.bolt_rounded
                                  : Icons.local_gas_station_rounded,
                              size: 13,
                              color: Colors.blueGrey.shade300,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              vehicle.fuelType,
                              style: TextStyle(
                                color: Colors.blueGrey.shade400,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions
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

  Widget _buildVehicleImage(String source) {
    if (source.startsWith('http')) {
      return Image.network(
        source,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _buildPlaceholderImage(),
      );
    }
    try {
      return Image.memory(
        base64Decode(source),
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _buildPlaceholderImage(),
      );
    } catch (e) {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 140,
      width: double.infinity,
      alignment: Alignment.center,
      color: Colors.grey.shade100,
      child: Icon(
        Icons.local_shipping_rounded,
        size: 60,
        color: Colors.grey.withValues(alpha: 0.4),
      ),
    );
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

  void _showDeleteConfirmation(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Are you sure you want to delete ${vehicle.model}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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

  Widget _buildActionButton(
      IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
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
  final ImagePicker _picker = ImagePicker();

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
        statusColor:
            widget.vehicle?.isAvailable ?? true ? Colors.green : Colors.redAccent,
      );

      if (formState.id == null) {
        await ref.read(vehicleProvider.notifier).addVehicle(newVehicle);
      } else {
        await ref.read(vehicleProvider.notifier).updateVehicle(newVehicle);
      }

      if (mounted) {
        ref.read(vehicleFormProvider.notifier).setLoading(false);
        Navigator.pop(context);
        AppToast.show(
          context,
          formState.id == null
              ? 'Vehicle added successfully'
              : 'Vehicle updated successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        ref.read(vehicleFormProvider.notifier).setLoading(false);
        AppToast.show(context, 'Error saving vehicle: $e', isError: true);
      }
    }
  }

  void _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        ref.read(vehicleFormProvider.notifier).updateImage(image);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Error picking image: $e', isError: true);
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20, top: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: AppColors.primary),
                ),
                title: const Text('Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Pick an existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.camera_alt_outlined, color: Colors.teal),
                ),
                title: const Text('Take a Photo',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Use the camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePreview() {
    final formState = ref.read(vehicleFormProvider);
    if (formState.pickedImage == null && formState.image == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: formState.pickedImage != null
                  ? Image.file(File(formState.pickedImage!.path),
                      fit: BoxFit.contain)
                  : _buildImage(formState.image!, fit: BoxFit.contain),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 30),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String source, {BoxFit fit = BoxFit.cover}) {
    if (source.startsWith('http')) {
      return Image.network(source, fit: fit);
    }
    return Image.memory(base64Decode(source), fit: fit);
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(vehicleFormProvider);
    final hasImage = formState.pickedImage != null || formState.image != null;

    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      formState.id == null ? 'Add Vehicle' : 'Edit Vehicle',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: _showImageSourceSheet,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: hasImage
                                            ? AppColors.primary
                                            : Colors.grey.shade200,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                              alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: formState.pickedImage != null
                                          ? Image.file(
                                              File(formState
                                                  .pickedImage!.path),
                                              fit: BoxFit.cover,
                                            )
                                          : (formState.image != null
                                              ? _buildImage(formState.image!)
                                              : Container(
                                                  color:
                                                      Colors.grey.shade100,
                                                  child: Icon(
                                                      Icons.local_shipping,
                                                      color: Colors
                                                          .grey.shade300,
                                                      size: 40),
                                                )),
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    bottom: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (hasImage)
                            TextButton.icon(
                              onPressed: () => ref
                                  .read(vehicleFormProvider.notifier)
                                  .resetImage(),
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Colors.redAccent),
                              label: const Text(
                                'Remove Photo',
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          else ...[
                            const Text(
                              'Vehicle Photo',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Click the icon to upload a photo.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (hasImage)
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    label: 'Preview',
                                    onPressed: _showImagePreview,
                                    icon: Icons.visibility_outlined,
                                    height: 44,
                                    backgroundColor: Colors.blue.shade50,
                                    foregroundColor: Colors.blue.shade700,
                                    fullWidth: false,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppButton(
                                    label: 'Change',
                                    onPressed: _showImageSourceSheet,
                                    icon: Icons.sync_rounded,
                                    height: 44,
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    foregroundColor: AppColors.primary,
                                    fullWidth: false,
                                  ),
                                ),
                              ],
                            )
                          else
                            AppButton(
                              label: 'Pick Photo',
                              onPressed: _showImageSourceSheet,
                              icon: Icons.add_a_photo_outlined,
                              height: 44,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              foregroundColor: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    AppTextField(
                      label: 'Vehicle Number',
                      hint: 'e.g. ABC-1234',
                      prefixIcon: Icons.numbers_outlined,
                      initialValue: formState.regNumber,
                      onChanged: (val) => ref
                          .read(vehicleFormProvider.notifier)
                          .updateRegNumber(val),
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Model',
                      hint: 'e.g. Toyota Camry',
                      prefixIcon: Icons.directions_car_outlined,
                      initialValue: formState.model,
                      onChanged: (val) =>
                          ref.read(vehicleFormProvider.notifier).updateModel(val),
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Capacity (Tons)',
                      hint: 'e.g. 10.5',
                      prefixIcon: Icons.monitor_weight_outlined,
                      initialValue: formState.capacityValue,
                      onChanged: (val) => ref
                          .read(vehicleFormProvider.notifier)
                          .updateCapacity(val),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
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
                      label:
                          formState.id == null ? 'Add Vehicle' : 'Update Vehicle',
                      onPressed: _handleSaveVehicle,
                      icon: Icons.app_registration_outlined,
                      isLoading: formState.isLoading,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelOption(String label, IconData icon) {
    final formState = ref.watch(vehicleFormProvider);
    final bool isSelected = formState.fuelType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(vehicleFormProvider.notifier).updateFuelType(label),
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
