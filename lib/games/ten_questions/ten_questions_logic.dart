import '../../engine/round_result.dart';
import '../../models/session.dart';
import '../../models/player.dart';

class TenQuestionsLogic {
  final Player activePlayer;
  final String targetWord;
  final String hint;
  final List<String> distractors; // for kid multiple choice

  int _questionCount = 0;
  final List<String> _responses = [];
  bool? _guessedCorrectly;

  TenQuestionsLogic({
    required this.activePlayer,
    required this.targetWord,
    required this.hint,
    required this.distractors,
  });

  int get questionCount => _questionCount;
  bool get questionsRemaining => _questionCount < 10;
  List<String> get responses => List.unmodifiable(_responses);

  void answerQuestion(String response) {
    if (_questionCount < 10) {
      _responses.add(response);
      _questionCount++;
    }
  }

  void submitGuess(String guess) {
    _guessedCorrectly = guess.trim().toLowerCase() == targetWord.toLowerCase();
  }

  void submitMultipleChoice(String choice) {
    _guessedCorrectly = choice == targetWord;
  }

  bool? get guessedCorrectly => _guessedCorrectly;

  RoundResult buildResult({bool isPartyMode = false}) {
    final correct = _guessedCorrectly == true;
    final scores = <String, int>{};
    if (isPartyMode) {
      scores[activePlayer.id] = correct ? 3 : 0;
    }

    return RoundResult(
      gameType: GameType.tenQuestions,
      headline: correct
          ? '${activePlayer.name} guessed it!'
          : 'So close\u2026',
      subtext: 'The answer was: $targetWord',
      winners: correct ? [activePlayer.id] : [],
      scoresDelta: scores,
    );
  }
}
