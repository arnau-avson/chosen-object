import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/auth_service.dart';
import '../../core/profile_service.dart';
import '../../core/push_notification_service.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;
  bool _buttonPressed = false;

  late final AnimationController _enter;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _titleFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _formFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.2, 0.75, curve: Curves.easeOut),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    _footerFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );

    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.login(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      );
      ProfileService.instance.loadFromBackend();
      if (Platform.isAndroid || Platform.isIOS) {
        await PushNotificationService.instance.initialize();
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const HomeScreen(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
        (_) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.message == 'Email not verified.') {
        _showVerificationModal();
      } else {
        _showError(e.message);
      }
    } catch (_) {
      if (!mounted) return;
      _showError('Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.bone),
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }

  void _showVerificationModal() {
    final identifier = _identifierController.text.trim();
    final email = identifier.contains('@') ? identifier : '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _VerifyEmailDialog(
        email: email,
        onVerified: () {
          Navigator.of(ctx).pop();
          ProfileService.instance.loadFromBackend();
          if (Platform.isAndroid || Platform.isIOS) {
            PushNotificationService.instance.initialize();
          }
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, _, _) => const HomeScreen(),
              transitionsBuilder: (_, animation, _, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 350),
            ),
            (_) => false,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 88),

                // ── Cabecera ─────────────────────────────────
                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chosen Object',
                          style: GoogleFonts.fraunces(
                            fontSize: 32,
                            fontWeight: FontWeight.w400,
                            color: AppColors.inkStrong,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(width: 32, height: 1, color: AppColors.hairline),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ── Formulario ───────────────────────────────
                FadeTransition(
                  opacity: _formFade,
                  child: SlideTransition(
                    position: _formSlide,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.07),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FieldLabel('Email or username'),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: _identifierController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              color: AppColors.inkStrong,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'you@email.com or @username',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter your email or username';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 22),

                          _FieldLabel('Password'),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_passwordVisible,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              color: AppColors.inkStrong,
                            ),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                  () => _passwordVisible = !_passwordVisible,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: Icon(
                                    _passwordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter your password';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 8),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 2,
                                ),
                              ),
                              child: Text(
                                'Forgot your password?',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Botón principal ────────────────
                          GestureDetector(
                            onTapDown: (_) =>
                                setState(() => _buttonPressed = true),
                            onTapUp: (_) =>
                                setState(() => _buttonPressed = false),
                            onTapCancel: () =>
                                setState(() => _buttonPressed = false),
                            onTap: _isLoading ? null : _handleLogin,
                            child: AnimatedScale(
                              scale: _buttonPressed ? 0.98 : 1.0,
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeInOut,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                curve: Curves.easeInOut,
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  color: _isLoading
                                      ? AppColors.inkSoft
                                      : AppColors.ink,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.center,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _isLoading
                                      ? const SizedBox(
                                          key: ValueKey('loader'),
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.bone,
                                          ),
                                        )
                                      : Text(
                                          'Sign in',
                                          key: const ValueKey('label'),
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.bone,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Pie ──────────────────────────────────────
                FadeTransition(
                  opacity: _footerFade,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: AppColors.muted,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, _, _) => const OnboardingScreen(),
                            transitionsBuilder: (_, anim, _, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration:
                                const Duration(milliseconds: 300),
                          ),
                        ),
                        child: Text(
                          'Sign up',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
        letterSpacing: 1.4,
      ),
    );
  }
}

// ── Verify-email dialog (shown when login fails due to unverified email) ──

class _VerifyEmailDialog extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;

  const _VerifyEmailDialog({
    required this.email,
    required this.onVerified,
  });

  @override
  State<_VerifyEmailDialog> createState() => _VerifyEmailDialogState();
}

class _VerifyEmailDialogState extends State<_VerifyEmailDialog> {
  final _pinCtrl = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_pinCtrl.text.trim().length < 6) {
      _showError('Enter the 6-digit code');
      return;
    }
    setState(() => _isVerifying = true);
    try {
      await AuthService.verifyEmail(
        email: widget.email,
        pin: _pinCtrl.text.trim(),
      );
      if (!mounted) return;
      widget.onVerified();
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    if (widget.email.isEmpty) return;
    setState(() => _isResending = true);
    try {
      await AuthService.resendPin(email: widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A new code has been generated.',
            style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.bone),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.bone),
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button row
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: AppColors.muted,
                ),
              ),
            ),

            // Mail icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.bone,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.hairline, width: 1),
              ),
              child: const Icon(
                Icons.mail_outline_rounded,
                size: 26,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              'Verify your email',
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: AppColors.inkStrong,
              ),
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              'Your email is not verified yet. Enter the code we sent to:',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            if (widget.email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkStrong,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // PIN input
            _DialogPinInput(controller: _pinCtrl),
            const SizedBox(height: 16),

            // Resend link
            GestureDetector(
              onTap: _isResending ? null : _resend,
              child: Text(
                _isResending ? 'Sending...' : 'Resend code',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Verify button
            GestureDetector(
              onTap: _isVerifying ? null : _verify,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeInOut,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: _isVerifying ? AppColors.inkSoft : AppColors.ink,
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isVerifying
                      ? const SizedBox(
                          key: ValueKey('loader'),
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.bone,
                          ),
                        )
                      : Text(
                          'Verify',
                          key: const ValueKey('label'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.bone,
                            letterSpacing: 0.1,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PIN input for the verification dialog ────────────────────────

class _DialogPinInput extends StatefulWidget {
  final TextEditingController controller;
  const _DialogPinInput({required this.controller});

  @override
  State<_DialogPinInput> createState() => _DialogPinInputState();
}

class _DialogPinInputState extends State<_DialogPinInput> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;

    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Stack(
        children: [
          // Hidden input
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
          ),

          // Visual boxes
          Row(
            children: List.generate(6, (i) {
              final filled = i < text.length;
              final isActive = i == text.length && _focus.hasFocus;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 52,
                  margin: EdgeInsets.only(right: i < 5 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: AppColors.bone,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? AppColors.ink
                          : filled
                              ? AppColors.hairline
                              : AppColors.hairline2,
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    filled ? text[i] : '',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkStrong,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
