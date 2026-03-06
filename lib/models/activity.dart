import 'package:flutter/material.dart';

class Activity {
  final String id;
  final String plateId;
  final String name;
  final double percentage;
  final Color color;
  final int sortOrder;
  final DateTime createdAt;

  const Activity({
    required this.id,
    required this.plateId,
    required this.name,
    required this.percentage,
    required this.color,
    this.sortOrder = 0,
    required this.createdAt,
  });

  Activity copyWith({
    String? id,
    String? plateId,
    String? name,
    double? percentage,
    Color? color,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Activity(
      id: id ?? this.id,
      plateId: plateId ?? this.plateId,
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get colorHex =>
      '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  Map<String, dynamic> toMap() => {
        'id': id,
        'plate_id': plateId,
        'name': name,
        'percentage': percentage,
        'color': colorHex,
        'sort_order': sortOrder,
      };

  factory Activity.fromMap(Map<String, dynamic> map) => Activity(
        id: map['id'] as String,
        plateId: map['plate_id'] as String,
        name: map['name'] as String,
        percentage: (map['percentage'] as num).toDouble(),
        color: parseColor(map['color'] as String),
        sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  static Color parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final padded = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    return Color(int.parse(padded, radix: 16));
  }

  // Preset activity colors
  static const List<Color> presetColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF8BC34A),
    Color(0xFF607D8B),
    Color(0xFFFFC107),
    Color(0xFF3F51B5),
    Color(0xFF009688),
  ];
}
