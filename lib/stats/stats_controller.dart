import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';
import '../engine/round_result.dart';

class PlayerStats {
  int wins;
  int totalPointsEarned;
  int headsUpBestScore;
  int hotPotatoLosses;

  PlayerStats({
    this.wins = 0,
    this.totalPointsEarned = 0,
    this.headsUpBestScore = 0,
    this.hotPotatoLosses = 0,
  });

  Map<String, dynamic> toJson() => {
        'wins': wins,
        'totalPointsEarned': totalPointsEarned,
        'headsUpBestScore': headsUpBestScore,
        'hotPotatoLosses': hotPotatoLosses,
      };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
        wins: json['wins'] as int? ?? 0,
        totalPointsEarned: json['totalPointsEarned'] as int? ?? 0,
        headsUpBestScore: json['headsUpBestScore'] as int? ?? 0,
        hotPotatoLosses: json['hotPotatoLosses'] as int? ?? 0,
      );
}

class AppStats {
  int totalSessionsPlayed;
  int totalPartySessionsPlayed;
  int totalRoundsPlayed;
  Map<String, int> perGamePlays; // GameType.name -> count
  Map<String, PlayerStats> perPlayer; // playerName (lowercase) -> stats

  AppStats({
    this.totalSessionsPlayed = 0,
    this.totalPartySessionsPlayed = 0,
    this.totalRoundsPlayed = 0,
    Map<String, int>? perGamePlays,
    Map<String, PlayerStats>? perPlayer,
  })  : perGamePlays = perGamePlays ?? {},
        perPlayer = perPlayer ?? {};

  Map<String, dynamic> toJson() => {
        'totalSessionsPlayed': totalSessionsPlayed,
        'totalPartySessionsPlayed': totalPartySessionsPlayed,
        'totalRoundsPlayed': totalRoundsPlayed,
        'perGamePlays': perGamePlays,
        'perPlayer': perPlayer.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory AppStats.fromJson(Map<String, dynamic> json) {
    final pgp = <String, int>{};
    if (json['perGamePlays'] is Map) {
      for (final e in (json['perGamePlays'] as Map).entries) {
        pgp[e.key as String] = (e.value as num).toInt();
      }
    }
    final pp = <String, PlayerStats>{};
    if (json['perPlayer'] is Map) {
      for (final e in (json['perPlayer'] as Map).entries) {
        pp[e.key as String] =
            PlayerStats.fromJson(Map<String, dynamic>.from(e.value as Map));
      }
    }
    return AppStats(
      totalSessionsPlayed: json['totalSessionsPlayed'] as int? ?? 0,
      totalPartySessionsPlayed: json['totalPartySessionsPlayed'] as int? ?? 0,
      totalRoundsPlayed: json['totalRoundsPlayed'] as int? ?? 0,
      perGamePlays: pgp,
      perPlayer: pp,
    );
  }
}

class StatsController {
  static const _key = 'app_stats';
  static final StatsController _instance = StatsController._();
  factory StatsController() => _instance;
  StatsController._();

  AppStats _stats = AppStats();
  AppStats get stats => _stats;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        _stats = AppStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _stats = AppStats();
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_stats.toJson()));
  }

  /// Record a round result. playerIdToName maps id -> display name.
  Future<void> recordRound(
      RoundResult result, Map<String, String> playerIdToName) async {
    _stats.totalRoundsPlayed++;

    final gameName = result.gameType.name;
    _stats.perGamePlays[gameName] = (_stats.perGamePlays[gameName] ?? 0) + 1;

    // Update per-player stats
    for (final entry in result.scoresDelta.entries) {
      final name =
          (playerIdToName[entry.key] ?? entry.key).trim().toLowerCase();
      final ps = _stats.perPlayer.putIfAbsent(name, () => PlayerStats());
      ps.totalPointsEarned += entry.value;
    }

    // Track heads up best
    if (result.gameType == GameType.headsUp) {
      for (final entry in result.scoresDelta.entries) {
        final name =
            (playerIdToName[entry.key] ?? entry.key).trim().toLowerCase();
        final ps = _stats.perPlayer.putIfAbsent(name, () => PlayerStats());
        if (entry.value > ps.headsUpBestScore) {
          ps.headsUpBestScore = entry.value;
        }
      }
    }

    // Track hot potato losses
    if (result.gameType == GameType.hotPotato) {
      for (final loserId in result.losers) {
        final name =
            (playerIdToName[loserId] ?? loserId).trim().toLowerCase();
        final ps = _stats.perPlayer.putIfAbsent(name, () => PlayerStats());
        ps.hotPotatoLosses++;
      }
    }

    await _save();
  }

  /// Record party end.
  Future<void> recordPartyEnd(
      Map<String, int> scoreboard, Map<String, String> playerIdToName) async {
    _stats.totalSessionsPlayed++;
    _stats.totalPartySessionsPlayed++;

    // Find winner
    String? winnerId;
    int topScore = -999;
    for (final e in scoreboard.entries) {
      if (e.value > topScore) {
        topScore = e.value;
        winnerId = e.key;
      }
    }
    if (winnerId != null) {
      final name =
          (playerIdToName[winnerId] ?? winnerId).trim().toLowerCase();
      final ps = _stats.perPlayer.putIfAbsent(name, () => PlayerStats());
      ps.wins++;
    }

    await _save();
  }

  /// Record normal mode session end.
  Future<void> recordNormalSessionEnd() async {
    _stats.totalSessionsPlayed++;
    await _save();
  }

  Future<void> resetStats() async {
    _stats = AppStats();
    await _save();
  }
}
