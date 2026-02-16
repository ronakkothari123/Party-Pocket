import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class KawaiiIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? fillColor;
  final Color? iconColor;
  final double size;
  final double borderWidth;

  const KawaiiIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.fillColor,
    this.iconColor,
    this.size = 40,
    this.borderWidth = 2.5,
  });

  @override
  State<KawaiiIconButton> createState() => _KawaiiIconButtonState();
}

class _KawaiiIconButtonState extends State<KawaiiIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.fillColor ?? KawaiiColors.cardWhite,
            shape: BoxShape.circle,
            border: Border.all(
              color: KawaiiColors.deepInk,
              width: widget.borderWidth,
            ),
          ),
          child: Icon(
            widget.icon,
            size: widget.size * 0.5,
            color: widget.iconColor ?? KawaiiColors.deepInk,
          ),
        ),
      ),
    );
  }
}
