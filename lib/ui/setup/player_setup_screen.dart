import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../state/session_controller.dart';
import '../../theme/app_theme.dart';
import '../../services/player_persistence.dart';
import '../components/kawaii_button.dart';
import '../components/kawaii_icon_button.dart';
import '../components/kawaii_stepper_header.dart';
import '../components/kawaii_text_field.dart';
import '../../models/player.dart';

class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final _nameController = TextEditingController();
  String? _error;
  bool _loadedSaved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedSaved) {
      _loadedSaved = true;
      _prefillSavedPlayers();
    }
  }

  Future<void> _prefillSavedPlayers() async {
    final controller = SessionControllerProvider.of(context);
    if (controller.current.players.isNotEmpty) return; // already have players
    final saved = await PlayerPersistence.loadPlayers();
    if (saved.isEmpty || !mounted) return;
    for (final p in saved) {
      final name = p['name'] as String? ?? '';
      final isKid = p['isKid'] as bool? ?? false;
      if (name.isNotEmpty && !controller.hasDuplicateName(name)) {
        controller.addPlayer(name);
        if (isKid) {
          final added = controller.current.players.last;
          controller.toggleKid(added.id);
        }
      }
    }
    if (mounted) setState(() {});
  }

  void _savePlayers() {
    final controller = SessionControllerProvider.of(context);
    final data = controller.current.players
        .map((p) => {'name': p.name, 'isKid': p.isKid})
        .toList();
    PlayerPersistence.savePlayers(data);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final controller = SessionControllerProvider.of(context);
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Name can\'t be empty!');
      return;
    }
    if (name.length > 16) {
      setState(() => _error = 'Max 16 characters!');
      return;
    }
    if (controller.hasDuplicateName(name)) {
      setState(() => _error = 'That name is taken!');
      return;
    }

    controller.addPlayer(name);
    _nameController.clear();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final controller = SessionControllerProvider.of(context);
    final session = controller.current;
    final canProceed = session.players.length >= 3;

    return Scaffold(
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
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const KawaiiStepperHeader(currentStep: 1),
                      const SizedBox(height: 16),
                      Text(
                        'Add Players',
                        style: GoogleFonts.fredoka(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: KawaiiColors.deepInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pass the phone. Add everyone playing.',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Add player row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: KawaiiTextField(
                              controller: _nameController,
                              hintText: 'Player name',
                              errorText: _error,
                              onSubmitted: _addPlayer,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: KawaiiIconButton(
                              icon: Icons.add_rounded,
                              onPressed: _addPlayer,
                              fillColor: KawaiiColors.mintGreen,
                              iconColor: KawaiiColors.cardWhite,
                              size: 46,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    // Player count + Remove All
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${session.players.length} player${session.players.length == 1 ? '' : 's'}${session.players.length < 3 ? ' (need at least 3)' : ''}',
                          style: GoogleFonts.fredoka(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: session.players.length < 3
                                ? KawaiiColors.primaryPink
                                : KawaiiColors.mintGreen,
                          ),
                        ),
                        if (session.players.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              for (final p in List.of(session.players)) {
                                controller.removePlayer(p.id);
                              }
                              PlayerPersistence.clearPlayers();
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: KawaiiColors.primaryPink
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: KawaiiColors.primaryPink
                                      .withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'Remove All',
                                style: GoogleFonts.fredoka(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: KawaiiColors.primaryPink,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Player list
                      ...session.players.map((p) => _buildPlayerTile(p, controller)),
                      const SizedBox(height: 24),
                      KawaiiButton(
                        label: 'Next: Settings',
                  onPressed: canProceed
                              ? () {
                                  _savePlayers();
                                  Navigator.pushNamed(context, '/global-settings');
                                }
                              : () {},
                        fillColor: canProceed
                            ? KawaiiColors.skyBlue
                            : KawaiiColors.deepInk.withValues(alpha: 0.15),
                        textColor: canProceed
                            ? KawaiiColors.cardWhite
                            : KawaiiColors.deepInk.withValues(alpha: 0.35),
                        icon: Icons.arrow_forward_rounded,
                        isPrimary: true,
                        borderColor: canProceed
                            ? KawaiiColors.deepInk
                            : KawaiiColors.deepInk.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerTile(Player player, SessionController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: KawaiiColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KawaiiColors.deepInk, width: 2),
        ),
        child: Row(
          children: [
            // Avatar dot
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: player.avatarColor,
                shape: BoxShape.circle,
                border: Border.all(color: KawaiiColors.deepInk, width: 2),
              ),
              child: Center(
                child: Text(
                  player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: KawaiiColors.cardWhite,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Name
            Expanded(
              child: Text(
                player.name,
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: KawaiiColors.deepInk,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Kid toggle
            GestureDetector(
              onTap: () => controller.toggleKid(player.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: player.isKid
                      ? KawaiiColors.sunshineYellow
                      : KawaiiColors.cardWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: player.isKid
                        ? KawaiiColors.deepInk
                        : KawaiiColors.deepInk.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: Text(
                  '\u{1F476} Kid',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: KawaiiColors.deepInk,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Remove
            GestureDetector(
              onTap: () => controller.removePlayer(player.id),
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: KawaiiColors.deepInk.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
