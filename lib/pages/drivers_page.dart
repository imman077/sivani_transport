import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/models/driver.dart';
import 'package:sivani_transport/providers/driver_provider.dart';
import 'package:sivani_transport/providers/driver_form_provider.dart';
import 'package:sivani_transport/providers/search_provider.dart';
import 'package:sivani_transport/widgets/app_components.dart';

class DriversPage extends ConsumerStatefulWidget {
  const DriversPage({super.key});

  @override
  ConsumerState<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends ConsumerState<DriversPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(driverSearchProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Driver> _getFilteredDrivers(List<Driver> drivers, String searchQuery, String selectedFilter) {
    return drivers.where((d) {
      final query = searchQuery.toLowerCase();
      final nameMatch = d.name.toLowerCase().contains(query) || 
                       d.email.toLowerCase().contains(query) ||
                       d.id.toLowerCase().contains(query);

      final statusMatch = selectedFilter == 'All' ||
          (selectedFilter == 'Available' && d.isAvailable) ||
          (selectedFilter == 'Busy' && !d.isAvailable);

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
    final driversAsync = ref.watch(driversStreamProvider);
    final searchQuery = ref.watch(driverSearchProvider);
    final selectedFilter = ref.watch(driverFilterProvider);

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
      body: driversAsync.when(
        data: (drivers) {
          final filteredDrivers = _getFilteredDrivers(drivers, searchQuery, selectedFilter);
          return Column(
            children: [
              // Sticky Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSearchAndFilter(filteredDrivers.length, drivers),
              ),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSearchAndFilter(int driverCount, List<Driver> drivers) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
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
              onChanged: (val) => ref.read(driverSearchProvider.notifier).state = val,
              decoration: const InputDecoration(
                hintText: 'Search drivers by name',
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
          AppButton(
            label: 'Add New Driver',
            onPressed: _showAddDriverForm,
            icon: Icons.add,
            height: 46,
          ),
          const SizedBox(height: 20),
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
                Expanded(child: _buildFilterTab('All', drivers.length, Icons.group_rounded)),
                Expanded(child: _buildFilterTab('Available', drivers.where((d) => d.isAvailable).length, Icons.check_circle_rounded)),
                Expanded(child: _buildFilterTab('Busy', drivers.where((d) => !d.isAvailable).length, Icons.timer_rounded)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, int count, IconData icon) {
    final selectedFilter = ref.watch(driverFilterProvider);
    final bool isSelected = selectedFilter == label;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(driverFilterProvider.notifier).state = label,
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
    final baseColor = isAvailable ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: baseColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isAvailable ? 'Available' : 'Busy',
            style: TextStyle(
              color: baseColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(Driver driver) {
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
                      // Avatar Section
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: driver.pickedImage != null
                              ? Image.file(
                                  File(driver.pickedImage!.path),
                                  fit: BoxFit.cover,
                                )
                              : (driver.image != null
                                  ? _buildImage(driver.image!)
                                  : _defaultAvatar()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Info Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              driver.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.phone_rounded,
                                    size: 13, color: Colors.blueGrey.shade300),
                                const SizedBox(width: 6),
                                Text(
                                  driver.phone,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blueGrey.shade400,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildStatusBadge(driver.isAvailable),
                          ],
                        ),
                      ),
                      // Action Section
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildActionButton(
                            Icons.edit_rounded,
                            const Color(0xFFEFF6FF),
                            const Color(0xFF2563EB),
                            () => _showAddDriverForm(driver: driver),
                          ),
                          const SizedBox(height: 8),
                          _buildActionButton(
                            Icons.delete_outline_rounded,
                            const Color(0xFFFFF1F2),
                            const Color(0xFFE11D48),
                            () => _showDeleteConfirmation(driver),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
  }

  Widget _buildImage(String source) {
    if (source.startsWith('http')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _defaultAvatar(),
      );
    }
    try {
      return Image.memory(
        base64Decode(source),
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _defaultAvatar(),
      );
    } catch (e) {
      return _defaultAvatar();
    }
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
            onPressed: () async {
              await ref.read(driverActionProvider.notifier).deleteDriver(driver.id);
              if (context.mounted) {
                Navigator.pop(context);
                AppToast.show(context, 'Driver removed successfully');
              }
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

    if (formState.name.trim().isEmpty || formState.email.trim().isEmpty || formState.password.trim().isEmpty) {
      AppToast.show(context, 'Name, Email and Password are required', isError: true);
      return;
    }

    final newDriver = Driver(
      id: formState.id ?? '', // Will be generated in FirebaseService if empty
      name: formState.name,
      phone: formState.phone,
      email: formState.email,
      password: formState.password,
      license: formState.license,
      isAvailable: true,
      pickedImage: formState.pickedImage,
      image: formState.existingImageUrl,
    );

    await ref.read(driverActionProvider.notifier).saveDriver(newDriver);

    if (mounted) {
      final state = ref.read(driverActionProvider);
      if (!state.hasError) {
        Navigator.pop(context);
        AppToast.show(
          context,
          formState.id == null
              ? 'Driver added successfully'
              : 'Driver updated successfully',
        );
      } else {
        AppToast.show(context, 'Error: ${state.error}', isError: true);
      }
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
        AppToast.show(context, 'Error picking image: $e', isError: true);
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
                  : _buildImage(formState.existingImageUrl!, fit: BoxFit.contain),
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

  Widget _buildImage(String source, {BoxFit fit = BoxFit.cover}) {
    if (source.startsWith('http')) {
      return Image.network(
        source,
        fit: fit,
        errorBuilder: (c, e, s) => _defaultAvatar(),
      );
    }
    try {
      return Image.memory(
        base64Decode(source),
        fit: fit,
        errorBuilder: (c, e, s) => _defaultAvatar(),
      );
    } catch (e) {
      return _defaultAvatar();
    }
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
                                              ? _buildImage(
                                                  formState.existingImageUrl!,
                                                  fit: BoxFit.cover,
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
                      label: 'Email Address',
                      hint: 'john.doe@example.com',
                      initialValue: formState.email,
                      onChanged: (val) => ref
                          .read(driverFormProvider.notifier)
                          .updateEmail(val),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Password',
                      hint: '••••••••',
                      initialValue: formState.password,
                      onChanged: (val) => ref
                          .read(driverFormProvider.notifier)
                          .updatePassword(val),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Phone Number',
                      hint: '+91 98765 43210',
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
                      isLoading: ref.watch(driverActionProvider).isLoading,
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
