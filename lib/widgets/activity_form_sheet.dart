import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/activity.dart';

class ActivityFormSheet extends StatefulWidget {
  final String? initialName;
  final double? initialPercentage;
  final Color? initialColor;
  final String title;
  final void Function(String name, double percentage, String colorHex) onSave;

  const ActivityFormSheet({
    super.key,
    this.initialName,
    this.initialPercentage,
    this.initialColor,
    this.title = 'Add Activity',
    required this.onSave,
  });

  @override
  State<ActivityFormSheet> createState() => _ActivityFormSheetState();
}

class _ActivityFormSheetState extends State<ActivityFormSheet> {
  late final TextEditingController _nameCtrl;
  late double _percentage;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _percentage = widget.initialPercentage ?? 20.0;
    _color = widget.initialColor ?? Activity.presetColors.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _colorHex =>
      '#${_color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 14, 24, bottomInset + 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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
            widget.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),

          // Name
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Activity name',
              hintText: 'Work, Family, Side project…',
              prefixIcon: const Icon(Icons.label_outline_rounded),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Percentage
          Row(
            children: [
              Text(
                'Plate fill',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _color,
                    thumbColor: _color,
                    overlayColor: _color.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _percentage,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (v) => setState(() => _percentage = v),
                  ),
                ),
              ),
              _PctBadge(percentage: _percentage, color: _color),
            ],
          ),
          const SizedBox(height: 16),

          // Color picker
          Text(
            'Color',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: Activity.presetColors.map((color) {
              final selected = color.value == _color.value;
              return GestureDetector(
                onTap: () => setState(() => _color = color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.55),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 17)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Save
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canSave
                  ? () {
                      widget.onSave(
                        _nameCtrl.text.trim(),
                        _percentage,
                        _colorHex,
                      );
                      Navigator.of(context).pop();
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: _color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PctBadge extends StatelessWidget {
  final double percentage;
  final Color color;
  const _PctBadge({required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 52,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        '${percentage.round()}%',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}
