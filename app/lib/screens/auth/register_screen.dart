import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/auth_service.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _isLoading = false;
  bool _buttonPressed = false;
  int _step = 0; // 0, 1, 2

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
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ──────────────────────────────────────────────

  void _nextStep() {
    if (_step == 0 && !_step1Key.currentState!.validate()) return;
    if (_step == 1 && !_step2Key.currentState!.validate()) return;
    if (_step < 2) setState(() => _step++);
  }

  void _prevStep() {
    if (_step > 0) setState(() => _step--);
  }

  // ── Submit ──────────────────────────────────────────────────

  Future<void> _handleRegister() async {
    if (_pinCtrl.text.trim().length < 6) {
      _showError('Enter the 6-digit code');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.register(
        email: _emailCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        role: widget.role,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
      );
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
      _showError(e.message);
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

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final titles = ['Create account', 'Secure your account', 'Verify email'];

    return Scaffold(
      backgroundColor: AppColors.bone,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 88),

              // ── Header ────────────────────────────────────
              FadeTransition(
                opacity: _titleFade,
                child: SlideTransition(
                  position: _titleSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back arrow for steps 1 & 2
                      if (_step > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: GestureDetector(
                            onTap: _prevStep,
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 22,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Column(
                          key: ValueKey(_step),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titles[_step],
                              style: GoogleFonts.fraunces(
                                fontSize: 32,
                                fontWeight: FontWeight.w400,
                                color: AppColors.inkStrong,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Step ${_step + 1} of 3',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Step indicator bar
                      _StepIndicator(step: _step),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Form card ─────────────────────────────────
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
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _step == 0
                          ? _buildStep1()
                          : _step == 1
                              ? _buildStep2()
                              : _buildStep3(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Footer ────────────────────────────────────
              FadeTransition(
                opacity: _footerFade,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.inter(
                          fontSize: 13.5, color: AppColors.muted),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (_, _, _) => const LoginScreen(),
                          transitionsBuilder: (_, anim, _, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration:
                              const Duration(milliseconds: 300),
                        ),
                      ),
                      child: Text(
                        'Sign in',
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
    );
  }

  // ── Step 1: First name, Last name, Email, Username, City, Country ──

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        key: const ValueKey('step1'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // First name + Last name side by side
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _FieldLabel('First name'),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: _firstNameCtrl,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      style: GoogleFonts.inter(
                          fontSize: 14.5, color: AppColors.inkStrong),
                      decoration: const InputDecoration(hintText: 'John'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? '' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _FieldLabel('Last name'),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: _lastNameCtrl,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      style: GoogleFonts.inter(
                          fontSize: 14.5, color: AppColors.inkStrong),
                      decoration: const InputDecoration(hintText: 'Doe'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? '' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          const _FieldLabel('Email'),
          const SizedBox(height: 7),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            style:
                GoogleFonts.inter(fontSize: 14.5, color: AppColors.inkStrong),
            decoration: const InputDecoration(hintText: 'you@email.com'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return '';
              if (!v.contains('@')) return '';
              return null;
            },
          ),
          const SizedBox(height: 22),

          const _FieldLabel('Username'),
          const SizedBox(height: 7),
          TextFormField(
            controller: _usernameCtrl,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            style:
                GoogleFonts.inter(fontSize: 14.5, color: AppColors.inkStrong),
            decoration: const InputDecoration(hintText: '@username'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return '';
              if (v.trim().length < 3) return '';
              return null;
            },
          ),
          const SizedBox(height: 22),

          // City + Country side by side
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _FieldLabel('City'),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: _cityCtrl,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      style: GoogleFonts.inter(
                          fontSize: 14.5, color: AppColors.inkStrong),
                      decoration:
                          const InputDecoration(hintText: 'Barcelona'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? '' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _FieldLabel('Country'),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: _countryCtrl,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      style: GoogleFonts.inter(
                          fontSize: 14.5, color: AppColors.inkStrong),
                      decoration: const InputDecoration(hintText: 'Spain'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? '' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),

          _ActionButton(
            label: 'Next',
            onTap: _nextStep,
            isLoading: false,
            pressed: _buttonPressed,
            onPressedChanged: (v) => setState(() => _buttonPressed = v),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Password + Strength meter ───────────────────────

  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: Column(
        key: const ValueKey('step2'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FieldLabel('Password'),
          const SizedBox(height: 7),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: !_passwordVisible,
            textInputAction: TextInputAction.next,
            style:
                GoogleFonts.inter(fontSize: 14.5, color: AppColors.inkStrong),
            decoration: InputDecoration(
              hintText: '••••••••',
              suffixIcon: GestureDetector(
                onTap: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
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
              if (v == null || v.isEmpty) return '';
              if (v.length < 8) return '';
              return null;
            },
          ),
          const SizedBox(height: 22),

          const _FieldLabel('Confirm password'),
          const SizedBox(height: 7),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: !_confirmVisible,
            textInputAction: TextInputAction.done,
            style:
                GoogleFonts.inter(fontSize: 14.5, color: AppColors.inkStrong),
            decoration: InputDecoration(
              hintText: '••••••••',
              suffixIcon: GestureDetector(
                onTap: () =>
                    setState(() => _confirmVisible = !_confirmVisible),
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    _confirmVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return '';
              if (v != _passwordCtrl.text) return '';
              return null;
            },
          ),

          const SizedBox(height: 20),

          // ── Strength bar (reactive via ValueListenableBuilder) ──
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _passwordCtrl,
            builder: (context, value, _) {
              final text = value.text;
              final hasMin = text.length >= 8;
              final hasUpper = text.contains(RegExp(r'[A-Z]'));
              final hasLower = text.contains(RegExp(r'[a-z]'));
              final hasDigit = text.contains(RegExp(r'[0-9]'));
              final hasSpecial =
                  text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
              final score =
                  [hasMin, hasUpper, hasLower, hasDigit, hasSpecial]
                      .where((b) => b)
                      .length;
              final pct = text.isEmpty ? 0.0 : score / 5;

              Color color;
              if (score <= 1) {
                color = AppColors.danger;
              } else if (score <= 2) {
                color = const Color(0xFFD4822E);
              } else if (score <= 3) {
                color = AppColors.gold;
              } else if (score <= 4) {
                color = AppColors.sage;
              } else {
                color = AppColors.success;
              }

              String label;
              if (text.isEmpty) {
                label = '';
              } else if (score <= 1) {
                label = 'Weak';
              } else if (score <= 2) {
                label = 'Fair';
              } else if (score <= 3) {
                label = 'Good';
              } else if (score <= 4) {
                label = 'Strong';
              } else {
                label = 'Very strong';
              }

              return Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 4,
                        color: AppColors.hairline2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            widthFactor: pct,
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 70,
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 26),

          _ActionButton(
            label: 'Next',
            onTap: _nextStep,
            isLoading: false,
            pressed: _buttonPressed,
            onPressedChanged: (v) => setState(() => _buttonPressed = v),
          ),
        ],
      ),
    );
  }

  // ── Step 3: PIN verification ────────────────────────────────

  Widget _buildStep3() {
    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
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
        ),
        const SizedBox(height: 20),
        Text(
          'We sent a 6-digit code to',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: AppColors.muted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _emailCtrl.text.trim(),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.inkStrong,
          ),
        ),
        const SizedBox(height: 28),

        // PIN fields
        _PinInput(controller: _pinCtrl),

        const SizedBox(height: 20),

        // Resend link
        Center(
          child: GestureDetector(
            onTap: () {
              _showError('Verification emails are not sent yet.');
            },
            child: Text(
              'Resend code',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        const SizedBox(height: 26),

        _ActionButton(
          label: 'Verify & create account',
          onTap: _handleRegister,
          isLoading: _isLoading,
          pressed: _buttonPressed,
          onPressedChanged: (v) => setState(() => _buttonPressed = v),
        ),
      ],
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────

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

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  final bool pressed;
  final ValueChanged<bool> onPressedChanged;

  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.isLoading,
    required this.pressed,
    required this.onPressedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onPressedChanged(true),
      onTapUp: (_) => onPressedChanged(false),
      onTapCancel: () => onPressedChanged(false),
      onTap: isLoading ? null : onTap,
      child: AnimatedScale(
        scale: pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeInOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isLoading ? AppColors.inkSoft : AppColors.ink,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
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
                    label,
                    key: ValueKey(label),
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
    );
  }
}

// ── Step indicator ──────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final done = i < step;
        final active = i == step;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            height: 3,
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            decoration: BoxDecoration(
              color: done
                  ? AppColors.ink
                  : active
                      ? AppColors.inkSoft
                      : AppColors.hairline2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ── Animated fractionally sized box ─────────────────────────────

class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  final double widthFactor;
  final Widget child;

  const AnimatedFractionallySizedBox({
    super.key,
    required this.widthFactor,
    required this.child,
    required super.duration,
    super.curve,
  });

  @override
  AnimatedWidgetBaseState<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(
      _widthFactor,
      widget.widthFactor,
      (v) => Tween<double>(begin: v as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: _widthFactor!.evaluate(animation),
      child: widget.child,
    );
  }
}

// ── PIN input widget ────────────────────────────────────────────

class _PinInput extends StatefulWidget {
  final TextEditingController controller;
  const _PinInput({required this.controller});

  @override
  State<_PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<_PinInput> {
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
