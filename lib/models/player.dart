import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../powerups/powerup_type.dart';

class Player {
  final String id;
  String name;
  bool isKid;
  int colorIndex;
  Map<PowerupType, int> inventory;

  Player({
    required this.id,
    required this.name,
    this.isKid = false,
    this.colorIndex = 0,
    Map<PowerupType, int>? inventory,
  }) : inventory = inventory ?? {};

  static const List<Color> avatarColors = [
    KawaiiColors.primaryPink,
    KawaiiColors.skyBlue,
    KawaiiColors.sunshineYellow,
    KawaiiColors.mintGreen,
    KawaiiColors.softPurple,
    Color(0xFFFF8A65),
    Color(0xFF81C784),
    Color(0xFFFFB74D),
  ];

  Color get avatarColor => avatarColors[colorIndex % avatarColors.length];

  bool hasPowerup(PowerupType type) => (inventory[type] ?? 0) > 0;

  void consumePowerup(PowerupType type) {
    if (hasPowerup(type)) {
      inventory[type] = inventory[type]! - 1;
      if (inventory[type]! <= 0) inventory.remove(type);
    }
  }

  int get totalPowerups =>
      inventory.values.fold(0, (sum, count) => sum + count);
}
