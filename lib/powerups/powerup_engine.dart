import 'dart:math';
import 'powerup_type.dart';

/// Handles powerup scoring pipeline and inventory initialization.
class PowerupEngine {
  static final _rand = Random();

  /// Initialize inventory for a player: 2 common + 1 special
  static Map<PowerupType, int> generateStartingInventory() {
    final commons = powerupDefs.values
        .where((d) => d.rarity == PowerupRarity.common)
        .toList();
    final specials = powerupDefs.values
        .where((d) => d.rarity == PowerupRarity.special)
        .toList();

    final inv = <PowerupType, int>{};

    // 2 random common (can be same type)
    for (int i = 0; i < 2; i++) {
      final pick = commons[_rand.nextInt(commons.length)].type;
      inv[pick] = (inv[pick] ?? 0) + 1;
    }
    // 1 random special
    final specialPick = specials[_rand.nextInt(specials.length)].type;
    inv[specialPick] = (inv[specialPick] ?? 0) + 1;

    return inv;
  }

  /// Apply powerup effects to base scores delta.
  /// [activePowerups] maps playerId -> PowerupType they activated this round.
  /// [targetSelections] maps playerId -> targetPlayerId for targeted powerups.
  /// [partyScoreboard] is the current total scoreboard (for swap).
  /// Returns the modified scoresDelta.
  static Map<String, int> applyPowerups({
    required Map<String, int> baseScoresDelta,
    required Map<String, PowerupType> activePowerups,
    required Map<String, String> targetSelections,
    required Map<String, int> partyScoreboard,
  }) {
    final result = Map<String, int>.from(baseScoresDelta);

    // Phase 1: Per-player modifiers
    for (final entry in activePowerups.entries) {
      final pid = entry.key;
      final pType = entry.value;
      final delta = result[pid] ?? 0;

      switch (pType) {
        case PowerupType.doublePoints:
          if (delta > 0) result[pid] = delta * 2;
          break;
        case PowerupType.shield:
          if (delta < 0) result[pid] = 0;
          break;
        case PowerupType.immunity:
          if (delta < 0) result[pid] = 0;
          break;
        case PowerupType.halfPoints:
          // Applied to TARGET
          final target = targetSelections[pid];
          if (target != null) {
            final tDelta = result[target] ?? 0;
            if (tDelta > 0) result[target] = (tDelta * 0.5).floor();
          }
          break;
        default:
          break;
      }
    }

    // Phase 2: Cross-player effects
    for (final entry in activePowerups.entries) {
      final pid = entry.key;
      final pType = entry.value;

      if (pType == PowerupType.steal) {
        // Steal 2 from highest scorer of round
        String? topScorer;
        int topScore = -999;
        for (final e in result.entries) {
          if (e.key != pid && e.value > topScore) {
            topScore = e.value;
            topScorer = e.key;
          }
        }
        if (topScorer != null && topScore > 0) {
          final stolen = topScore < 2 ? topScore : 2;
          result[topScorer] = (result[topScorer] ?? 0) - stolen;
          result[pid] = (result[pid] ?? 0) + stolen;
        }
      }
    }

    // Phase 3: Swap (after all deltas applied, swap total scores)
    // Swap is handled separately in the session controller after applying deltas

    return result;
  }
}
