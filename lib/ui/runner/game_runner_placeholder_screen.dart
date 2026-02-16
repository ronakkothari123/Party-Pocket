import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/session.dart';
import '../../state/session_controller.dart';
import '../../theme/app_theme.dart';
import '../components/kawaii_button.dart';
import '../components/kawaii_card.dart';

class GameRunnerPlaceholderScreen extends StatefulWidget {
  const GameRunnerPlaceholderScreen({super.key});

  @override
  State<GameRunnerPlaceholderScreen> createState() =>
      _GameRunnerPlaceholderScreenState();
}

class _GameRunnerPlaceholderScreenState
    extends State<GameRunnerPlaceholderScreen> {
  int _activePlayerIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = SessionControllerProvider.of(context);
    final session = controller.current;
    final games = session.selectedGames.toList();
    final nextGame = games.isNotEmpty ? games.first : null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  '\u{1F3AE} Game Runner',
                  style: GoogleFonts.fredoka(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: KawaiiColors.deepInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Game logic coming next.',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 28),
                KawaiiCard(
                  fillColor: session.mode == SessionMode.party
                      ? KawaiiColors.lightPink
                      : KawaiiColors.lightBlue,
                  child: Column(
                    children: [
                      _infoRow(
                        'Mode',
                        session.mode == SessionMode.party
                            ? 'Party Mode'
                            : 'Normal Mode',
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        'Players',
                        '${session.players.length}',
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        'Games',
                        '${session.selectedGames.length}',
                      ),
                      if (nextGame != null) ...[
                        const SizedBox(height: 8),
                        _infoRow(
                          'Next Game',
                          '${gameEmoji(nextGame)} ${gameDisplayName(nextGame)}',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (session.players.isNotEmpty)
                  KawaiiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Player',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: KawaiiColors.deepInk,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: session
                                .players[_activePlayerIndex % session.players.length]
                                .avatarColor
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: KawaiiColors.deepInk,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              session
                                  .players[
                                      _activePlayerIndex % session.players.length]
                                  .name,
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: KawaiiColors.deepInk,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                if (session.players.isNotEmpty)
                  KawaiiButton(
                    label: 'Simulate Next Round',
                    onPressed: () {
                      setState(() {
                        _activePlayerIndex++;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Now it\'s ${session.players[_activePlayerIndex % session.players.length].name}\'s turn!',
                            style: GoogleFonts.fredoka(),
                          ),
                          duration: const Duration(seconds: 1),
                          backgroundColor: KawaiiColors.softPurple,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    fillColor: KawaiiColors.sunshineYellow,
                    icon: Icons.skip_next_rounded,
                    isPrimary: true,
                  ),
                const SizedBox(height: 14),
                KawaiiButton(
                  label: 'End Session',
                  onPressed: () {
                    controller.resetSession();
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/', (route) => false);
                  },
                  fillColor: KawaiiColors.primaryPink,
                  textColor: KawaiiColors.cardWhite,
                  icon: Icons.home_rounded,
                  isPrimary: true,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 14,
            color: KawaiiColors.deepInk.withValues(alpha: 0.6),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.fredoka(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: KawaiiColors.deepInk,
          ),
        ),
      ],
    );
  }
}
