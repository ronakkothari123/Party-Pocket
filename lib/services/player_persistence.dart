import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists player names locally so they prefill on next session.
class PlayerPersistence {
  static const _key = 'saved_players';

  /// Save list of player maps: [{name, isKid}]
  static Future<void> savePlayers(List<Map<String, dynamic>> players) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(players));
  }

  /// Load saved player list.
  static Future<List<Map<String, dynamic>>> loadPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Clear all saved players.
  static Future<void> clearPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
