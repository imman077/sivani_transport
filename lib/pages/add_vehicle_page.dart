import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/models/vehicle.dart';
import 'package:sivani_transport/providers/vehicle_form_provider.dart';
import 'package:sivani_transport/providers/vehicle_provider.dart';
import 'package:sivani_transport/widgets/app_components.dart';

class AddVehiclePage extends ConsumerStatefulWidget {
  final Vehicle? vehicle;
  const AddVehiclePage({super.key, this.vehicle});

  @override
  ConsumerState<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends ConsumerState<AddVehiclePage> {
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

    return MasterFormPage(
      type: MasterFormType.page,
      title: formState.id == null ? 'Add Vehicle' : 'Edit Vehicle',
      sectionTitle: 'Vehicle Information',
      imagePicker: AppImagePicker(
        pickedImage: formState.pickedImage,
        imageUrl: formState.image,
        placeholderIcon: Icons.local_shipping_rounded,
        onImagePicked: (file) => ref.read(vehicleFormProvider.notifier).updateImage(file),
        onImageDeleted: () => ref.read(vehicleFormProvider.notifier).updateImage(null),
      ),
      onSave: _handleSaveVehicle,
      isLoading: formState.isLoading,
      saveButtonLabel: formState.id == null ? 'Register Vehicle' : 'Update Vehicle',
      children: [
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
      ],
    );
  }
}
