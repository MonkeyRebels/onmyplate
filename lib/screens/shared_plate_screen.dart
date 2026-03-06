import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/activity.dart';
import '../models/plate.dart';
import '../services/supabase_service.dart';
import '../widgets/plate_widget.dart';

class SharedPlateScreen extends StatefulWidget {
  final String shareId;
  const SharedPlateScreen({super.key, required this.shareId});

  @override
  State<SharedPlateScreen> createState() => _SharedPlateScreenState();
}

class _SharedPlateScreenState extends State<SharedPlateScreen> {
  Plate? _plate;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlate();
  }

  Future<void> _loadPlate() async {
    try {
      final plate = await SupabaseService.getPlateByShareId(widget.shareId);
      setState(() {
        _plate = plate;
        _loading = false;
        if (plate == null) _error = 'Plate not found';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _plate == null) {
      return _ErrorView(onRetry: _loadPlate);
    }

    final plate = _plate!;
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: _bgColor(context, plate),
      body: isWide
          ? _WideSharedLayout(plate: plate)
          : _NarrowSharedLayout(plate: plate),
    );
  }

  Color _bgColor(BuildContext context, Plate plate) {
    return plate.design.isDark
        ? Color.lerp(plate.design.rimColor, Colors.black, 0.6)!
        : Theme.of(context).colorScheme.surfaceContainerLowest;
  }
}

// ─── Wide layout ──────────────────────────────────────────────────────────

class _WideSharedLayout extends StatelessWidget {
  final Plate plate;
  const _WideSharedLayout({required this.plate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _SharedTopBar(plate: plate),
              Expanded(child: Center(child: PlateWidget(plate: plate, interactive: false))),
              const _Footer(),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Container(
          width: 320,
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
          child: _ReadOnlyActivityPanel(plate: plate),
        ),
      ],
    );
  }
}

// ─── Narrow layout ────────────────────────────────────────────────────────

class _NarrowSharedLayout extends StatelessWidget {
  final Plate plate;
  const _NarrowSharedLayout({required this.plate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SharedTopBar(plate: plate),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Center(
                    child: PlateWidget(plate: plate, interactive: false),
                  ),
                ),
                _ReadOnlyActivityPanel(plate: plate),
                const _Footer(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared top bar ───────────────────────────────────────────────────────

class _SharedTopBar extends StatelessWidget {
  final Plate plate;
  const _SharedTopBar({required this.plate});

  @override
  Widget build(BuildContext context) {
    final isDark = plate.design.isDark;
    final textColor =
        isDark ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 28))
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(width: 10),
            Expanded(
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
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.visibility_outlined,
                                size: 12, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              'Read only',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Copy share link
            IconButton(
              onPressed: () => _copyLink(context),
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Copy share link',
              style: IconButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyLink(BuildContext context) {
    final url = '${Uri.base.origin}/#/share/${plate.shareId}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Link copied!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Read-only activity panel ─────────────────────────────────────────────

class _ReadOnlyActivityPanel extends StatelessWidget {
  final Plate plate;
  const _ReadOnlyActivityPanel({required this.plate});

  @override
  Widget build(BuildContext context) {
    final activities = plate.activities;
    final fallenItems = plate.fallenItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (activities.isNotEmpty) ...[
          _SectionLabel(
            title: 'On the plate',
            badge: '${plate.totalPercentage.toStringAsFixed(0)}%',
            badgeColor:
                plate.isOverflowing ? Colors.red : Colors.green.shade600,
          ),
          ...activities.asMap().entries.map((e) => _ReadOnlyActivityRow(
                activity: e.value,
                index: e.key,
              )),
        ],
        if (fallenItems.isNotEmpty) ...[
          _SectionLabel(title: 'Dropped off', badge: '${fallenItems.length}'),
          ...fallenItems.map(
            (item) => ListTile(
              dense: true,
              leading: Text(item.emoji, style: const TextStyle(fontSize: 20)),
              title: Text(
                item.name,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
          ),
        ],
        if (activities.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Nothing on this plate yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String? badge;
  final Color? badgeColor;
  const _SectionLabel({required this.title, this.badge, this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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

class _ReadOnlyActivityRow extends StatelessWidget {
  final Activity activity;
  final int index;

  const _ReadOnlyActivityRow({required this.activity, required this.index});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: activity.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: activity.color.withOpacity(0.4), blurRadius: 4)
          ],
        ),
      ),
      title: Text(
        activity.name,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Row(
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
      ),
    )
        .animate()
        .slideX(
          begin: -0.06,
          duration: 350.ms,
          delay: (index * 60).ms,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 300.ms, delay: (index * 60).ms);
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            'Made with OnMyPlate',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Plate not found',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'This plate may have been removed\nor the link is invalid.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms),
    );
  }
}
