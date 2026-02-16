import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/player.dart';
import '../../powerups/powerup_type.dart';
import '../runner/pass_device_screen.dart';
import '../components/kawaii_button.dart';

/// Pass-n-play inventory preview at the start of a party.
class PowerupStartInventoryFlow extends StatefulWidget {
  final List<Player> players;
  final VoidCallback onComplete;

  const PowerupStartInventoryFlow({
    super.key,
    required this.players,
    required this.onComplete,
  });

  @override
  State<PowerupStartInventoryFlow> createState() =>
      _PowerupStartInventoryFlowState();
}

enum _FlowPhase { pass, view }

class _PowerupStartInventoryFlowState
    extends State<PowerupStartInventoryFlow> {
  int _index = 0;
  _FlowPhase _phase = _FlowPhase.pass;

  Player get _current => widget.players[_index];

  void _advance() {
    if (_index < widget.players.length - 1) {
      setState(() {
        _index++;
        _phase = _FlowPhase.pass;
      });
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _FlowPhase.pass) {
      return PassDeviceScreen(
        playerName: _current.name,
        playerColor: _current.avatarColor,
        onReady: () => setState(() => _phase = _FlowPhase.view),
      );
    }

    final inv = _current.inventory;

    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const Text('\u{1F381}', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                '${_current.name}\'s Powerups',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: KawaiiColors.deepInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Here\'s what you got for this party!',
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              if (inv.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('No powerups!',
                      style: GoogleFonts.fredoka(
                          fontSize: 16,
                          color: KawaiiColors.deepInk
                              .withValues(alpha: 0.4))),
                )
              else
                ...inv.entries.map((e) {
                  final def = powerupDefs[e.key]!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: KawaiiColors.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: KawaiiColors.deepInk, width: 2.5),
                      ),
                      child: Row(
                        children: [
                          Text(def.emoji,
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(def.name,
                                    style: GoogleFonts.fredoka(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                Text(def.description,
                                    style: GoogleFonts.fredoka(
                                        fontSize: 12,
                                        color: KawaiiColors.deepInk
                                            .withValues(alpha: 0.5))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: KawaiiColors.sunshineYellow
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: KawaiiColors.deepInk,
                                  width: 1.5),
                            ),
                            child: Text('x${e.value}',
                                style: GoogleFonts.fredoka(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),
              KawaiiButton(
                label: _index < widget.players.length - 1
                    ? 'Next Player'
                    : 'Done',
                onPressed: _advance,
                fillColor: KawaiiColors.skyBlue,
                textColor: KawaiiColors.cardWhite,
                icon: Icons.arrow_forward_rounded,
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
