import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/app_theme.dart';

class MagicCursor extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double intensity;

  const MagicCursor({
    super.key,
    required this.child,
    this.enabled = true,
    this.intensity = 0.8,
  });

  @override
  State<MagicCursor> createState() => _MagicCursorState();
}

class _MagicCursorState extends State<MagicCursor> with SingleTickerProviderStateMixin {
  final List<_Particle> _particles = [];
  final Map<int, Offset> _pointers = {};
  late Ticker _ticker;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !widget.enabled) return;

    setState(() {
      // 1. Update and filter particles
      for (final p in _particles) {
        p.update();
      }
      _particles.removeWhere((p) => p.life <= 0);

      // 2. Spawn particles from active touches/hovers
      _pointers.forEach((pointerId, position) {
        // Spawn 1-2 particles per pointer per tick for a smooth density
        int count = widget.intensity > 0.5 ? 2 : 1;
        for (int i = 0; i < count; i++) {
          final angle = _random.nextDouble() * 2 * pi;
          final speed = _random.nextDouble() * 1.5 + 0.5;
          _particles.add(
            _Particle(
              position: position,
              velocity: Offset(cos(angle) * speed, sin(angle) * speed),
              color: _random.nextBool() ? AppTheme.primaryTeal : AppTheme.primaryMagenta,
              maxLife: _random.nextInt(30) + 20,
              size: _random.nextDouble() * 5.0 + 2.0,
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Listener(
      onPointerDown: (event) {
        _pointers[event.pointer] = event.localPosition;
      },
      onPointerMove: (event) {
        _pointers[event.pointer] = event.localPosition;
      },
      onPointerUp: (event) {
        _pointers.remove(event.pointer);
      },
      onPointerCancel: (event) {
        _pointers.remove(event.pointer);
      },
      onPointerHover: (event) {
        // Support mouse/stylus hovers (extremely relevant for Googlebooks/Pixel tablet)
        _pointers[event.pointer] = event.localPosition;
      },
      child: Stack(
        children: [
          widget.child,
          IgnorePointer(
            child: CustomPaint(
              painter: _MagicCursorPainter(
                particles: _particles,
                pointers: _pointers.values.toList(),
                intensity: widget.intensity,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  Offset position;
  Offset velocity;
  Color color;
  int life;
  final int maxLife;
  double size;

  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.maxLife,
    required this.size,
  }) : life = maxLife;

  void update() {
    position += velocity;
    // Slight friction
    velocity = velocity * 0.96;
    life--;
  }

  double get opacity => max(0.0, life / maxLife);
}

class _MagicCursorPainter extends CustomPainter {
  final List<_Particle> particles;
  final List<Offset> pointers;
  final double intensity;

  _MagicCursorPainter({
    required this.particles,
    required this.pointers,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // 1. Draw glowing circular halos at touch/pointer points
    for (final pointer in pointers) {
      final double radius = 70.0 * intensity;
      
      // Radial glow gradient
      final glowGradient = RadialGradient(
        colors: [
          AppTheme.primaryTeal.withValues(alpha: 0.20 * intensity),
          AppTheme.primaryMagenta.withValues(alpha: 0.08 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      );

      final rect = Rect.fromCircle(center: pointer, radius: radius);
      paint.shader = glowGradient.createShader(rect);
      canvas.drawCircle(pointer, radius, paint);

      // Core point highlight
      paint.shader = null;
      paint.color = Colors.white.withValues(alpha: 0.4 * intensity);
      canvas.drawCircle(pointer, 4.0, paint);
    }

    // 2. Draw active trailing particles
    for (final p in particles) {
      paint.color = p.color.withValues(alpha: p.opacity * intensity);
      canvas.drawCircle(p.position, p.size * p.opacity, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MagicCursorPainter oldDelegate) {
    return true; // Always repaint as particles animate
  }
}
