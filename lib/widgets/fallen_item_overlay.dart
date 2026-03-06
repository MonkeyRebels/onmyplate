import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/fallen_item.dart';

class FallenItemOverlay extends StatelessWidget {
  final FallenItem item;
  final bool interactive;

  const FallenItemOverlay({
    super.key,
    required this.item,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.name,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            item.emoji,
            style: const TextStyle(fontSize: 22),
          ),
        ),
      ),
    )
        .animate()
        .slideY(
          begin: -4,
          end: 0,
          duration: 700.ms,
          curve: Curves.bounceOut,
        )
        .rotate(
          begin: -0.2,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 250.ms)
        .then(delay: 2000.ms)
        .shimmer(duration: 600.ms, color: Colors.white24);
  }
}
