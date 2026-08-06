import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../services/user_service.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle_fill,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.checkmark_alt_circle_fill,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showErrorSnackBar('Please enter your email address');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showErrorSnackBar('Please enter a valid email address');
      return;
    }

    if (password.isEmpty) {
      _showErrorSnackBar('Please enter your password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await SupabaseService().signInUser(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final user = res.user;
      final fullName =
          user?.userMetadata?['full_name'] as String? ?? 'Inventory User';
      final phone = user?.userMetadata?['phone'] as String? ?? '';

      UserService().updateUserProfile(
        fullName: fullName,
        email: email,
        phone: phone,
      );

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Login failed. Please check your credentials.';
      if (e is AuthException) {
        errorMessage = e.message;
      } else if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Invalid email address or password.';
      }
      _showErrorSnackBar(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          // Background ambient curves
          const Positioned.fill(
            child: _LoginBackgroundBlobs(),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Top Glass Inventory Icon
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.cube_box_fill,
                          size: 38,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title: Welcome Back 👋
                    const Text(
                      'Welcome Back 👋',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF101010),
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Subtitle: Login to continue
                    const Text(
                      'Login to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Email Glass TextField
                    _GlassTextField(
                      controller: _emailController,
                      hintText: 'Email address',
                      icon: CupertinoIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    // Password Glass TextField
                    _GlassTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      icon: CupertinoIcons.lock,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? CupertinoIcons.eye
                              : CupertinoIcons.eye_slash,
                          color: const Color(0xFF6B7280),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showForgotPasswordModal(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Large Rounded Black Button: Login
                    _LargeBlackButton(
                      text: 'Login',
                      isLoading: _isLoading,
                      onTap: _handleLogin,
                    ),

                    const SizedBox(height: 32),

                    // Divider: OR CONTINUE WITH
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey.withValues(alpha: 0.3),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9CA3AF),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey.withValues(alpha: 0.3),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Social Buttons Row (Google & Apple)
                    Row(
                      children: [
                        // Google Button
                        Expanded(
                          child: _SocialGlassButton(
                            iconWidget: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                              width: 20,
                              height: 20,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(CupertinoIcons.globe,
                                      size: 20, color: Color(0xFF3B82F6)),
                            ),
                            label: 'Google',
                            onTap: _handleLogin,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Apple Button
                        Expanded(
                          child: _SocialGlassButton(
                            iconWidget: const Icon(
                              Icons.apple,
                              size: 24,
                              color: Color(0xFF101010),
                            ),
                            label: 'Apple',
                            onTap: _handleLogin,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // Bottom Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder<void>(
                                transitionDuration: const Duration(milliseconds: 320),
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    const RegisterScreen(),
                                transitionsBuilder:
                                    (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          child: const Text(
                            'Register',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF101010),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordModal(BuildContext context) {
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim());
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    int step = 1; // 1: Send OTP, 2: Enter OTP, 3: New Password
    bool isModalLoading = false;
    bool obscureNewPass = true;
    bool obscureConfirmPass = true;
    String? modalError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (step == 1) ...[
                      const Icon(CupertinoIcons.lock_shield_fill,
                          size: 48, color: Color(0xFF3B82F6)),
                      const SizedBox(height: 12),
                      const Text(
                        'Forgot Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF101010),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter your registered email address to receive an 8-digit verification OTP code.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (modalError != null) ...[
                        Text(
                          modalError!,
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                      ],
                      _GlassTextField(
                        controller: resetEmailController,
                        hintText: 'Email address',
                        icon: CupertinoIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      _LargeBlackButton(
                        text: 'Send OTP Code',
                        isLoading: isModalLoading,
                        onTap: () async {
                          final email = resetEmailController.text.trim();
                          if (email.isEmpty ||
                              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(email)) {
                            setModalState(() {
                              modalError = 'Please enter a valid email address';
                            });
                            return;
                          }
                          setModalState(() {
                            isModalLoading = true;
                            modalError = null;
                          });
                          try {
                            await SupabaseService().sendPasswordResetOtp(email);
                            setModalState(() {
                              isModalLoading = false;
                              step = 2;
                            });
                          } catch (e) {
                            setModalState(() {
                              isModalLoading = false;
                              modalError = e is AuthException
                                  ? e.message
                                  : 'Failed to send OTP code. Please check your email.';
                            });
                          }
                        },
                      ),
                    ] else if (step == 2) ...[
                      const Icon(CupertinoIcons.device_phone_portrait,
                          size: 48, color: Color(0xFF3B82F6)),
                      const SizedBox(height: 12),
                      const Text(
                        'Enter Verification OTP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF101010),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter the 8-digit code sent to ${resetEmailController.text.trim()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (modalError != null) ...[
                        Text(
                          modalError!,
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                      ],
                      _GlassTextField(
                        controller: otpController,
                        hintText: 'Enter 8-Digit OTP',
                        icon: CupertinoIcons.number,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      _LargeBlackButton(
                        text: 'Verify OTP',
                        isLoading: isModalLoading,
                        onTap: () async {
                          final otp = otpController.text.trim();
                          if (otp.isEmpty) {
                            setModalState(() {
                              modalError = 'Please enter the valid OTP code';
                            });
                            return;
                          }
                          setModalState(() {
                            isModalLoading = true;
                            modalError = null;
                          });
                          try {
                            await SupabaseService().verifyPasswordResetOtp(
                              email: resetEmailController.text.trim(),
                              otp: otp,
                            );
                            setModalState(() {
                              isModalLoading = false;
                              step = 3;
                            });
                          } catch (e) {
                            setModalState(() {
                              isModalLoading = false;
                              modalError = e is AuthException
                                  ? e.message
                                  : 'Invalid or expired OTP code.';
                            });
                          }
                        },
                      ),
                    ] else if (step == 3) ...[
                      const Icon(CupertinoIcons.lock_shield_fill,
                          size: 48, color: Color(0xFF10B981)),
                      const SizedBox(height: 12),
                      const Text(
                        'Set New Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF101010),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Create a strong password for your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (modalError != null) ...[
                        Text(
                          modalError!,
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                      ],
                      _GlassTextField(
                        controller: newPasswordController,
                        hintText: 'New Password',
                        icon: CupertinoIcons.lock,
                        obscureText: obscureNewPass,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNewPass
                                ? CupertinoIcons.eye
                                : CupertinoIcons.eye_slash,
                            color: const Color(0xFF6B7280),
                            size: 20,
                          ),
                          onPressed: () {
                            setModalState(() {
                              obscureNewPass = !obscureNewPass;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _GlassTextField(
                        controller: confirmPasswordController,
                        hintText: 'Confirm New Password',
                        icon: CupertinoIcons.lock_shield,
                        obscureText: obscureConfirmPass,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPass
                                ? CupertinoIcons.eye
                                : CupertinoIcons.eye_slash,
                            color: const Color(0xFF6B7280),
                            size: 20,
                          ),
                          onPressed: () {
                            setModalState(() {
                              obscureConfirmPass = !obscureConfirmPass;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      _LargeBlackButton(
                        text: 'Reset Password',
                        isLoading: isModalLoading,
                        onTap: () async {
                          final newPass = newPasswordController.text.trim();
                          final confirmPass =
                              confirmPasswordController.text.trim();
                          if (newPass.length < 6) {
                            setModalState(() {
                              modalError =
                                  'Password must be at least 6 characters long.';
                            });
                            return;
                          }
                          if (newPass != confirmPass) {
                            setModalState(() {
                              modalError = 'Passwords do not match.';
                            });
                            return;
                          }
                          setModalState(() {
                            isModalLoading = true;
                            modalError = null;
                          });
                          try {
                            await SupabaseService().updatePassword(newPass);
                            if (context.mounted) {
                              Navigator.pop(bottomSheetContext);
                            }
                            _showSuccessSnackBar(
                              'Password reset successfully! Please log in with your new password.',
                            );
                            _emailController.text =
                                resetEmailController.text.trim();
                            _passwordController.clear();
                          } catch (e) {
                            setModalState(() {
                              isModalLoading = false;
                              modalError = e is AuthException
                                  ? e.message
                                  : 'Failed to update password. Please try again.';
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Glass TextField Widget
class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF101010),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF9CA3AF),
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF6B7280),
            size: 20,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

/// Large Rounded Black Button Widget
class _LargeBlackButton extends StatefulWidget {
  const _LargeBlackButton({
    required this.text,
    required this.onTap,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  State<_LargeBlackButton> createState() => _LargeBlackButtonState();
}

class _LargeBlackButtonState extends State<_LargeBlackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF101010),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 18,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    widget.text,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Social Glass Button Widget
class _SocialGlassButton extends StatelessWidget {
  const _SocialGlassButton({
    required this.iconWidget,
    required this.label,
    required this.onTap,
  });

  final Widget iconWidget;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF101010),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Background Ambient Blobs
class _LoginBackgroundBlobs extends StatelessWidget {
  const _LoginBackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF64748B).withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
