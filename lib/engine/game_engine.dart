import 'dart:math';
import '../models/session.dart';
import '../models/player.dart';

/// Manages game selection and player rotation for a session.
class GameEngine {
  final Session session;
  final Random _rand = Random();

  int _playerRotationIndex = 0;
  int _gameOrderIndex = 0;
  late List<GameType> _gameOrder;
  int _roundNumber = 0;

  GameEngine({required this.session}) {
    _buildGameOrder();
  }

  void _buildGameOrder() {
    _gameOrder = session.selectedGames.toList();
    if (session.settings.shuffleGames) {
      _gameOrder.shuffle(_rand);
    }
  }

  int get roundNumber => _roundNumber;

  GameType nextGame() {
    final game = _gameOrder[_gameOrderIndex % _gameOrder.length];
    _gameOrderIndex++;
    return game;
  }

  Player nextActivePlayer() {
    final player = session.players[_playerRotationIndex % session.players.length];
    _playerRotationIndex++;
    return player;
  }

  Player randomPlayer() {
    return session.players[_rand.nextInt(session.players.length)];
  }

  void incrementRound() {
    _roundNumber++;
  }

  bool get isPartyMode => session.mode == SessionMode.party;

  bool isPartyComplete() {
    return isPartyMode && _roundNumber >= session.settings.partyRounds;
  }

  int get totalPartyRounds => session.settings.partyRounds;
  int get remainingPartyRounds => isPartyMode ? (session.settings.partyRounds - _roundNumber).clamp(0, 999) : -1;
}
