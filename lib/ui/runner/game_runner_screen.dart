import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../engine/game_engine.dart';
import '../../engine/round_result.dart';
import '../../engine/content_repository.dart';
import '../../models/session.dart';
import '../../state/session_controller.dart';
import '../../powerups/powerup_type.dart';
import '../../powerups/powerup_engine.dart';
import '../../services/audio_service.dart';
import '../../stats/stats_controller.dart';
import '../../ui/components/kawaii_button.dart';
import '../../ui/components/kawaii_card.dart';
import '../../games/heads_up/heads_up_screen.dart';
import '../../games/hot_potato/hot_potato_screen.dart';
import '../../games/ten_questions/ten_questions_screen.dart';
import '../../games/wavelength/wavelength_screen.dart';
import '../../games/chameleon/chameleon_screens.dart';
import '../../ui/powerups/powerup_round_select_screen.dart';
import '../../ui/powerups/powerup_start_inventory_flow.dart';
import '../../ads/interstitial_ad_service.dart';
import 'random_game_reveal_screen.dart';
import 'round_summary_screen.dart';

class GameRunnerScreen extends StatefulWidget {
  const GameRunnerScreen({super.key});

  @override
  State<GameRunnerScreen> createState() => _GameRunnerScreenState();
}

class _GameRunnerScreenState extends State<GameRunnerScreen> {
  late GameEngine _engine;
  late SessionController _sc;
  bool _initialized = false;
  bool _contentLoaded = false;

  /// Armed powerups for the current round. Cleared after the round ends.
  Map<String, PowerupType> _armedPowerups = {};
  Map<String, String> _armedTargets = {};

  /// Counter for normal-mode rounds completed (for every-5-rounds ad).
  int _normalRoundsCompleted = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _sc = SessionController.of(context);

      // Guard: if session is invalid, bail to Home
      if (_sc.current.players.isEmpty || _sc.current.selectedGames.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (route) => false);
          }
        });
        return;
      }

      _engine = GameEngine(session: _sc.current);
      _sc.initPartyScoreboard();
      _initialized = true;
      _loadContent();
    }
  }

  Future<void> _loadContent() async {
    await ContentRepository().preload();
    if (mounted) {
      setState(() => _contentLoaded = true);
      if (_engine.isPartyMode && _sc.current.settings.enablePowerups) {
        _showPowerupStartInventory();
      } else {
        _startNextRound();
      }
    }
  }

  void _showPowerupStartInventory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PowerupStartInventoryFlow(
          players: _sc.current.players,
          onComplete: () {
            Navigator.of(context).pop();
            _startNextRound();
          },
        ),
      ),
    );
  }

  void _startNextRound() {
    if (_engine.isPartyMode && _engine.isPartyComplete()) {
      _showPartyEnd();
      return;
    }

    _engine.incrementRound();
    // Clear armed powerups from previous round
    _armedPowerups = {};
    _armedTargets = {};

    final gameType = _engine.nextGame();

    if (_engine.isPartyMode && _sc.current.settings.enablePowerups) {
      _showPowerupBoard(gameType);
    } else {
      _showRevealOrLaunch(gameType);
    }
  }

  void _showPowerupBoard(GameType pendingGame) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PowerupRoundSelectScreen(
          players: _sc.current.players,
          nextGame: pendingGame,
          onComplete: (result) {
            Navigator.of(context).pop();

            // Arm selections and consume inventory immediately
            _armedPowerups = Map.from(result.selections);
            _armedTargets = Map.from(result.targets);

            for (final entry in _armedPowerups.entries) {
              _sc.consumePowerup(entry.key, entry.value);
            }

            // Handle reroll(s): consume and apply
            if (result.hasReroll) {
              // Collect all reroll users (apply up to 2)
              final rerollers = _armedPowerups.entries
                  .where((e) => e.value == PowerupType.reroll)
                  .take(2)
                  .toList();

              GameType game = pendingGame;
                for (var i = 0; i < rerollers.length; i++) {
                // Each reroll picks a new game
                final newGame = _engine.nextGame();
                if (newGame != game ||
                    _sc.current.selectedGames.length <= 1) {
                  game = newGame;
                } else {
                  // Try one more time to get a different game
                  game = _engine.nextGame();
                }
                // reroll is already consumed above
                // Keep in _armedPowerups so it shows in usedPowerups reveal
              }
              _showRevealOrLaunch(game);
            } else {
              _showRevealOrLaunch(pendingGame);
            }
          },
        ),
      ),
    );
  }

  void _showRevealOrLaunch(GameType gameType) {
    if (_engine.isPartyMode || _sc.current.settings.shuffleGames) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RandomGameRevealScreen(
            selectedGame: gameType,
            allGames: _sc.current.selectedGames.toList(),
            onComplete: () {
              Navigator.of(context).pop();
              _launchGame(gameType);
            },
          ),
        ),
      );
    } else {
      _launchGame(gameType);
    }
  }

  void _launchGame(GameType gameType) {
    final session = _sc.current;
    final activePlayer = _engine.nextActivePlayer();

    bool hasPeek = false;
    String? peekPlayerId;
    for (final entry in _armedPowerups.entries) {
      if (entry.value == PowerupType.peek &&
          gameType == GameType.chameleon) {
        hasPeek = true;
        peekPlayerId = entry.key;
        break;
      }
    }

    Widget gameScreen;
    switch (gameType) {
      case GameType.headsUp:
        gameScreen = HeadsUpScreen(
          session: session,
          activePlayer: activePlayer,
          onComplete: (result) => _onRoundComplete(result),
        );
        break;
      case GameType.hotPotato:
        gameScreen = HotPotatoScreen(
          session: session,
          startingPlayer: _engine.randomPlayer(),
          onComplete: (result) => _onRoundComplete(result),
        );
        break;
      case GameType.tenQuestions:
        gameScreen = TenQuestionsScreen(
          session: session,
          activePlayer: activePlayer,
          onComplete: (result) => _onRoundComplete(result),
        );
        break;
      case GameType.wavelength:
        gameScreen = WavelengthScreen(
          session: session,
          activePlayer: activePlayer,
          onComplete: (result) => _onRoundComplete(result),
        );
        break;
      case GameType.chameleon:
        gameScreen = ChameleonScreen(
          session: session,
          players: session.players,
          onComplete: (result) => _onRoundComplete(result),
          hasPeekPowerup: hasPeek,
          peekPlayerId: peekPlayerId,
        );
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => gameScreen),
    );
  }

  void _onRoundComplete(RoundResult result) {
    final idToName = <String, String>{};
    for (final p in _sc.current.players) {
      idToName[p.id] = p.name;
    }

    // Apply powerup effects to scoring
    Map<String, int> finalDelta = result.scoresDelta;
    final usedPowerups = Map<String, PowerupType>.from(_armedPowerups);

    if (_engine.isPartyMode && _armedPowerups.isNotEmpty) {
      finalDelta = PowerupEngine.applyPowerups(
        baseScoresDelta: result.scoresDelta,
        activePowerups: _armedPowerups,
        targetSelections: _armedTargets,
        partyScoreboard: _sc.partyScoreboard,
      );
    }

    if (_engine.isPartyMode) {
      _sc.applyScoresDelta(finalDelta);

      for (final entry in _armedPowerups.entries) {
        if (entry.value == PowerupType.swap) {
          final target = _armedTargets[entry.key];
          if (target != null) {
            _sc.applySwap(entry.key, target);
          }
        }
      }
    }

    // Attach usedPowerups to result for the summary screen
    final enrichedResult = result.withUsedPowerups(usedPowerups);

    // Clear armed powerups now that the round is done
    _armedPowerups = {};
    _armedTargets = {};

    // Record stats
    StatsController().recordRound(enrichedResult, idToName);

    // Pop back from game screen
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Show summary
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoundSummaryScreen(
          result: enrichedResult,
          isPartyMode: _engine.isPartyMode,
          partyScoreboard: _sc.partyScoreboard,
          playerIdToName: idToName,
          roundNumber: _engine.roundNumber,
          totalRounds:
              _engine.isPartyMode ? _engine.totalPartyRounds : null,
          extraDetails:
              result.debug?['correctWords'] as List<String>?,
          onNext: () {
              Navigator.of(context).pop();
              // Normal mode: show ad every 5 rounds
              if (!_engine.isPartyMode) {
                _normalRoundsCompleted++;
                if (_normalRoundsCompleted % 5 == 0) {
                  InterstitialAdService()
                      .showIfAvailable(placement: 'normal_every_5_rounds')
                      .then((_) {
                    if (mounted) _startNextRound();
                  });
                  return;
                }
              }
              _startNextRound();
            },
          onEndSession: () {
            if (!_engine.isPartyMode) {
              StatsController().recordNormalSessionEnd();
            }
            _endSession();
          },
        ),
      ),
    );
  }

  Future<void> _showPartyEnd() async {
    final idToName = <String, String>{};
    final idToColor = <String, Color>{};
    for (final p in _sc.current.players) {
      idToName[p.id] = p.name;
      idToColor[p.id] = p.avatarColor;
    }

    StatsController().recordPartyEnd(_sc.partyScoreboard, idToName);

    // Show interstitial before podium (non-blocking)
    await InterstitialAdService()
        .showIfAvailable(placement: 'party_end');

    if (!mounted) return;

    AudioService().playWinMusic();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _PartyPodiumScreen(
          scoreboard: Map.from(_sc.partyScoreboard),
          playerIdToName: idToName,
          playerIdToColor: idToColor,
        ),
      ),
    );
  }

  void _endSession() {
    AudioService().resumeMainMusic();
    _sc.resetSession();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (!_contentLoaded) {
      return Scaffold(
        backgroundColor: KawaiiColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                  color: KawaiiColors.primaryPink),
              const SizedBox(height: 16),
              Text(
                'Loading games...',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  color: KawaiiColors.deepInk,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: const Center(
        child:
            CircularProgressIndicator(color: KawaiiColors.primaryPink),
      ),
    );
  }
}

/// Animated podium reveal: 3rd -> 2nd -> 1st with spotlight
class _PartyPodiumScreen extends StatefulWidget {
  final Map<String, int> scoreboard;
  final Map<String, String> playerIdToName;
  final Map<String, Color> playerIdToColor;

  const _PartyPodiumScreen({
    required this.scoreboard,
    required this.playerIdToName,
    required this.playerIdToColor,
  });

  @override
  State<_PartyPodiumScreen> createState() => _PartyPodiumScreenState();
}

class _PartyPodiumScreenState extends State<_PartyPodiumScreen>
    with TickerProviderStateMixin {
  late List<MapEntry<String, int>> _sorted;
  int _revealStage = 0;
  late AnimationController _spotlightController;
  late Animation<double> _spotlightAnimation;

  @override
  void initState() {
    super.initState();
    _sorted = widget.scoreboard.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _spotlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _spotlightAnimation = CurvedAnimation(
      parent: _spotlightController,
      curve: Curves.easeOut,
    );

    _runRevealSequence();
  }

  Future<void> _runRevealSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    if (_sorted.length >= 3) {
      setState(() => _revealStage = 1);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
    }
    if (_sorted.length >= 2) {
      setState(() => _revealStage = 2);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
    }
    setState(() => _revealStage = 3);
    _spotlightController.forward();
  }

  @override
  void dispose() {
    _spotlightController.dispose();
    super.dispose();
  }

  Future<void> _handleBackHome() async {
    final sc = SessionController.of(context);
    await AudioService().stopWinMusic();
    await AudioService().resumeMainMusic();
    sc.endSessionAndReset();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  Future<void> _handlePlayAgain() async {
    final sc = SessionController.of(context);
    await AudioService().stopWinMusic();
    await AudioService().resumeMainMusic();
    sc.restartPartySameSetup();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/game-runner',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                'Party Over!',
                style: GoogleFonts.fredoka(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: KawaiiColors.deepInk,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 280,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_sorted.length >= 2)
                      _buildPodiumBlock(
                        rank: 2,
                        playerId: _sorted[1].key,
                        score: _sorted[1].value,
                        height: 140,
                        color: KawaiiColors.skyBlue,
                        visible: _revealStage >= 2,
                      ),
                    if (_sorted.length >= 2) const SizedBox(width: 8),
                    if (_sorted.isNotEmpty)
                      AnimatedBuilder(
                        animation: _spotlightAnimation,
                        builder: (context, child) {
                          return Container(
                            decoration: _revealStage >= 3
                                ? BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: KawaiiColors
                                            .sunshineYellow
                                            .withValues(
                                                alpha: 0.3 *
                                                    _spotlightAnimation
                                                        .value),
                                        blurRadius: 30 *
                                            _spotlightAnimation.value,
                                        spreadRadius: 5 *
                                            _spotlightAnimation.value,
                                      ),
                                    ],
                                  )
                                : null,
                            child: child,
                          );
                        },
                        child: _buildPodiumBlock(
                          rank: 1,
                          playerId: _sorted[0].key,
                          score: _sorted[0].value,
                          height: 180,
                          color: KawaiiColors.sunshineYellow,
                          visible: _revealStage >= 3,
                        ),
                      ),
                    if (_sorted.length >= 3)
                      const SizedBox(width: 8),
                    if (_sorted.length >= 3)
                      _buildPodiumBlock(
                        rank: 3,
                        playerId: _sorted[2].key,
                        score: _sorted[2].value,
                        height: 100,
                        color: KawaiiColors.primaryPink,
                        visible: _revealStage >= 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_revealStage >= 3) ...[
                KawaiiCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Final Scores',
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._sorted.asMap().entries.map((entry) {
                        final rank = entry.key + 1;
                        final id = entry.value.key;
                        final score = entry.value.value;
                        final name =
                            widget.playerIdToName[id] ?? id;
                        final isWinner = rank == 1;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isWinner
                                ? KawaiiColors.sunshineYellow
                                    .withValues(alpha: 0.3)
                                : KawaiiColors.cardWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: KawaiiColors.deepInk,
                              width: isWinner ? 2.5 : 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                rank == 1
                                    ? '\u{1F947}'
                                    : rank == 2
                                        ? '\u{1F948}'
                                        : rank == 3
                                            ? '\u{1F949}'
                                            : '$rank.',
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 16,
                                    fontWeight: isWinner
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '$score pts',
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: KawaiiColors.primaryPink,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                KawaiiButton(
                    label: 'Play Again',
                    onPressed: _handlePlayAgain,
                    fillColor: KawaiiColors.mintGreen,
                    textColor: KawaiiColors.deepInk,
                    icon: Icons.replay_rounded,
                    isPrimary: true,
                  ),
                  const SizedBox(height: 12),
                  KawaiiButton(
                    label: 'Back Home',
                    onPressed: _handleBackHome,
                    fillColor: KawaiiColors.skyBlue,
                    textColor: KawaiiColors.cardWhite,
                    icon: Icons.home_rounded,
                    isPrimary: true,
                  ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumBlock({
    required int rank,
    required String playerId,
    required int score,
    required double height,
    required Color color,
    required bool visible,
  }) {
    final name = widget.playerIdToName[playerId] ?? '?';
    final avatarColor =
        widget.playerIdToColor[playerId] ?? color;
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';

    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.3),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: SizedBox(
          width: 90,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: KawaiiColors.deepInk, width: 2.5),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: KawaiiColors.cardWhite,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: KawaiiColors.deepInk,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '$score pts',
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: KawaiiColors.deepInk
                      .withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 90,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border.all(
                      color: KawaiiColors.deepInk, width: 2.5),
                ),
                child: Center(
                  child: Text(
                    rank == 1
                        ? '\u{1F947}'
                        : rank == 2
                            ? '\u{1F948}'
                            : '\u{1F949}',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
