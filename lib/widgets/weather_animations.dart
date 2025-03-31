import 'package:flutter/material.dart';
import 'dart:math' as math;

class WeatherAnimation extends StatefulWidget {
  final String weatherCondition;
  const WeatherAnimation({Key? key, required this.weatherCondition}) : super(key: key);

  @override
  State<WeatherAnimation> createState() => _WeatherAnimationState();
}

class _WeatherAnimationState extends State<WeatherAnimation> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeController;
  List<RainDrop> rainDrops = [];
  List<Snowflake> snowflakes = [];
  List<SunRay> sunRays = [];
  bool _isRaining = false;
  bool _isSnowing = false;
  bool _isSunny = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _updateWeatherCondition();
  }

  @override
  void didUpdateWidget(WeatherAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherCondition != widget.weatherCondition) {
      _updateWeatherCondition();
    }
  }

  void _updateWeatherCondition() {
    final condition = widget.weatherCondition.toLowerCase();
    
    setState(() {
      _isRaining = condition.contains('rain') || 
                   condition.contains('drizzle') || 
                   condition.contains('thunderstorm');
      _isSnowing = condition.contains('snow');
      _isSunny = condition.contains('clear');
    });

    if (_isRaining) {
      _initializeRain();
      _fadeController.forward();
    } else if (_isSnowing) {
      _initializeSnow();
      _fadeController.forward();
    } else if (_isSunny) {
      _initializeSunRays();
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  void _initializeRain() {
    rainDrops.clear();
    final random = math.Random();
    for (int i = 0; i < 200; i++) {
      rainDrops.add(RainDrop(
        x: random.nextDouble() * 2000, // Wider range for more coverage
        y: random.nextDouble() * 2000,
        speed: 15 + random.nextDouble() * 10,
        length: 20 + random.nextDouble() * 20,
        thickness: 1 + random.nextDouble() * 2,
        opacity: 0.2 + random.nextDouble() * 0.3,
      ));
    }
  }

  void _initializeSnow() {
    snowflakes.clear();
    final random = math.Random();
    for (int i = 0; i < 100; i++) {
      snowflakes.add(Snowflake(
        x: random.nextDouble() * 2000,
        y: random.nextDouble() * 2000,
        size: 2 + random.nextDouble() * 4,
        speed: 2 + random.nextDouble() * 3,
        angle: random.nextDouble() * 360,
        opacity: 0.3 + random.nextDouble() * 0.5,
      ));
    }
  }

  void _initializeSunRays() {
    sunRays.clear();
    for (int i = 0; i < 12; i++) {
      sunRays.add(SunRay(angle: i * 30.0));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: WeatherPainter(
              animation: _controller,
              isRaining: _isRaining,
              isSnowing: _isSnowing,
              isSunny: _isSunny,
              rainDrops: rainDrops,
              snowflakes: snowflakes,
              sunRays: sunRays,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class WeatherPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isRaining;
  final bool isSnowing;
  final bool isSunny;
  final List<RainDrop> rainDrops;
  final List<Snowflake> snowflakes;
  final List<SunRay> sunRays;

  WeatherPainter({
    required this.animation,
    required this.isRaining,
    required this.isSnowing,
    required this.isSunny,
    required this.rainDrops,
    required this.snowflakes,
    required this.sunRays,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (isRaining) {
      _paintRain(canvas, size);
    } else if (isSnowing) {
      _paintSnow(canvas, size);
    } else if (isSunny) {
      _paintSun(canvas, size);
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    for (var drop in rainDrops) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(drop.opacity)
        ..strokeWidth = drop.thickness
        ..strokeCap = StrokeCap.round;

      drop.y = (drop.y + drop.speed) % size.height;
      
      // Add slight wind effect
      drop.x += math.sin(animation.value * 2 * math.pi) * 0.5;
      if (drop.x < 0) drop.x = size.width;
      if (drop.x > size.width) drop.x = 0;

      // Draw main raindrop
      final path = Path();
      final dropHeight = drop.length;
      final dropWidth = drop.thickness * 2;
      
      path.moveTo(drop.x, drop.y);
      path.quadraticBezierTo(
        drop.x + dropWidth / 2,
        drop.y + dropHeight / 2,
        drop.x,
        drop.y + dropHeight,
      );
      path.quadraticBezierTo(
        drop.x - dropWidth / 2,
        drop.y + dropHeight / 2,
        drop.x,
        drop.y,
      );

      canvas.drawPath(path, paint..style = PaintingStyle.fill);

      // Add splash effect at the bottom
      if (drop.y + drop.length > size.height - 10) {
        final splashPaint = Paint()
          ..color = Colors.white.withOpacity(drop.opacity * 0.5)
          ..style = PaintingStyle.fill;

        // Draw multiple splash circles
        for (var i = 0; i < 3; i++) {
          final radius = (i + 1) * 1.5;
          final offset = (i + 1) * 2.0;
          canvas.drawCircle(
            Offset(drop.x - offset, size.height - 5),
            radius,
            splashPaint,
          );
          canvas.drawCircle(
            Offset(drop.x + offset, size.height - 5),
            radius,
            splashPaint,
          );
        }
      }
    }
  }

  void _paintSnow(Canvas canvas, Size size) {
    for (var flake in snowflakes) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(flake.opacity)
        ..style = PaintingStyle.fill;

      flake.y = (flake.y + flake.speed) % size.height;
      flake.x += math.sin(flake.angle + animation.value * 2 * math.pi) * 0.5;
      
      if (flake.x < 0) flake.x = size.width;
      if (flake.x > size.width) flake.x = 0;

      canvas.drawCircle(
        Offset(flake.x, flake.y),
        flake.size,
        paint,
      );
    }
  }

  void _paintSun(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 4);
    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Draw sun glow
    final gradient = RadialGradient(
      colors: [
        Colors.yellow.withOpacity(0.2),
        Colors.yellow.withOpacity(0.1),
        Colors.yellow.withOpacity(0),
      ],
    );

    paint.shader = gradient.createShader(
      Rect.fromCircle(center: center, radius: 100),
    );

    canvas.drawCircle(center, 100, paint);

    // Draw animated rays
    paint.shader = null;
    paint.color = Colors.yellow.withOpacity(0.2);
    paint.strokeWidth = 3;
    paint.style = PaintingStyle.stroke;

    for (var ray in sunRays) {
      final rotatedAngle = ray.angle + (animation.value * 360);
      final startPoint = Offset(
        center.dx + math.cos(rotatedAngle * math.pi / 180) * 60,
        center.dy + math.sin(rotatedAngle * math.pi / 180) * 60,
      );
      final endPoint = Offset(
        center.dx + math.cos(rotatedAngle * math.pi / 180) * 100,
        center.dy + math.sin(rotatedAngle * math.pi / 180) * 100,
      );
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RainDrop {
  double x;
  double y;
  final double speed;
  final double length;
  final double thickness;
  final double opacity;

  RainDrop({
    required this.x,
    required this.y,
    required this.speed,
    required this.length,
    required this.thickness,
    required this.opacity,
  });
}

class Snowflake {
  double x;
  double y;
  final double size;
  final double speed;
  final double angle;
  final double opacity;

  Snowflake({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.opacity,
  });
}

class SunRay {
  final double angle;

  SunRay({required this.angle});
}
