import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../components/kawaii_card.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: KawaiiColors.mintGreen,
        foregroundColor: KawaiiColors.deepInk,
        title: Text('How to Play',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      backgroundColor: KawaiiColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            _GameRulesCard(
              emoji: '\u{1F98E}',
              name: 'Chameleon',
              color: KawaiiColors.lightYellow,
              goal: 'Find the chameleon hiding among you!',
              setup:
                  'Everyone gets the secret word except the chameleon(s). A grid of words from the category is shown.',
              howToPlay:
                  '1. Each player says ONE word related to the secret word.\n'
                  '2. The chameleon must blend in without knowing the word.\n'
                  '3. After everyone speaks, discuss who the chameleon is.\n'
                  '4. Press "End Discussion" when ready to vote.\n'
                  '5. Everyone votes on who they think the chameleon is.',
              scoring:
                  'Chameleon caught: +2 pts each non-chameleon. '
                  'Chameleon escapes: +3 pts chameleon. '
                  'Redemption guess: chameleon picks from 4 choices.',
              tips: [
                'Be vague enough to not give it away, specific enough to prove you know.',
                'Watch who hesitates or copies others!',
                'With 7+ players, there can be 2 chameleons.',
              ],
            ),
            const SizedBox(height: 12),
            _GameRulesCard(
              emoji: '\u{1F30A}',
              name: 'Wavelength',
              color: KawaiiColors.lightBlue,
              goal: 'Guess the secret number your teammates are hinting at!',
              setup:
                  'The active player gets a secret number (1-10). Other players will be asked one at a time.',
              howToPlay:
                  '1. The active player asks each other player a category question.\n'
                  '2. Each player answers on a scale of 1-10.\n'
                  '3. Tap "Need Ideas?" for random category suggestions.\n'
                  '4. After asking everyone, the active player guesses the secret number.',
              scoring:
                  'Exact match: +5 pts. Off by 1: +3 pts. Off by 2: +1 pt.',
              tips: [
                'Pick categories that naturally have a wide range.',
                'Pay attention to patterns in the answers!',
                'Use "Need Ideas?" if you are stuck on what to ask.',
              ],
            ),
            const SizedBox(height: 12),
            _GameRulesCard(
              emoji: '\u{1F64B}',
              name: 'Heads Up',
              color: KawaiiColors.lightPink,
              goal: 'Guess as many words as possible from your friends\' clues!',
              setup:
                  'The active player holds the phone on their forehead. Others give clues.',
              howToPlay:
                  '1. Hold the phone on your forehead so others see the word.\n'
                  '2. Your friends describe the word WITHOUT saying it.\n'
                  '3. Tilt DOWN to mark correct, tilt UP to pass/skip.\n'
                  '4. Manual buttons available as backup.\n'
                  '5. Race against the timer!',
              scoring: '+1 pt per correct answer in Party Mode.',
              tips: [
                'Tilt must be held for a moment to register.',
                'Use sounds and gestures - no saying the word!',
                'Skip quickly if stuck to maximize score.',
              ],
            ),
            const SizedBox(height: 12),
            _GameRulesCard(
              emoji: '\u{2753}',
              name: '10 Questions',
              color: Color(0xFFE8F5E9),
              goal: 'Figure out the secret object in 10 yes/no questions!',
              setup:
                  'The group sees the secret target (but NOT the active player). The active player asks questions.',
              howToPlay:
                  '1. The group sees the word first - don\'t show the active player!\n'
                  '2. Pass the phone to the active player.\n'
                  '3. Ask up to 10 yes/no questions.\n'
                  '4. The group answers honestly.\n'
                  '5. After 10 questions (or earlier), guess the object!',
              scoring:
                  'Correct guess: +3 pts guesser. Wrong: +1 pt each other player.',
              tips: [
                'Start broad: "Is it alive?" "Is it bigger than a car?"',
                'Narrow down categories before guessing specifics.',
                'You can guess early if you are confident!',
              ],
            ),
            const SizedBox(height: 12),
            _GameRulesCard(
              emoji: '\u{1F954}',
              name: 'Hot Potato',
              color: Color(0xFFFFF3E0),
              goal: 'Don\'t be holding the potato when time runs out!',
              setup:
                  'Everyone sits in a circle. A random category is shown.',
              howToPlay:
                  '1. Sit in a circle (the app shows seating order).\n'
                  '2. A category appears (e.g., "Types of fruit").\n'
                  '3. Say something in that category and pass the phone clockwise.\n'
                  '4. If you repeat or can\'t answer, you\'re out!\n'
                  '5. The person holding the phone when the timer buzzes loses.',
              scoring: 'Loser: -1 pt. Everyone else: +1 pt.',
              tips: [
                'The timer is random - don\'t get comfy!',
                'No repeats allowed - listen carefully.',
                'Pass quickly to keep the pressure on!',
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _GameRulesCard extends StatefulWidget {
  final String emoji;
  final String name;
  final Color color;
  final String goal;
  final String setup;
  final String howToPlay;
  final String scoring;
  final List<String> tips;

  const _GameRulesCard({
    required this.emoji,
    required this.name,
    required this.color,
    required this.goal,
    required this.setup,
    required this.howToPlay,
    required this.scoring,
    required this.tips,
  });

  @override
  State<_GameRulesCard> createState() => _GameRulesCardState();
}

class _GameRulesCardState extends State<_GameRulesCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: KawaiiCard(
        fillColor: widget.color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name,
                          style: GoogleFonts.fredoka(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(widget.goal,
                          style: GoogleFonts.fredoka(
                              fontSize: 12,
                              color: KawaiiColors.deepInk
                                  .withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more_rounded, size: 24),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildExpanded(),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('Setup', widget.setup),
          const SizedBox(height: 10),
          _section('How to Play', widget.howToPlay),
          const SizedBox(height: 10),
          _section('Scoring (Party Mode)', widget.scoring),
          const SizedBox(height: 10),
          Text('Quick Tips',
              style: GoogleFonts.fredoka(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ...widget.tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('\u{2022} ',
                        style: GoogleFonts.fredoka(fontSize: 13)),
                    Expanded(
                      child: Text(t,
                          style: GoogleFonts.fredoka(
                              fontSize: 13,
                              color: KawaiiColors.deepInk
                                  .withValues(alpha: 0.7))),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(body,
            style: GoogleFonts.fredoka(
                fontSize: 13,
                color: KawaiiColors.deepInk.withValues(alpha: 0.7))),
      ],
    );
  }
}
