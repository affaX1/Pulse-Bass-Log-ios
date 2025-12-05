import 'dart:ui';

import 'package:flutter/material.dart';

class ChartPoint {
  ChartPoint({required this.date, required this.value});
  final DateTime date;
  final double value;
}

class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.points,
    required this.color,
  });
  final String title;
  final List<ChartPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: points.isEmpty
                      ? const Center(child: Text('No data yet'))
                      : CustomPaint(
                          painter: _LineChartPainter(
                            points: points,
                            color: color,
                          ),
                          child: Container(),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.points, required this.color});
  final List<ChartPoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final sorted = [...points]..sort((a, b) => a.date.compareTo(b.date));
    final minDate = sorted.first.date.millisecondsSinceEpoch.toDouble();
    final maxDate = sorted.last.date.millisecondsSinceEpoch.toDouble();
    final minValue = 1.0;
    final maxValue = 10.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < sorted.length; i++) {
      final point = sorted[i];
      final boundedValue = point.value.clamp(minValue, maxValue);
      final x = maxDate == minDate
          ? 0.0
          : (point.date.millisecondsSinceEpoch - minDate) /
                (maxDate - minDate) *
                size.width;
      final y =
          size.height -
          ((boundedValue - minValue) / (maxValue - minValue) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
