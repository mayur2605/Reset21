import 'package:flutter/material.dart';
import '../design_system.dart';

class KineticButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Widget? icon;

  const KineticButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.icon,
  });

  @override
  State<KineticButton> createState() => _KineticButtonState();
}

class _KineticButtonState extends State<KineticButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isPrimary ? AppColors.primary : AppColors.surface;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        transform: _isPressed ? Matrix4.translationValues(4, 4, 0) : Matrix4.identity(),
        decoration: AppDecoration.kineticContainer(
          backgroundColor: backgroundColor,
          showShadow: !_isPressed,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              widget.icon!,
              const SizedBox(width: 8),
            ],
            Text(
              widget.text.toUpperCase(),
              style: AppTypography.headlineMedium.copyWith(
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KineticCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final bool showShadow;
  final double padding;

  const KineticCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.showShadow = true,
    this.padding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecoration.kineticContainer(
        backgroundColor: backgroundColor ?? AppColors.surface,
        showShadow: showShadow,
      ),
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}
