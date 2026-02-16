import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../engine/round_result.dart';
import '../../engine/content_repository.dart';
import '../../models/session.dart';
import '../../models/player.dart';
import '../../ui/components/kawaii_card.dart';
import 'chameleon_logic.dart';

class ChameleonScreen extends StatefulWidget {
  final Session session;
  final List<Player> players;
  final void Function(RoundResult result) onComplete;
  final bool hasPeekPowerup; // player used peek powerup
  final String? peekPlayerId; // who used peek

  const ChameleonScreen({
    super.key,
    required this.session,
    required this.players,
    required this.onComplete,
    this.hasPeekPowerup = false,
    this.peekPlayerId,
  });

  @override
  State<ChameleonScreen> createState() => _ChameleonScreenState();
}

enum _ChamPhase {
  rolePass,
  roleReveal,
  peek, // peek powerup flash
  discussion,
  vote,
  reveal,
  redemptionPass,
  redemptionGuess,
  done,
}

class _ChameleonScreenState extends State<ChameleonScreen> {
  _ChamPhase _phase = _ChamPhase.rolePass;
  late ChameleonLogic _logic;

  int _rolePassIndex = 0;
  final Set<String> _votedPlayerIds = {};
  int _requiredVotes = 1;

  // Discussion timer
  Timer? _discussionTimer;
  int _discussionSecondsLeft = 90;

  // Redemption
  int _redemptionIndex = 0;
  List<String> _redemptionQueue = [];

  // Peek
  bool _peekShown = false;

  @override
  void initState() {
    super.initState();
    final card = ContentRepository().getChameleonCard();
    final settings = widget.session.settings;
    final chamCount = (settings.allowTwoChameleons && widget.players.length >= 7) ? 2 : 1;
    _requiredVotes = chamCount;

    _logic = ChameleonLogic(
      players: widget.players,
      category: card['category'] as String,
      secretWord: card['secretWord'] as String,
      allWords: List<String>.from(card['words'] as List),
      chameleonCount: chamCount,
      enableRedemption: settings.enableChameleonRedemption,
    );
  }

  @override
  void dispose() {
    _discussionTimer?.cancel();
    super.dispose();
  }

  void _startDiscussionTimer() {
    _discussionTimer?.cancel();
    _discussionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_discussionSecondsLeft <= 1) {
        t.cancel();
        setState(() => _discussionSecondsLeft = 0);
      } else {
        setState(() => _discussionSecondsLeft--);
      }
    });
  }

  void _addTime() {
    setState(() => _discussionSecondsLeft += 30);
  }

  void _endDiscussion() {
    _discussionTimer?.cancel();
    setState(() => _phase = _ChamPhase.vote);
  }

  void _handleVoteComplete() {
    _logic.vote(_votedPlayerIds.toList());

    if (_logic.correctVoteCount == 0) {
      // No chameleon found
      setState(() => _phase = _ChamPhase.reveal);
    } else if (_logic.enableRedemption && _logic.caughtChameleonIds.isNotEmpty) {
      // Redemption flow
      _redemptionQueue = _logic.caughtChameleonIds.toList();
      _redemptionIndex = 0;
      setState(() => _phase = _ChamPhase.redemptionPass);
    } else {
      // No redemption
      setState(() => _phase = _ChamPhase.done);
      _finishAfterDelay();
    }
  }

  void _handleRedemptionGuess(String chamId, String guess) {
    _logic.chameleonGuess(chamId, guess);
    _redemptionIndex++;

    if (_redemptionIndex < _redemptionQueue.length) {
      setState(() => _phase = _ChamPhase.redemptionPass);
    } else {
      setState(() => _phase = _ChamPhase.done);
      _finishAfterDelay();
    }
  }

  void _finishAfterDelay() {
    final result = _logic.buildResult(
      isPartyMode: widget.session.mode == SessionMode.party,
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) widget.onComplete(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _ChamPhase.rolePass:
        return _buildRolePassScreen();
      case _ChamPhase.roleReveal:
        return _buildRoleRevealScreen();
      case _ChamPhase.peek:
        return _buildPeekScreen();
      case _ChamPhase.discussion:
        return _buildDiscussionScreen();
      case _ChamPhase.vote:
        return _buildVoteScreen();
      case _ChamPhase.reveal:
        return _buildRevealScreen();
      case _ChamPhase.redemptionPass:
        return _buildRedemptionPassScreen();
      case _ChamPhase.redemptionGuess:
        return _buildRedemptionGuessScreen();
      case _ChamPhase.done:
        return _buildDoneScreen();
    }
  }

  Widget _buildRolePassScreen() {
    final player = widget.players[_rolePassIndex];
    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('\u2606', style: TextStyle(fontSize: 20, color: KawaiiColors.sunshineYellow.withValues(alpha: 0.4))),
                    const SizedBox(width: 16),
                    const Text('\u{1F98E}', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 16),
                    Text('\u2606', style: TextStyle(fontSize: 20, color: KawaiiColors.skyBlue.withValues(alpha: 0.4))),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: player.avatarColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: KawaiiColors.deepInk, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      player.name[0].toUpperCase(),
                      style: GoogleFonts.fredoka(fontSize: 32, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pass to',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  player.name,
                  style: GoogleFonts.fredoka(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: KawaiiColors.deepInk,
                  ),
                ),
                const SizedBox(height: 32),
                _HoldButton(
                  label: 'Hold to Reveal',
                  color: KawaiiColors.softPurple,
                  onReady: () {
                    setState(() => _phase = _ChamPhase.roleReveal);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleRevealScreen() {
    final player = widget.players[_rolePassIndex];
    final isCham = _logic.isChameleon(player.id);

    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Category: ${_logic.category}',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: KawaiiColors.deepInk,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: isCham
                        ? KawaiiColors.primaryPink.withValues(alpha: 0.15)
                        : KawaiiColors.mintGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: KawaiiColors.deepInk, width: 3),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isCham ? '\u{1F98E}' : '\u{1F464}',
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(height: 12),
                      if (isCham) ...[
                        Text(
                          'You are the Chameleon!',
                          style: GoogleFonts.fredoka(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: KawaiiColors.primaryPink,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Blend in. Don\'t get caught!',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Secret Word:',
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _logic.secretWord,
                          style: GoogleFonts.fredoka(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: KawaiiColors.deepInk,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () {
                    if (_rolePassIndex < widget.players.length - 1) {
                      setState(() {
                        _rolePassIndex++;
                        _phase = _ChamPhase.rolePass;
                      });
                    } else {
                      // Check if peek powerup applies
                      if (widget.hasPeekPowerup && widget.peekPlayerId != null) {
                        setState(() => _phase = _ChamPhase.peek);
                      } else {
                        _startDiscussionTimer();
                        setState(() => _phase = _ChamPhase.discussion);
                      }
                    }
                  },
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
                        'Got it!',
                        style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600),
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

  Widget _buildPeekScreen() {
    final peekerId = widget.peekPlayerId!;
    final isCham = _logic.isChameleon(peekerId);

    if (!_peekShown) {
      _peekShown = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _startDiscussionTimer();
          setState(() => _phase = _ChamPhase.discussion);
        }
      });
    }

    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('\u{1F440}', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                isCham ? 'Nope!' : 'Peek!',
                style: GoogleFonts.fredoka(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isCham ? KawaiiColors.primaryPink : KawaiiColors.mintGreen,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isCham
                    ? 'You\'re the chameleon\u2026 peek wasted!'
                    : 'The word is: ${_logic.secretWord}',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '(auto-hiding in 2s)',
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscussionScreen() {
    final minutes = _discussionSecondsLeft ~/ 60;
    final seconds = _discussionSecondsLeft % 60;
    final timeStr = minutes > 0
        ? '$minutes:${seconds.toString().padLeft(2, '0')}'
        : '${seconds}s';

    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('\u{1F5E3}', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'Discussion',
                  style: GoogleFonts.fredoka(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: KawaiiColors.deepInk,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Category: ${_logic.category}',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    color: KawaiiColors.deepInk.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                KawaiiCard(
                  padding: const EdgeInsets.all(16),
                  fillColor: KawaiiColors.lightYellow,
                  child: Text(
                    'Start giving clues out loud.\nGo around the circle!',
                    style: GoogleFonts.fredoka(
                      fontSize: 15,
                      color: KawaiiColors.deepInk.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                // Timer display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: _discussionSecondsLeft <= 10
                        ? KawaiiColors.primaryPink.withValues(alpha: 0.15)
                        : KawaiiColors.skyBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: KawaiiColors.deepInk, width: 2.5),
                  ),
                  child: Text(
                    timeStr,
                    style: GoogleFonts.fredoka(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: _discussionSecondsLeft <= 10
                          ? KawaiiColors.primaryPink
                          : KawaiiColors.deepInk,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // +30s button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _addTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: KawaiiColors.lightBlue,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: KawaiiColors.deepInk, width: 2),
                        ),
                        child: Text(
                          '+30s',
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _endDiscussion,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: KawaiiColors.sunshineYellow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: KawaiiColors.deepInk, width: 2),
                        ),
                        child: Text(
                          'End Discussion',
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoteScreen() {
    final canConfirm = _votedPlayerIds.length == _requiredVotes;

    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const Text('\u{1F5F3}', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                _requiredVotes == 1
                    ? 'Who is the Chameleon?'
                    : 'Who are the 2 Chameleons?',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: KawaiiColors.deepInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _requiredVotes > 1
                    ? 'Selected ${_votedPlayerIds.length} / $_requiredVotes'
                    : 'Group consensus vote',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              ...widget.players.map((p) {
                final selected = _votedPlayerIds.contains(p.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _votedPlayerIds.remove(p.id);
                        } else if (_votedPlayerIds.length < _requiredVotes) {
                          _votedPlayerIds.add(p.id);
                        }
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? p.avatarColor.withValues(alpha: 0.3)
                            : KawaiiColors.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: KawaiiColors.deepInk,
                          width: selected ? 3 : 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: p.avatarColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: KawaiiColors.deepInk, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                p.name[0].toUpperCase(),
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              p.name,
                              style: GoogleFonts.fredoka(
                                fontSize: 17,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.check_circle, color: KawaiiColors.mintGreen, size: 24),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: canConfirm ? _handleVoteComplete : null,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: canConfirm
                        ? KawaiiColors.primaryPink
                        : KawaiiColors.deepInk.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: KawaiiColors.deepInk, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      'Lock Vote!',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: canConfirm
                            ? Colors.white
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

  Widget _buildRevealScreen() {
    final chamNames = _logic.chameleonPlayers.map((p) => p.name).join(' & ');
    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('\u{1F98E}', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text(
                  'Wrong!',
                  style: GoogleFonts.fredoka(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: KawaiiColors.primaryPink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$chamNames ${_logic.chameleonCount > 1 ? "were" : "was"} the Chameleon${_logic.chameleonCount > 1 ? "s" : ""}!',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    color: KawaiiColors.deepInk,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'They hid successfully!',
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () {
                    setState(() => _phase = _ChamPhase.done);
                    _finishAfterDelay();
                  },
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
                        'Continue',
                        style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600),
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

  Widget _buildRedemptionPassScreen() {
    final chamId = _redemptionQueue[_redemptionIndex];
    final chamPlayer = widget.players.firstWhere((p) => p.id == chamId);
    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('\u{1F98E}', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 16),
                Text(
                  'Caught!',
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: KawaiiColors.primaryPink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pass to ${chamPlayer.name}',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    color: KawaiiColors.deepInk.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Redemption chance: guess the word!',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    color: KawaiiColors.deepInk.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 32),
                _HoldButton(
                  label: 'Hold to Reveal Options',
                  color: KawaiiColors.softPurple,
                  onReady: () => setState(() => _phase = _ChamPhase.redemptionGuess),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRedemptionGuessScreen() {
    final chamId = _redemptionQueue[_redemptionIndex];
    final chamPlayer = widget.players.firstWhere((p) => p.id == chamId);
    final options = _logic.multipleChoiceOptions;

    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const Text('\u{1F98E}', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                '${chamPlayer.name}, guess the word!',
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: KawaiiColors.primaryPink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Category: ${_logic.category}',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 24),
              ...options.map((opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => _handleRedemptionGuess(chamId, opt),
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

  Widget _buildDoneScreen() {
    final bool humansWin;
    if (_logic.chameleonCount == 1) {
      humansWin = _logic.allChameleonsCaught &&
          (!_logic.enableRedemption || !_logic.chameleonGuessedCorrectly(_logic.chameleonIds.first));
    } else {
      humansWin = _logic.allChameleonsCaught && _logic.successfulRedemptionCount == 0;
    }

    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              humansWin ? '\u{1F389}' : '\u{1F98E}',
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 12),
            Text(
              humansWin ? 'Humans Win!' : 'Chameleon${_logic.chameleonCount > 1 ? "s" : ""} Win!',
              style: GoogleFonts.fredoka(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: humansWin ? KawaiiColors.mintGreen : KawaiiColors.primaryPink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The word was: ${_logic.secretWord}',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                color: KawaiiColors.deepInk.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onReady;

  const _HoldButton({
    required this.label,
    required this.color,
    required this.onReady,
  });

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _holding = false;

  void _onHoldStart() {
    setState(() => _holding = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_holding && mounted) {
        HapticFeedback.mediumImpact();
        widget.onReady();
      }
    });
  }

  void _onHoldEnd() {
    setState(() => _holding = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onHoldStart(),
      onTapUp: (_) => _onHoldEnd(),
      onTapCancel: _onHoldEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: _holding ? widget.color : widget.color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: KawaiiColors.deepInk, width: 3),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: KawaiiColors.deepInk,
            ),
          ),
        ),
      ),
    );
  }
}
