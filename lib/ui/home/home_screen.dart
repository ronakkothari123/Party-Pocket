import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/session.dart';
import '../../state/session_controller.dart';
import '../../theme/app_theme.dart';
import '../../services/audio_service.dart';
import '../../settings/app_settings.dart';
import '../components/kawaii_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(_fadeAnimation);
    _fadeController.forward();

    // Ensure main music is playing when we arrive on Home
    AudioService().resumeMainMusic();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onButtonPress(VoidCallback action) {
    AudioService().registerUserGesture();
    AudioService().startMainLoopIfNeeded();
    action();
  }

  /// Apply persisted defaults to session settings
  void _applyDefaults(SessionController sc) {
    final d = SettingsController().settings;
    sc.setRoundLength(d.defaultRoundLength);
    sc.setShuffleGames(d.defaultShuffleGames);
    sc.setPartyRounds(d.defaultPartyRounds);
    sc.setEnablePowerups(d.defaultEnablePowerups);
    sc.setAllowTwoChameleons(d.defaultAllowTwoChameleons);
    sc.setEnableChameleonRedemption(d.defaultEnableRedemption);
    sc.setEnableHaptics(d.hapticsEnabled);
    sc.setEnableSounds(d.soundEffectsEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ..._buildDoodles(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 24),
                          _buildLogo(),
                          const SizedBox(height: 8),
                          _buildSubtitle(),
                          const SizedBox(height: 36),
                          _buildPrimaryButtons(),
                          const SizedBox(height: 20),
                          _buildSecondaryButtons(),
                          const SizedBox(height: 32),
                          _buildMicrocopy(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDoodles() {
    final doodles = <Widget>[];
    final items = [
      (0.08, 0.05, Icons.star_rounded, KawaiiColors.primaryPink, 18.0),
      (0.85, 0.08, Icons.favorite_rounded, KawaiiColors.skyBlue, 14.0),
      (0.12, 0.35, Icons.circle, KawaiiColors.sunshineYellow, 10.0),
      (0.9, 0.3, Icons.star_rounded, KawaiiColors.mintGreen, 16.0),
      (0.05, 0.65, Icons.favorite_rounded, KawaiiColors.softPurple, 12.0),
      (0.88, 0.6, Icons.circle, KawaiiColors.primaryPink, 8.0),
      (0.5, 0.02, Icons.star_rounded, KawaiiColors.sunshineYellow, 12.0),
      (0.7, 0.85, Icons.favorite_rounded, KawaiiColors.mintGreen, 14.0),
    ];

    for (final (left, top, icon, color, size) in items) {
      doodles.add(
        Positioned(
          left: MediaQuery.of(context).size.width * left,
          top: MediaQuery.of(context).size.height * top,
          child: Opacity(
            opacity: 0.09,
            child: Icon(icon, color: color, size: size),
          ),
        ),
      );
    }
    return doodles;
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/main.png',
      height: 220,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _buildFallbackTitle(),
    );
  }

  Widget _buildFallbackTitle() {
    return Text(
      'Party Pocket',
      style: GoogleFonts.fredoka(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: KawaiiColors.deepInk,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Pass \u2022 Play \u2022 Laugh',
      style: GoogleFonts.fredoka(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: KawaiiColors.deepInk.withValues(alpha: 0.55),
      ),
    );
  }

  Widget _buildPrimaryButtons() {
    return Column(
      children: [
        KawaiiButton(
          label: 'Normal Mode',
          onPressed: () => _onButtonPress(() {
            final sc = SessionControllerProvider.of(context);
            sc.startNewSession(SessionMode.normal);
            _applyDefaults(sc);
            Navigator.pushNamed(context, '/game-select');
          }),
          fillColor: KawaiiColors.skyBlue,
          textColor: KawaiiColors.cardWhite,
          icon: Icons.play_circle_outline_rounded,
          isPrimary: true,
        ),
        const SizedBox(height: 14),
        KawaiiButton(
          label: 'Party Mode',
          onPressed: () => _onButtonPress(() {
            final sc = SessionControllerProvider.of(context);
            sc.startNewSession(SessionMode.party);
            _applyDefaults(sc);
            Navigator.pushNamed(context, '/game-select');
          }),
          fillColor: KawaiiColors.primaryPink,
          textColor: KawaiiColors.cardWhite,
          icon: Icons.celebration_rounded,
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildSecondaryButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        KawaiiButton(
          label: 'Settings',
          onPressed: () => _onButtonPress(
              () => Navigator.pushNamed(context, '/settings')),
          fillColor: KawaiiColors.lightYellow,
          icon: Icons.settings_rounded,
          isPrimary: false,
        ),
        KawaiiButton(
          label: 'Stats',
          onPressed: () => _onButtonPress(
              () => Navigator.pushNamed(context, '/stats')),
          fillColor: KawaiiColors.lightBlue,
          icon: Icons.bar_chart_rounded,
          isPrimary: false,
        ),
        KawaiiButton(
          label: 'How to Play',
          onPressed: () => _onButtonPress(
              () => Navigator.pushNamed(context, '/how-to-play')),
          fillColor: KawaiiColors.lightPink,
          icon: Icons.help_outline_rounded,
          isPrimary: false,
        ),
      ],
    );
  }

  Widget _buildMicrocopy() {
    return Text(
      '5 games included: Chameleon \u2022 Wavelength \u2022 Heads Up \u2022 10 Questions \u2022 Hot Potato',
      textAlign: TextAlign.center,
      style: GoogleFonts.fredoka(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: KawaiiColors.deepInk.withValues(alpha: 0.35),
      ),
    );
  }
}
