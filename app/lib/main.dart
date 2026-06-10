import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp();
  }
  runApp(const ChosenObjectApp());
}

class ChosenObjectApp extends StatelessWidget {
  const ChosenObjectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chosen Object',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
