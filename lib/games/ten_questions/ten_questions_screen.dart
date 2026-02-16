import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../engine/round_result.dart';
import '../../engine/content_repository.dart';
import '../../models/session.dart';
import '../../models/player.dart';
import '../../ui/runner/pass_device_screen.dart';
import '../../ui/runner/countdown_screen.dart';
import '../../ui/components/kawaii_card.dart';
import 'ten_questions_logic.dart';

class TenQuestionsScreen extends StatefulWidget {
  final Session session;
  final Player activePlayer;
  final void Function(RoundResult result) onComplete;

  const TenQuestionsScreen({
    super.key,
    required this.session,
    required this.activePlayer,
    required this.onComplete,
  });

  @override
  State<TenQuestionsScreen> createState() => _TenQuestionsScreenState();
}

enum _TQPhase { groupPass, groupReveal, playerPass, countdown, questions, guess, done }

class _TenQuestionsScreenState extends State<TenQuestionsScreen> {
  _TQPhase _phase = _TQPhase.groupPass;
  late TenQuestionsLogic _logic;
  final _guessController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final repo = ContentRepository();
    final hasKid = widget.session.players.any((p) => p.isKid);
    final target = repo.getTenQuestionsTarget(kidSafe: hasKid);
    final distractors = repo.getTenQuestionsDistractors(
      target['word'] as String,
      count: 3,
    );

    _logic = TenQuestionsLogic(
      activePlayer: widget.activePlayer,
      targetWord: target['word'] as String,
      hint: target['hint'] as String? ?? '',
      distractors: distractors,
    );
  }

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  void _answerQuestion(String response) {
    _logic.answerQuestion(response);
    if (!_logic.questionsRemaining) {
      setState(() => _phase = _TQPhase.guess);
    } else {
      setState(() {});
    }
  }

  void _submitGuess() {
    if (widget.activePlayer.isKid) return;
    _logic.submitGuess(_guessController.text);
    _finishRound();
  }

  void _submitMultipleChoice(String choice) {
    _logic.submitMultipleChoice(choice);
    _finishRound();
  }

  void _finishRound() {
    setState(() => _phase = _TQPhase.done);
    final result = _logic.buildResult(
      isPartyMode: widget.session.mode == SessionMode.party,
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) widget.onComplete(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _TQPhase.groupPass:
        return PassDeviceScreen(
          playerName: 'the Group (not ${widget.activePlayer.name})',
          playerColor: KawaiiColors.softPurple,
          onReady: () => setState(() => _phase = _TQPhase.groupReveal),
        );
      case _TQPhase.groupReveal:
        return _buildGroupRevealScreen();
      case _TQPhase.playerPass:
        return PassDeviceScreen(
          playerName: widget.activePlayer.name,
          playerColor: widget.activePlayer.avatarColor,
          onReady: () => setState(() => _phase = _TQPhase.countdown),
        );
      case _TQPhase.countdown:
        return CountdownScreen(
          enableHaptics: widget.session.settings.enableHaptics,
          onComplete: () => setState(() => _phase = _TQPhase.questions),
        );
      case _TQPhase.questions:
        return _buildQuestionsScreen();
      case _TQPhase.guess:
        return _buildGuessScreen();
      case _TQPhase.done:
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
                const Text('\u{2753}', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'Secret Target:',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    color: KawaiiColors.deepInk.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: BoxDecoration(
                    color: KawaiiColors.sunshineYellow.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: KawaiiColors.deepInk, width: 3),
                  ),
                  child: Text(
                    _logic.targetWord,
                    style: GoogleFonts.fredoka(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: KawaiiColors.deepInk,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: KawaiiColors.primaryPink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KawaiiColors.primaryPink, width: 2),
                  ),
                  child: Text(
                    'Do NOT show ${widget.activePlayer.name}!',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: KawaiiColors.primaryPink,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => setState(() => _phase = _TQPhase.playerPass),
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
                        'Hide Word',
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

  Widget _buildQuestionsScreen() {
    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Text('\u{2753}', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                'Question ${_logic.questionCount + 1} / 10',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: KawaiiColors.deepInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.activePlayer.name}, ask a yes/no question!',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
              if (_logic.hint.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: KawaiiColors.lightYellow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: KawaiiColors.deepInk, width: 1.5),
                  ),
                  child: Text(
                    'Hint: ${_logic.hint}',
                    style: GoogleFonts.fredoka(fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_logic.responses.isNotEmpty) ...[
                KawaiiCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _logic.responses.asMap().entries.map((entry) {
                      final i = entry.key + 1;
                      final r = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Q$i: $r',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            color: r == 'YES'
                                ? KawaiiColors.mintGreen
                                : KawaiiColors.primaryPink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _answerQuestion('YES'),
                      child: Container(
                        height: 72,
                        decoration: BoxDecoration(
                          color: KawaiiColors.mintGreen,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: KawaiiColors.deepInk, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            'YES',
                            style: GoogleFonts.fredoka(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _answerQuestion('NO'),
                      child: Container(
                        height: 72,
                        decoration: BoxDecoration(
                          color: KawaiiColors.primaryPink,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: KawaiiColors.deepInk, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            'NO',
                            style: GoogleFonts.fredoka(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _phase = _TQPhase.guess),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: KawaiiColors.sunshineYellow.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: KawaiiColors.deepInk, width: 2),
                  ),
                  child: Text(
                    'Ready to Guess!',
                    style: GoogleFonts.fredoka(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
    final isKid = widget.activePlayer.isKid;

    if (isKid) {
      final options = [_logic.targetWord, ..._logic.distractors]..shuffle(Random());
      return Scaffold(
        backgroundColor: KawaiiColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                const Text('\u{1F914}', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(
                  'What is it?',
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: KawaiiColors.deepInk,
                  ),
                ),
                const SizedBox(height: 24),
                ...options.map((opt) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _submitMultipleChoice(opt),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: KawaiiColors.cardWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: KawaiiColors.deepInk, width: 2.5),
                          ),
                          child: Center(
                            child: Text(
                              opt,
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const Text('\u{1F914}', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                'What is it?',
                style: GoogleFonts.fredoka(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: KawaiiColors.deepInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Type your guess',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: KawaiiColors.deepInk, width: 2.5),
                  color: KawaiiColors.cardWhite,
                ),
                child: TextField(
                  controller: _guessController,
                  style: GoogleFonts.fredoka(fontSize: 18),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Your guess...',
                    hintStyle: GoogleFonts.fredoka(
                      fontSize: 18,
                      color: KawaiiColors.deepInk.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _submitGuess,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: KawaiiColors.mintGreen,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: KawaiiColors.deepInk, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      'Reveal!',
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
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
    final correct = _logic.guessedCorrectly == true;
    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              correct ? '\u{1F389}' : '\u{1F614}',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              correct ? 'Correct!' : 'Not quite!',
              style: GoogleFonts.fredoka(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: correct ? KawaiiColors.mintGreen : KawaiiColors.primaryPink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'It was: ${_logic.targetWord}',
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
