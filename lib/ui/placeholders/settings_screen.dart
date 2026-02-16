import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../settings/app_settings.dart';
import '../../services/audio_service.dart';
import '../../services/player_persistence.dart';
import '../../stats/stats_controller.dart';
import '../components/kawaii_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _s;

  @override
  void initState() {
    super.initState();
    _s = SettingsController().settings;
  }

  Future<void> _save() async {
    await SettingsController().save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: KawaiiColors.sunshineYellow,
        foregroundColor: KawaiiColors.deepInk,
        title: Text('Settings',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      backgroundColor: KawaiiColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // --- Audio ---
            KawaiiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\u{1F3B5} Audio',
                      style: GoogleFonts.fredoka(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _toggle('Music', Icons.music_note_rounded, _s.musicEnabled,
                      (v) {
                    setState(() => _s.musicEnabled = v);
                    AudioService().setEnabled(v);
                    _save();
                  }),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.volume_up_rounded,
                          size: 20,
                          color: KawaiiColors.deepInk.withValues(alpha: 0.5)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Volume',
                            style: GoogleFonts.fredoka(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: KawaiiColors.primaryPink,
                      inactiveTrackColor:
                          KawaiiColors.deepInk.withValues(alpha: 0.12),
                      thumbColor: KawaiiColors.primaryPink,
                      overlayColor:
                          KawaiiColors.primaryPink.withValues(alpha: 0.15),
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 10),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _s.musicVolume,
                      min: 0,
                      max: 1,
                      onChanged: _s.musicEnabled
                          ? (v) {
                              setState(() => _s.musicVolume = v);
                              AudioService().setVolume(v);
                            }
                          : null,
                      onChangeEnd: (_) => _save(),
                    ),
                  ),
                  _toggle('Sound Effects', Icons.speaker_rounded,
                      _s.soundEffectsEnabled, (v) {
                    setState(() => _s.soundEffectsEnabled = v);
                    _save();
                  }),
                  _toggle(
                      'Haptics', Icons.vibration_rounded, _s.hapticsEnabled,
                      (v) {
                    setState(() => _s.hapticsEnabled = v);
                    _save();
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // --- Gameplay Defaults ---
            KawaiiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\u{1F3AE} Gameplay Defaults',
                      style: GoogleFonts.fredoka(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Text('Default Round Timer',
                      style: GoogleFonts.fredoka(
                          fontSize: 13,
                          color:
                              KawaiiColors.deepInk.withValues(alpha: 0.6))),
                  const SizedBox(height: 6),
                  _chips([45, 60, 90, 120], _s.defaultRoundLength, (v) {
                    setState(() => _s.defaultRoundLength = v);
                    _save();
                  }, suffix: 's'),
                  const SizedBox(height: 12),
                  _toggle('Shuffle Games', Icons.shuffle_rounded,
                      _s.defaultShuffleGames, (v) {
                    setState(() => _s.defaultShuffleGames = v);
                    _save();
                  }),
                  const SizedBox(height: 12),
                  Text('Default Party Rounds',
                      style: GoogleFonts.fredoka(
                          fontSize: 13,
                          color:
                              KawaiiColors.deepInk.withValues(alpha: 0.6))),
                  const SizedBox(height: 6),
                  _chips([3, 5, 7, 10, 15], _s.defaultPartyRounds, (v) {
                    setState(() => _s.defaultPartyRounds = v);
                    _save();
                  }),
                  const SizedBox(height: 8),
                  _toggle('Enable Powerups by Default', Icons.bolt_rounded,
                      _s.defaultEnablePowerups, (v) {
                    setState(() => _s.defaultEnablePowerups = v);
                    _save();
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // --- Chameleon ---
            KawaiiCard(
              fillColor: KawaiiColors.lightYellow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\u{1F98E} Chameleon Defaults',
                      style: GoogleFonts.fredoka(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _toggle('Allow 2 Chameleons (7+ players)',
                      Icons.people_alt_rounded, _s.defaultAllowTwoChameleons,
                      (v) {
                    setState(() => _s.defaultAllowTwoChameleons = v);
                    _save();
                  }),
                  _toggle('Chameleon Redemption', Icons.refresh_rounded,
                      _s.defaultEnableRedemption, (v) {
                    setState(() => _s.defaultEnableRedemption = v);
                    _save();
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // --- Content / Safety ---
            KawaiiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\u{1F6E1}\u{FE0F} Content & Safety',
                      style: GoogleFonts.fredoka(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _toggle('Kid-Safe Mode', Icons.child_care_rounded,
                      _s.kidSafeMode, (v) {
                    setState(() => _s.kidSafeMode = v);
                    _save();
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // --- Data ---
            KawaiiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\u{1F4BE} Data',
                      style: GoogleFonts.fredoka(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _dangerButton('Reset Stats', () async {
                    final confirm = await _confirm(
                        context, 'Reset all stats?', 'This cannot be undone.');
                    if (confirm) {
                      await StatsController().resetStats();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Stats reset!')),
                        );
                      }
                    }
                  }),
                  const SizedBox(height: 8),
                  _dangerButton('Reset Saved Players', () async {
                    final confirm = await _confirm(context,
                        'Remove saved players?', 'This cannot be undone.');
                    if (confirm) {
                      await PlayerPersistence.clearPlayers();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Saved players cleared!')),
                        );
                      }
                    }
                  }),
                  const SizedBox(height: 8),
                  _dangerButton('Restore All Defaults', () async {
                    final confirm = await _confirm(context,
                        'Restore all defaults?', 'Settings will be reset.');
                    if (confirm) {
                      await SettingsController().restoreDefaults();
                      setState(
                          () => _s = SettingsController().settings);
                      AudioService().setEnabled(_s.musicEnabled);
                      AudioService().setVolume(_s.musicVolume);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Defaults restored!')),
                        );
                      }
                    }
                  }),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _toggle(
      String label, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: KawaiiColors.deepInk.withValues(alpha: 0.5)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: GoogleFonts.fredoka(
                      fontSize: 14, fontWeight: FontWeight.w500))),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(!value);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value
                    ? KawaiiColors.mintGreen
                    : KawaiiColors.deepInk.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: value
                      ? KawaiiColors.deepInk
                      : KawaiiColors.deepInk.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: KawaiiColors.cardWhite,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: KawaiiColors.deepInk, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips(List<int> options, int selected, ValueChanged<int> onChanged,
      {String suffix = ''}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((v) {
        final sel = selected == v;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: sel ? KawaiiColors.skyBlue : KawaiiColors.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sel
                    ? KawaiiColors.deepInk
                    : KawaiiColors.deepInk.withValues(alpha: 0.25),
                width: sel ? 2.5 : 2,
              ),
            ),
            child: Text(
              '$v$suffix',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: sel ? KawaiiColors.cardWhite : KawaiiColors.deepInk,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dangerButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: KawaiiColors.primaryPink.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: KawaiiColors.primaryPink.withValues(alpha: 0.4),
              width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: KawaiiColors.primaryPink,
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirm(
      BuildContext ctx, String title, String message) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (c) => AlertDialog(
            title: Text(title,
                style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
            content: Text(message, style: GoogleFonts.fredoka()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text('Cancel',
                    style: GoogleFonts.fredoka(
                        color: KawaiiColors.deepInk.withValues(alpha: 0.5))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text('Confirm',
                    style: GoogleFonts.fredoka(
                        color: KawaiiColors.primaryPink,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ) ??
        false;
  }
}
