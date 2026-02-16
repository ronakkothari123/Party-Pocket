import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/session.dart';
import '../../state/session_controller.dart';
import '../../theme/app_theme.dart';
import '../components/kawaii_button.dart';
import '../components/kawaii_stepper_header.dart';
import '../components/kawaii_toggle_chip.dart';
import 'components/game_banner_tile.dart';

class GameSelectScreen extends StatelessWidget {
  const GameSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SessionControllerProvider.of(context);
    final session = controller.current;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
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
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const KawaiiStepperHeader(currentStep: 0),
                      const SizedBox(height: 16),
                      Text(
                        'Pick Your Games',
                        style: GoogleFonts.fredoka(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: KawaiiColors.deepInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose what you want to play tonight.',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Game grid
                      _buildGameGrid(controller, session),
                      const SizedBox(height: 16),
                      // Controls row
                      _buildControlsRow(controller, session),
                      const SizedBox(height: 24),
                      // Next button
                      KawaiiButton(
                        label: 'Next: Players',
                        onPressed: session.selectedGames.isEmpty
                            ? () {}
                            : () => Navigator.pushNamed(context, '/player-setup'),
                        fillColor: session.selectedGames.isEmpty
                            ? KawaiiColors.deepInk.withValues(alpha: 0.15)
                            : KawaiiColors.skyBlue,
                        textColor: session.selectedGames.isEmpty
                            ? KawaiiColors.deepInk.withValues(alpha: 0.35)
                            : KawaiiColors.cardWhite,
                        icon: Icons.arrow_forward_rounded,
                        isPrimary: true,
                        borderColor: session.selectedGames.isEmpty
                            ? KawaiiColors.deepInk.withValues(alpha: 0.15)
                            : KawaiiColors.deepInk,
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

  Widget _buildGameGrid(SessionController controller, Session session) {
    final games = GameType.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        final selected = session.selectedGames.contains(game);

        return GameBannerTile(
          game: game,
          selected: selected,
          onTap: () => controller.toggleGame(game),
        );
      },
    );
  }

  Widget _buildControlsRow(SessionController controller, Session session) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        KawaiiToggleChip(
          label: 'Shuffle',
          selected: session.settings.shuffleGames,
          onTap: () => controller.setShuffleGames(!session.settings.shuffleGames),
          selectedColor: KawaiiColors.softPurple,
          icon: Icons.shuffle_rounded,
        ),
        const SizedBox(width: 10),
        KawaiiToggleChip(
          label: 'Select All',
          selected: session.selectedGames.length == GameType.values.length,
          onTap: () {
            if (session.selectedGames.length == GameType.values.length) {
              controller.clearGames();
            } else {
              controller.selectAllGames();
            }
          },
          selectedColor: KawaiiColors.mintGreen,
        ),
        const SizedBox(width: 10),
        KawaiiToggleChip(
          label: 'Clear',
          selected: false,
          onTap: () => controller.clearGames(),
          selectedColor: KawaiiColors.primaryPink,
        ),
      ],
    );
  }
}
