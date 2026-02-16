import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/session.dart';
import '../../state/session_controller.dart';
import '../../theme/app_theme.dart';
import '../components/kawaii_button.dart';
import '../components/kawaii_card.dart';
import '../components/kawaii_stepper_header.dart';

class GlobalSettingsScreen extends StatelessWidget {
  const GlobalSettingsScreen({super.key});

  static const _roundOptions = [45, 60, 90, 120];
  static const _partyRoundOptions = [3, 5, 7, 10, 15];

  @override
  Widget build(BuildContext context) {
    final controller = SessionControllerProvider.of(context);
    final session = controller.current;
    final settings = session.settings;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      const KawaiiStepperHeader(currentStep: 2),
                      const SizedBox(height: 16),
                      Text(
                        'Settings',
                        style: GoogleFonts.fredoka(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: KawaiiColors.deepInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Make it comfy.',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Round length
                      KawaiiCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\u{23F1}\u{FE0F} Round Timer',
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: KawaiiColors.deepInk,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _roundOptions.map((seconds) {
                                final selected = settings.roundLengthSeconds == seconds;
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    controller.setRoundLength(seconds);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? KawaiiColors.skyBlue
                                          : KawaiiColors.cardWhite,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? KawaiiColors.deepInk
                                            : KawaiiColors.deepInk.withValues(alpha: 0.25),
                                        width: selected ? 2.5 : 2,
                                      ),
                                    ),
                                    child: Text(
                                      '${seconds}s',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? KawaiiColors.cardWhite
                                            : KawaiiColors.deepInk,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Vibes
                      KawaiiCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\u{2728} Vibes',
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: KawaiiColors.deepInk,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildToggleRow(
                              'Sounds',
                              Icons.volume_up_rounded,
                              settings.enableSounds,
                              (v) => controller.setEnableSounds(v),
                            ),
                            _buildToggleRow(
                              'Haptics',
                              Icons.vibration_rounded,
                              settings.enableHaptics,
                              (v) => controller.setEnableHaptics(v),
                            ),
                          ],
                        ),
                      ),
                      // Party mode section
                      if (session.mode == SessionMode.party) ...[
                        const SizedBox(height: 14),
                        KawaiiCard(
                          fillColor: KawaiiColors.lightPink,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\u{1F389} Party Rules',
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: KawaiiColors.deepInk,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Party Rounds',
                                style: GoogleFonts.fredoka(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: KawaiiColors.deepInk.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _partyRoundOptions.map((rounds) {
                                  final selected = settings.partyRounds == rounds;
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      controller.setPartyRounds(rounds);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? KawaiiColors.primaryPink
                                            : KawaiiColors.cardWhite,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selected
                                              ? KawaiiColors.deepInk
                                              : KawaiiColors.deepInk.withValues(alpha: 0.25),
                                          width: selected ? 2.5 : 2,
                                        ),
                                      ),
                                      child: Text(
                                        '$rounds',
                                        style: GoogleFonts.fredoka(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? KawaiiColors.cardWhite
                                              : KawaiiColors.deepInk,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              _buildToggleRow(
                                'Enable Powerups',
                                Icons.bolt_rounded,
                                settings.enablePowerups,
                                (v) => controller.setEnablePowerups(v),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Chameleon settings (party mode only, with Chameleon selected)
                      if (session.mode == SessionMode.party &&
                          session.selectedGames.contains(GameType.chameleon)) ...[
                        const SizedBox(height: 14),
                        KawaiiCard(
                          fillColor: KawaiiColors.lightYellow,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\u{1F98E} Chameleon Options',
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: KawaiiColors.deepInk,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (session.players.length >= 7)
                                _buildToggleRow(
                                  'Allow 2 Chameleons (7+ players)',
                                  Icons.people_alt_rounded,
                                  settings.allowTwoChameleons,
                                  (v) => controller.setAllowTwoChameleons(v),
                                ),
                              if (session.players.length < 7)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    '2 Chameleons unlocked at 7+ players',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 13,
                                      color: KawaiiColors.deepInk.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                              _buildToggleRow(
                                'Chameleon Redemption (guess the word)',
                                Icons.refresh_rounded,
                                settings.enableChameleonRedemption,
                                (v) => controller.setEnableChameleonRedemption(v),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      KawaiiButton(
                        label: 'Next: Review',
                        onPressed: () =>
                            Navigator.pushNamed(context, '/review-start'),
                        fillColor: KawaiiColors.skyBlue,
                        textColor: KawaiiColors.cardWhite,
                        icon: Icons.arrow_forward_rounded,
                        isPrimary: true,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: KawaiiColors.deepInk.withValues(alpha: 0.5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: KawaiiColors.deepInk,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(!value);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? KawaiiColors.mintGreen : KawaiiColors.deepInk.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: value ? KawaiiColors.deepInk : KawaiiColors.deepInk.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: KawaiiColors.cardWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: KawaiiColors.deepInk, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
