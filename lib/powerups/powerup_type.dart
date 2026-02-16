enum PowerupType {
  doublePoints,
  halfPoints,
  shield,
  steal,
  swap,
  immunity,
  reroll,
  peek,
}

enum PowerupRarity { common, special }

class PowerupDef {
  final PowerupType type;
  final String name;
  final String emoji;
  final String description;
  final PowerupRarity rarity;
  final bool isTargeted; // needs a target player

  const PowerupDef({
    required this.type,
    required this.name,
    required this.emoji,
    required this.description,
    required this.rarity,
    this.isTargeted = false,
  });
}

const Map<PowerupType, PowerupDef> powerupDefs = {
  PowerupType.doublePoints: PowerupDef(
    type: PowerupType.doublePoints,
    name: 'Double Points',
    emoji: '\u{2728}',
    description: 'x2 points gained this round',
    rarity: PowerupRarity.common,
  ),
  PowerupType.halfPoints: PowerupDef(
    type: PowerupType.halfPoints,
    name: 'Half Points',
    emoji: '\u{1F4A2}',
    description: 'Target gets 0.5x points this round',
    rarity: PowerupRarity.common,
    isTargeted: true,
  ),
  PowerupType.shield: PowerupDef(
    type: PowerupType.shield,
    name: 'Shield',
    emoji: '\u{1F6E1}',
    description: 'Cannot lose points this round',
    rarity: PowerupRarity.common,
  ),
  PowerupType.steal: PowerupDef(
    type: PowerupType.steal,
    name: 'Steal',
    emoji: '\u{1F48E}',
    description: 'Steal 2pts from top scorer',
    rarity: PowerupRarity.special,
  ),
  PowerupType.swap: PowerupDef(
    type: PowerupType.swap,
    name: 'Swap',
    emoji: '\u{1F500}',
    description: 'Swap total scores with someone',
    rarity: PowerupRarity.special,
    isTargeted: true,
  ),
  PowerupType.immunity: PowerupDef(
    type: PowerupType.immunity,
    name: 'Immunity',
    emoji: '\u{1F9CA}',
    description: 'Block loser penalties',
    rarity: PowerupRarity.common,
  ),
  PowerupType.reroll: PowerupDef(
    type: PowerupType.reroll,
    name: 'Reroll',
    emoji: '\u{1F3B2}',
    description: 'Reroll the next game',
    rarity: PowerupRarity.special,
  ),
  PowerupType.peek: PowerupDef(
    type: PowerupType.peek,
    name: 'Peek',
    emoji: '\u{1F440}',
    description: 'Chameleon: see the word for 2s',
    rarity: PowerupRarity.special,
  ),
};
