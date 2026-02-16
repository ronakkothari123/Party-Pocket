import '../models/session.dart';
import 'round_result.dart';

class GameRound {
  final String id;
  final GameType gameType;
  final SessionMode mode;
  final List<String> playerIds;
  final DateTime startedAt;
  DateTime? endedAt;
  RoundResult? result;

  GameRound({
    required this.id,
    required this.gameType,
    required this.mode,
    required this.playerIds,
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  void complete(RoundResult r) {
    result = r;
    endedAt = DateTime.now();
  }
}
