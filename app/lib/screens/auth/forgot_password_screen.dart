import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    // TODO: llamar al backend
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _isLoading = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _sent ? _SuccessView(_emailController.text.trim()) : _FormView(
            formKey: _formKey,
            emailController: _emailController,
            isLoading: _isLoading,
            onSubmit: _handleSubmit,
          ),
        ),
      ),
    );
  }
}

// — Vista del formulario —

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _FormView({
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),

          // — Icono —
          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.hairline2,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.lock_reset_outlined,
                size: 24,
                color: AppColors.inkSoft,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              'Reset password',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: AppColors.inkStrong,
                height: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              "We'll send you a link to\nreset your password.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.muted,
                height: 1.55,
              ),
            ),
          ),

          const SizedBox(height: 36),

          // — Formulario —
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.hairline, width: 1),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FieldLabel('Email'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  onFieldSubmitted: (_) => onSubmit(),
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    color: AppColors.inkStrong,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'you@email.com',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter your email';
                    }
                    final hasAt = v.contains('@') && v.contains('.');
                    if (!hasAt) return 'Enter a valid email';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onSubmit,
                    child: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.bone,
                            ),
                          )
                        : const Text('Send reset link'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Back to sign in',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// — Vista de confirmación —

class _SuccessView extends StatelessWidget {
  final String email;
  const _SuccessView(this.email);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 72),

        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0E9),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_outlined,
              size: 26,
              color: AppColors.success,
            ),
          ),
        ),

        const SizedBox(height: 20),

        Center(
          child: Text(
            'Check your inbox',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: AppColors.inkStrong,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Center(
          child: Text(
            "If $email has an account,\nyou'll receive a link shortly.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.muted,
              height: 1.55,
            ),
          ),
        ),

        const SizedBox(height: 40),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Volver al inicio de sesión'),
          ),
        ),

        const SizedBox(height: 40),
      ],
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
        fontWeight: FontWeight.w500,
        color: AppColors.muted,
        letterSpacing: 0.14 * 10,
      ),
    );
  }
}
