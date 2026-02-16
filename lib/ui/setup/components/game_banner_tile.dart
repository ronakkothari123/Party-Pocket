import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/session.dart';
import '../../../theme/app_theme.dart';

class GameBannerTile extends StatelessWidget {
  const GameBannerTile({
    super.key,
    required this.game,
    required this.selected,
    required this.onTap,
    this.fillColor,
    this.borderColor,
    this.borderWidth = 2.5,
  });

  final GameType game;
  final bool selected;
  final VoidCallback onTap;
  final Color? fillColor;
  final Color? borderColor;
  final double borderWidth;

  static const _gameColors = {
    GameType.chameleon: KawaiiColors.mintGreen,
    GameType.wavelength: KawaiiColors.skyBlue,
    GameType.headsUp: KawaiiColors.sunshineYellow,
    GameType.tenQuestions: KawaiiColors.softPurple,
    GameType.hotPotato: KawaiiColors.primaryPink,
  };

  @override
  Widget build(BuildContext context) {
    final accent = fillColor ?? _gameColors[game] ?? KawaiiColors.primaryPink;
    final border = borderColor ?? KawaiiColors.deepInk;
    final effectiveBorderWidth = selected ? borderWidth + 1.5 : borderWidth;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.12)
              : KawaiiColors.cardWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? border : border.withValues(alpha: 0.18),
            width: effectiveBorderWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            18 - effectiveBorderWidth,
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner image
                  Expanded(
                    flex: 5,
                    child: _BannerImage(game: game, accent: accent),
                  ),
                  // Info strip
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gameDisplayName(game),
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: KawaiiColors.deepInk,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            gameDescription(game),
                            style: GoogleFonts.fredoka(
                              fontSize: 11,
                              color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Check badge
              if (selected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: KawaiiColors.deepInk,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: KawaiiColors.cardWhite,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.game, required this.accent});

  final GameType game;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      gameBannerAsset(game),
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, e, s) => Container(
        color: accent.withValues(alpha: 0.25),
        child: Center(
          child: Text(
            gameEmoji(game),
            style: const TextStyle(fontSize: 36),
          ),
        ),
      ),
    );
  }
}
