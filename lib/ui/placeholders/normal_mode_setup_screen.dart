import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class NormalModeSetupScreen extends StatelessWidget {
  const NormalModeSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: KawaiiColors.skyBlue,
        foregroundColor: KawaiiColors.cardWhite,
        title: Text('Normal Mode', style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'Normal Mode Setup\nComing Soon!',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(fontSize: 20, color: KawaiiColors.deepInk),
        ),
      ),
    );
  }
}
