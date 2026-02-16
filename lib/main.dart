import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'theme/app_theme.dart';
import 'state/session_controller.dart';
import 'services/audio_service.dart';
import 'settings/app_settings.dart';
import 'stats/stats_controller.dart';
import 'app/app_lifecycle_handler.dart';
import 'ads/interstitial_ad_service.dart';
import 'ui/home/home_screen.dart';
import 'ui/placeholders/settings_screen.dart';
import 'ui/placeholders/stats_screen.dart';
import 'ui/placeholders/how_to_play_screen.dart';
import 'ui/setup/game_select_screen.dart';
import 'ui/setup/player_setup_screen.dart';
import 'ui/setup/global_settings_screen.dart';
import 'ui/setup/review_start_screen.dart';
import 'ui/runner/game_runner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await SettingsController().load();
  await StatsController().load();
  await AudioService().init();

  // Apply persisted audio settings
  final s = SettingsController().settings;
  AudioService().setEnabled(s.musicEnabled);
  await AudioService().setVolume(s.musicVolume);

  // Register global lifecycle handler for background/foreground audio
  AppLifecycleHandler();

  // Preload first interstitial ad
  InterstitialAdService().preload();

  runApp(const PartyPocketApp());
}

class PartyPocketApp extends StatefulWidget {
  const PartyPocketApp({super.key});

  @override
  State<PartyPocketApp> createState() => _PartyPocketAppState();
}

class _PartyPocketAppState extends State<PartyPocketApp> {
  final _sessionController = SessionController();

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SessionControllerProvider(
      controller: _sessionController,
      child: MaterialApp(
        title: 'Party Pocket',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const HomeScreen(),
        routes: {
          '/home': (_) => const HomeScreen(),
          '/game-select': (_) => const GameSelectScreen(),
          '/player-setup': (_) => const PlayerSetupScreen(),
          '/global-settings': (_) => const GlobalSettingsScreen(),
          '/review-start': (_) => const ReviewStartScreen(),
          '/game-runner': (_) => const GameRunnerScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/stats': (_) => const StatsScreen(),
          '/how-to-play': (_) => const HowToPlayScreen(),
        },
      ),
    );
  }
}
