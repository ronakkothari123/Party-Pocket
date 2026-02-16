import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../engine/round_result.dart';
import '../../models/session.dart';
import '../../powerups/powerup_type.dart';
import '../../ui/components/kawaii_card.dart';
import '../../ui/components/kawaii_button.dart';

/// Shows result of a single round. In party mode also shows mini leaderboard.
class RoundSummaryScreen extends StatelessWidget {
  final RoundResult result;
  final bool isPartyMode;
  final Map<String, int>? partyScoreboard;
  final List<String>? playerNames;
  final Map<String, String>? playerIdToName;
  final VoidCallback onNext;
  final VoidCallback onEndSession;
  final int? roundNumber;
  final int? totalRounds;
  final List<String>? extraDetails;

  const RoundSummaryScreen({
    super.key,
    required this.result,
    required this.isPartyMode,
    this.partyScoreboard,
    this.playerNames,
    this.playerIdToName,
    required this.onNext,
    required this.onEndSession,
    this.roundNumber,
    this.totalRounds,
    this.extraDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              // Game emoji
              Text(
                gameEmoji(result.gameType),
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 8),
              Text(
                gameDisplayName(result.gameType),
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 16),
              // Headline
              Text(
                result.headline,
                style: GoogleFonts.fredoka(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: KawaiiColors.deepInk,
                ),
                textAlign: TextAlign.center,
              ),
              if (result.subtext.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  result.subtext,
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    color: KawaiiColors.deepInk.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              // Extra details
              if (extraDetails != null && extraDetails!.isNotEmpty) ...[
                const SizedBox(height: 16),
                KawaiiCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: KawaiiColors.deepInk,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...extraDetails!.map((d) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              d,
                              style: GoogleFonts.fredoka(
                                fontSize: 14,
                                color: KawaiiColors.deepInk
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
              // Powerups Used section (revealed here for the first time)
              if (result.usedPowerups.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildPowerupsUsed(),
              ],
              // Party mode: leaderboard
              if (isPartyMode && partyScoreboard != null) ...[
                const SizedBox(height: 20),
                _buildLeaderboard(),
              ],
              // Round info
              if (roundNumber != null &&
                  totalRounds != null &&
                  isPartyMode) ...[
                const SizedBox(height: 12),
                Text(
                  'Round $roundNumber / $totalRounds',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    color: KawaiiColors.deepInk.withValues(alpha: 0.4),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              // Buttons
              KawaiiButton(
                label: isPartyMode && roundNumber == totalRounds
                    ? 'See Final Results'
                    : 'Next Round',
                onPressed: onNext,
                fillColor: KawaiiColors.mintGreen,
              ),
              const SizedBox(height: 12),
              KawaiiButton(
                label: 'End Session',
                onPressed: onEndSession,
                fillColor: KawaiiColors.lightPink,
                isPrimary: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPowerupsUsed() {
    return KawaiiCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('\u{26A1}', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'Powerups Used',
                style: GoogleFonts.fredoka(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: KawaiiColors.deepInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: result.usedPowerups.entries.map((e) {
              final name = playerIdToName?[e.key] ?? e.key;
              final def = powerupDefs[e.value];
              final emoji = def?.emoji ?? '\u{2728}';
              final powerupName = def?.name ?? e.value.name;

              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: KawaiiColors.softPurple.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: KawaiiColors.deepInk, width: 1.5),
                ),
                child: Text(
                  '$emoji $name used $powerupName',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: KawaiiColors.deepInk,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    final sorted = partyScoreboard!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return KawaiiCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scoreboard',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: KawaiiColors.deepInk,
            ),
          ),
          const SizedBox(height: 8),
          ...sorted.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final playerId = entry.value.key;
            final score = entry.value.value;
            final name = playerIdToName?[playerId] ?? playerId;
            final medal = rank == 1
                ? '\u{1F947}'
                : rank == 2
                    ? '\u{1F948}'
                    : rank == 3
                        ? '\u{1F949}'
                        : '';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      medal.isNotEmpty ? medal : '$rank.',
                      style: GoogleFonts.fredoka(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.fredoka(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: KawaiiColors.deepInk,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: KawaiiColors.sunshineYellow
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: KawaiiColors.deepInk, width: 1.5),
                    ),
                    child: Text(
                      '$score',
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
