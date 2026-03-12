import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/models/driver.dart';
import 'package:sivani_transport/providers/driver_provider.dart';
import 'package:sivani_transport/providers/driver_form_provider.dart';
import 'package:sivani_transport/widgets/app_components.dart';

class DriversPage extends ConsumerStatefulWidget {
  const DriversPage({super.key});

  @override
  ConsumerState<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends ConsumerState<DriversPage> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Driver> _getFilteredDrivers(List<Driver> drivers) {
    return drivers.where((d) {
      final nameMatch = d.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final statusMatch = _selectedFilter == 'All' ||
          (_selectedFilter == 'Available' && d.isAvailable) ||
          (_selectedFilter == 'Busy' && !d.isAvailable);

      return nameMatch && statusMatch;
    }).toList();
  }

  void _showAddDriverForm({Driver? driver}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AddDriverSheet(driver: driver),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drivers = ref.watch(driverProvider);
    final filteredDrivers = _getFilteredDrivers(drivers);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Driver Management',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(filteredDrivers.length),
          Expanded(
            child: filteredDrivers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDrivers.length,
                    itemBuilder: (context, index) =>
                        _buildDriverCard(filteredDrivers[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDriverForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter(int driverCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Search drivers by name',
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
          AppButton(
            label: 'Add New Driver',
            onPressed: _showAddDriverForm,
            icon: Icons.add,
            height: 48,
          ),
          const SizedBox(height: 20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Drivers ($driverCount)',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final String actualValue = label == 'Busy' ? 'On Assignment' : label;
    final bool isSelected = _selectedFilter == actualValue;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedFilter = actualValue),
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

  Widget _buildEmptyState() {
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
              Icons.person_off_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No drivers found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or add a new driver.',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isAvailable ? Colors.green : Colors.orange).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAvailable ? 'Available' : 'Busy',
        style: TextStyle(
          color: isAvailable ? Colors.green : Colors.orange,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDriverCard(Driver driver) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: driver.pickedImage != null
                  ? Image.file(
                      File(driver.pickedImage!.path),
                      fit: BoxFit.cover,
                    )
                  : (driver.image != null
                      ? Image.network(
                          driver.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => _defaultAvatar(),
                        )
                      : _defaultAvatar()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  driver.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      driver.phone,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildStatusBadge(driver.isAvailable),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                Icons.edit_rounded,
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.primary,
                () => _showAddDriverForm(driver: driver),
              ),
              const SizedBox(height: 10),
              _buildActionButton(
                Icons.delete_outline_rounded,
                Colors.red.withValues(alpha: 0.08),
                Colors.redAccent,
                () => _showDeleteConfirmation(driver),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(Icons.person, color: Colors.grey.shade300, size: 30),
    );
  }

  Widget _buildActionButton(IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }

  void _showDeleteConfirmation(Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Driver'),
        content: Text('Are you sure you want to delete ${driver.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(driverProvider.notifier).deleteDriver(driver.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Driver removed'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class AddDriverSheet extends ConsumerStatefulWidget {
  final Driver? driver;
  const AddDriverSheet({super.key, this.driver});

  @override
  ConsumerState<AddDriverSheet> createState() => _AddDriverSheetState();
}

class _AddDriverSheetState extends ConsumerState<AddDriverSheet> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverFormProvider.notifier).init(widget.driver);
    });
  }

  void _handleSave() async {
    final formState = ref.read(driverFormProvider);

    if (formState.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    ref.read(driverFormProvider.notifier).setLoading(true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    final newDriver = Driver(
      id: formState.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: formState.name,
      phone: formState.phone,
      license: formState.license,
      isAvailable: true,
      pickedImage: formState.pickedImage,
      image: formState.existingImageUrl,
    );

    if (formState.id == null) {
      ref.read(driverProvider.notifier).addDriver(newDriver);
    } else {
      ref.read(driverProvider.notifier).updateDriver(newDriver);
    }

    if (mounted) {
      ref.read(driverFormProvider.notifier).setLoading(false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formState.id == null
              ? 'Driver added successfully'
              : 'Driver updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        ref.read(driverFormProvider.notifier).updateImage(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImagePreview() {
    final formState = ref.read(driverFormProvider);
    if (formState.pickedImage == null && formState.existingImageUrl == null) {
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
                  : Image.network(formState.existingImageUrl!,
                      fit: BoxFit.contain),
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
                margin: const EdgeInsets.only(bottom: 16),
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
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(Icons.person, color: Colors.grey.shade300, size: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(driverFormProvider);
    final hasImage =
        formState.pickedImage != null || formState.existingImageUrl != null;

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
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      formState.id == null ? 'Add Driver' : 'Edit Driver',
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
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: formState.pickedImage != null
                                          ? Image.file(
                                              File(formState.pickedImage!.path),
                                              fit: BoxFit.cover,
                                            )
                                          : (formState.existingImageUrl != null
                                              ? Image.network(
                                                  formState.existingImageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) =>
                                                      _defaultAvatar(),
                                                )
                                              : _defaultAvatar()),
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
                                  .read(driverFormProvider.notifier)
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
                              'Driver Photo',
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
                                    backgroundColor:
                                        AppColors.primary.withValues(alpha: 0.1),
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
                    const SizedBox(height: 24),
                    AppTextField(
                      label: 'Full Name',
                      hint: 'John Doe',
                      initialValue: formState.name,
                      onChanged: (val) => ref
                          .read(driverFormProvider.notifier)
                          .updateName(val),
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Phone Number',
                      hint: '+1 (555) 000-0000',
                      initialValue: formState.phone,
                      onChanged: (val) => ref
                          .read(driverFormProvider.notifier)
                          .updatePhone(val),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'License Number',
                      hint: 'DL-8293-XJ',
                      initialValue: formState.license,
                      onChanged: (val) => ref
                          .read(driverFormProvider.notifier)
                          .updateLicense(val),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: formState.id == null
                          ? 'Save Driver'
                          : 'Update Driver',
                      onPressed: _handleSave,
                      icon: Icons.save_outlined,
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
}
