import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/services/firebase_service.dart';
import 'package:sivani_transport/providers/notification_provider.dart';
import 'package:sivani_transport/models/app_notification.dart';
import 'package:sivani_transport/providers/auth_provider.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String hint;
  final String? initialValue;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final bool readOnly;
  final bool obscureText;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final String? errorText;

  const AppTextField({
    super.key,
    this.label = '',
    required this.hint,
    this.initialValue,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardType,
    this.onTap,
    this.onChanged,
    this.autofillHints,
    this.maxLines = 1,
    this.errorText,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  TextEditingController? _internalController;
  bool _obscureText = false;

  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    if (widget.controller == null) {
      _internalController = TextEditingController(text: widget.initialValue);
    }
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.controller == null) {
      if (widget.initialValue != oldWidget.initialValue) {
        _internalController?.text = widget.initialValue ?? '';
      }
    }
    if (widget.obscureText != oldWidget.obscureText) {
      setState(() => _obscureText = widget.obscureText);
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _effectiveController,
          readOnly: widget.readOnly,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          autofillHints: widget.autofillHints,
          maxLines: widget.maxLines,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: AppColors.textPrimary.withValues(alpha: 0.6),
                  )
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : widget.suffixIcon,
            errorText: widget.errorText,
            errorStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class AppDatePicker extends StatefulWidget {
  final String label;
  final String hint;
  final ValueChanged<DateTime>? onDateSelected;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;

  const AppDatePicker({
    super.key,
    required this.label,
    required this.hint,
    this.onDateSelected,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
  });

  @override
  State<AppDatePicker> createState() => _AppDatePickerState();
}

class _AppDatePickerState extends State<AppDatePicker> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateText();
  }

  @override
  void didUpdateWidget(AppDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      _updateText();
    }
  }

  void _updateText() {
    if (widget.initialDate != null) {
      final d = widget.initialDate!;
      _controller.text =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year.toString().substring(2)}';
    } else {
      _controller.text = '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (!widget.enabled) return;

    final now = DateTime.now();
    final firstDate = widget.firstDate ?? DateTime(2000);
    final lastDate = widget.lastDate ?? DateTime(2100);

    DateTime initialDate = widget.initialDate ?? now;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              elevation: 24,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year.toString().substring(2)}';
      setState(() => _controller.text = formatted);
      widget.onDateSelected?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
      child: AppTextField(
        label: widget.label,
        hint: widget.hint,
        controller: _controller,
        readOnly: true,
        onTap: widget.enabled ? _pickDate : null,
        suffixIcon: GestureDetector(
          onTap: widget.enabled ? _pickDate : null,
          child: const Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;
  final double? borderRadius;
  final bool isLoading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
    this.borderRadius,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      minimumSize: Size(0, height ?? 56),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
      ),
      elevation: 0,
    );

    final content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: foregroundColor ?? Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                if (label.isNotEmpty) const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          );

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: content,
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class BrandedHeader extends ConsumerWidget {
  final String? title;
  final bool showProfile;
  const BrandedHeader({super.key, this.title, this.showProfile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Elegant Logo Block
          Container(
            height: 44,
            width: 72,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset('assets/images/logo2.png', fit: BoxFit.contain),
          ),
          if (title != null) ...[
            const SizedBox(width: 10),
            Text(
              title!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
          const Spacer(),
          InkWell(
            onTap: () => Scaffold.of(context).openEndDrawer(),
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _HeaderAction(
                  icon: Icons.notifications_none_rounded, 
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 9, 
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Conditionally show profile icon
          if (showProfile) ...[
            const SizedBox(width: 8),
          InkWell(
            onTap: () => context.push('/profile'),
            borderRadius: BorderRadius.circular(14),
            child: const _HeaderAction(
              icon: Icons.person_rounded,
              isPrimary: true,
            ),
          ),
          ],
        ],
      ),
    );
  }
}

class NotificationDrawer extends ConsumerWidget {
  const NotificationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      width: MediaQuery.of(context).size.width, // Full screen width as requested
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'All your latest updates',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(14),
                    child: const _HeaderAction(
                      icon: Icons.close_rounded,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                   _NotificationActionButton(
                    label: 'Mark all as read',
                    icon: Icons.done_all_rounded,
                    onTap: () async {
                      final auth = ref.read(authProvider);
                      if (auth == null) return;
                      final role = (auth.role).trim();
                      await FirebaseService().markAllAsRead(role, auth.id);
                    },
                  ),
                  const SizedBox(width: 12),
                  _NotificationActionButton(
                    label: 'Clear all',
                    icon: Icons.delete_sweep_outlined,
                    isDanger: true,
                    onTap: () async {
                      final auth = ref.read(authProvider);
                      if (auth == null) return;
                      final role = (auth.role).trim();
                      await FirebaseService().clearNotifications(role, auth.id);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final notesAsync = ref.watch(notificationProvider);
                  return notesAsync.when(
                    data: (notes) {
                      if (notes.isEmpty) {
                        return const Center(child: Text('No notifications yet', style: TextStyle(color: Colors.grey)));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: notes.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return _NotificationItem(note: note);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error loading notifications: $e')),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Helper Widget for Action Buttons
class _NotificationActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDanger;

  const _NotificationActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.red.shade400 : AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends ConsumerWidget {
  final AppNotification note;
  const _NotificationItem({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isUpdate = note.type.contains('updated');
    final bool isDelete = note.type.contains('deleted');
    
    final Color iconColor = isDelete ? Colors.red : (isUpdate ? Colors.orange : AppColors.primary);
    final IconData icon = isDelete ? Icons.delete_sweep_rounded : (isUpdate ? Icons.update_rounded : Icons.add_circle_outline_rounded);

    return InkWell(
      onTap: note.isRead ? null : () async {
        await FirebaseService().markAsRead(note.id);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: note.isRead ? Colors.transparent : iconColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: note.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(note.timestamp),
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                      ),
                      const SizedBox(width: 8),
                      // Individual Delete Option
                      InkWell(
                        onTap: () => FirebaseService().deleteNotification(note.id),
                        child: Icon(Icons.close_rounded, size: 14, color: Colors.grey.shade300),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final bool isPrimary;

  const _HeaderAction({
    required this.icon,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPrimary
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: 22,
        color: isPrimary ? AppColors.primary : AppColors.textPrimary,
      ),
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final IconData? prefixIcon;
  final bool readOnly;

  const AppDropdown({
    super.key,
    this.label = '',
    required this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.prefixIcon,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: readOnly ? null : onChanged,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    size: 20,
                    color: AppColors.textPrimary.withValues(alpha: 0.6),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.blueGrey.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.blueGrey.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }
}

class AppToast {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    // Clear existing snackbars
    ScaffoldMessenger.of(context).clearSnackBars();

    // Create new snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFE11D48)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        duration: const Duration(seconds: 3),
        elevation: 8,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class AppImageWidget extends StatelessWidget {
  final String? source;
  final BoxFit fit;
  final Widget? placeholder;
  final double? width;
  final double? height;

  const AppImageWidget({
    super.key,
    this.source,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (source == null || source!.isEmpty) {
      return placeholder ?? _defaultPlaceholder();
    }

    if (source!.startsWith('http')) {
      return Image.network(
        source!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (c, e, s) => placeholder ?? _defaultPlaceholder(),
      );
    }

    try {
      return Image.memory(
        base64Decode(source!),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (c, e, s) => placeholder ?? _defaultPlaceholder(),
      );
    } catch (e) {
      return placeholder ?? _defaultPlaceholder();
    }
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade300, size: 24),
    );
  }
}

class AppImagePicker extends StatelessWidget {
  final XFile? pickedImage;
  final String? imageUrl;
  final Function(XFile?) onImagePicked;
  final VoidCallback onImageDeleted;
  final IconData placeholderIcon;
  final double size;

  const AppImagePicker({
    super.key,
    this.pickedImage,
    this.imageUrl,
    required this.onImagePicked,
    required this.onImageDeleted,
    this.placeholderIcon = Icons.person,
    this.size = 120,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        onImagePicked(image);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(context, 'Error picking image: $e', isError: true);
      }
    }
  }

  void _showImageSourceSheet(BuildContext context) {
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
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Colors.teal),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.camera);
                },
              ),
              if (pickedImage != null || imageUrl != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  ),
                  title: const Text('Remove Photo', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    onImageDeleted();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context) {
    if (pickedImage == null && imageUrl == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: pickedImage != null
                  ? Image.file(File(pickedImage!.path), fit: BoxFit.contain)
                  : AppImageWidget(source: imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
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

  @override
  Widget build(BuildContext context) {
    final bool hasImage = pickedImage != null || imageUrl != null;

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: hasImage ? () => _showImagePreview(context) : () => _showImageSourceSheet(context),
            onLongPress: () => _showImageSourceSheet(context),
            child: Stack(
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasImage ? AppColors.primary : Colors.grey.shade200,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: pickedImage != null
                        ? Image.file(File(pickedImage!.path), fit: BoxFit.cover)
                        : AppImageWidget(
                            source: imageUrl, 
                            placeholder: Container(
                              color: Colors.white,
                              child: Center(
                                child: Icon(placeholderIcon, size: size * 0.4, color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: GestureDetector(
                    onTap: () => _showImageSourceSheet(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
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
                ),
              ],
            ),
          ),
          if (hasImage) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _showImagePreview(context),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Preview', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                Container(
                  width: 1,
                  height: 16,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                TextButton.icon(
                  onPressed: () => _showImageSourceSheet(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Change', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class FilterTabItem {
  final String label;
  final int count;
  final IconData icon;
  FilterTabItem({required this.label, required this.count, required this.icon});
}

class MasterPageHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String searchHint;
  final Function(String) onSearchChanged;
  final VoidCallback onSearchCleared;
  final String? addButtonLabel;
  final VoidCallback? onAddPressed;
  final List<FilterTabItem> filters;
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final bool showAddButton;

  const MasterPageHeader({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.onSearchChanged,
    required this.onSearchCleared,
    this.addButtonLabel,
    this.onAddPressed,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          // Search Bar
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
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: searchHint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 20),
                        onPressed: onSearchCleared,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (showAddButton && addButtonLabel != null) ...[
            const SizedBox(height: 16),
            AppButton(
              label: addButtonLabel!,
              onPressed: onAddPressed,
              icon: Icons.add_rounded,
              height: 46,
            ),
          ],
          if (filters.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              height: 52,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: filters.map((filter) {
                  final bool isSelected = selectedFilter == filter.label;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onFilterChanged(filter.label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ] : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              filter.icon,
                              size: 14,
                              color: isSelected ? Colors.white : Colors.blueGrey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              filter.label,
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
                                filter.count.toString(),
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
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MasterCard extends StatelessWidget {
  final Widget image;
  final String title;
  final String subtitle;
  final IconData subtitleIcon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget? statusBadge;

  const MasterCard({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    this.subtitleIcon = Icons.phone_rounded,
    required this.onEdit,
    required this.onDelete,
    this.statusBadge,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Image Section
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
                child: image,
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
                    title,
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
                      Icon(subtitleIcon, size: 13, color: Colors.blueGrey.shade300),
                      const SizedBox(width: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blueGrey.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (statusBadge != null) ...[
                    const SizedBox(height: 8),
                    statusBadge!,
                  ] else ...[
                    const SizedBox(height: 6),
                  ],
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
                  onEdit,
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  Icons.delete_outline_rounded,
                  const Color(0xFFFFF1F2),
                  const Color(0xFFE11D48),
                  onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
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
}

enum MasterFormType { page, sheet }

class MasterFormPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? sectionTitle;
  final MasterFormType type;
  final Widget? imagePicker;
  final List<Widget> children;
  final String saveButtonLabel;
  final VoidCallback onSave;
  final bool isLoading;
  final IconData? saveIcon;

  const MasterFormPage({
    super.key,
    required this.title,
    this.subtitle,
    this.sectionTitle,
    this.type = MasterFormType.page,
    this.imagePicker,
    required this.children,
    required this.saveButtonLabel,
    required this.onSave,
    this.isLoading = false,
    this.saveIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (type == MasterFormType.sheet) {
      return _buildSheet(context);
    }
    return _buildPage(context);
  }

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
        ),
        elevation: 0,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildSheet(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 8, 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagePicker != null) ...[
            imagePicker!,
            const SizedBox(height: 32),
          ],
          if (sectionTitle != null) ...[
            Text(
              sectionTitle!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
          ],
          ...children,
          const SizedBox(height: 48),
          AppButton(
            label: saveButtonLabel,
            onPressed: onSave,
            isLoading: isLoading,
            icon: saveIcon,
          ),
        ],
      ),
    );
  }
}


class AppFormHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final bool showBack;

  const AppFormHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      color: Colors.white,
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: onBack,
              color: AppColors.textPrimary,
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: showBack ? 0 : 16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppStepCard extends StatelessWidget {
  final String title;
  final dynamic subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isCompleted;

  const AppStepCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isCompleted ? Colors.green : AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isCompleted ? Colors.green : AppColors.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: subtitle is Widget
              ? subtitle
              : Text(
                  subtitle.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 22,
          color: Colors.blueGrey.shade300,
        ),
      ),
    );
  }
}

class AppListItem extends StatelessWidget {
  final String title;
  final String amount;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AppListItem({
    super.key,
    required this.title,
    required this.amount,
    this.subtitle,
    this.icon = Icons.receipt_long_outlined,
    this.color,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.primary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon section
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: themeColor, size: 20),
            ),
            const SizedBox(width: 16),
            
            // Title & Subtitle section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: themeColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Amount & Actions section
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  amount,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      _buildActionBtn(
                        Icons.edit_rounded,
                        AppColors.primary,
                        onEdit!,
                      ),
                    if (onEdit != null && onDelete != null)
                      const SizedBox(width: 6),
                    if (onDelete != null)
                      _buildActionBtn(
                        Icons.delete_outline_rounded,
                        Colors.red.shade400,
                        onDelete!,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

class AppSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const AppSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: isBold ? 16 : 14,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class AppDeleteConfirmation {
  static void show(
    BuildContext context, {
    required String title,
    required String itemName,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete $title', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
