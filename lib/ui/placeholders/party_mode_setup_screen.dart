import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class PartyModeSetupScreen extends StatelessWidget {
  const PartyModeSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: KawaiiColors.primaryPink,
        foregroundColor: KawaiiColors.cardWhite,
        title: Text('Party Mode', style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'Party Mode Setup\nComing Soon!',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(fontSize: 20, color: KawaiiColors.deepInk),
        ),
      ),
    );
  }
}
