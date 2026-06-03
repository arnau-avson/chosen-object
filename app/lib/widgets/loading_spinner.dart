import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class LoadingSpinner extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const LoadingSpinner({
    super.key,
    this.size = 24,
    this.strokeWidth = 1.5,
    this.color,
  });

  @override
  State<LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<LoadingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CircularProgressIndicator(
        strokeWidth: widget.strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.color ?? AppColors.ink,
        ),
      ),
    );
  }
}
