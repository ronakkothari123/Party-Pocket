import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Neutral screen shown when passing the device between players.
/// Hides all game info until the receiving player taps "Ready".
class PassDeviceScreen extends StatefulWidget {
  final String playerName;
  final Color? playerColor;
  final VoidCallback onReady;

  const PassDeviceScreen({
    super.key,
    required this.playerName,
    this.playerColor,
    required this.onReady,
  });

  @override
  State<PassDeviceScreen> createState() => _PassDeviceScreenState();
}

class _PassDeviceScreenState extends State<PassDeviceScreen> {
  bool _holding = false;
  bool _revealed = false;

  void _onHoldStart() {
    setState(() => _holding = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_holding && mounted) {
        HapticFeedback.mediumImpact();
        setState(() => _revealed = true);
        widget.onReady();
      }
    });
  }

  void _onHoldEnd() {
    setState(() => _holding = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.playerColor ?? KawaiiColors.skyBlue;

    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cute doodle dots
                _buildDoodles(),
                const SizedBox(height: 24),
                // Player avatar circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: KawaiiColors.deepInk,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.playerName.isNotEmpty
                          ? widget.playerName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.fredoka(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: KawaiiColors.deepInk,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Pass to',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: KawaiiColors.deepInk.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.playerName,
                  style: GoogleFonts.fredoka(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: KawaiiColors.deepInk,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Hold-to-confirm button
                GestureDetector(
                  onTapDown: (_) => _onHoldStart(),
                  onTapUp: (_) => _onHoldEnd(),
                  onTapCancel: _onHoldEnd,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _holding
                          ? color
                          : color.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: KawaiiColors.deepInk,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _revealed ? 'Go!' : 'Hold to Ready',
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: KawaiiColors.deepInk,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hold the button when ready',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    color: KawaiiColors.deepInk.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoodles() {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('\u2606', style: TextStyle(fontSize: 20, color: KawaiiColors.sunshineYellow.withValues(alpha: 0.4))),
          const SizedBox(width: 16),
          Text('\u2665', style: TextStyle(fontSize: 16, color: KawaiiColors.primaryPink.withValues(alpha: 0.3))),
          const SizedBox(width: 16),
          Text('\u2606', style: TextStyle(fontSize: 24, color: KawaiiColors.skyBlue.withValues(alpha: 0.3))),
          const SizedBox(width: 16),
          Text('\u2665', style: TextStyle(fontSize: 18, color: KawaiiColors.mintGreen.withValues(alpha: 0.3))),
        ],
      ),
    );
  }
}
