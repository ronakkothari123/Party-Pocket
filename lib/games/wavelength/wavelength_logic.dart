import 'dart:math';
import '../../engine/round_result.dart';
import '../../models/session.dart';
import '../../models/player.dart';

class WavelengthLogic {
  final Player activePlayer;
  final List<Player> otherPlayers;
  final int secretNumber;

  int? _guess;
  int _currentOtherIndex = 0;

  WavelengthLogic({
    required this.activePlayer,
    required List<Player> allPlayers,
    int? secretNumber,
  })  : otherPlayers = allPlayers.where((p) => p.id != activePlayer.id).toList(),
        secretNumber = secretNumber ?? (Random().nextInt(10) + 1);

  Player get currentOtherPlayer => otherPlayers[_currentOtherIndex];

  int get currentOtherPlayerIndex => _currentOtherIndex;

  int get totalOtherPlayers => otherPlayers.length;

  bool get isLastOtherPlayer => _currentOtherIndex >= otherPlayers.length - 1;

  void advanceToNextPlayer() {
    if (!isLastOtherPlayer) {
      _currentOtherIndex++;
    }
  }

  int? get guess => _guess;

  void submitGuess(int g) {
    _guess = g;
  }

  int get difference => _guess == null ? 99 : (_guess! - secretNumber).abs();

  String get accuracyLabel {
    final d = difference;
    if (d == 0) return 'Perfect!';
    if (d <= 1) return 'So close!';
    if (d <= 2) return 'Decent!';
    return 'Way off!';
  }

  RoundResult buildResult({bool isPartyMode = false}) {
    final d = difference;
    final scores = <String, int>{};
    if (isPartyMode) {
      if (d == 0) {
        scores[activePlayer.id] = 3;
      } else if (d == 1) {
        scores[activePlayer.id] = 2;
      } else if (d == 2) {
        scores[activePlayer.id] = 1;
      } else {
        scores[activePlayer.id] = 0;
      }
    }

    return RoundResult(
      gameType: GameType.wavelength,
      headline: 'Secret was $secretNumber. You guessed ${_guess ?? '?'}!',
      subtext: 'Off by $d \u2014 $accuracyLabel',
      winners: d <= 1 ? [activePlayer.id] : [],
      scoresDelta: scores,
    );
  }
}
