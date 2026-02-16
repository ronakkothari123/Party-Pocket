import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class KawaiiToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;
  final IconData? icon;

  const KawaiiToggleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? KawaiiColors.primaryPink;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : KawaiiColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? KawaiiColors.deepInk : KawaiiColors.deepInk.withValues(alpha: 0.3),
            width: selected ? 2.5 : 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? KawaiiColors.cardWhite : KawaiiColors.deepInk,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? KawaiiColors.cardWhite : KawaiiColors.deepInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
