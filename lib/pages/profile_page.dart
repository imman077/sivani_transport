import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/providers/auth_provider.dart';
import 'package:sivani_transport/widgets/app_components.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider);
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = ref.read(authProvider);
    if (user != null) {
      try {
        final updatedUser = user.copyWith(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
        );
        await ref.read(authProvider.notifier).updateProfile(updatedUser);
        if (mounted) {
          setState(() => _isEditing = false);
          AppToast.show(context, 'Profile updated successfully');
        }
      } catch (e) {
        if (mounted) {
          AppToast.show(context, 'Error updating profile: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    final isAdmin = user.role == 'Admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Admin Profile' : 'Driver Profile',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        // actions: [
        //   if (isAdmin)
        //     if (!_isEditing)
        //       IconButton(
        //         icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
        //         onPressed: () => setState(() => _isEditing = true),
        //       )
        //     else
        //       TextButton(
        //         onPressed: _saveProfile,
        //         child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
        //       ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(child: _buildProfileImage(user.image)),
                      ),
                      if (_isEditing)
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_isEditing) ...[
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${user.role} • Sivani Transport',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_isEditing) ...[
              AppTextField(
                label: 'Full Name',
                hint: 'Enter your name',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email Address',
                hint: 'Enter your email',
                controller: _emailController,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Phone Number',
                hint: 'Enter your phone',
                controller: _phoneController,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Save Changes',
                onPressed: _saveProfile,
                icon: Icons.save_rounded,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => setState(() => _isEditing = false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ] else ...[
              _buildInfoTile(Icons.email_outlined, 'Email Address', user.email),
              _buildInfoTile(Icons.phone_outlined, 'Phone Number', user.phone),
              if (!isAdmin && user.license.isNotEmpty)
                _buildInfoTile(
                  Icons.description_outlined,
                  'License ID',
                  user.license,
                ),
              _buildInfoTile(
                Icons.badge_outlined,
                isAdmin ? 'Admin ID' : 'Driver ID',
                user.id,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    AppToast.show(context, 'Logged out successfully');
                    context.go('/');
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.05),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? source) {
    if (source == null || source.isEmpty) {
      return const Icon(Icons.person, size: 60, color: Colors.white);
    }

    if (source.startsWith('http')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.person, size: 60, color: Colors.white),
      );
    }

    try {
      return Image.memory(
        base64Decode(source),
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.person, size: 60, color: Colors.white),
      );
    } catch (e) {
      return const Icon(Icons.person, size: 60, color: Colors.white);
    }
  }
}
