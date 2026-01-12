import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pantalla para marcar 3 puntos sobre la foto y calcular el ángulo formado.
class FlexMeasurePage extends StatefulWidget {
  const FlexMeasurePage({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<FlexMeasurePage> createState() => _FlexMeasurePageState();
}

class _FlexMeasurePageState extends State<FlexMeasurePage> {
  final List<Offset> _points = [];

  void _onTap(TapDownDetails details) {
    final pos = details.localPosition;
    setState(() {
      if (_points.length == 3) _points.clear();
      _points.add(pos);
    });
  }

  double? get _angleDeg {
    if (_points.length < 3) return null;
    final a = _points[0];
    final b = _points[1];
    final c = _points[2];
    final v1 = a - b;
    final v2 = c - b;
    final mag1 = v1.distance;
    final mag2 = v2.distance;
    if (mag1 == 0 || mag2 == 0) return null;
    var cosang = (v1.dx * v2.dx + v1.dy * v2.dy) / (mag1 * mag2);
    cosang = cosang.clamp(-1.0, 1.0);
    final rad = math.acos(cosang);
    return rad * 180 / math.pi;
  }

  void _reset() => setState(() => _points.clear());

  @override
  Widget build(BuildContext context) {
    final angle = _angleDeg;
    return Scaffold(
      appBar: AppBar(title: const Text('Medir ángulo')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: _onTap,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.contain,
                        ),
                        CustomPaint(
                          painter: _PointsPainter(points: _points, angle: angle),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Toca 3 puntos: proximal, vértice, distal.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    angle == null
                        ? 'Ángulo: --'
                        : 'Ángulo: ${angle.toStringAsFixed(1)}°',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Borrar puntos'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(angle);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Listo'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointsPainter extends CustomPainter {
  _PointsPainter({required this.points, required this.angle});

  final List<Offset> points;
  final double? angle;

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.yellowAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final paintPoint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    if (points.length >= 2) {
      canvas.drawLine(points[0], points[1], paintLine);
    }
    if (points.length == 3) {
      canvas.drawLine(points[1], points[2], paintLine);
    }
    for (final p in points) {
      canvas.drawCircle(p, 6, paintPoint);
      canvas.drawCircle(p, 10, paintLine);
    }
    if (angle != null && points.length == 3) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${angle!.toStringAsFixed(1)}°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = points[1] + const Offset(8, -8);
      textPainter.paint(canvas, pos);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
