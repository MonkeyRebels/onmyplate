import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/fallen_item.dart';

class FallenItemFormSheet extends StatefulWidget {
  final void Function(
    String name,
    String emoji,
    double offsetX,
    double offsetY,
  ) onSave;

  const FallenItemFormSheet({super.key, required this.onSave});

  @override
  State<FallenItemFormSheet> createState() => _FallenItemFormSheetState();
}

class _FallenItemFormSheetState extends State<FallenItemFormSheet> {
  final _nameCtrl = TextEditingController();
  String _emoji = FallenItem.emojiOptions.first;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 14, 24, bottomInset + 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Drop it off your plate',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'What are you letting go of?',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: scheme.onSurface.withOpacity(0.55)),
          ),
          const SizedBox(height: 18),

          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'What are you dropping?',
              hintText: 'That extra project, late emails…',
              prefixText: '$_emoji  ',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),

          Text(
            'Pick an emoji',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FallenItem.emojiOptions.map((e) {
              final sel = e == _emoji;
              return GestureDetector(
                onTap: () => setState(() => _emoji = e),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sel
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: sel
                        ? Border.all(color: scheme.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _nameCtrl.text.trim().isEmpty
                  ? null
                  : () {
                      // Place item at random position around the rim
                      final rng = math.Random();
                      final angle = rng.nextDouble() * 2 * math.pi;
                      final dist = 1.18 + rng.nextDouble() * 0.25;
                      widget.onSave(
                        _nameCtrl.text.trim(),
                        _emoji,
                        math.cos(angle) * dist,
                        math.sin(angle) * dist,
                      );
                      Navigator.of(context).pop();
                    },
              icon: const Text('🗑️', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Drop it!',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
