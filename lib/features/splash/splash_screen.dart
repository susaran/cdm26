import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainCtrl;   // drives the entrance sequence
  late final AnimationController _orbitCtrl;  // continuous star orbit + hex spin
  late final AnimationController _pulseCtrl;  // badge glow pulse

  // Staggered entrance tweens derived from _mainCtrl
  late final Animation<double> _badgeScale;
  late final Animation<double> _badgeOpacity;
  late final Animation<double> _starsOpacity;
  late final Animation<double> _titleSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _dotsOpacity;

  static const _gold = Color(0xFFD4AF37);
  static const _darkBlue = Color(0xFF060E1A);

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..forward();
    _orbitCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);

    _badgeScale = CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut))
        .drive(Tween(begin: 0.0, end: 1.0));

    _badgeOpacity = CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn))
        .drive(Tween(begin: 0.0, end: 1.0));

    _starsOpacity = CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.3, 0.55, curve: Curves.easeIn))
        .drive(Tween(begin: 0.0, end: 1.0));

    _titleSlide = CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.42, 0.70, curve: Curves.easeOutCubic))
        .drive(Tween(begin: 48.0, end: 0.0));

    _titleOpacity = CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.42, 0.70, curve: Curves.easeOut))
        .drive(Tween(begin: 0.0, end: 1.0));

    _subtitleOpacity = CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.60, 0.82, curve: Curves.easeOut))
        .drive(Tween(begin: 0.0, end: 1.0));

    _taglineOpacity = CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.72, 0.92, curve: Curves.easeOut))
        .drive(Tween(begin: 0.0, end: 1.0));

    _dotsOpacity = CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.85, 1.0, curve: Curves.easeIn))
        .drive(Tween(begin: 0.0, end: 1.0));

    Future.delayed(const Duration(milliseconds: 3800), () {
      if (mounted) context.go('/fixtures');
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _orbitCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBlue,
      body: AnimatedBuilder(
        animation: Listenable.merge([_mainCtrl, _orbitCtrl, _pulseCtrl]),
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            // ── Animated hexagonal background ───────────────────────────────
            CustomPaint(
              painter: _HexBgPainter(
                progress: _orbitCtrl.value,
                opacity: _badgeOpacity.value * 0.6,
              ),
            ),

            // ── Shooting-star particles ──────────────────────────────────────
            CustomPaint(
              painter: _ParticlePainter(progress: _orbitCtrl.value),
            ),

            // ── Main content ─────────────────────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge
                  Opacity(
                    opacity: _badgeOpacity.value,
                    child: Transform.scale(
                      scale: _badgeScale.value,
                      child: _GallardiganBadge(
                        orbitAngle: _orbitCtrl.value * math.pi * 2,
                        pulse: _pulseCtrl.value,
                        starsOpacity: _starsOpacity.value,
                        size: 210,
                      ),
                    ),
                  ),

                  const SizedBox(height: 38),

                  // "GALLARDIGAN$"
                  Transform.translate(
                    offset: Offset(0, _titleSlide.value),
                    child: Opacity(
                      opacity: _titleOpacity.value,
                      child: const Text(
                        'GALLARDIGAN\$',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Gold divider
                  Opacity(
                    opacity: _subtitleOpacity.value,
                    child: Container(
                      width: 220,
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _gold.withValues(alpha: 0),
                            _gold,
                            _gold.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // "WORLD CUP 2026"
                  Opacity(
                    opacity: _subtitleOpacity.value,
                    child: const Text(
                      'WORLD CUP 2026',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // "FANTASY POOL"
                  Opacity(
                    opacity: _taglineOpacity.value,
                    child: const Text(
                      'FANTASY POOL',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Pulsing loading dots at bottom ───────────────────────────────
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: _dotsOpacity.value,
                child: _LoadingDots(progress: _orbitCtrl.value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THE BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _GallardiganBadge extends StatelessWidget {
  const _GallardiganBadge({
    required this.orbitAngle,
    required this.pulse,
    required this.starsOpacity,
    required this.size,
  });
  final double orbitAngle;
  final double pulse;
  final double starsOpacity;
  final double size;

  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow ring behind badge
          CustomPaint(
            size: Size(size, size),
            painter: _BadgeGlowPainter(pulse: pulse),
          ),

          // Badge circle (gradient fill + gold border)
          CustomPaint(
            size: Size(size, size),
            painter: _BadgeCirclePainter(
              orbitAngle: orbitAngle,
              starsOpacity: starsOpacity,
            ),
          ),

          // "G$" + "FANTASY" monogram
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'G\$',
                style: TextStyle(
                  color: _gold,
                  fontSize: size * 0.30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: _gold.withValues(alpha: 0.6),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              Text(
                'FANTASY',
                style: TextStyle(
                  color: _gold.withValues(alpha: 0.85),
                  fontSize: size * 0.095,
                  fontWeight: FontWeight.w700,
                  letterSpacing: size * 0.025,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeGlowPainter extends CustomPainter {
  const _BadgeGlowPainter({required this.pulse});
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final glowRadius = size.width * 0.46 + pulse * 8;
    final glowPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.12 + pulse * 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(center, glowRadius, glowPaint);
  }

  @override
  bool shouldRepaint(_BadgeGlowPainter old) => old.pulse != pulse;
}

class _BadgeCirclePainter extends CustomPainter {
  const _BadgeCirclePainter({required this.orbitAngle, required this.starsOpacity});
  final double orbitAngle;
  final double starsOpacity;

  static const _gold = Color(0xFFD4AF37);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;

    // Gradient fill
    canvas.drawCircle(
      center, r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: const [Color(0xFF1A3A6B), Color(0xFF060E1A)],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Subtle globe grid lines inside the circle
    _drawGlobeLines(canvas, center, r);

    // Outer gold ring
    canvas.drawCircle(center, r,
        Paint()
          ..color = _gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5);

    // Inner gold ring
    canvas.drawCircle(center, r * 0.86,
        Paint()
          ..color = _gold.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    // 5 orbiting gold stars
    if (starsOpacity > 0) {
      _drawOrbitingStars(canvas, center, r + 16, 5, starsOpacity);
    }
  }

  void _drawGlobeLines(Canvas canvas, Offset center, double r) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Horizontal latitude lines
    for (int i = 1; i <= 3; i++) {
      final y = center.dy - r + (i * r / 2);
      final halfWidth = math.sqrt(math.max(0, r * r - math.pow(y - center.dy, 2).toDouble()));
      canvas.drawArc(
        Rect.fromCenter(center: center, width: halfWidth * 2, height: (r - (i - 1) * r / 4) * 0.4),
        0, math.pi * 2, false, paint);
    }

    // Vertical longitude lines
    for (int i = 1; i <= 4; i++) {
      canvas.drawLine(
        Offset(center.dx + r * math.cos(i * math.pi / 4), center.dy + r * math.sin(i * math.pi / 4)),
        Offset(center.dx - r * math.cos(i * math.pi / 4), center.dy - r * math.sin(i * math.pi / 4)),
        paint,
      );
    }
  }

  void _drawOrbitingStars(Canvas canvas, Offset center, double orbitR, int count, double opacity) {
    final paint = Paint()
      ..color = _gold.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final angle = orbitAngle + (i * math.pi * 2 / count);
      final x = center.dx + orbitR * math.cos(angle);
      final y = center.dy + orbitR * math.sin(angle);
      _drawStar(canvas, Offset(x, y), 7, paint);

      // Trailing glow for each star
      canvas.drawCircle(
          Offset(x, y), 4,
          Paint()
            ..color = _gold.withValues(alpha: opacity * 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    const points = 5;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.42;
      final a = (i * math.pi / points) - math.pi / 2;
      final p = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BadgeCirclePainter old) =>
      old.orbitAngle != orbitAngle || old.starsOpacity != starsOpacity;
}

class _HexBgPainter extends CustomPainter {
  const _HexBgPainter({required this.progress, required this.opacity});
  final double progress;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final paint = Paint()
      ..color = const Color(0xFF1A3A6B).withValues(alpha: opacity * 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const hexSize = 40.0;
    final cols = (size.width / hexSize).ceil() + 2;
    final rows = (size.height / (hexSize * 0.866)).ceil() + 2;

    canvas.save();
    canvas.translate(
      size.width / 2 + math.cos(progress * math.pi * 2) * 20,
      size.height / 2 + math.sin(progress * math.pi * 2) * 12,
    );
    canvas.rotate(progress * 0.08);
    canvas.translate(-size.width / 2, -size.height / 2);

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final x = col * hexSize * 1.5;
        final y = row * hexSize * 0.866 * 2 + (col.isOdd ? hexSize * 0.866 : 0);
        _drawHex(canvas, Offset(x, y), hexSize * 0.88, paint);
      }
    }

    canvas.restore();
  }

  void _drawHex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = (i * math.pi / 3) - math.pi / 6;
      final p = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HexBgPainter old) =>
      old.progress != progress || old.opacity != opacity;
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({required this.progress});
  final double progress;

  static final _rng = math.Random(42);
  static final _particles = List.generate(
    26,
    (i) => (
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      speed: 0.15 + _rng.nextDouble() * 0.4,
      size: 0.8 + _rng.nextDouble() * 1.8,
      phase: _rng.nextDouble(),
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in _particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final x = p.x * size.width;
      final y = (p.y * size.height - t * size.height * 1.3 + size.height) % size.height;
      final alpha = (math.sin(t * math.pi)).clamp(0.0, 1.0);

      paint.color = const Color(0xFFD4AF37).withValues(alpha: alpha * 0.5);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING DOTS
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final phase = (progress * 3 - i).clamp(0.0, 1.0);
        final pulse = math.sin(phase * math.pi).clamp(0.0, 1.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 6 + pulse * 3,
          height: 6 + pulse * 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFD4AF37).withValues(alpha: 0.4 + pulse * 0.6),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE SMALL LOGO (used in overscroll / other screens)
// ─────────────────────────────────────────────────────────────────────────────

class GallardiganLogo extends StatelessWidget {
  const GallardiganLogo({super.key, this.size = 48});
  final double size;

  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFF1A3A6B), Color(0xFF060E1A)],
        ),
        border: Border.all(color: _gold, width: size * 0.04),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.3),
            blurRadius: size * 0.25,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'G\$',
            style: TextStyle(
              color: _gold,
              fontSize: size * 0.32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              height: 1.0,
            ),
          ),
          Text(
            'FANTASY',
            style: TextStyle(
              color: _gold.withValues(alpha: 0.85),
              fontSize: size * 0.115,
              fontWeight: FontWeight.w700,
              letterSpacing: size * 0.03,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
