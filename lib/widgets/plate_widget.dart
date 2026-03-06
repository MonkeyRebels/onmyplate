import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/plate.dart';
import '../models/fallen_item.dart';
import 'plate_painter.dart';
import 'fallen_item_overlay.dart';

class PlateWidget extends StatefulWidget {
  final Plate plate;
  final bool interactive;
  final VoidCallback? onTap;

  const PlateWidget({
    super.key,
    required this.plate,
    this.interactive = true,
    this.onTap,
  });

  @override
  State<PlateWidget> createState() => _PlateWidgetState();
}

class _PlateWidgetState extends State<PlateWidget>
    with TickerProviderStateMixin {
  late AnimationController _sweepCtrl;
  late AnimationController _wobbleCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _bounceCtrl;

  late Animation<double> _sweepAnim;
  late Animation<double> _wobbleAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _bounceAnim;

  int _prevActivityCount = 0;

  @override
  void initState() {
    super.initState();
    _prevActivityCount = widget.plate.activities.length;
    _initAnimations();
    _sweepCtrl.forward();
    _updateOverflowAnimations();
  }

  void _initAnimations() {
    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _wobbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _sweepAnim = CurvedAnimation(parent: _sweepCtrl, curve: Curves.easeOutCubic);
    _wobbleAnim = Tween<double>(begin: -0.018, end: 0.018).animate(
      CurvedAnimation(parent: _wobbleCtrl, curve: Curves.easeInOut),
    );
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
    _bounceAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut),
    );
  }

  void _updateOverflowAnimations() {
    if (widget.plate.isOverflowing) {
      if (!_wobbleCtrl.isAnimating) {
        _wobbleCtrl.repeat(reverse: true);
        _glowCtrl.repeat(reverse: true);
      }
    } else {
      _wobbleCtrl.stop();
      _wobbleCtrl.animateTo(0);
      _glowCtrl.stop();
      _glowCtrl.reset();
    }
  }

  @override
  void didUpdateWidget(PlateWidget old) {
    super.didUpdateWidget(old);

    // Activity added → re-sweep
    if (widget.plate.activities.length != _prevActivityCount) {
      _prevActivityCount = widget.plate.activities.length;
      _sweepCtrl.forward(from: 0.0);
      _bounceCtrl.forward(from: 0.0);
    }

    _updateOverflowAnimations();
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    _wobbleCtrl.dispose();
    _glowCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final plateSize =
            math.min(constraints.maxWidth, constraints.maxHeight) * 0.82;
        // Extra container to show fallen items outside the plate
        final containerSize = plateSize * 1.5;

        return SizedBox(
          width: containerSize,
          height: containerSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Plate
              _buildAnimatedPlate(plateSize),
              // Fallen items
              ..._buildFallenItemWidgets(plateSize),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedPlate(double size) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _sweepAnim,
        _wobbleAnim,
        _glowAnim,
        _bounceAnim,
      ]),
      builder: (context, _) {
        return Transform.rotate(
          angle: widget.plate.isOverflowing ? _wobbleAnim.value : 0,
          child: Transform.scale(
            scale: _bounceAnim.value,
            child: GestureDetector(
              onTap: widget.interactive ? widget.onTap : null,
              child: CustomPaint(
                size: Size(size, size),
                painter: PlatePainter(
                  activities: widget.plate.activities,
                  design: widget.plate.design,
                  sweepProgress: _sweepAnim.value,
                  wobbleAngle: _wobbleAnim.value,
                  glowPulse: _glowAnim.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildFallenItemWidgets(double plateSize) {
    return widget.plate.fallenItems.map((item) {
      return _FallenItemPositioned(
        key: ValueKey(item.id),
        item: item,
        plateSize: plateSize,
        interactive: widget.interactive,
        onDelete: widget.interactive
            ? () {
                // Bubble up via callback if needed
              }
            : null,
      );
    }).toList();
  }
}

class _FallenItemPositioned extends StatelessWidget {
  final FallenItem item;
  final double plateSize;
  final bool interactive;
  final VoidCallback? onDelete;

  const _FallenItemPositioned({
    super.key,
    required this.item,
    required this.plateSize,
    required this.interactive,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final half = plateSize / 2;
    // Scale offset so 1.0 corresponds to just beyond the rim
    final rimPixels = half * 0.93;
    final x = item.offsetX * rimPixels;
    final y = item.offsetY * rimPixels;

    return Positioned(
      left: half + x - 24,
      top: half + y - 24,
      child: FallenItemOverlay(
        item: item,
        interactive: interactive,
      ),
    );
  }
}
