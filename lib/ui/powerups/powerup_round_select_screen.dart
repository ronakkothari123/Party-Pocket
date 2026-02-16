import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/player.dart';
import '../../models/session.dart';
import '../../powerups/powerup_type.dart';
import '../components/kawaii_button.dart';
import '../components/kawaii_card.dart';

/// Result of the powerup round-select board.
class PowerupBoardResult {
  /// Only contains entries for players who actually selected a powerup.
  final Map<String, PowerupType> selections;
  final Map<String, String> targets;

  const PowerupBoardResult({
    required this.selections,
    required this.targets,
  });

  bool get hasReroll =>
      selections.values.any((t) => t == PowerupType.reroll);

  String? get rerollUserId {
    for (final e in selections.entries) {
      if (e.value == PowerupType.reroll) return e.key;
    }
    return null;
  }
}

/// All-players board for powerup selection between rounds.
/// Selections are SECRET — the board shows no indicators of who picked what.
/// "Start Round" is always enabled; players who don't pick simply use nothing.
class PowerupRoundSelectScreen extends StatefulWidget {
  final List<Player> players;
  final GameType? nextGame;
  final void Function(PowerupBoardResult result) onComplete;

  const PowerupRoundSelectScreen({
    super.key,
    required this.players,
    this.nextGame,
    required this.onComplete,
  });

  @override
  State<PowerupRoundSelectScreen> createState() =>
      _PowerupRoundSelectScreenState();
}

class _PowerupRoundSelectScreenState extends State<PowerupRoundSelectScreen> {
  // Only players who actually picked something appear here.
  final Map<String, PowerupType> _selections = {};
  final Map<String, String> _targets = {};

  void _finish() {
    widget.onComplete(PowerupBoardResult(
      selections: Map.unmodifiable(_selections),
      targets: Map.unmodifiable(_targets),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  const Text('\u{26A1}', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 4),
                  Text(
                    'Powerup Phase',
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: KawaiiColors.deepInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap your name to secretly choose a powerup',
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: widget.players.map((p) {
                    // All tiles look identical — no indication of selection
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => _openPlayerModal(p),
                        child: KawaiiCard(
                          fillColor: KawaiiColors.cardWhite,
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: p.avatarColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: KawaiiColors.deepInk,
                                      width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    p.name.isNotEmpty
                                        ? p.name[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: KawaiiColors.cardWhite,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  color: KawaiiColors.deepInk
                                      .withValues(alpha: 0.3),
                                  size: 22),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: KawaiiButton(
                label: 'Start Round',
                onPressed: _finish,
                fillColor: KawaiiColors.skyBlue,
                textColor: KawaiiColors.cardWhite,
                isPrimary: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPlayerModal(Player player) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PlayerPowerupModal(
        player: player,
        allPlayers: widget.players,
        nextGame: widget.nextGame,
        currentSelection: _selections[player.id],
        onSelect: (type, target) {
          Navigator.pop(ctx);
          setState(() {
            _selections[player.id] = type;
            if (target != null) {
              _targets[player.id] = target;
            } else {
              _targets.remove(player.id);
            }
          });
        },
        onClear: () {
          Navigator.pop(ctx);
          setState(() {
            _selections.remove(player.id);
            _targets.remove(player.id);
          });
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }
}

/// Modal: identity confirm -> pick powerup -> (target if needed) -> done.
/// Shows current selection only inside this modal. Nothing leaks to the board.
class _PlayerPowerupModal extends StatefulWidget {
  final Player player;
  final List<Player> allPlayers;
  final GameType? nextGame;
  final PowerupType? currentSelection;
  final void Function(PowerupType type, String? target) onSelect;
  final VoidCallback onClear;
  final VoidCallback onCancel;

  const _PlayerPowerupModal({
    required this.player,
    required this.allPlayers,
    this.nextGame,
    this.currentSelection,
    required this.onSelect,
    required this.onClear,
    required this.onCancel,
  });

  @override
  State<_PlayerPowerupModal> createState() => _PlayerPowerupModalState();
}

enum _ModalPhase { confirm, choose, target }

class _PlayerPowerupModalState extends State<_PlayerPowerupModal> {
  _ModalPhase _phase = _ModalPhase.confirm;
  PowerupType? _selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: KawaiiColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_phase) {
      case _ModalPhase.confirm:
        return _buildConfirm();
      case _ModalPhase.choose:
        return _buildChoose();
      case _ModalPhase.target:
        return _buildTarget();
    }
  }

  Widget _buildConfirm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: widget.player.avatarColor,
            shape: BoxShape.circle,
            border: Border.all(color: KawaiiColors.deepInk, width: 2.5),
          ),
          child: Center(
            child: Text(
              widget.player.name.isNotEmpty
                  ? widget.player.name[0].toUpperCase()
                  : '?',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: KawaiiColors.cardWhite,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Are you ${widget.player.name}?',
          style: GoogleFonts.fredoka(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: KawaiiColors.deepInk,
          ),
        ),
        const SizedBox(height: 20),
        KawaiiButton(
          label: 'Yes, choose powerup',
          onPressed: () => setState(() => _phase = _ModalPhase.choose),
          fillColor: KawaiiColors.mintGreen,
          textColor: KawaiiColors.deepInk,
          icon: Icons.bolt_rounded,
          isPrimary: true,
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: widget.onCancel,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Not me',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                color: KawaiiColors.deepInk.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoose() {
    final inv = widget.player.inventory;
    final hasCurrent = widget.currentSelection != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.player.name}\u{2019}s Powerups',
          style: GoogleFonts.fredoka(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: KawaiiColors.deepInk,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pick one for this round',
          style: GoogleFonts.fredoka(
            fontSize: 13,
            color: KawaiiColors.deepInk.withValues(alpha: 0.5),
          ),
        ),
        if (hasCurrent) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: KawaiiColors.sunshineYellow.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: KawaiiColors.deepInk, width: 1.5),
            ),
            child: Text(
              'Current: ${powerupDefs[widget.currentSelection]?.name ?? ""}',
              style: GoogleFonts.fredoka(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: KawaiiColors.deepInk,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (inv.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No powerups left!',
                style: GoogleFonts.fredoka(
                    fontSize: 15,
                    color:
                        KawaiiColors.deepInk.withValues(alpha: 0.4))),
          )
        else
          ...inv.entries.map((e) {
            final def = powerupDefs[e.key]!;
            // Hide peek unless next game is chameleon
            if (e.key == PowerupType.peek &&
                widget.nextGame != GameType.chameleon) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _selected = e.key;
                  if (def.isTargeted) {
                    setState(() => _phase = _ModalPhase.target);
                  } else {
                    widget.onSelect(e.key, null);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: KawaiiColors.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: KawaiiColors.deepInk, width: 2.5),
                  ),
                  child: Row(
                    children: [
                      Text(def.emoji,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(def.name,
                                style: GoogleFonts.fredoka(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            Text(def.description,
                                style: GoogleFonts.fredoka(
                                    fontSize: 11,
                                    color: KawaiiColors.deepInk
                                        .withValues(alpha: 0.5))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
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
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        // Clear selection button (only shown if they already picked one)
        if (hasCurrent)
          GestureDetector(
            onTap: widget.onClear,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: KawaiiColors.lightPink.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: KawaiiColors.deepInk, width: 2),
              ),
              child: Center(
                child: Text('Clear selection',
                    style: GoogleFonts.fredoka(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: KawaiiColors.deepInk)),
              ),
            ),
          ),
        if (hasCurrent) const SizedBox(height: 8),
        // Close without choosing — just dismiss
        GestureDetector(
          onTap: widget.onCancel,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Close',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                color: KawaiiColors.deepInk.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTarget() {
    final others =
        widget.allPlayers.where((p) => p.id != widget.player.id).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('\u{1F3AF}', style: TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text('Choose a target',
            style: GoogleFonts.fredoka(
                fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        ...others.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => widget.onSelect(_selected!, p.id),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: KawaiiColors.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: KawaiiColors.deepInk, width: 2.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: p.avatarColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: KawaiiColors.deepInk, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            p.name[0].toUpperCase(),
                            style: GoogleFonts.fredoka(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: KawaiiColors.cardWhite),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(p.name,
                          style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }
}
