import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// 3-2-1 countdown with bounce animation + haptics.
class CountdownScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final int from;
  final bool enableHaptics;

  const CountdownScreen({
    super.key,
    required this.onComplete,
    this.from = 3,
    this.enableHaptics = true,
  });

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen>
    with SingleTickerProviderStateMixin {
  late int _current;
  Timer? _timer;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _current = widget.from;
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _startCountdown();
  }

  void _startCountdown() {
    _bounceController.forward(from: 0);
    if (widget.enableHaptics) HapticFeedback.lightImpact();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_current <= 1) {
        timer.cancel();
        widget.onComplete();
      } else {
        setState(() => _current--);
        _bounceController.forward(from: 0);
        if (widget.enableHaptics) HapticFeedback.lightImpact();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      KawaiiColors.primaryPink,
      KawaiiColors.sunshineYellow,
      KawaiiColors.mintGreen,
      KawaiiColors.skyBlue,
    ];
    final color = colors[_current % colors.length];

    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _bounceAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _bounceAnim.value,
              child: child,
            );
          },
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: KawaiiColors.deepInk,
                width: 4,
              ),
            ),
            child: Center(
              child: Text(
                '$_current',
                style: GoogleFonts.fredoka(
                  fontSize: 72,
                  fontWeight: FontWeight.w700,
                  color: KawaiiColors.deepInk,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
