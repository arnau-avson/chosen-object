import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/auth_service.dart';
import '../core/profile_service.dart';
import '../core/push_notification_service.dart';
import 'home/home_screen.dart';
import 'auth/login_screen.dart';

/// Pantalla inicial que comprueba el token y redirige al destino correcto.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    bool authenticated = false;
    try {
      authenticated = await AuthService.isAuthenticated();
    } catch (_) {
      authenticated = false;
    }
    if (!mounted) return;

    if (authenticated) {
      ProfileService.instance.loadFromBackend();
      await PushNotificationService.instance.initialize();
    }

    // Authenticated → home. Not authenticated → login.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            authenticated ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Text(
            'Chosen Object',
            style: GoogleFonts.fraunces(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: AppColors.inkStrong,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
