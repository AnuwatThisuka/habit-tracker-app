import 'dart:ui';

import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool showTrend;
  final bool isIncreasing;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.showTrend = false,
    this.isIncreasing = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final shimmerGradient = LinearGradient(
      colors: [
        color.withOpacity(0.1),
        color.withOpacity(0.2),
        color.withOpacity(0.1),
      ],
      stops: [0.1, 0.5, 0.9],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      width: 160,
      height: 130,
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.05),
                ],
              )
            : shimmerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: color.withOpacity(isDarkMode ? 0.3 : 0.15),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.05)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                // Icon background design
                Positioned(
                  right: -25,
                  bottom: -25,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 35,
                        color: color.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),

                // Main content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card header with icon
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 16,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.grey[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    Spacer(),

                    // Value display
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        if (showTrend) ...[
                          SizedBox(width: 10),
                          TrendIndicator(
                            color: isIncreasing ? Colors.green : Colors.red,
                            isIncreasing: isIncreasing,
                          ),
                        ],
                      ],
                    ),

                    // Mini sparkline graph (optional visual)
                    if (showTrend)
                      Container(
                        height: 20,
                        margin: EdgeInsets.only(top: 4),
                        child: CustomPaint(
                          size: Size(100, 20),
                          painter: SparklinePainter(
                            color: color,
                            isIncreasing: isIncreasing,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TrendIndicator extends StatelessWidget {
  final Color color;
  final bool isIncreasing;

  const TrendIndicator({
    required this.color,
    required this.isIncreasing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isIncreasing ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
            size: 14,
          ),
          SizedBox(width: 2),
          Text(
            isIncreasing ? '+12%' : '-8%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final Color color;
  final bool isIncreasing;

  SparklinePainter({required this.color, required this.isIncreasing});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // Demo points - ในที่นี้เราสร้างข้อมูลตัวอย่าง
    // แต่ในแอปจริงคุณควรใช้ข้อมูลจริง
    List<double> points;
    if (isIncreasing) {
      points = [0.7, 0.5, 0.9, 0.6, 0.8, 0.9];
    } else {
      points = [0.5, 0.7, 0.4, 0.5, 0.3, 0.2];
    }

    path.moveTo(0, size.height * (1 - points[0]));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height * (1 - points[0]));

    for (int i = 1; i < points.length; i++) {
      final double x = size.width * i / (points.length - 1);
      final double y = size.height * (1 - points[i]);
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
