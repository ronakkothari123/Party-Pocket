import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../stats/stats_controller.dart';
import '../../models/session.dart';
import '../components/kawaii_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late AppStats _stats;

  @override
  void initState() {
    super.initState();
    _stats = StatsController().stats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: KawaiiColors.skyBlue,
        foregroundColor: KawaiiColors.cardWhite,
        title: Text('Stats',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      backgroundColor: KawaiiColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Overview
            KawaiiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\u{1F4CA} Overview',
                      style: GoogleFonts.fredoka(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _statRow('Sessions Played', '${_stats.totalSessionsPlayed}'),
                  _statRow(
                      'Party Sessions', '${_stats.totalPartySessionsPlayed}'),
                  _statRow('Rounds Played', '${_stats.totalRoundsPlayed}'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Most Played Games
            KawaiiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\u{1F3AE} Most Played Games',
                      style: GoogleFonts.fredoka(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (_stats.perGamePlays.isEmpty)
                    Text('No games played yet!',
                        style: GoogleFonts.fredoka(
                            fontSize: 13,
                            color: KawaiiColors.deepInk
                                .withValues(alpha: 0.4)))
                  else
                    ..._buildGameList(),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Player Leaderboard
            KawaiiCard(
              fillColor: KawaiiColors.lightPink,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\u{1F3C6} Player Leaderboard',
                      style: GoogleFonts.fredoka(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (_stats.perPlayer.isEmpty)
                    Text('No players tracked yet!',
                        style: GoogleFonts.fredoka(
                            fontSize: 13,
                            color: KawaiiColors.deepInk
                                .withValues(alpha: 0.4)))
                  else
                    ..._buildLeaderboard(),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Best Moments
            KawaiiCard(
              fillColor: KawaiiColors.lightYellow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\u{2B50} Best Moments',
                      style: GoogleFonts.fredoka(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _buildBestMoments(),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Reset
            GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text('Reset all stats?',
                            style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w600)),
                        content: Text('This cannot be undone.',
                            style: GoogleFonts.fredoka()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: Text('Cancel',
                                style: GoogleFonts.fredoka()),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: Text('Reset',
                                style: GoogleFonts.fredoka(
                                    color: KawaiiColors.primaryPink,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (confirm) {
                  await StatsController().resetStats();
                  setState(() => _stats = StatsController().stats);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: KawaiiColors.primaryPink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color:
                          KawaiiColors.primaryPink.withValues(alpha: 0.4),
                      width: 2),
                ),
                child: Center(
                  child: Text('Reset All Stats',
                      style: GoogleFonts.fredoka(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: KawaiiColors.primaryPink)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.fredoka(
                  fontSize: 14,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.7))),
          Text(value,
              style: GoogleFonts.fredoka(
                  fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  List<Widget> _buildGameList() {
    final sorted = _stats.perGamePlays.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) {
      final gt = GameType.values.where((g) => g.name == e.key);
      final name = gt.isNotEmpty ? gameDisplayName(gt.first) : e.key;
      final emoji = gt.isNotEmpty ? gameEmoji(gt.first) : '\u{1F3B2}';
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(name,
                    style: GoogleFonts.fredoka(
                        fontSize: 14, fontWeight: FontWeight.w500))),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: KawaiiColors.skyBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${e.value}x',
                  style: GoogleFonts.fredoka(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildLeaderboard() {
    final sorted = _stats.perPlayer.entries.toList()
      ..sort((a, b) => b.value.wins.compareTo(a.value.wins));
    final top = sorted.take(5).toList();

    return top.asMap().entries.map((e) {
      final rank = e.key + 1;
      final name = e.value.key;
      final ps = e.value.value;
      final medal = rank == 1
          ? '\u{1F947}'
          : rank == 2
              ? '\u{1F948}'
              : rank == 3
                  ? '\u{1F949}'
                  : '$rank.';

      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child:
                  Text(medal, style: const TextStyle(fontSize: 16)),
            ),
            Expanded(
              child: Text(
                _capitalize(name),
                style: GoogleFonts.fredoka(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Text('${ps.wins}W',
                style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: KawaiiColors.primaryPink)),
            const SizedBox(width: 8),
            Text('${ps.totalPointsEarned}pts',
                style: GoogleFonts.fredoka(
                    fontSize: 12,
                    color: KawaiiColors.deepInk.withValues(alpha: 0.5))),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildBestMoments() {
    // Heads Up best
    String? huBestName;
    int huBest = 0;
    // Hot Potato most caught
    String? hpWorstName;
    int hpWorst = 0;

    for (final e in _stats.perPlayer.entries) {
      if (e.value.headsUpBestScore > huBest) {
        huBest = e.value.headsUpBestScore;
        huBestName = e.key;
      }
      if (e.value.hotPotatoLosses > hpWorst) {
        hpWorst = e.value.hotPotatoLosses;
        hpWorstName = e.key;
      }
    }

    if (huBestName == null && hpWorstName == null) {
      return Text('Play some games to see records!',
          style: GoogleFonts.fredoka(
              fontSize: 13,
              color: KawaiiColors.deepInk.withValues(alpha: 0.4)));
    }

    return Column(
      children: [
        if (huBestName != null)
          _momentRow('\u{1F64B} Heads Up Best',
              '${_capitalize(huBestName)} - $huBest correct'),
        if (hpWorstName != null)
          _momentRow('\u{1F954} Hot Potato Caught Most',
              '${_capitalize(hpWorstName)} - ${hpWorst}x'),
      ],
    );
  }

  Widget _momentRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.7))),
          Text(value,
              style:
                  GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
