import '../models/session.dart';
import '../powerups/powerup_type.dart';

class RoundResult {
  final GameType gameType;
  final String headline;
  final String subtext;
  final List<String> winners;
  final List<String> losers;
  final Map<String, int> scoresDelta;
  final Map<String, num> statsDelta;
  final Map<String, dynamic>? debug;

  /// Powerups that were actually used/consumed this round.
  /// Populated after scoring is applied. Empty if none.
  final Map<String, PowerupType> usedPowerups;

  const RoundResult({
    required this.gameType,
    required this.headline,
    this.subtext = '',
    this.winners = const [],
    this.losers = const [],
    this.scoresDelta = const {},
    this.statsDelta = const {},
    this.debug,
    this.usedPowerups = const {},
  });

  /// Create a copy with usedPowerups filled in.
  RoundResult withUsedPowerups(Map<String, PowerupType> used) {
    return RoundResult(
      gameType: gameType,
      headline: headline,
      subtext: subtext,
      winners: winners,
      losers: losers,
      scoresDelta: scoresDelta,
      statsDelta: statsDelta,
      debug: debug,
      usedPowerups: used,
    );
  }
}
