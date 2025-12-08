import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomIcons {
  // Colors matching the image style
  static const Color bluePrimary = Color(0xFF6366F1); // Indigo
  static const Color blueLight = Color(0xFF818CF8);
  static const Color orangePrimary = Color(0xFFFF8F6B);
  static const Color orangeLight = Color(0xFFFFA07A);
  static const Color greenAccent = Color(0xFF34D399);
  static const Color yellowSparkle = Color(0xFFFBBF24);
  static const Color purpleAccent = Color(0xFF9333EA);
}

class ErrandIcon extends StatelessWidget {
  final double size;
  
  const ErrandIcon({super.key, this.size = 48.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ErrandIconPainter(),
      ),
    );
  }
}

class DeliveryTruckIcon extends StatelessWidget {
  final double size;
  
  const DeliveryTruckIcon({super.key, this.size = 48.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: DeliveryTruckIconPainter(),
      ),
    );
  }
}

class BusServiceIcon extends StatelessWidget {
  final double size;
  
  const BusServiceIcon({super.key, this.size = 48.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: BusServiceIconPainter(),
      ),
    );
  }
}

class SedanCarIcon extends StatelessWidget {
  final double size;
  
  const SedanCarIcon({super.key, this.size = 48.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: SedanCarIconPainter(),
      ),
    );
  }
}

class ErrandIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Back purple/blue box (tilted slightly)
    final backBoxPath = Path();
    paint.color = CustomIcons.bluePrimary;
    canvas.save();
    canvas.translate(size.width * 0.2, size.height * 0.35);
    canvas.rotate(-0.1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * 0.35, size.height * 0.4),
        const Radius.circular(4),
      ),
      paint,
    );
    canvas.restore();

    // Front orange box (main package)
    paint.color = CustomIcons.orangePrimary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.3, size.height * 0.3, size.width * 0.45, size.height * 0.45),
        const Radius.circular(4),
      ),
      paint,
    );

    // Darker orange strip (tape on package)
    paint.color = const Color(0xFFE67350);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.45, size.height * 0.3, size.width * 0.15, size.height * 0.45),
      paint,
    );

    // Small green accent box/tag on top
    paint.color = CustomIcons.greenAccent;
    final tagPath = Path();
    tagPath.moveTo(size.width * 0.5, size.height * 0.2);
    tagPath.lineTo(size.width * 0.6, size.height * 0.25);
    tagPath.lineTo(size.width * 0.58, size.height * 0.32);
    tagPath.lineTo(size.width * 0.48, size.height * 0.27);
    tagPath.close();
    canvas.drawPath(tagPath, paint);

    // Yellow sparkle/star top right
    _drawStar(canvas, Offset(size.width * 0.78, size.height * 0.22), size.width * 0.08, CustomIcons.yellowSparkle);
  }

  void _drawStar(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - math.pi / 4;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      // Add inner point
      final innerAngle = angle + math.pi / 4;
      final innerX = center.dx + (size * 0.3) * math.cos(innerAngle);
      final innerY = center.dy + (size * 0.3) * math.sin(innerAngle);
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DeliveryTruckIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Cargo container (orange)
    paint.color = CustomIcons.orangePrimary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.35, size.height * 0.25, size.width * 0.5, size.height * 0.45),
        const Radius.circular(6),
      ),
      paint,
    );

    // Cargo door details
    paint.color = const Color(0xFFE67350);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.55, size.height * 0.3, size.width * 0.02, size.height * 0.35),
      paint,
    );

    // Truck cab (blue)
    paint.color = CustomIcons.bluePrimary;
    final cabPath = Path();
    cabPath.moveTo(size.width * 0.15, size.height * 0.7);
    cabPath.lineTo(size.width * 0.15, size.height * 0.45);
    cabPath.lineTo(size.width * 0.25, size.height * 0.35);
    cabPath.lineTo(size.width * 0.38, size.height * 0.35);
    cabPath.lineTo(size.width * 0.38, size.height * 0.7);
    cabPath.close();
    canvas.drawPath(cabPath, paint);

    // Windshield
    paint.color = const Color(0xFF9CA3FF);
    final windshieldPath = Path();
    windshieldPath.moveTo(size.width * 0.2, size.height * 0.45);
    windshieldPath.lineTo(size.width * 0.26, size.height * 0.36);
    windshieldPath.lineTo(size.width * 0.33, size.height * 0.36);
    windshieldPath.lineTo(size.width * 0.33, size.height * 0.45);
    windshieldPath.close();
    canvas.drawPath(windshieldPath, paint);

    // Wheels (dark circles)
    paint.color = const Color(0xFF374151);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.72), size.width * 0.08, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.72), size.width * 0.08, paint);

    // Wheel centers (lighter)
    paint.color = const Color(0xFF6B7280);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.72), size.width * 0.04, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.72), size.width * 0.04, paint);

    // Green leaf/tag on cargo
    paint.color = CustomIcons.greenAccent;
    final leafPath = Path();
    leafPath.moveTo(size.width * 0.65, size.height * 0.28);
    leafPath.quadraticBezierTo(size.width * 0.7, size.height * 0.22, size.width * 0.68, size.height * 0.18);
    leafPath.quadraticBezierTo(size.width * 0.63, size.height * 0.22, size.width * 0.65, size.height * 0.28);
    canvas.drawPath(leafPath, paint);

    // Yellow sparkle
    _drawStar(canvas, Offset(size.width * 0.78, size.height * 0.22), size.width * 0.08);
  }

  void _drawStar(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = CustomIcons.yellowSparkle
      ..style = PaintingStyle.fill;
    
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - math.pi / 4;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      final innerAngle = angle + math.pi / 4;
      final innerX = center.dx + (size * 0.3) * math.cos(innerAngle);
      final innerY = center.dy + (size * 0.3) * math.sin(innerAngle);
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BusServiceIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Bus body (blue/indigo)
    paint.color = CustomIcons.bluePrimary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.15, size.height * 0.3, size.width * 0.7, size.height * 0.45),
        const Radius.circular(8),
      ),
      paint,
    );

    // Bus roof
    paint.color = CustomIcons.blueLight;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.2, size.height * 0.25, size.width * 0.6, size.height * 0.1),
        const Radius.circular(8),
      ),
      paint,
    );

    // Windows (lighter blue sections)
    paint.color = const Color(0xFF9CA3FF);
    // Front windshield
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.2, size.height * 0.35, size.width * 0.25, size.height * 0.2),
        const Radius.circular(4),
      ),
      paint,
    );
    // Side window
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.5, size.height * 0.35, size.width * 0.3, size.height * 0.2),
        const Radius.circular(4),
      ),
      paint,
    );

    // Wheels (dark)
    paint.color = const Color(0xFF374151);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.75), size.width * 0.08, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.75), size.width * 0.08, paint);

    // Wheel centers
    paint.color = const Color(0xFF6B7280);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.75), size.width * 0.04, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.75), size.width * 0.04, paint);

    // Front bumper/grille
    paint.color = const Color(0xFF4F46E5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.18, size.height * 0.6, size.width * 0.15, size.height * 0.08),
        const Radius.circular(2),
      ),
      paint,
    );

    // Orange bow/ribbon on top
    paint.color = CustomIcons.orangePrimary;
    final bowPath = Path();
    // Left loop
    bowPath.addOval(Rect.fromCircle(center: Offset(size.width * 0.42, size.height * 0.2), radius: size.width * 0.06));
    canvas.drawPath(bowPath, paint);
    
    // Right loop
    final bowPath2 = Path();
    bowPath2.addOval(Rect.fromCircle(center: Offset(size.width * 0.58, size.height * 0.2), radius: size.width * 0.06));
    canvas.drawPath(bowPath2, paint);
    
    // Center knot
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.23), size.width * 0.04, paint);

    // Yellow sparkle
    _drawStar(canvas, Offset(size.width * 0.78, size.height * 0.22), size.width * 0.08);
  }

  void _drawStar(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = CustomIcons.yellowSparkle
      ..style = PaintingStyle.fill;
    
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - math.pi / 4;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      final innerAngle = angle + math.pi / 4;
      final innerX = center.dx + (size * 0.3) * math.cos(innerAngle);
      final innerY = center.dy + (size * 0.3) * math.sin(innerAngle);
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SedanCarIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Car body (main blue shape)
    paint.color = CustomIcons.bluePrimary;
    final carBodyPath = Path();
    
    // Bottom of car
    carBodyPath.moveTo(size.width * 0.15, size.height * 0.65);
    // Front bumper curve
    carBodyPath.lineTo(size.width * 0.2, size.height * 0.65);
    carBodyPath.lineTo(size.width * 0.22, size.height * 0.6);
    // Hood
    carBodyPath.lineTo(size.width * 0.3, size.height * 0.5);
    // Windshield
    carBodyPath.lineTo(size.width * 0.35, size.height * 0.4);
    // Roof
    carBodyPath.lineTo(size.width * 0.65, size.height * 0.4);
    // Rear windshield
    carBodyPath.lineTo(size.width * 0.7, size.height * 0.5);
    // Trunk
    carBodyPath.lineTo(size.width * 0.78, size.height * 0.6);
    // Rear bumper
    carBodyPath.lineTo(size.width * 0.8, size.height * 0.65);
    carBodyPath.lineTo(size.width * 0.85, size.height * 0.65);
    // Bottom line
    carBodyPath.lineTo(size.width * 0.85, size.height * 0.68);
    carBodyPath.lineTo(size.width * 0.15, size.height * 0.68);
    carBodyPath.close();
    canvas.drawPath(carBodyPath, paint);

    // Windows (lighter blue)
    paint.color = const Color(0xFF9CA3FF);
    // Front windshield
    final frontWindowPath = Path();
    frontWindowPath.moveTo(size.width * 0.32, size.height * 0.48);
    frontWindowPath.lineTo(size.width * 0.36, size.height * 0.42);
    frontWindowPath.lineTo(size.width * 0.48, size.height * 0.42);
    frontWindowPath.lineTo(size.width * 0.48, size.height * 0.48);
    frontWindowPath.close();
    canvas.drawPath(frontWindowPath, paint);

    // Rear window
    final rearWindowPath = Path();
    rearWindowPath.moveTo(size.width * 0.52, size.height * 0.42);
    rearWindowPath.lineTo(size.width * 0.64, size.height * 0.42);
    rearWindowPath.lineTo(size.width * 0.68, size.height * 0.48);
    rearWindowPath.lineTo(size.width * 0.52, size.height * 0.48);
    rearWindowPath.close();
    canvas.drawPath(rearWindowPath, paint);

    // Wheels (dark)
    paint.color = const Color(0xFF374151);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.68), size.width * 0.09, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.68), size.width * 0.09, paint);

    // Wheel centers (lighter)
    paint.color = const Color(0xFF6B7280);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.68), size.width * 0.045, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.68), size.width * 0.045, paint);

    // Headlights (orange accent)
    paint.color = CustomIcons.orangePrimary;
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.19, size.height * 0.58, size.width * 0.05, size.height * 0.04),
      paint,
    );

    // Tail lights (orange accent)
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.76, size.height * 0.58, size.width * 0.05, size.height * 0.04),
      paint,
    );

    // Door handle accent
    paint.color = const Color(0xFF4F46E5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.48, size.height * 0.52, size.width * 0.08, size.height * 0.02),
        const Radius.circular(1),
      ),
      paint,
    );

    // Yellow sparkle
    _drawStar(canvas, Offset(size.width * 0.78, size.height * 0.25), size.width * 0.08);
  }

  void _drawStar(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = CustomIcons.yellowSparkle
      ..style = PaintingStyle.fill;
    
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - math.pi / 4;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      final innerAngle = angle + math.pi / 4;
      final innerX = center.dx + (size * 0.3) * math.cos(innerAngle);
      final innerY = center.dy + (size * 0.3) * math.sin(innerAngle);
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
