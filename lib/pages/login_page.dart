import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
          _emailController.text = prefs.getString('${prefix}${_keyEmail}') ?? '';
          _passwordController.text =
              prefs.getString('${prefix}${_keyPassword}') ?? '';
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
      await prefs.setString('${prefix}${_keyEmail}', _emailController.text);
      await prefs.setString('${prefix}${_keyPassword}', _passwordController.text);
    } else {
      await prefs.remove('${prefix}${_keyEmail}');
      await prefs.remove('${prefix}${_keyPassword}');
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Logo
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'TRANSPORT MANAGEMENT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 3,
                      width: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Truck Image
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1519003722824-194d4455a60c?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              const Text(
                'Login to Continue',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your credentials to access your account.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 40),

              // Sleek Modern Role Tabs
              const Text(
                'Select Role',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFF475569),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9), // Slate 100
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    // Precision Background Slider
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutBack,
                      alignment: isAdministrator ? Alignment.centerLeft : Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Tab Content (Wrapped in Positioned.fill to ensure full width integration)
                    Positioned.fill(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildRoleTab(
                              'Administrator',
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              AutofillGroup(
                child: Column(
                  children: [
                    AppTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'name@company.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AppColors.primary,
                      onChanged: (value) =>
                          setState(() => _rememberMe = value ?? false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Remember Me',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              AppButton(
                label: 'Sign In',
                isLoading: _isLoading,
                onPressed: _handleLogin,
                icon: Icons.arrow_forward,
              ),
              const SizedBox(height: 32),

              // Footer
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(text: "Don't have an account? "),
                      TextSpan(
                        text: 'Contact Administrator',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
