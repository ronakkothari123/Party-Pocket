import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/session.dart';
import '../../state/session_controller.dart';
import '../../theme/app_theme.dart';
import '../../ads/interstitial_ad_service.dart';
import '../components/kawaii_button.dart';
import '../components/kawaii_card.dart';
import '../components/kawaii_stepper_header.dart';
import '../powerups/powerup_inventory_screen.dart';

class ReviewStartScreen extends StatelessWidget {
  const ReviewStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SessionControllerProvider.of(context);
    final session = controller.current;

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
                      const KawaiiStepperHeader(currentStep: 3),
                      const SizedBox(height: 16),
                      Text(
                        'Ready?',
                        style: GoogleFonts.fredoka(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: KawaiiColors.deepInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quick check before you start.',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Mode
                      _buildSummaryCard(
                        context,
                        title: 'Mode',
                        icon: session.mode == SessionMode.party
                            ? Icons.celebration_rounded
                            : Icons.play_circle_outline_rounded,
                        content: session.mode == SessionMode.party
                            ? 'Party Mode'
                            : 'Normal Mode',
                        color: session.mode == SessionMode.party
                            ? KawaiiColors.primaryPink
                            : KawaiiColors.skyBlue,
                      ),
                      const SizedBox(height: 12),
                      // Games
                      KawaiiCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '\u{1F3AE} Games (${session.selectedGames.length})',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: KawaiiColors.deepInk,
                                  ),
                                ),
                                const Spacer(),
                                _buildEditButton(context, 'Edit', () {
                                  Navigator.popUntil(
                                      context, ModalRoute.withName('/game-select'));
                                }),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: session.selectedGames.map((g) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: KawaiiColors.lightBlue,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: KawaiiColors.deepInk.withValues(alpha: 0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    '${gameEmoji(g)} ${gameDisplayName(g)}',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: KawaiiColors.deepInk,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Players
                      KawaiiCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '\u{1F465} Players (${session.players.length})',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: KawaiiColors.deepInk,
                                  ),
                                ),
                                const Spacer(),
                                _buildEditButton(context, 'Edit', () {
                                  Navigator.popUntil(
                                      context, ModalRoute.withName('/player-setup'));
                                }),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: session.players.map((p) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: p.avatarColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: KawaiiColors.deepInk.withValues(alpha: 0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        p.name,
                                        style: GoogleFonts.fredoka(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: KawaiiColors.deepInk,
                                        ),
                                      ),
                                      if (p.isKid) ...[
                                        const SizedBox(width: 4),
                                        const Text('\u{1F476}',
                                            style: TextStyle(fontSize: 11)),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Settings
                      KawaiiCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '\u{2699}\u{FE0F} Settings',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: KawaiiColors.deepInk,
                                  ),
                                ),
                                const Spacer(),
                                _buildEditButton(context, 'Edit', () {
                                  Navigator.popUntil(context,
                                      ModalRoute.withName('/global-settings'));
                                }),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _settingLine('Round',
                                '${session.settings.roundLengthSeconds}s'),
                            _settingLine('Sounds',
                                session.settings.enableSounds ? 'On' : 'Off'),
                            _settingLine('Haptics',
                                session.settings.enableHaptics ? 'On' : 'Off'),
                            _settingLine('Shuffle',
                                session.settings.shuffleGames ? 'On' : 'Off'),
                            if (session.mode == SessionMode.party) ...[
                              _settingLine('Party Rounds',
                                  '${session.settings.partyRounds}'),
                              _settingLine(
                                  'Powerups',
                                  session.settings.enablePowerups
                                      ? 'On'
                                      : 'Off'),
                            ],
                          ],
                        ),
                      ),
                      // Chameleon settings
                      if (session.mode == SessionMode.party &&
                          session.selectedGames.contains(GameType.chameleon)) ...[
                        const SizedBox(height: 12),
                        KawaiiCard(
                          fillColor: KawaiiColors.lightYellow,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\u{1F98E} Chameleon',
                                style: GoogleFonts.fredoka(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: KawaiiColors.deepInk,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _settingLine('2 Chameleons',
                                  session.settings.allowTwoChameleons && session.players.length >= 7 ? 'On' : 'Off'),
                              _settingLine('Redemption',
                                  session.settings.enableChameleonRedemption ? 'On' : 'Off'),
                            ],
                          ),
                        ),
                      ],
                      // Powerup inventory button
                      if (session.mode == SessionMode.party && session.settings.enablePowerups) ...[
                        const SizedBox(height: 12),
                        KawaiiButton(
                          label: 'View Powerups Inventory',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PowerupInventoryScreen(
                                  players: session.players,
                                ),
                              ),
                            );
                          },
                          fillColor: KawaiiColors.sunshineYellow,
                          icon: Icons.bolt_rounded,
                          isPrimary: false,
                        ),
                      ],
                      const SizedBox(height: 28),
                      // Start button
                      KawaiiButton(
                        label: 'Start!',
                        onPressed: () async {
                          // Show pre-start interstitial (non-blocking)
                          if (session.mode == SessionMode.party) {
                            await InterstitialAdService()
                                .showIfAvailable(placement: 'party_pre_start');
                          }
                          if (context.mounted) {
                            Navigator.pushNamed(context, '/game-runner');
                          }
                        },
                        fillColor: KawaiiColors.primaryPink,
                        textColor: KawaiiColors.cardWhite,
                        icon: Icons.rocket_launch_rounded,
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

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String content,
    required Color color,
  }) {
    return KawaiiCard(
      fillColor: color.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                ),
              ),
              Text(
                content,
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: KawaiiColors.deepInk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton(
      BuildContext context, String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: KawaiiColors.lightYellow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: KawaiiColors.deepInk.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: KawaiiColors.deepInk,
          ),
        ),
      ),
    );
  }

  Widget _settingLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 13,
              color: KawaiiColors.deepInk.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: KawaiiColors.deepInk,
            ),
          ),
        ],
      ),
    );
  }
}
