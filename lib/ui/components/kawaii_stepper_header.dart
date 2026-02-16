import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class KawaiiStepperHeader extends StatelessWidget {
  final int currentStep; // 0-indexed
  final List<String> labels;

  const KawaiiStepperHeader({
    super.key,
    required this.currentStep,
    this.labels = const ['Games', 'Players', 'Settings', 'Review'],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(labels.length, (i) {
          final isCompleted = i < currentStep;
          final isCurrent = i == currentStep;

          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2.5,
                      color: isCompleted
                          ? KawaiiColors.primaryPink
                          : KawaiiColors.deepInk.withValues(alpha: 0.15),
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? KawaiiColors.primaryPink
                            : isCompleted
                                ? KawaiiColors.mintGreen
                                : KawaiiColors.cardWhite,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent || isCompleted
                              ? KawaiiColors.deepInk
                              : KawaiiColors.deepInk.withValues(alpha: 0.25),
                          width: isCurrent ? 2.5 : 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check_rounded,
                                size: 16, color: KawaiiColors.cardWhite)
                            : Text(
                                '${i + 1}',
                                style: GoogleFonts.fredoka(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent
                                      ? KawaiiColors.cardWhite
                                      : KawaiiColors.deepInk.withValues(alpha: 0.4),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: GoogleFonts.fredoka(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                        color: isCurrent
                            ? KawaiiColors.deepInk
                            : KawaiiColors.deepInk.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
                if (i < labels.length - 1)
                  Expanded(
                    child: Container(
                      height: 2.5,
                      color: isCompleted
                          ? KawaiiColors.primaryPink
                          : KawaiiColors.deepInk.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
