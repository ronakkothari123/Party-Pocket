import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/session.dart';
import '../powerups/powerup_type.dart';
import '../powerups/powerup_engine.dart';

class SessionController extends ChangeNotifier {
  Session _current = Session(mode: SessionMode.normal);

  Session get current => _current;

  void startNewSession(SessionMode mode) {
    _current = Session(mode: mode);
    notifyListeners();
  }

  void toggleGame(GameType game) {
    if (_current.selectedGames.contains(game)) {
      _current.selectedGames.remove(game);
    } else {
      _current.selectedGames.add(game);
    }
    notifyListeners();
  }

  void selectAllGames() {
    _current.selectedGames = Set.from(GameType.values);
    notifyListeners();
  }

  void clearGames() {
    _current.selectedGames.clear();
    notifyListeners();
  }

  void setShuffleGames(bool value) {
    _current.settings.shuffleGames = value;
    notifyListeners();
  }

  int _colorCounter = 0;

  void addPlayer(String name, {bool isKid = false}) {
    final player = Player(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      isKid: isKid,
      colorIndex: _colorCounter,
    );
    _colorCounter++;
    _current.players.add(player);
    notifyListeners();
  }

  void removePlayer(String id) {
    _current.players.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void toggleKid(String id) {
    final player = _current.players.firstWhere((p) => p.id == id);
    player.isKid = !player.isKid;
    notifyListeners();
  }

  void updateSettings(SessionSettings newSettings) {
    _current.settings = newSettings;
    notifyListeners();
  }

  void setRoundLength(int seconds) {
    _current.settings.roundLengthSeconds = seconds;
    notifyListeners();
  }

  void setEnableSounds(bool value) {
    _current.settings.enableSounds = value;
    notifyListeners();
  }

  void setEnableHaptics(bool value) {
    _current.settings.enableHaptics = value;
    notifyListeners();
  }

  void setPartyRounds(int rounds) {
    _current.settings.partyRounds = rounds;
    notifyListeners();
  }

  void setEnablePowerups(bool value) {
    _current.settings.enablePowerups = value;
    notifyListeners();
  }

  void setAllowTwoChameleons(bool value) {
    _current.settings.allowTwoChameleons = value;
    notifyListeners();
  }

  void setEnableChameleonRedemption(bool value) {
    _current.settings.enableChameleonRedemption = value;
    notifyListeners();
  }

  // Party mode scoreboard
  Map<String, int> _partyScoreboard = {};

  Map<String, int> get partyScoreboard => _partyScoreboard;

  void initPartyScoreboard() {
    _partyScoreboard = {};
    for (final p in _current.players) {
      _partyScoreboard[p.id] = 0;
    }
    // Initialize powerup inventories if enabled
    if (_current.settings.enablePowerups) {
      for (final p in _current.players) {
        p.inventory = PowerupEngine.generateStartingInventory();
      }
    }
    notifyListeners();
  }

  void applyScoresDelta(Map<String, int> delta) {
    for (final entry in delta.entries) {
      _partyScoreboard[entry.key] = (_partyScoreboard[entry.key] ?? 0) + entry.value;
    }
    notifyListeners();
  }

  /// Apply swap powerup: swap total scores between two players
  void applySwap(String playerA, String playerB) {
    final scoreA = _partyScoreboard[playerA] ?? 0;
    final scoreB = _partyScoreboard[playerB] ?? 0;
    _partyScoreboard[playerA] = scoreB;
    _partyScoreboard[playerB] = scoreA;
    notifyListeners();
  }

  /// Consume a powerup from a player's inventory
  void consumePowerup(String playerId, PowerupType type) {
    final player = _current.players.firstWhere((p) => p.id == playerId);
    player.consumePowerup(type);
    notifyListeners();
  }

  void resetSession() {
    _current = Session(mode: SessionMode.normal);
    _colorCounter = 0;
    _partyScoreboard = {};
    notifyListeners();
  }

  /// End the current session and reset to a "no active session" state.
  /// Does NOT wipe saved players from persistence.
  void endSessionAndReset() {
    _partyScoreboard = {};
    _current = Session(mode: SessionMode.normal);
    _colorCounter = 0;
    notifyListeners();
  }

  /// Restart the party with the same players, games, and settings.
  /// Resets scoreboard, round tracking, and re-rolls powerup inventories.
  void restartPartySameSetup() {
    assert(_current.mode == SessionMode.party);
    assert(_current.players.length >= 3);
    assert(_current.selectedGames.isNotEmpty);

    // Reset scoreboard
    _partyScoreboard = {};
    for (final p in _current.players) {
      _partyScoreboard[p.id] = 0;
    }

    // Re-roll powerup inventories if powerups enabled
    if (_current.settings.enablePowerups) {
      for (final p in _current.players) {
        p.inventory = PowerupEngine.generateStartingInventory();
      }
    }

    notifyListeners();
  }

  bool hasDuplicateName(String name) {
    final lower = name.trim().toLowerCase();
    return _current.players.any((p) => p.name.trim().toLowerCase() == lower);
  }

  static SessionController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SessionControllerProvider>()!
        .controller;
  }
}

class SessionControllerProvider extends InheritedNotifier<SessionController> {
  final SessionController controller;

  const SessionControllerProvider({
    super.key,
    required this.controller,
    required super.child,
  }) : super(notifier: controller);

  static SessionController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SessionControllerProvider>()!
        .controller;
  }
}
