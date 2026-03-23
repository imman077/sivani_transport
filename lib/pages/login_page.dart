import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/widgets/app_components.dart';
import 'package:sivani_transport/services/firebase_service.dart';
import 'package:sivani_transport/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool isAdministrator = true;
  bool _isLoading = false;
  bool _rememberMe = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const String _keyEmail = 'saved_email';
  static const String _keyPassword = 'saved_password';
  static const String _keyIsAdmin = 'saved_is_admin';
  static const String _keyRememberMe = 'saved_remember_me';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final String prefix = isAdministrator ? 'admin_' : 'driver_';

    if (mounted) {
      setState(() {
        _rememberMe = prefs.getBool(_keyRememberMe) ?? true;
        if (_rememberMe) {
          _emailController.text = prefs.getString('$prefix$_keyEmail') ?? '';
          _passwordController.text =
              prefs.getString('$prefix$_keyPassword') ?? '';
        }
      });
    }
  }

  void _switchRole(bool toAdmin) {
    if (isAdministrator == toAdmin) return;
    setState(() {
      isAdministrator = toAdmin;
      _emailController.clear();
      _passwordController.clear();
    });
  }

  void _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final String prefix = isAdministrator ? 'admin_' : 'driver_';

    await prefs.setBool(_keyRememberMe, _rememberMe);
    if (_rememberMe) {
      await prefs.setString('$prefix$_keyEmail', _emailController.text);
      await prefs.setString('$prefix$_keyPassword', _passwordController.text);
    } else {
      await prefs.remove('$prefix$_keyEmail');
      await prefs.remove('$prefix$_keyPassword');
    }
    await prefs.setBool(_keyIsAdmin, isAdministrator);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      AppToast.show(context, 'Please enter email and password', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await FirebaseService().login(
        _emailController.text,
        _passwordController.text,
      );

      if (user != null) {
        if (mounted) {
          // Validate role
          final selectedRole = isAdministrator ? 'Admin' : 'Driver';
          if (user.role != selectedRole) {
            AppToast.show(
              context,
              'Invalid credentials for ${isAdministrator ? "Administrator" : "Driver"} role.',
              isError: true,
            );
            setState(() => _isLoading = false);
            return;
          }

          _saveCredentials();
          TextInput.finishAutofillContext();
          ref.read(authProvider.notifier).login(user);
          AppToast.show(context, 'Welcome back, ${user.name}!');
          context.go('/dashboard');
        }
      } else {
        if (mounted) {
          AppToast.show(context, 'Invalid email or password', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Login Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Premium Background Decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              height: 400,
              width: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.05),
                    Colors.blue.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // Login Form Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 40,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please log in to manage your shipments.',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Role Toggle
                              Container(
                                height: 52,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedAlign(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      alignment: isAdministrator
                                          ? Alignment.centerLeft
                                          : Alignment.centerRight,
                                      child: FractionallySizedBox(
                                        widthFactor: 0.5,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.06,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildRoleTab(
                                            'Admin',
                                            Icons.shield_rounded,
                                            isAdministrator,
                                            () => _switchRole(true),
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildRoleTab(
                                            'Driver',
                                            Icons.local_shipping_rounded,
                                            !isAdministrator,
                                            () => _switchRole(false),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              AutofillGroup(
                                child: Column(
                                  children: [
                                    _buildModernTextField(
                                      controller: _emailController,
                                      label: 'Email Address',
                                      hint: 'name@sivani.com',
                                      icon: Icons.alternate_email_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: [AutofillHints.email],
                                    ),
                                    const SizedBox(height: 24),
                                    _buildModernTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      hint: '••••••••',
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: true,
                                      autofillHints: [AutofillHints.password],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Transform.scale(
                                    scale: 0.9,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (value) => setState(
                                        () => _rememberMe = value ?? false,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Stay signed in',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              AppButton(
                                label: 'LOG IN NOW',
                                isLoading: _isLoading,
                                onPressed: _handleLogin,
                                icon: Icons.login_rounded,
                                borderRadius: 16,
                                height: 58,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Footer Section
                        Center(
                          child: Column(
                            children: [
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    const TextSpan(text: "Need access? "),
                                    TextSpan(
                                      text: 'Help Center',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Sivani Transport v1.0.0',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTab(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: GoogleFonts.outfit(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<String>? autofillHints,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
