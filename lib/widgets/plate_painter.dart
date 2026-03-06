import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/plate_design.dart';

class PlatePainter extends CustomPainter {
  final List<Activity> activities;
  final PlateDesign design;
  final double sweepProgress; // 0‑1 reveal animation
  final double wobbleAngle;   // radians – shakes when overflowing
  final double glowPulse;     // 0‑1 pulse for overflow warning

  const PlatePainter({
    required this.activities,
    required this.design,
    this.sweepProgress = 1.0,
    this.wobbleAngle = 0.0,
    this.glowPulse = 0.0,
  });

  // Layout constants relative to outer radius
  static const double _rimRatio = 0.92;
  static const double _plateRatio = 0.79;
  static const double _innerGrooveRatio = 0.855;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    final rimR = outerR * _rimRatio;
    final plateR = outerR * _plateRatio;

    _drawDropShadow(canvas, center, outerR);
    _drawRim(canvas, center, outerR, rimR);
    _drawInnerGroove(canvas, center, rimR, plateR);
    _drawPlateSurface(canvas, center, plateR);

    if (design.hasPattern) {
      _drawPattern(canvas, center, plateR);
    }

    _drawActivitySegments(canvas, center, plateR * 0.97);
    _drawOverflowGlow(canvas, center, plateR);
    _drawGloss(canvas, center, plateR);
  }

  // ─── Shadow ───────────────────────────────────────────────────────────────

  void _drawDropShadow(Canvas canvas, Offset center, double r) {
    final paint = Paint()
      ..color = design.shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawOval(
      Rect.fromCenter(center: center + const Offset(3, 10), width: r * 1.9, height: r * 1.6),
      paint,
    );
  }

  // ─── Rim ──────────────────────────────────────────────────────────────────

  void _drawRim(Canvas canvas, Offset center, double outerR, double rimR) {
    // Outer edge fillet
    final edgePaint = Paint()
      ..color = design.rimColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerR, edgePaint);

    // Rim gradient
    final gradient = SweepGradient(
      colors: [
        design.rimInnerColor,
        design.rimColor,
        design.rimInnerColor.withOpacity(0.7),
        design.rimColor,
        design.rimInnerColor,
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );
    final rimPaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: outerR))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerR, rimPaint);

    // Top highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(design.isDark ? 0.06 : 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: (outerR + rimR) / 2),
      math.pi * 1.1,
      math.pi * 0.8,
      false,
      highlightPaint,
    );
  }

  // ─── Inner groove ─────────────────────────────────────────────────────────

  void _drawInnerGroove(Canvas canvas, Offset center, double rimR, double plateR) {
    final grooveR = outerRatioToRadius(center, rimR, plateR, _innerGrooveRatio);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, grooveR, shadowPaint);

    final lightPaint = Paint()
      ..color = Colors.white.withOpacity(design.isDark ? 0.05 : 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, grooveR - 2, lightPaint);
  }

  double outerRatioToRadius(Offset center, double rimR, double plateR, double ratio) {
    return plateR + (rimR - plateR) * (1 - ratio) * 2;
  }

  // ─── Plate surface ────────────────────────────────────────────────────────

  void _drawPlateSurface(Canvas canvas, Offset center, double plateR) {
    final gradient = RadialGradient(
      center: const Alignment(-0.4, -0.45),
      radius: 1.1,
      colors: design.surfaceGradient,
    );
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: plateR))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, plateR, paint);
  }

  // ─── Patterns ─────────────────────────────────────────────────────────────

  void _drawPattern(Canvas canvas, Offset center, double plateR) {
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: plateR)));

    if (design.id == 'marble') {
      _drawMarbleVeins(canvas, center, plateR);
    } else if (design.id == 'midnight') {
      _drawStars(canvas, center, plateR);
    }

    canvas.restore();
  }

  void _drawMarbleVeins(Canvas canvas, Offset center, double r) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rng = math.Random(7);
    for (var i = 0; i < 8; i++) {
      final startAngle = rng.nextDouble() * 2 * math.pi;
      final curvature = rng.nextDouble() * math.pi / 2 - math.pi / 4;
      final length = r * (0.4 + rng.nextDouble() * 0.5);
      final startDist = rng.nextDouble() * r * 0.5;

      final sx = center.dx + math.cos(startAngle) * startDist;
      final sy = center.dy + math.sin(startAngle) * startDist;
      final ex = sx + math.cos(startAngle + curvature) * length;
      final ey = sy + math.sin(startAngle + curvature) * length;
      final cx1 = sx + math.cos(startAngle + curvature / 2) * length * 0.4;
      final cy1 = sy + math.sin(startAngle + curvature / 2) * length * 0.4;

      final path = Path()
        ..moveTo(sx, sy)
        ..quadraticBezierTo(cx1, cy1, ex, ey);

      paint
        ..color = Colors.white.withOpacity(0.08 + rng.nextDouble() * 0.06)
        ..strokeWidth = 0.8 + rng.nextDouble() * 1.2;
      canvas.drawPath(path, paint);
    }
  }

  void _drawStars(Canvas canvas, Offset center, double r) {
    final rng = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 55; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final dist = rng.nextDouble() * r * 0.88;
      final x = center.dx + math.cos(angle) * dist;
      final y = center.dy + math.sin(angle) * dist;
      final size = rng.nextDouble() * 2.0 + 0.5;
      final opacity = rng.nextDouble() * 0.5 + 0.15;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), size, paint);
    }
  }

  // ─── Activity segments ────────────────────────────────────────────────────

  void _drawActivitySegments(Canvas canvas, Offset center, double plateR) {
    if (activities.isEmpty) {
      _drawEmptyHint(canvas, center, plateR);
      return;
    }

    double total = activities.fold(0.0, (s, a) => s + a.percentage);
    double startAngle = -math.pi / 2;

    for (final activity in activities) {
      // Cap display to 100% total; scale each segment proportionally if over
      double displayPct = total > 100
          ? (activity.percentage / total) * 100
          : activity.percentage;
      displayPct = displayPct.clamp(0.0, 100.0);

      final sweep = 2 * math.pi * (displayPct / 100) * sweepProgress;
      if (sweep <= 0) continue;

      _drawSegment(canvas, center, plateR, startAngle, sweep, activity);
      startAngle += sweep;
    }

    // Overflow indicator (pulsing red ring)
    if (total > 100) {
      _drawOverflowSegmentIndicator(canvas, center, plateR, total);
    }
  }

  void _drawSegment(
    Canvas canvas,
    Offset center,
    double r,
    double startAngle,
    double sweepAngle,
    Activity activity,
  ) {
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: r), startAngle, sweepAngle, false)
      ..close();

    // Filled segment
    canvas.drawPath(
      path,
      Paint()
        ..color = activity.color.withOpacity(design.isDark ? 0.88 : 0.82)
        ..style = PaintingStyle.fill,
    );

    // Inner gradient overlay for depth
    final gradientPath = path;
    final innerGrad = RadialGradient(
      center: const Alignment(0, -0.2),
      colors: [Colors.white.withOpacity(0.12), Colors.transparent],
    );
    canvas.drawPath(
      gradientPath,
      Paint()
        ..shader = innerGrad.createShader(Rect.fromCircle(center: center, radius: r))
        ..style = PaintingStyle.fill,
    );

    // Divider lines
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(design.isDark ? 0.2 : 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Label if segment is large enough
    if (sweepAngle > 0.28 && sweepProgress > 0.7) {
      _drawSegmentLabel(canvas, center, r, startAngle, sweepAngle, activity);
    }
  }

  void _drawSegmentLabel(
    Canvas canvas,
    Offset center,
    double r,
    double startAngle,
    double sweepAngle,
    Activity activity,
  ) {
    final mid = startAngle + sweepAngle / 2;
    final labelR = r * 0.60;
    final pos = Offset(
      center.dx + math.cos(mid) * labelR,
      center.dy + math.sin(mid) * labelR,
    );

    // Background pill
    final pct = activity.percentage.toStringAsFixed(0);
    final label = activity.name.length > 12
        ? '${activity.name.substring(0, 11)}…'
        : activity.name;

    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label\n',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
              shadows: [Shadow(blurRadius: 4, color: Colors.black38)],
            ),
          ),
          TextSpan(
            text: '$pct%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              shadows: const [Shadow(blurRadius: 3, color: Colors.black38)],
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 72);

    textPainter.paint(
      canvas,
      pos - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawEmptyHint(Canvas canvas, Offset center, double r) {
    final paint = Paint()
      ..color = (design.isDark ? Colors.white : Colors.grey).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    _dashedCircle(canvas, center, r * 0.45, paint, dashLen: 10, gapLen: 6);
  }

  void _dashedCircle(
    Canvas canvas,
    Offset center,
    double r,
    Paint paint, {
    double dashLen = 8,
    double gapLen = 5,
  }) {
    final dashAngle = dashLen / r;
    final gapAngle = gapLen / r;
    double angle = 0;
    while (angle < 2 * math.pi) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        angle,
        dashAngle,
        false,
        paint,
      );
      angle += dashAngle + gapAngle;
    }
  }

  void _drawOverflowSegmentIndicator(
    Canvas canvas,
    Offset center,
    double r,
    double total,
  ) {
    final overflow = ((total - 100) / 100).clamp(0.0, 1.0);
    canvas.drawCircle(
      center,
      r,
      Paint()..color = Colors.red.withOpacity(0.07 + overflow * 0.08),
    );
  }

  // ─── Overflow glow ────────────────────────────────────────────────────────

  void _drawOverflowGlow(Canvas canvas, Offset center, double r) {
    if (glowPulse <= 0) return;

    final paint = Paint()
      ..color = Colors.redAccent.withOpacity(0.45 * glowPulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 + glowPulse * 2
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + glowPulse * 4);
    canvas.drawCircle(center, r * 0.98, paint);
  }

  // ─── Gloss ────────────────────────────────────────────────────────────────

  void _drawGloss(Canvas canvas, Offset center, double r) {
    final gradient = RadialGradient(
      center: const Alignment(-0.45, -0.55),
      radius: 0.65,
      colors: [
        Colors.white.withOpacity(design.isDark ? 0.08 : 0.22),
        Colors.white.withOpacity(0.04),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: r))
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(PlatePainter old) =>
      old.activities != activities ||
      old.design != design ||
      old.sweepProgress != sweepProgress ||
      old.wobbleAngle != wobbleAngle ||
      old.glowPulse != glowPulse;
}
