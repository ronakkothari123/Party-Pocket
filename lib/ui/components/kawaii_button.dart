import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class KawaiiButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color fillColor;
  final Color? textColor;
  final IconData? icon;
  final bool isPrimary;
  final Color borderColor;
  final double borderWidth;

  const KawaiiButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.fillColor,
    this.textColor,
    this.icon,
    this.isPrimary = true,
    this.borderColor = const Color(0xFF2B2B2B),
    this.borderWidth = 3,
  });

  @override
  State<KawaiiButton> createState() => _KawaiiButtonState();
}

class _KawaiiButtonState extends State<KawaiiButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final height = widget.isPrimary ? 64.0 : 44.0;
    final fontSize = widget.isPrimary ? 18.0 : 14.0;
    final effectiveTextColor = widget.textColor ?? KawaiiColors.deepInk;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: widget.fillColor,
            borderRadius: BorderRadius.circular(widget.isPrimary ? 20 : 16),
            border: Border.all(
              color: widget.borderColor,
              width: widget.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.borderColor.withValues(alpha: 0.08),
                offset: const Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize:
                widget.isPrimary ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: effectiveTextColor, size: fontSize + 4),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  style: GoogleFonts.fredoka(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: effectiveTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
