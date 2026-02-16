import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class KawaiiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? fillColor;
  final double borderRadius;
  final double borderWidth;
  final Color? borderColor;

  const KawaiiCard({
    super.key,
    required this.child,
    this.padding,
    this.fillColor,
    this.borderRadius = 20,
    this.borderWidth = 2.5,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fillColor ?? KawaiiColors.cardWhite,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? KawaiiColors.deepInk,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: KawaiiColors.deepInk.withValues(alpha: 0.06),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
