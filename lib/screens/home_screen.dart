import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/activity.dart';
import '../models/plate.dart';
import '../providers/plate_provider.dart';
import '../widgets/activity_form_sheet.dart';
import '../widgets/fallen_item_form_sheet.dart';
import '../widgets/plate_design_picker.dart';
import '../widgets/plate_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlateProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (provider.error != null || provider.plate == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(provider.error ?? 'Something went wrong'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: provider.reload,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return _PlateEditorView(plate: provider.plate!, provider: provider);
      },
    );
  }
}

class _PlateEditorView extends StatelessWidget {
  final Plate plate;
  final PlateProvider provider;

  const _PlateEditorView({required this.plate, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: _bgColor(context),
      body: isWide
          ? _WideLayout(plate: plate, provider: provider)
          : _NarrowLayout(plate: plate, provider: provider),
    );
  }

  Color _bgColor(BuildContext context) {
    final design = plate.design;
    return design.isDark
        ? Color.lerp(design.rimColor, Colors.black, 0.6)!
        : Theme.of(context).colorScheme.surfaceContainerLowest;
  }
}

// ─── Wide (desktop / tablet landscape) layout ─────────────────────────────

class _WideLayout extends StatelessWidget {
  final Plate plate;
  final PlateProvider provider;
  const _WideLayout({required this.plate, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: plate
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _TopBar(plate: plate, provider: provider),
              Expanded(
                child: Center(
                  child: PlateWidget(plate: plate),
                ),
              ),
              _BottomActions(plate: plate, provider: provider),
              const SizedBox(height: 16),
            ],
          ),
        ),
        // Right: activity list
        Container(
          width: 340,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(-4, 0),
              ),
            ],
          ),
          child: _ActivityPanel(plate: plate, provider: provider),
        ),
      ],
    );
  }
}

// ─── Narrow (mobile / portrait) layout ────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final Plate plate;
  final PlateProvider provider;
  const _NarrowLayout({required this.plate, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopBar(plate: plate, provider: provider),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Center(child: PlateWidget(plate: plate)),
                ),
                _ActivityPanel(plate: plate, provider: provider),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        _BottomActions(plate: plate, provider: provider),
      ],
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final Plate plate;
  final PlateProvider provider;
  const _TopBar({required this.plate, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = plate.design.isDark;
    final textColor = isDark ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            // Logo
            Text(
              '🍽️',
              style: const TextStyle(fontSize: 28),
            ).animate().scale(
                  begin: const Offset(0, 0),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(width: 10),

            // Plate name (editable)
            Expanded(
              child: GestureDetector(
                onTap: () => _editName(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plate.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    _OverflowBadge(plate: plate),
                  ],
                ),
              ),
            ),

            // Share button
            _ShareButton(plate: plate, isDark: isDark),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final ctrl = TextEditingController(text: plate.name);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename plate'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Plate name'),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await provider.updateName(result.trim());
    }
    ctrl.dispose();
  }
}

class _OverflowBadge extends StatelessWidget {
  final Plate plate;
  const _OverflowBadge({required this.plate});

  @override
  Widget build(BuildContext context) {
    final total = plate.totalPercentage;
    if (total == 0) {
      return Text(
        'Empty plate — add something!',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      );
    }
    final isOver = plate.isOverflowing;
    final color = isOver ? Colors.red : Colors.green.shade600;
    final label = isOver
        ? '${total.toStringAsFixed(0)}% — overflowing!'
        : '${total.toStringAsFixed(0)}% filled';

    return Row(
      children: [
        Icon(
          isOver ? Icons.warning_amber_rounded : Icons.check_circle_outline,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: isOver ? 1200.ms : 0.ms,
          color: Colors.red.withOpacity(0.3),
        );
  }
}

// ─── Share button ─────────────────────────────────────────────────────────

class _ShareButton extends StatelessWidget {
  final Plate plate;
  final bool isDark;
  const _ShareButton({required this.plate, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: () => _share(context),
      icon: const Icon(Icons.share_rounded),
      style: IconButton.styleFrom(
        backgroundColor: isDark
            ? Colors.white.withOpacity(0.15)
            : Theme.of(context).colorScheme.primaryContainer,
      ),
      tooltip: 'Copy share link',
    );
  }

  void _share(BuildContext context) {
    final shareId = plate.shareId;
    final baseUrl = Uri.base.origin;
    final url = '$baseUrl/#/share/$shareId';
    Clipboard.setData(ClipboardData(text: url));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.link_rounded, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(child: Text('Share link copied!')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ─── Bottom action bar ────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final Plate plate;
  final PlateProvider provider;
  const _BottomActions({required this.plate, required this.provider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Change design
            _ActionChip(
              icon: Icons.palette_outlined,
              label: 'Design',
              onTap: () => _pickDesign(context),
            ),
            const SizedBox(width: 8),
            // Add fallen item
            _ActionChip(
              icon: Icons.dining_rounded,
              label: 'Drop item',
              onTap: () => _addFallenItem(context),
            ),
            const Spacer(),
            // Add activity FAB
            FloatingActionButton.extended(
              onPressed: () => _addActivity(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add activity'),
              elevation: 2,
            ),
          ],
        ),
      ),
    );
  }

  void _addActivity(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ActivityFormSheet(
        onSave: (name, pct, hex) =>
            provider.addActivity(name: name, percentage: pct, colorHex: hex),
      ),
    );
  }

  void _addFallenItem(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FallenItemFormSheet(
        onSave: (name, emoji, x, y) =>
            provider.addFallenItem(name: name, emoji: emoji, offsetX: x, offsetY: y),
      ),
    );
  }

  void _pickDesign(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PlateDesignPicker(
        selectedId: plate.designId,
        onSelected: provider.updateDesign,
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Activity panel ───────────────────────────────────────────────────────

class _ActivityPanel extends StatelessWidget {
  final Plate plate;
  final PlateProvider provider;
  const _ActivityPanel({required this.plate, required this.provider});

  @override
  Widget build(BuildContext context) {
    final activities = plate.activities;
    final fallenItems = plate.fallenItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (activities.isNotEmpty) ...[
          _SectionHeader(
            title: 'On your plate',
            badge: '${plate.totalPercentage.toStringAsFixed(0)}%',
            badgeColor: plate.isOverflowing ? Colors.red : Colors.green.shade600,
          ),
          ...activities.asMap().entries.map((e) {
            return _ActivityTile(
              key: ValueKey(e.value.id),
              activity: e.value,
              index: e.key,
              onEdit: () => _editActivity(context, e.value),
              onDelete: () => provider.deleteActivity(e.value.id),
            );
          }),
        ],
        if (fallenItems.isNotEmpty) ...[
          _SectionHeader(title: 'Dropped off', badge: '${fallenItems.length}'),
          ...fallenItems.map((item) => _FallenItemTile(
                key: ValueKey(item.id),
                emoji: item.emoji,
                name: item.name,
                onDelete: () => provider.deleteFallenItem(item.id),
              )),
        ],
        if (activities.isEmpty && fallenItems.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    'Your plate is empty.\nAdd an activity to get started!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms),
          ),
      ],
    );
  }

  void _editActivity(BuildContext context, Activity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ActivityFormSheet(
        title: 'Edit Activity',
        initialName: activity.name,
        initialPercentage: activity.percentage,
        initialColor: activity.color,
        onSave: (name, pct, hex) => provider.updateActivity(
          activity.copyWith(
            name: name,
            percentage: pct,
            color: Activity.parseColor(hex),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? badge;
  final Color? badgeColor;
  const _SectionHeader({required this.title, this.badge, this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              letterSpacing: 0.4,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? Colors.grey).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badgeColor ?? Colors.grey,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Activity activity;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActivityTile({
    super.key,
    required this.activity,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(activity.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
        leading: _ColorDot(color: activity.color),
        title: Text(
          activity.name,
          style:
              GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: _PercentBar(activity: activity),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          onPressed: onEdit,
        ),
      ),
    )
        .animate()
        .slideX(begin: -0.08, duration: 350.ms, delay: (index * 60).ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms, delay: (index * 60).ms);
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)],
      ),
    );
  }
}

class _PercentBar extends StatelessWidget {
  final Activity activity;
  const _PercentBar({required this.activity});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: activity.percentage / 100,
              backgroundColor: activity.color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(activity.color),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${activity.percentage.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: activity.color,
          ),
        ),
      ],
    );
  }
}

class _FallenItemTile extends StatelessWidget {
  final String emoji;
  final String name;
  final VoidCallback onDelete;

  const _FallenItemTile({
    super.key,
    required this.emoji,
    required this.name,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(name + emoji),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
        leading: Text(emoji, style: const TextStyle(fontSize: 22)),
        title: Text(
          name,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
              decoration: TextDecoration.lineThrough),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 16),
          onPressed: onDelete,
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

