import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSentSuccessfully = false;

  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 60;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        _cooldownTimer?.cancel();
      }
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AuthProvider>();

    // SECURITY COMPLIANCE NOTE:
    // To protect against email enumeration attacks and maintain production security standards,
    // we call the generic Firebase password reset API directly without querying Firestore to check
    // if the email exists. The Firebase Spark plan does not provide a secure, server-side method
    // to check emailVerified or registration status without exposing user data to anonymous clients.
    final success =
        await provider.sendPasswordReset(_emailController.text.trim());

    if (success && mounted) {
      setState(() {
        _emailSentSuccessfully = true;
      });
      _startCooldown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Iconsax.key, size: 72, color: AppColors.primary),
                const SizedBox(height: 24),
                if (!_emailSentSuccessfully) ...[
                  Text(
                    'Forgot Password?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Enter your email and we'll send you a password reset link.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          theme.textTheme.bodyMedium?.color?.withAlpha(178) ??
                              AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon:
                          Icon(Icons.email_outlined, color: AppColors.primary),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Email cannot be empty.';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(val.trim())) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (provider.error != null) ...[
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: provider.loading || _cooldownSeconds > 0
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                    child: provider.loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            _cooldownSeconds > 0
                                ? 'Send Link (${_cooldownSeconds}s)'
                                : 'Send Reset Link',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ] else ...[
                  Text(
                    'Check your email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            theme.textTheme.bodyMedium?.color?.withAlpha(178) ??
                                AppColors.textSecondary,
                      ),
                      children: [
                        const TextSpan(text: 'If an account exists for '),
                        TextSpan(
                          text: _emailController.text.trim(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                        const TextSpan(
                            text: ', we\'ve sent a password reset link.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please check your inbox and spam/junk folder. Follow the link to create a new password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          theme.textTheme.bodyMedium?.color?.withAlpha(128) ??
                              AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),
                  OutlinedButton(
                    onPressed: provider.loading || _cooldownSeconds > 0
                        ? null
                        : _submit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                    child: Text(
                      _cooldownSeconds > 0
                          ? 'Resend Link (${_cooldownSeconds}s)'
                          : 'Resend Link',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
