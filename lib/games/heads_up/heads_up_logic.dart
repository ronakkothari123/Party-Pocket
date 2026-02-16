import '../../engine/round_result.dart';
import '../../models/session.dart';
import '../../models/player.dart';

class HeadsUpLogic {
  final Player activePlayer;
  final List<String> words;
  final int roundLengthSeconds;

  int _currentWordIndex = 0;
  final List<String> _correctWords = [];
  final List<String> _passedWords = [];

  HeadsUpLogic({
    required this.activePlayer,
    required this.words,
    required this.roundLengthSeconds,
  });

  String get currentWord =>
      _currentWordIndex < words.length ? words[_currentWordIndex] : '';

  bool get hasMoreWords => _currentWordIndex < words.length;

  int get correctCount => _correctWords.length;
  int get passedCount => _passedWords.length;
  List<String> get correctWords => List.unmodifiable(_correctWords);

  void markCorrect() {
    if (hasMoreWords) {
      _correctWords.add(words[_currentWordIndex]);
      _currentWordIndex++;
    }
  }

  void markPassed() {
    if (hasMoreWords) {
      _passedWords.add(words[_currentWordIndex]);
      _currentWordIndex++;
    }
  }

  RoundResult buildResult({bool isPartyMode = false}) {
    final scores = <String, int>{};
    if (isPartyMode) {
      scores[activePlayer.id] = correctCount;
    }

    return RoundResult(
      gameType: GameType.headsUp,
      headline: '${activePlayer.name} got $correctCount!',
      subtext: '$passedCount passed',
      winners: correctCount > 0 ? [activePlayer.id] : [],
      scoresDelta: scores,
      debug: {
        'correctWords': _correctWords,
        'passedWords': _passedWords,
      },
    );
  }
}
