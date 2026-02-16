import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/player.dart';
import '../../models/session.dart';
import '../../powerups/powerup_type.dart';
import '../../ui/runner/pass_device_screen.dart';

/// Result of the powerup phase for all players.
class PowerupPhaseResult {
  /// playerId -> powerup they chose (null = skip)
  final Map<String, PowerupType?> selections;
  /// playerId -> targetPlayerId for targeted powerups
  final Map<String, String> targets;
  /// true if someone used reroll
  final bool rerollUsed;
  final String? rerollUserId;

  const PowerupPhaseResult({
    required this.selections,
    required this.targets,
    this.rerollUsed = false,
    this.rerollUserId,
  });
}

/// Pass-n-play powerup selection between rounds.
class PowerupPhaseScreen extends StatefulWidget {
  final List<Player> players;
  final GameType? nextGame; // for peek checks
  final void Function(PowerupPhaseResult result) onComplete;

  const PowerupPhaseScreen({
    super.key,
    required this.players,
    this.nextGame,
    required this.onComplete,
  });

  @override
  State<PowerupPhaseScreen> createState() => _PowerupPhaseScreenState();
}

enum _PPPhase { pass, choose, target, done }

class _PowerupPhaseScreenState extends State<PowerupPhaseScreen> {
  int _currentPlayerIndex = 0;
  _PPPhase _phase = _PPPhase.pass;

  final Map<String, PowerupType?> _selections = {};
  final Map<String, String> _targets = {};
  bool _rerollUsed = false;
  String? _rerollUserId;

  Player get _currentPlayer => widget.players[_currentPlayerIndex];

  void _selectPowerup(PowerupType? type) {
    final pid = _currentPlayer.id;
    _selections[pid] = type;

    if (type == PowerupType.reroll) {
      _rerollUsed = true;
      _rerollUserId = pid;
      _advance();
      return;
    }

    if (type != null) {
      final def = powerupDefs[type];
      if (def != null && def.isTargeted) {
        setState(() => _phase = _PPPhase.target);
        return;
      }
    }

    _advance();
  }

  void _selectTarget(String targetId) {
    _targets[_currentPlayer.id] = targetId;
    _advance();
  }

  void _advance() {
    if (_currentPlayerIndex < widget.players.length - 1) {
      setState(() {
        _currentPlayerIndex++;
        _phase = _PPPhase.pass;
      });
    } else {
      widget.onComplete(PowerupPhaseResult(
        selections: _selections,
        targets: _targets,
        rerollUsed: _rerollUsed,
        rerollUserId: _rerollUserId,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _PPPhase.pass:
        return PassDeviceScreen(
          playerName: _currentPlayer.name,
          playerColor: _currentPlayer.avatarColor,
          onReady: () => setState(() => _phase = _PPPhase.choose),
        );
      case _PPPhase.choose:
        return _buildChooseScreen();
      case _PPPhase.target:
        return _buildTargetScreen();
      case _PPPhase.done:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChooseScreen() {
    final player = _currentPlayer;
    final inv = player.inventory;

    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              Text(
                '\u{26A1}',
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 8),
              Text(
                '${player.name}\'s Powerups',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: KawaiiColors.deepInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Use one for the next round, or skip.',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              if (inv.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No powerups left!',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      color: KawaiiColors.deepInk.withValues(alpha: 0.4),
                    ),
                  ),
                )
              else
                ...inv.entries.map((e) {
                  final def = powerupDefs[e.key]!;
                  // Don't show peek unless next game is chameleon
                  if (e.key == PowerupType.peek && widget.nextGame != GameType.chameleon) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _selectPowerup(e.key);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: KawaiiColors.cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: KawaiiColors.deepInk, width: 2.5),
                        ),
                        child: Row(
                          children: [
                            Text(def.emoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    def.name,
                                    style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    def.description,
                                    style: GoogleFonts.fredoka(
                                      fontSize: 12,
                                      color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: KawaiiColors.sunshineYellow.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: KawaiiColors.deepInk, width: 1.5),
                              ),
                              child: Text(
                                'x${e.value}',
                                style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectPowerup(null),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: KawaiiColors.lightBlue,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: KawaiiColors.deepInk, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      'Skip',
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: KawaiiColors.deepInk,
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

  Widget _buildTargetScreen() {
    final others = widget.players.where((p) => p.id != _currentPlayer.id).toList();

    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const Text('\u{1F3AF}', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                'Choose a target',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: KawaiiColors.deepInk,
                ),
              ),
              const SizedBox(height: 24),
              ...others.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => _selectTarget(p.id),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: KawaiiColors.cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: KawaiiColors.deepInk, width: 2.5),
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
                                  style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              p.name,
                              style: GoogleFonts.fredoka(fontSize: 17, fontWeight: FontWeight.w500),
                            ),
                          ],
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
}
