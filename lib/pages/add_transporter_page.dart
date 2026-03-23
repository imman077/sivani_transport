import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:sivani_transport/models/transporter.dart';
import 'package:sivani_transport/providers/transporter_provider.dart';
import 'package:sivani_transport/widgets/app_components.dart';

class AddTransporterPage extends ConsumerStatefulWidget {
  final Transporter? transporter;
  const AddTransporterPage({super.key, this.transporter});

  @override
  ConsumerState<AddTransporterPage> createState() => _AddTransporterPageState();
}

class _AddTransporterPageState extends ConsumerState<AddTransporterPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  bool _isLoading = false;
  XFile? _pickedImage;
  String? _existingImageUrl;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.transporter?.name ?? '');
    _phoneController = TextEditingController(text: widget.transporter?.phone ?? '');
    _emailController = TextEditingController(text: widget.transporter?.email ?? '');
    _addressController = TextEditingController(text: widget.transporter?.address ?? '');
    _existingImageUrl = widget.transporter?.image;
    _isAvailable = widget.transporter?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      AppToast.show(context, 'Name and Phone are required', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final transporter = Transporter(
      id: widget.transporter?.id ?? '', 
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      image: _existingImageUrl,
      pickedImage: _pickedImage,
      isAvailable: _isAvailable,
    );

    try {
      await ref.read(transporterActionProvider.notifier).saveTransporter(transporter);
      if (mounted) {
        context.pop();
        AppToast.show(
          context,
          widget.transporter == null ? 'Transporter added successfully' : 'Transporter updated successfully'
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, 'Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transporter != null;
    return MasterFormPage(
      title: isEditing ? 'Edit Transporter' : 'Add Transporter',
      sectionTitle: isEditing ? 'Update Transporter' : 'Transporter Details',
      subtitle: isEditing 
        ? 'Update the contact information and availability for this transporter.' 
        : 'Please provide the contact information for the new transporter agency.',
      imagePicker: AppImagePicker(
        pickedImage: _pickedImage,
        imageUrl: _existingImageUrl,
        placeholderIcon: Icons.business,
        onImagePicked: (file) => setState(() {
          _pickedImage = file;
          _existingImageUrl = null;
        }),
        onImageDeleted: () => setState(() {
          _pickedImage = null;
          _existingImageUrl = null;
        }),
      ),
      onSave: _handleSave,
      isLoading: _isLoading,
      saveButtonLabel: isEditing ? 'Update Transporter' : 'Save Transporter',
      saveIcon: isEditing ? Icons.update_rounded : Icons.check_circle_outline,
      children: [
        AppTextField(
          label: 'Transporter Name',
          hint: 'e.g. Sivani Transport',
          controller: _nameController,
          prefixIcon: Icons.business_outlined,
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Phone Number',
          hint: 'e.g. 9876543210',
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Email (Optional)',
          hint: 'e.g. contact@sivani.com',
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Address (Optional)',
          hint: 'e.g. 1st Floor, Sivan Kovil St',
          controller: _addressController,
          prefixIcon: Icons.location_on_outlined,
          maxLines: 3,
        ),
      ],
    );
  }
}
