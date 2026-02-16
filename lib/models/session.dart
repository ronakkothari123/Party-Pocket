import 'player.dart';

enum SessionMode { normal, party }

enum GameType { chameleon, wavelength, headsUp, tenQuestions, hotPotato }

String gameDisplayName(GameType game) {
  switch (game) {
    case GameType.chameleon:
      return 'Chameleon';
    case GameType.wavelength:
      return 'Wavelength';
    case GameType.headsUp:
      return 'Heads Up';
    case GameType.tenQuestions:
      return '10 Questions';
    case GameType.hotPotato:
      return 'Hot Potato';
  }
}

String gameEmoji(GameType game) {
  switch (game) {
    case GameType.chameleon:
      return '\u{1F98E}';
    case GameType.wavelength:
      return '\u{1F30A}';
    case GameType.headsUp:
      return '\u{1F64B}';
    case GameType.tenQuestions:
      return '\u{2753}';
    case GameType.hotPotato:
      return '\u{1F954}';
  }
}

String gameBannerAsset(GameType game) {
  switch (game) {
    case GameType.chameleon:
      return 'assets/images/chameleon.png';
    case GameType.wavelength:
      return 'assets/images/wavelength.png';
    case GameType.headsUp:
      return 'assets/images/heads_up.png';
    case GameType.tenQuestions:
      return 'assets/images/10_questions.png';
    case GameType.hotPotato:
      return 'assets/images/hot_potato.png';
  }
}

String gameDescription(GameType game) {
  switch (game) {
    case GameType.chameleon:
      return 'Blend in or be caught!';
    case GameType.wavelength:
      return 'Read minds on a spectrum.';
    case GameType.headsUp:
      return 'Guess what\'s on your head!';
    case GameType.tenQuestions:
      return 'Ask yes/no to find out.';
    case GameType.hotPotato:
      return 'Don\'t hold it too long!';
  }
}

class SessionSettings {
  int roundLengthSeconds;
  bool enableSounds;
  bool enableHaptics;
  bool shuffleGames;
  int partyRounds;
  bool enablePowerups;
  bool allowTwoChameleons;
  bool enableChameleonRedemption;

  SessionSettings({
    this.roundLengthSeconds = 60,
    this.enableSounds = true,
    this.enableHaptics = true,
    this.shuffleGames = false,
    this.partyRounds = 5,
    this.enablePowerups = false,
    this.allowTwoChameleons = false,
    this.enableChameleonRedemption = true,
  });

  SessionSettings copyWith({
    int? roundLengthSeconds,
    bool? enableSounds,
    bool? enableHaptics,
    bool? shuffleGames,
    int? partyRounds,
    bool? enablePowerups,
    bool? allowTwoChameleons,
    bool? enableChameleonRedemption,
  }) {
    return SessionSettings(
      roundLengthSeconds: roundLengthSeconds ?? this.roundLengthSeconds,
      enableSounds: enableSounds ?? this.enableSounds,
      enableHaptics: enableHaptics ?? this.enableHaptics,
      shuffleGames: shuffleGames ?? this.shuffleGames,
      partyRounds: partyRounds ?? this.partyRounds,
      enablePowerups: enablePowerups ?? this.enablePowerups,
      allowTwoChameleons: allowTwoChameleons ?? this.allowTwoChameleons,
      enableChameleonRedemption: enableChameleonRedemption ?? this.enableChameleonRedemption,
    );
  }
}

class Session {
  SessionMode mode;
  Set<GameType> selectedGames;
  List<Player> players;
  SessionSettings settings;

  Session({
    required this.mode,
    Set<GameType>? selectedGames,
    List<Player>? players,
    SessionSettings? settings,
  })  : selectedGames = selectedGames ?? {},
        players = players ?? [],
        settings = settings ?? SessionSettings();
}
