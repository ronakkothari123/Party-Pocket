import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/player.dart';
import '../../powerups/powerup_type.dart';
import '../components/kawaii_card.dart';

/// Shows each player's powerup inventory. Accessible from review page.
class PowerupInventoryScreen extends StatelessWidget {
  final List<Player> players;

  const PowerupInventoryScreen({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Powerups Inventory',
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: KawaiiColors.deepInk,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  children: players.map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: KawaiiCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: p.avatarColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: KawaiiColors.deepInk, width: 2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      p.name[0].toUpperCase(),
                                      style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  p.name,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (p.inventory.isEmpty)
                              Text(
                                'No powerups',
                                style: GoogleFonts.fredoka(
                                  fontSize: 13,
                                  color: KawaiiColors.deepInk.withValues(alpha: 0.4),
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: p.inventory.entries.map((e) {
                                  final def = powerupDefs[e.key]!;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: KawaiiColors.lightYellow,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: KawaiiColors.deepInk, width: 1.5),
                                    ),
                                    child: Text(
                                      '${def.emoji} ${def.name} x${e.value}',
                                      style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
