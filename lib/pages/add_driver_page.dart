import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/models/driver.dart';
import 'package:sivani_transport/providers/driver_provider.dart';
import 'package:sivani_transport/providers/driver_form_provider.dart';
import 'package:sivani_transport/widgets/app_components.dart';

class AddDriverPage extends ConsumerStatefulWidget {
  final Driver? driver;
  const AddDriverPage({super.key, this.driver});

  @override
  ConsumerState<AddDriverPage> createState() => _AddDriverPageState();
}

class _AddDriverPageState extends ConsumerState<AddDriverPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverFormProvider.notifier).init(widget.driver);
    });
  }

  void _handleSave() async {
    final formState = ref.read(driverFormProvider);

    if (formState.name.trim().isEmpty || formState.email.trim().isEmpty || (formState.id == null && formState.password.trim().isEmpty)) {
      AppToast.show(context, 'Name, Email and Password are required', isError: true);
      return;
    }

    final newDriver = Driver(
      id: formState.id ?? '', 
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
        context.pop();
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

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(driverFormProvider);
    final isEditing = formState.id != null;

    return MasterFormPage(
      title: isEditing ? 'Edit Driver' : 'Add New Driver',
      sectionTitle: 'Personal Information',
      subtitle: 'Please provide the contact details and credentials for the driver.',
      imagePicker: AppImagePicker(
        pickedImage: formState.pickedImage,
        imageUrl: formState.existingImageUrl,
        onImagePicked: (file) => ref.read(driverFormProvider.notifier).updateImage(file),
        onImageDeleted: () => ref.read(driverFormProvider.notifier).resetImage(),
      ),
      onSave: _handleSave,
      isLoading: ref.watch(driverActionProvider).isLoading,
      saveButtonLabel: isEditing ? 'Update Driver' : 'Register Driver',
      saveIcon: isEditing ? Icons.update_rounded : Icons.check_circle_outline,
      children: [
        AppTextField(
          label: 'Full Name',
          hint: 'e.g. John Doe',
          initialValue: formState.name,
          onChanged: ref.read(driverFormProvider.notifier).updateName,
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Phone Number',
          hint: 'e.g. 9876543210',
          initialValue: formState.phone,
          onChanged: ref.read(driverFormProvider.notifier).updatePhone,
          prefixIcon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Email Address',
          hint: 'e.g. john@example.com',
          initialValue: formState.email,
          onChanged: ref.read(driverFormProvider.notifier).updateEmail,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        if (!isEditing) ...[
          const SizedBox(height: 20),
          AppTextField(
            label: 'Account Password',
            hint: 'Set a secure password',
            initialValue: formState.password,
            onChanged: ref.read(driverFormProvider.notifier).updatePassword,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
          ),
        ],
        const SizedBox(height: 32),
        const Text(
          'Documentation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Driving License Number',
          hint: 'e.g. DL-1234567890',
          initialValue: formState.license,
          onChanged: ref.read(driverFormProvider.notifier).updateLicense,
          prefixIcon: Icons.badge_outlined,
        ),
      ],
    );
  }
}
