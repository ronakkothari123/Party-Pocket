import 'dart:math';
import '../../engine/round_result.dart';
import '../../models/session.dart';
import '../../models/player.dart';

class HotPotatoLogic {
  final List<Player> players;
  final Player startingPlayer;
  final String category;

  late int _currentHolderIndex;
  late int _totalDurationMs;
  String? _loserId;

  HotPotatoLogic({
    required this.players,
    required this.startingPlayer,
    required this.category,
  }) {
    _currentHolderIndex = players.indexWhere((p) => p.id == startingPlayer.id);
    if (_currentHolderIndex < 0) _currentHolderIndex = 0;
    // Random duration 10-25 seconds
    _totalDurationMs = (10 + Random().nextInt(16)) * 1000;
  }

  int get totalDurationMs => _totalDurationMs;

  Player get currentHolder => players[_currentHolderIndex];

  void passToNext() {
    _currentHolderIndex = (_currentHolderIndex + 1) % players.length;
  }

  void setLoser(String playerId) {
    _loserId = playerId;
  }

  void setLoserAsCurrent() {
    _loserId = currentHolder.id;
  }

  RoundResult buildResult({bool isPartyMode = false}) {
    final loser = players.firstWhere(
      (p) => p.id == _loserId,
      orElse: () => currentHolder,
    );

    final scores = <String, int>{};
    if (isPartyMode) {
      for (final p in players) {
        scores[p.id] = p.id == loser.id ? -2 : 0;
      }
    }

    return RoundResult(
      gameType: GameType.hotPotato,
      headline: 'Hot Potato! ${loser.name} got caught!',
      subtext: 'Category: $category',
      losers: [loser.id],
      scoresDelta: scores,
    );
  }
}
