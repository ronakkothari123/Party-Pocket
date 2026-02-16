import 'package:flutter/widgets.dart';
import '../services/audio_service.dart';

/// Global lifecycle observer that pauses/resumes audio when the app
/// goes to background or returns to foreground.
class AppLifecycleHandler with WidgetsBindingObserver {
  AppLifecycleHandler() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        debugPrint('[Lifecycle] app state=$state → pausing audio');
        AudioService().handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        debugPrint('[Lifecycle] app state=$state → resuming audio');
        AudioService().handleAppResumed();
        break;
      case AppLifecycleState.hidden:
        // treat like paused
        AudioService().handleAppPaused();
        break;
    }
  }
}
