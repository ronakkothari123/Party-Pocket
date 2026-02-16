import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../engine/round_result.dart';
import '../../engine/content_repository.dart';
import '../../models/session.dart';
import '../../models/player.dart';
import '../../ui/runner/pass_device_screen.dart';
import '../../ui/runner/countdown_screen.dart';
import 'wavelength_logic.dart';

class WavelengthScreen extends StatefulWidget {
  final Session session;
  final Player activePlayer;
  final void Function(RoundResult result) onComplete;

  const WavelengthScreen({
    super.key,
    required this.session,
    required this.activePlayer,
    required this.onComplete,
  });

  @override
  State<WavelengthScreen> createState() => _WavelengthScreenState();
}

enum _WLPhase { pass, groupReveal, countdown, askPlayers, guess, done }

class _WavelengthScreenState extends State<WavelengthScreen> {
  _WLPhase _phase = _WLPhase.pass;
  late WavelengthLogic _logic;
  int? _selectedGuess;

  // "Need ideas?" random prompts
  List<String>? _ideaPrompts;

  @override
  void initState() {
    super.initState();
    _logic = WavelengthLogic(
      activePlayer: widget.activePlayer,
      allPlayers: widget.session.players,
    );
  }

  void _generateIdeas() {
    final prompts = ContentRepository().getWavelengthPrompts(count: 4);
    setState(() => _ideaPrompts = prompts);
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _WLPhase.pass:
        return PassDeviceScreen(
          playerName: 'the group (not ${widget.activePlayer.name})',
          playerColor: KawaiiColors.softPurple,
          onReady: () => setState(() => _phase = _WLPhase.groupReveal),
        );
      case _WLPhase.groupReveal:
        return _buildGroupRevealScreen();
      case _WLPhase.countdown:
        return CountdownScreen(
          enableHaptics: widget.session.settings.enableHaptics,
          onComplete: () => setState(() => _phase = _WLPhase.askPlayers),
        );
      case _WLPhase.askPlayers:
        return _buildAskPlayersScreen();
      case _WLPhase.guess:
        return _buildGuessScreen();
      case _WLPhase.done:
        return _buildDoneScreen();
    }
  }

  Widget _buildGroupRevealScreen() {
    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('\u{1F30A}', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'The secret number is:',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    color: KawaiiColors.deepInk.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: KawaiiColors.sunshineYellow,
                    shape: BoxShape.circle,
                    border: Border.all(color: KawaiiColors.deepInk, width: 4),
                  ),
                  child: Center(
                    child: Text(
                      '${_logic.secretNumber}',
                      style: GoogleFonts.fredoka(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: KawaiiColors.deepInk,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Don\'t show ${widget.activePlayer.name}!',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: KawaiiColors.primaryPink,
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => setState(() => _phase = _WLPhase.countdown),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: KawaiiColors.skyBlue,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: KawaiiColors.deepInk, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        'Hide Number & Start',
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAskPlayersScreen() {
    final otherPlayer = _logic.currentOtherPlayer;
    final playerNum = _logic.currentOtherPlayerIndex + 1;
    final totalPlayers = _logic.totalOtherPlayers;

    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              Text(
                'CLUE ROUND',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.4),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Player $playerNum / $totalPlayers',
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              // "Ask {PlayerX} a category"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: otherPlayer.avatarColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: KawaiiColors.deepInk, width: 3),
                ),
                child: Column(
                  children: [
                    Text(
                      'Ask ${otherPlayer.name}',
                      style: GoogleFonts.fredoka(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: KawaiiColors.deepInk,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'a category clue',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        color: KawaiiColors.deepInk.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${otherPlayer.name} gives a clue that hints at the number.',
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // "Need ideas?" button
              if (_ideaPrompts == null)
                GestureDetector(
                  onTap: _generateIdeas,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: KawaiiColors.softPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: KawaiiColors.softPurple.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: KawaiiColors.softPurple,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Need ideas?',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: KawaiiColors.softPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Show idea prompts
              if (_ideaPrompts != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KawaiiColors.softPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: KawaiiColors.softPurple.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category ideas:',
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: KawaiiColors.softPurple,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._ideaPrompts!.map((prompt) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '\u2022 $prompt',
                              style: GoogleFonts.fredoka(
                                fontSize: 14,
                                color: KawaiiColors.deepInk.withValues(alpha: 0.7),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _generateIdeas,
                  child: Text(
                    'Shuffle ideas',
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: KawaiiColors.softPurple,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (_logic.isLastOtherPlayer) {
                    // Clear idea prompts for next time
                    _ideaPrompts = null;
                    setState(() => _phase = _WLPhase.guess);
                  } else {
                    _logic.advanceToNextPlayer();
                    _ideaPrompts = null; // reset ideas for next player
                    setState(() {});
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _logic.isLastOtherPlayer
                        ? KawaiiColors.mintGreen
                        : KawaiiColors.skyBlue,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: KawaiiColors.deepInk, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      _logic.isLastOtherPlayer ? 'Time to Guess!' : 'Next Player',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuessScreen() {
    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const Text('\u{1F914}', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                '${widget.activePlayer.name}, guess the number!',
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: KawaiiColors.deepInk,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Pick 1 \u2013 10',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(10, (i) {
                  final num = i + 1;
                  final selected = _selectedGuess == num;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedGuess = num),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: selected
                            ? KawaiiColors.sunshineYellow
                            : KawaiiColors.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: KawaiiColors.deepInk,
                          width: selected ? 3.5 : 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$num',
                          style: GoogleFonts.fredoka(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: KawaiiColors.deepInk,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _selectedGuess == null
                    ? null
                    : () {
                        _logic.submitGuess(_selectedGuess!);
                        setState(() => _phase = _WLPhase.done);
                        final result = _logic.buildResult(
                          isPartyMode: widget.session.mode == SessionMode.party,
                        );
                        Future.delayed(const Duration(milliseconds: 800), () {
                          if (mounted) widget.onComplete(result);
                        });
                      },
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _selectedGuess != null
                        ? KawaiiColors.mintGreen
                        : KawaiiColors.deepInk.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: KawaiiColors.deepInk, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      'Lock In!',
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _selectedGuess != null
                            ? KawaiiColors.deepInk
                            : KawaiiColors.deepInk.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoneScreen() {
    final d = _logic.difference;
    final emoji = d == 0
        ? '\u{1F389}'
        : d <= 1
            ? '\u{1F60D}'
            : d <= 2
                ? '\u{1F44D}'
                : '\u{1F605}';

    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              _logic.accuracyLabel,
              style: GoogleFonts.fredoka(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: KawaiiColors.deepInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Secret: ${_logic.secretNumber}  You: ${_logic.guess}',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                color: KawaiiColors.deepInk.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
