import 'package:flutter/material.dart';

class PlateDesign {
  final String id;
  final String name;
  final String description;
  final Color rimColor;
  final Color rimInnerColor;
  final Color surfaceColor;
  final List<Color> surfaceGradient;
  final Color shadowColor;
  final bool hasPattern;
  final bool isDark;

  const PlateDesign({
    required this.id,
    required this.name,
    required this.description,
    required this.rimColor,
    required this.rimInnerColor,
    required this.surfaceColor,
    required this.surfaceGradient,
    required this.shadowColor,
    this.hasPattern = false,
    this.isDark = false,
  });

  static const List<PlateDesign> all = [
    PlateDesign(
      id: 'classic',
      name: 'Classic',
      description: 'Clean white ceramic',
      rimColor: Color(0xFFDDDDDD),
      rimInnerColor: Color(0xFFF2F2F2),
      surfaceColor: Color(0xFFFAFAFA),
      surfaceGradient: [Color(0xFFFFFFFF), Color(0xFFEEEEEE)],
      shadowColor: Color(0x35000000),
    ),
    PlateDesign(
      id: 'marble',
      name: 'Marble',
      description: 'Luxurious marble & gold',
      rimColor: Color(0xFFB8960C),
      rimInnerColor: Color(0xFFD4AF37),
      surfaceColor: Color(0xFFF5F0EB),
      surfaceGradient: [Color(0xFFFAF6F0), Color(0xFFE8DDD0)],
      shadowColor: Color(0x40B8960C),
      hasPattern: true,
    ),
    PlateDesign(
      id: 'slate',
      name: 'Dark Slate',
      description: 'Modern dark ceramic',
      rimColor: Color(0xFF333333),
      rimInnerColor: Color(0xFF555555),
      surfaceColor: Color(0xFF2A2A2A),
      surfaceGradient: [Color(0xFF3A3A3A), Color(0xFF1C1C1C)],
      shadowColor: Color(0x60000000),
      isDark: true,
    ),
    PlateDesign(
      id: 'terracotta',
      name: 'Terracotta',
      description: 'Warm rustic clay',
      rimColor: Color(0xFF7A3B1E),
      rimInnerColor: Color(0xFF9E4F2C),
      surfaceColor: Color(0xFFC06B3A),
      surfaceGradient: [Color(0xFFD4834F), Color(0xFFB85C2A)],
      shadowColor: Color(0x508B3A1E),
    ),
    PlateDesign(
      id: 'midnight',
      name: 'Midnight',
      description: 'Deep navy with stars',
      rimColor: Color(0xFF0D0D2E),
      rimInnerColor: Color(0xFF1A1A4E),
      surfaceColor: Color(0xFF0A0A22),
      surfaceGradient: [Color(0xFF141436), Color(0xFF070718)],
      shadowColor: Color(0x806600CC),
      hasPattern: true,
      isDark: true,
    ),
    PlateDesign(
      id: 'rose',
      name: 'Rose Gold',
      description: 'Elegant blush & rose gold',
      rimColor: Color(0xFFB76E79),
      rimInnerColor: Color(0xFFD4929A),
      surfaceColor: Color(0xFFFCF0F0),
      surfaceGradient: [Color(0xFFFFF0F2), Color(0xFFF5DDE0)],
      shadowColor: Color(0x40B76E79),
    ),
  ];

  static PlateDesign findById(String id) =>
      all.firstWhere((d) => d.id == id, orElse: () => all[0]);
}
