import 'dart:math';
import '../../engine/round_result.dart';
import '../../models/session.dart';
import '../../models/player.dart';

class ChameleonLogic {
  final List<Player> players;
  final String category;
  final String secretWord;
  final List<String> allWords;
  final int chameleonCount;
  final bool enableRedemption;

  late List<String> _chameleonIds;
  List<String> _votedPlayerIds = [];
  final Map<String, String?> _chameleonGuesses = {}; // chamId -> guess

  ChameleonLogic({
    required this.players,
    required this.category,
    required this.secretWord,
    required this.allWords,
    this.chameleonCount = 1,
    this.enableRedemption = true,
  }) {
    final rand = Random();
    final indices = <int>{};
    while (indices.length < chameleonCount && indices.length < players.length) {
      indices.add(rand.nextInt(players.length));
    }
    _chameleonIds = indices.map((i) => players[i].id).toList();
  }

  List<String> get chameleonIds => _chameleonIds;

  Player get chameleonPlayer => players.firstWhere((p) => p.id == _chameleonIds.first);

  List<Player> get chameleonPlayers =>
      players.where((p) => _chameleonIds.contains(p.id)).toList();

  bool isChameleon(String playerId) => _chameleonIds.contains(playerId);

  void vote(List<String> suspectedPlayerIds) {
    _votedPlayerIds = suspectedPlayerIds;
  }

  // For single vote compat
  void voteSingle(String suspectedPlayerId) {
    _votedPlayerIds = [suspectedPlayerId];
  }

  List<String> get votedPlayerIds => _votedPlayerIds;

  /// How many of the voted players are actual chameleons
  int get correctVoteCount {
    return _votedPlayerIds.where((id) => _chameleonIds.contains(id)).length;
  }

  /// Which chameleons were caught (voted for)
  List<String> get caughtChameleonIds =>
      _votedPlayerIds.where((id) => _chameleonIds.contains(id)).toList();

  /// Which chameleons escaped (not voted for)
  List<String> get escapedChameleonIds =>
      _chameleonIds.where((id) => !_votedPlayerIds.contains(id)).toList();

  bool get votedForChameleon => correctVoteCount > 0;

  bool get allChameleonsCaught => correctVoteCount == chameleonCount;

  void chameleonGuess(String chameleonId, String word) {
    _chameleonGuesses[chameleonId] = word;
  }

  bool chameleonGuessedCorrectly(String chameleonId) =>
      _chameleonGuesses[chameleonId]?.toLowerCase() == secretWord.toLowerCase();

  int get successfulRedemptionCount =>
      caughtChameleonIds.where((id) => chameleonGuessedCorrectly(id)).length;

  /// Generate 4 multiple-choice options including the secret word
  List<String> get multipleChoiceOptions {
    final options = <String>{secretWord};
    final others = allWords.where((w) => w != secretWord).toList()..shuffle();
    for (final w in others) {
      if (options.length >= 4) break;
      options.add(w);
    }
    final list = options.toList()..shuffle();
    return list;
  }

  RoundResult buildResult({bool isPartyMode = false}) {
    if (chameleonCount == 1) {
      return _buildSingleChameleonResult(isPartyMode: isPartyMode);
    } else {
      return _buildTwoChameleonResult(isPartyMode: isPartyMode);
    }
  }

  RoundResult _buildSingleChameleonResult({bool isPartyMode = false}) {
    final scores = <String, int>{};
    String headline = 'Chameleon was ${chameleonPlayer.name}!';
    String subtext;
    List<String> winners = [];
    final chamId = _chameleonIds.first;

    if (correctVoteCount == 0) {
      // Chameleon hid
      subtext = 'Chameleon wins! They hid successfully.';
      winners = [chamId];
      if (isPartyMode) {
        for (final p in players) {
          scores[p.id] = p.id == chamId ? 4 : 0;
        }
      }
    } else if (enableRedemption && chameleonGuessedCorrectly(chamId)) {
      // Caught but guessed word
      subtext = 'Chameleon was caught but guessed "$secretWord"!';
      winners = [chamId];
      if (isPartyMode) {
        for (final p in players) {
          scores[p.id] = p.id == chamId ? 6 : 0;
        }
      }
    } else {
      // Humans win
      subtext = 'Humans win! The word was "$secretWord".';
      winners = players.where((p) => p.id != chamId).map((p) => p.id).toList();
      if (isPartyMode) {
        for (final p in players) {
          scores[p.id] = p.id == chamId ? 0 : 2;
        }
      }
    }

    return RoundResult(
      gameType: GameType.chameleon,
      headline: headline,
      subtext: subtext,
      winners: winners,
      scoresDelta: scores,
    );
  }

  RoundResult _buildTwoChameleonResult({bool isPartyMode = false}) {
    final scores = <String, int>{};
    String headline;
    String subtext;
    List<String> winners = [];
    final humanIds = players.where((p) => !isChameleon(p.id)).map((p) => p.id).toList();
    final chamNames = chameleonPlayers.map((p) => p.name).join(' & ');
    headline = 'Chameleons: $chamNames';

    if (correctVoteCount == 2) {
      // Case A: Both caught
      if (enableRedemption) {
        final redeemed = successfulRedemptionCount;
        if (redeemed >= 1) {
          // At least one redeemed
          subtext = '$redeemed chameleon(s) guessed the word!';
          for (final p in players) {
            if (isChameleon(p.id)) {
              if (chameleonGuessedCorrectly(p.id)) {
                scores[p.id] = 4;
                winners.add(p.id);
              } else {
                scores[p.id] = 0;
              }
            } else {
              scores[p.id] = 1; // partial credit
            }
          }
        } else {
          // Both failed redemption
          subtext = 'Humans win! Both chameleons caught and failed.';
          winners = humanIds;
          for (final p in players) {
            scores[p.id] = isChameleon(p.id) ? 0 : 2;
          }
        }
      } else {
        // No redemption
        subtext = 'Humans win! Both chameleons caught!';
        winners = humanIds;
        for (final p in players) {
          scores[p.id] = isChameleon(p.id) ? 0 : 2;
        }
      }
    } else if (correctVoteCount == 1) {
      // Case B: One found, one hidden
      subtext = 'One chameleon escaped!';
      final caughtId = caughtChameleonIds.first;
      final hiddenId = escapedChameleonIds.first;

      for (final p in players) {
        if (p.id == hiddenId) {
          scores[p.id] = 4;
          winners.add(p.id);
        } else if (p.id == caughtId) {
          if (enableRedemption && chameleonGuessedCorrectly(caughtId)) {
            scores[p.id] = 3;
            winners.add(p.id);
          } else {
            scores[p.id] = 0;
          }
        } else {
          scores[p.id] = 0;
        }
      }
    } else {
      // Case C: None found
      subtext = 'Chameleons win! Neither was found!';
      for (final p in players) {
        if (isChameleon(p.id)) {
          scores[p.id] = 4;
          winners.add(p.id);
        } else {
          scores[p.id] = 0;
        }
      }
    }

    return RoundResult(
      gameType: GameType.chameleon,
      headline: headline,
      subtext: subtext,
      winners: winners,
      scoresDelta: isPartyMode ? scores : {},
    );
  }
}
