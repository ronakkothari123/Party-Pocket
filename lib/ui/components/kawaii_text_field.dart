import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class KawaiiTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? errorText;
  final VoidCallback? onSubmitted;
  final int maxLength;

  const KawaiiTextField({
    super.key,
    required this.controller,
    this.hintText = 'Name',
    this.errorText,
    this.onSubmitted,
    this.maxLength = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: KawaiiColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: errorText != null
                  ? KawaiiColors.primaryPink
                  : KawaiiColors.deepInk,
              width: 2.5,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLength: maxLength,
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: KawaiiColors.deepInk,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: KawaiiColors.deepInk.withValues(alpha: 0.35),
              ),
              counterText: '',
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (_) => onSubmitted?.call(),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              errorText!,
              style: GoogleFonts.fredoka(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: KawaiiColors.primaryPink,
              ),
            ),
          ),
      ],
    );
  }
}
