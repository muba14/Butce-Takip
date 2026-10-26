import 'package:flutter/material.dart';

import '../models.dart';

/// Lacivert cüzdan, arkasında iki mavi kart, ortada beyaz "BT".
class LogoMark extends StatelessWidget {
  final double size;
  const LogoMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _LogoPainter());
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.scale(s);

    final card1 = Path()
      ..moveTo(22, 30)
      ..lineTo(64, 12)
      ..quadraticBezierTo(70, 10, 71, 16)
      ..lineTo(74, 30)
      ..close();
    canvas.drawPath(card1, Paint()..color = AppColors.blueDark);

    final card2 = Path()
      ..moveTo(28, 32)
      ..lineTo(74, 20)
      ..quadraticBezierTo(79, 19, 79, 25)
      ..lineTo(79, 34)
      ..close();
    canvas.drawPath(card2, Paint()..color = AppColors.blue);

    final navy = Paint()..color = AppColors.navy;
    canvas.drawRRect(
        RRect.fromLTRBR(10, 32, 88, 90, const Radius.circular(10)), navy);

    final clasp = RRect.fromLTRBR(70, 51, 92, 69, const Radius.circular(5));
    canvas.drawRRect(clasp, navy);
    canvas.drawRRect(
        clasp,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    canvas.drawCircle(const Offset(78, 60), 3.2, Paint()..color = Colors.white);

    final tp = TextPainter(
      text: const TextSpan(
        text: 'BT',
        style: TextStyle(
            color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(40 - tp.width / 2, 61 - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
