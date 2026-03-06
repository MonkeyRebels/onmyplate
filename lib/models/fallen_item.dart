class FallenItem {
  final String id;
  final String plateId;
  final String name;
  final String emoji;
  // Cartesian offset from plate center, scaled so 1.0 = plate radius.
  // Items with |offset| > ~1.0 are outside the plate rim.
  final double offsetX;
  final double offsetY;
  final DateTime createdAt;

  const FallenItem({
    required this.id,
    required this.plateId,
    required this.name,
    required this.emoji,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    required this.createdAt,
  });

  FallenItem copyWith({
    String? id,
    String? plateId,
    String? name,
    String? emoji,
    double? offsetX,
    double? offsetY,
    DateTime? createdAt,
  }) =>
      FallenItem(
        id: id ?? this.id,
        plateId: plateId ?? this.plateId,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        offsetX: offsetX ?? this.offsetX,
        offsetY: offsetY ?? this.offsetY,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'plate_id': plateId,
        'name': name,
        'emoji': emoji,
        'offset_x': offsetX,
        'offset_y': offsetY,
      };

  factory FallenItem.fromMap(Map<String, dynamic> map) => FallenItem(
        id: map['id'] as String,
        plateId: map['plate_id'] as String,
        name: map['name'] as String,
        emoji: map['emoji'] as String? ?? '😅',
        offsetX: (map['offset_x'] as num?)?.toDouble() ?? 0.0,
        offsetY: (map['offset_y'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  static const List<String> emojiOptions = [
    '😅', '🍕', '📧', '📞', '🏃', '💼', '📚', '🎯',
    '⚡', '🔥', '🎪', '🎭', '🏋️', '🎨', '💡', '🌪️',
    '⏰', '📱', '🎸', '🚗', '✈️', '🏠', '💰', '🤝',
    '🐉', '🎲', '🧩', '🪴', '☕', '🍜', '🛒', '📺',
  ];
}
