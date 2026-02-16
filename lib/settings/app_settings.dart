import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app-wide settings.
class AppSettings {
  bool musicEnabled;
  double musicVolume; // 0.0 - 1.0
  bool soundEffectsEnabled;
  bool hapticsEnabled;

  // Gameplay defaults
  int defaultRoundLength; // 45/60/90/120
  bool defaultShuffleGames;
  int defaultPartyRounds; // 3/5/7/10/15
  bool defaultEnablePowerups;
  bool defaultAllowTwoChameleons;
  bool defaultEnableRedemption;

  // Content
  bool kidSafeMode;

  AppSettings({
    this.musicEnabled = true,
    this.musicVolume = 0.35,
    this.soundEffectsEnabled = true,
    this.hapticsEnabled = true,
    this.defaultRoundLength = 60,
    this.defaultShuffleGames = false,
    this.defaultPartyRounds = 5,
    this.defaultEnablePowerups = false,
    this.defaultAllowTwoChameleons = false,
    this.defaultEnableRedemption = true,
    this.kidSafeMode = false,
  });

  Map<String, dynamic> toJson() => {
        'musicEnabled': musicEnabled,
        'musicVolume': musicVolume,
        'soundEffectsEnabled': soundEffectsEnabled,
        'hapticsEnabled': hapticsEnabled,
        'defaultRoundLength': defaultRoundLength,
        'defaultShuffleGames': defaultShuffleGames,
        'defaultPartyRounds': defaultPartyRounds,
        'defaultEnablePowerups': defaultEnablePowerups,
        'defaultAllowTwoChameleons': defaultAllowTwoChameleons,
        'defaultEnableRedemption': defaultEnableRedemption,
        'kidSafeMode': kidSafeMode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      musicEnabled: json['musicEnabled'] as bool? ?? true,
      musicVolume: (json['musicVolume'] as num?)?.toDouble() ?? 0.35,
      soundEffectsEnabled: json['soundEffectsEnabled'] as bool? ?? true,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      defaultRoundLength: json['defaultRoundLength'] as int? ?? 60,
      defaultShuffleGames: json['defaultShuffleGames'] as bool? ?? false,
      defaultPartyRounds: json['defaultPartyRounds'] as int? ?? 5,
      defaultEnablePowerups: json['defaultEnablePowerups'] as bool? ?? false,
      defaultAllowTwoChameleons: json['defaultAllowTwoChameleons'] as bool? ?? false,
      defaultEnableRedemption: json['defaultEnableRedemption'] as bool? ?? true,
      kidSafeMode: json['kidSafeMode'] as bool? ?? false,
    );
  }
}

/// Manages loading/saving of AppSettings.
class SettingsController {
  static const _key = 'app_settings';
  static final SettingsController _instance = SettingsController._();
  factory SettingsController() => _instance;
  SettingsController._();

  AppSettings _settings = AppSettings();
  AppSettings get settings => _settings;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        _settings = AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _settings = AppSettings();
      }
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_settings.toJson()));
  }

  Future<void> restoreDefaults() async {
    _settings = AppSettings();
    await save();
  }
}
