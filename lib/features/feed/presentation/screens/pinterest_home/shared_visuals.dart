// ignore_for_file: unused_element, unused_element_parameter

part of '../pinterest_home_screen.dart';

class _PostImageFallback extends StatelessWidget {
  const _PostImageFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFAEC6CF), Color(0xFFB2D8B2)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_rounded,
          size: 40,
          color: AppTheme.ink.withValues(alpha: 0.56),
        ),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const Gap(10),
          Text(message),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF5B7FB7),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: mobile ? 10 : 16,
          sigmaY: mobile ? 10 : 16,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withValues(alpha: 0.92),
                const Color(0xFFF4FAFF).withValues(alpha: 0.78),
                const Color(0xFFFFF7FB).withValues(alpha: 0.64),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.tacticalBlue.withValues(
                alpha: mobile ? 0.18 : 0.30,
              ),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.ink.withValues(alpha: mobile ? 0.07 : 0.14),
                blurRadius: mobile ? 10 : 28,
                offset: Offset(0, mobile ? 4 : 16),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.86),
                blurRadius: 0,
                offset: const Offset(0, -1),
              ),
              if (!mobile)
                BoxShadow(
                  color: AppTheme.pastelRose.withValues(alpha: 0.14),
                  blurRadius: 30,
                  offset: const Offset(-10, 5),
                ),
              if (!mobile)
                BoxShadow(
                  color: AppTheme.pastelBlue.withValues(alpha: 0.17),
                  blurRadius: 30,
                  offset: const Offset(10, 5),
                ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                child: Container(
                  height: 2,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              Padding(padding: EdgeInsets.all(mobile ? 12 : 18), child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _PastelBackground extends StatelessWidget {
  const _PastelBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFF1FBFF),
            Color(0xFFF8F3FF),
            Color(0xFFFFF1F8),
            Color(0xFFF1FFF6),
          ],
          stops: <double>[0, 0.24, 0.52, 0.75, 1],
        ),
      ),
      child: CustomPaint(painter: _TechGridPainter(), child: SizedBox.expand()),
    );
  }
}

class _StorybookPaperPainter extends CustomPainter {
  const _StorybookPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (double y = 20; y < size.height; y += 34) {
      final path = Path()
        ..moveTo(0, y)
        ..cubicTo(
          size.width * 0.25,
          y - 8,
          size.width * 0.58,
          y + 8,
          size.width,
          y - 2,
        );
      canvas.drawPath(path, linePaint);
    }

    final glintPaint = Paint()
      ..color = AppTheme.signalYellow.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;
    _drawSparkle(canvas, Offset(size.width - 28, 24), 7, glintPaint);
    _drawSparkle(canvas, const Offset(24, 34), 5, glintPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryPaperLinesPainter extends CustomPainter {
  const _DiaryPaperLinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF91A9D8).withValues(alpha: 0.13)
      ..strokeWidth = 1;
    final marginPaint = Paint()
      ..color = const Color(0xFFE49AB3).withValues(alpha: 0.16)
      ..strokeWidth = 1.2;

    for (double y = size.height * 0.42; y < size.height - 8; y += 13) {
      canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), linePaint);
    }
    if (size.width > 72) {
      canvas.drawLine(
        Offset(size.width * 0.30, 10),
        Offset(size.width * 0.30, size.height - 10),
        marginPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryPhotoPocketPainter extends CustomPainter {
  const _DiaryPhotoPocketPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()
      ..color = const Color(0xFFCDE1FF).withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final line = Paint()
      ..color = const Color(0xFF8FAFE2).withValues(alpha: 0.20)
      ..strokeWidth = 1;
    final hill = Path()
      ..moveTo(size.width * 0.12, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.48,
        size.width * 0.60,
        size.height * 0.70,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.54,
        size.width * 0.90,
        size.height * 0.68,
      );
    canvas.drawPath(hill, blue);
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.32),
      size.shortestSide * 0.08,
      Paint()..color = const Color(0xFFFFDDE8).withValues(alpha: 0.82),
    );
    canvas.drawLine(
      Offset(size.width * 0.14, size.height * 0.84),
      Offset(size.width * 0.86, size.height * 0.84),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryWashiTapePainter extends CustomPainter {
  const _DiaryWashiTapePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.16, size.width, size.height * 0.68),
      Radius.circular(size.height * 0.26),
    );
    canvas.drawRRect(
      body,
      Paint()..color = const Color(0xFFFFF6CC).withValues(alpha: 0.82),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final stripe = Paint()
      ..color = const Color(0xFF9FC1EF).withValues(alpha: 0.28)
      ..strokeWidth = 1.2;
    for (double x = 8; x < size.width; x += 14) {
      canvas.drawLine(
        Offset(x, size.height * 0.28),
        Offset(x + 8, size.height * 0.72),
        stripe,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryPageCornerPainter extends CustomPainter {
  const _DiaryPageCornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fold = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(
      fold,
      Paint()..color = const Color(0xFFEAF3FF).withValues(alpha: 0.92),
    );
    canvas.drawPath(
      fold,
      Paint()
        ..color = const Color(0xFFBFD2EA).withValues(alpha: 0.62)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryTurnShadowPainter extends CustomPainter {
  const _DiaryTurnShadowPainter({required this.turnAmount, required this.page});

  final double turnAmount;
  final double page;

  @override
  void paint(Canvas canvas, Size size) {
    final sideBias = page <= 0.5 ? 1.0 : 0.0;
    final shadowWidth = lerpDouble(18, size.width * 0.28, turnAmount)!;
    final edgeX = lerpDouble(size.width, size.width * 0.58, turnAmount)!;
    final shadowRect = Rect.fromLTWH(
      edgeX - shadowWidth,
      0,
      shadowWidth,
      size.height,
    );
    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Colors.transparent,
          AppTheme.ink.withValues(alpha: 0.10 * turnAmount),
          Colors.white.withValues(alpha: 0.28 * turnAmount),
        ],
      ).createShader(shadowRect);
    canvas.drawRect(shadowRect, shadowPaint);

    if (turnAmount > 0.03) {
      final pageEdge = Path()
        ..moveTo(edgeX, 0)
        ..quadraticBezierTo(
          edgeX - shadowWidth * 0.38,
          size.height * 0.50,
          edgeX,
          size.height,
        );
      canvas.drawPath(
        pageEdge,
        Paint()
          ..color = const Color(
            0xFFABC3EA,
          ).withValues(alpha: (0.32 + sideBias * 0.08) * turnAmount)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiaryTurnShadowPainter oldDelegate) {
    return oldDelegate.turnAmount != turnAmount || oldDelegate.page != page;
  }
}

class _DiaryStripePainter extends CustomPainter {
  const _DiaryStripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.34);
    final soft = Paint()
      ..color = const Color(0xFFAFCBF7).withValues(alpha: 0.18);
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 13, size.height), stripe);
    }
    for (double y = size.height * 0.78; y < size.height; y += 18) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 8), soft);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryLacePainter extends CustomPainter {
  const _DiaryLacePainter({required this.compact});

  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.84)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = const Color(0xFF9FC1EF).withValues(alpha: 0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final top = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.42)
      ..lineTo(0, size.height * 0.42)
      ..close();
    canvas.drawPath(top, paint);
    canvas.drawPath(top, border);

    final radius = compact ? 8.0 : 11.0;
    for (double x = radius; x < size.width; x += radius * 1.82) {
      canvas.drawCircle(Offset(x, size.height * 0.45), radius, paint);
      canvas.drawCircle(Offset(x, size.height * 0.45), radius, border);
      canvas.drawCircle(
        Offset(x, size.height * 0.45),
        radius * 0.28,
        Paint()..color = const Color(0xFFCFE2FF),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiaryLacePainter oldDelegate) {
    return oldDelegate.compact != compact;
  }
}

class _DiaryCloudPainter extends CustomPainter {
  const _DiaryCloudPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = const Color(0xFFFFFEFA)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = const Color(0xFF8DB9EF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final dash = Paint()
      ..color = const Color(0xFFB7D4F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.14, size.height * 0.56)
      ..cubicTo(
        size.width * 0.03,
        size.height * 0.48,
        size.width * 0.08,
        size.height * 0.26,
        size.width * 0.24,
        size.height * 0.30,
      )
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.06,
        size.width * 0.52,
        size.height * 0.10,
        size.width * 0.57,
        size.height * 0.30,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.20,
        size.width * 0.88,
        size.height * 0.33,
        size.width * 0.82,
        size.height * 0.53,
      )
      ..cubicTo(
        size.width * 0.94,
        size.height * 0.62,
        size.width * 0.84,
        size.height * 0.84,
        size.width * 0.66,
        size.height * 0.78,
      )
      ..cubicTo(
        size.width * 0.50,
        size.height * 0.94,
        size.width * 0.30,
        size.height * 0.84,
        size.width * 0.27,
        size.height * 0.72,
      )
      ..cubicTo(
        size.width * 0.17,
        size.height * 0.76,
        size.width * 0.08,
        size.height * 0.68,
        size.width * 0.14,
        size.height * 0.56,
      )
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);

    for (double x = size.width * 0.20; x < size.width * 0.78; x += 12) {
      canvas.drawLine(
        Offset(x, size.height * 0.70),
        Offset(x + 4, size.height * 0.70),
        dash,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryCatEarPainter extends CustomPainter {
  const _DiaryCatEarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Paint()
      ..color = const Color(0xFFFFFEFA)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = const Color(0xFFB8CBEF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final inner = Paint()
      ..color = const Color(0xFFEAF3FF)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * 0.50, 0)
      ..quadraticBezierTo(
        size.width,
        size.height * 0.58,
        size.width * 0.74,
        size.height,
      )
      ..quadraticBezierTo(size.width * 0.34, size.height * 0.82, 0, size.height)
      ..quadraticBezierTo(
        size.width * 0.10,
        size.height * 0.36,
        size.width * 0.50,
        0,
      )
      ..close();
    final innerPath = Path()
      ..moveTo(size.width * 0.50, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.62,
        size.width * 0.58,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.66,
        size.width * 0.24,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.44,
        size.width * 0.50,
        size.height * 0.22,
      )
      ..close();
    canvas.drawPath(path, outer);
    canvas.drawPath(innerPath, inner);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryCatMouthPainter extends CustomPainter {
  const _DiaryCatMouthPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.ink.withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width / 2, size.height),
      0.1,
      2.5,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
      0.55,
      2.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryCuteMouthPainter extends CustomPainter {
  const _DiaryCuteMouthPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF69A4DD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.12),
      Offset(size.width * 0.50, size.height * 0.46),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        0,
        size.height * 0.18,
        size.width * 0.50,
        size.height * 0.72,
      ),
      0.1,
      2.45,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.50,
        size.height * 0.18,
        size.width * 0.50,
        size.height * 0.72,
      ),
      0.6,
      2.45,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryCloudBasePainter extends CustomPainter {
  const _DiaryCloudBasePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = const Color(0xFFFFFEFA)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = const Color(0xFF88B8EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.70)
      ..cubicTo(
        size.width * 0.02,
        size.height * 0.38,
        size.width * 0.22,
        size.height * 0.28,
        size.width * 0.32,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.40,
        size.height * 0.02,
        size.width * 0.70,
        size.height * 0.04,
        size.width * 0.75,
        size.height * 0.40,
      )
      ..cubicTo(
        size.width * 0.92,
        size.height * 0.30,
        size.width * 1.00,
        size.height * 0.58,
        size.width * 0.88,
        size.height * 0.78,
      )
      ..lineTo(size.width * 0.16, size.height * 0.82)
      ..cubicTo(
        size.width * 0.12,
        size.height * 0.82,
        size.width * 0.09,
        size.height * 0.78,
        size.width * 0.08,
        size.height * 0.70,
      )
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryWhiskerPainter extends CustomPainter {
  const _DiaryWhiskerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.ink.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width, size.height * 0.50),
      Offset(0, size.height * 0.16),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height * 0.58),
      Offset(0, size.height * 0.58),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height * 0.66),
      Offset(0, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TechGridPainter extends CustomPainter {
  const _TechGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.tacticalBlue.withValues(alpha: 0.028)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _drawSparkle(Canvas canvas, Offset center, double radius, Paint paint) {
  final path = Path()
    ..moveTo(center.dx, center.dy - radius)
    ..lineTo(center.dx + radius * 0.30, center.dy - radius * 0.30)
    ..lineTo(center.dx + radius, center.dy)
    ..lineTo(center.dx + radius * 0.30, center.dy + radius * 0.30)
    ..lineTo(center.dx, center.dy + radius)
    ..lineTo(center.dx - radius * 0.30, center.dy + radius * 0.30)
    ..lineTo(center.dx - radius, center.dy)
    ..lineTo(center.dx - radius * 0.30, center.dy - radius * 0.30)
    ..close();
  canvas.drawPath(path, paint);
}

InputDecoration _inputDecoration({
  required String hintText,
  required IconData icon,
}) {
  return InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.92),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  );
}
