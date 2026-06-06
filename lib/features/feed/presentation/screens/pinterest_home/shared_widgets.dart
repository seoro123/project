// ignore_for_file: unused_element, unused_element_parameter

part of '../pinterest_home_screen.dart';

class _SocialPostTag extends StatelessWidget {
  const _SocialPostTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.pastelBlue.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.26),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 170),
          child: Text(
            text,
            textAlign: TextAlign.center,
            softWrap: true,
            style: const TextStyle(
              color: AppTheme.tacticalBlue,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _FigmaGradientButton extends StatelessWidget {
  const _FigmaGradientButton({
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
    this.icon,
  });

  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    final effectiveColors = colors;
    return _PressableScale(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: effectiveColors),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: mobile ? 0.10 : 0.18),
              blurRadius: mobile ? 10 : 20,
              offset: Offset(0, mobile ? 5 : 13),
            ),
            BoxShadow(
              color: colors.first.withValues(alpha: mobile ? 0.13 : 0.24),
              blurRadius: mobile ? 12 : 24,
              offset: Offset(mobile ? -4 : -8, mobile ? 3 : 6),
            ),
            BoxShadow(
              color: colors.last.withValues(alpha: mobile ? 0.12 : 0.22),
              blurRadius: mobile ? 12 : 24,
              offset: Offset(mobile ? 4 : 8, mobile ? 3 : 5),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.26),
                      Colors.transparent,
                      AppTheme.pastelRose.withValues(alpha: 0.10),
                    ],
                  ),
                ),
              ),
            ),
            if (!mobile) const Positioned.fill(child: _CornerBrackets()),
            if (icon != null && !mobile)
              Positioned(
                right: mobile ? -8 : -7,
                bottom: mobile ? -10 : -11,
                child: Icon(
                  icon,
                  size: mobile ? 50 : 76,
                  color: Colors.white.withValues(alpha: mobile ? 0.12 : 0.18),
                ),
              ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: mobile ? 14 : 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null && mobile) ...<Widget>[
                      Icon(
                        icon,
                        size: 30,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                      const Gap(12),
                    ],
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: mobile ? 19 : null,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Gap(mobile ? 8 : 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w800,
                        fontSize: mobile ? 15 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.94 : (_hovered ? 1.018 : 1.0);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 135),
          curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
          child: AnimatedRotation(
            turns: _pressed ? -0.003 : (_hovered ? 0.0015 : 0),
            duration: const Duration(milliseconds: 135),
            curve: Curves.easeOutCubic,
            child: AnimatedSlide(
              offset: _pressed ? const Offset(0, 0.032) : Offset.zero,
              duration: const Duration(milliseconds: 135),
              curve: Curves.easeOutCubic,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  void onTap() {
    Feedback.forTap(context);
    SystemSound.play(SystemSoundType.click);
    widget.onTap();
  }
}

class _DimensionalCardSlot extends StatelessWidget {
  const _DimensionalCardSlot({
    required this.index,
    required this.child,
    this.depth = 1,
  });

  final int index;
  final Widget child;
  final double depth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3 * depth),
      child: child,
    );
  }
}

class _RaisedDiaryPanel extends StatelessWidget {
  const _RaisedDiaryPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFA).withValues(alpha: mobile ? 0.96 : 0.92),
        border: Border.all(
          color: const Color(0xFFE7D8F2).withValues(alpha: mobile ? 0.82 : 1),
          width: mobile ? 1 : 1.5,
        ),
        borderRadius: BorderRadius.circular(mobile ? 12 : 10),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(
              alpha: mobile ? 0.06 : 0.08,
            ),
            blurRadius: mobile ? 10 : 16,
            offset: Offset(0, mobile ? 4 : 8),
          ),
          if (!mobile)
            BoxShadow(
              color: const Color(0xFFFFF1C8).withValues(alpha: 0.36),
              blurRadius: 18,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(mobile ? 12 : 8),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.60),
                      Colors.transparent,
                      const Color(0xFFFFF5E2).withValues(alpha: 0.30),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: const _DiaryPaperLinesPainter()),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(mobile ? 10 : 14),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FigmaEmptyCard extends StatelessWidget {
  const _FigmaEmptyCard({required this.data});

  final _FigmaCardData data;

  @override
  Widget build(BuildContext context) {
    final description = data.description?.trim();
    final subtext = data.subtext?.trim();
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.13),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.68),
          border: Border.all(color: const Color(0xFF9FC4FF), width: 1.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8FF).withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: AppTheme.tacticalBlue.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Stack(
                    children: <Widget>[
                      const Positioned.fill(child: _CornerBrackets()),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.image_rounded,
                              color: AppTheme.tacticalBlue.withValues(
                                alpha: 0.55,
                              ),
                              size: 25,
                            ),
                            const Gap(5),
                            Text(
                              data.placeholder,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF75A8FF),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(8),
              Text(
                data.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.graphite,
                  fontSize: 12.5,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (description != null && description.isNotEmpty) ...<Widget>[
                const Gap(5),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.ink.withValues(alpha: 0.62),
                    fontSize: 10.5,
                    height: 1.22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              if (subtext != null && subtext.isNotEmpty) ...<Widget>[
                const Gap(5),
                Text(
                  subtext,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.tacticalBlue,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FigmaDropdown extends StatelessWidget {
  const _FigmaDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: _figmaField(label),
      items: values.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Center(child: Text(item, textAlign: TextAlign.center)),
        );
      }).toList(),
      onChanged: (String? next) {
        if (next != null) {
          Feedback.forTap(context);
          SystemSound.play(SystemSoundType.click);
          onChanged(next);
        }
      },
    );
  }
}

class _FigmaSmallField extends StatelessWidget {
  const _FigmaSmallField({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        border: Border.all(color: const Color(0xFFACCCFF)),
        borderRadius: BorderRadius.circular(6),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF6EA3FF)),
        ),
      ),
    );
  }
}

class _TerminalTitle extends StatelessWidget {
  const _TerminalTitle({
    required this.eyebrow,
    required this.title,
    required this.code,
  });

  final String eyebrow;
  final String title;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 6,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.tacticalBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Gap(10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                eyebrow,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.graphite.withValues(alpha: 0.58),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.graphite,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        _StatusChip(icon: Icons.tag_rounded, label: code),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.tacticalBlue.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 13, color: AppTheme.signalYellow),
            const Gap(4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _CornerBracketPainter()));
  }
}

class _CornerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const length = 18.0;
    const inset = 8.0;

    canvas
      ..drawLine(
        const Offset(inset, inset),
        const Offset(inset + length, inset),
        paint,
      )
      ..drawLine(
        const Offset(inset, inset),
        const Offset(inset, inset + length),
        paint,
      )
      ..drawLine(
        Offset(size.width - inset, inset),
        Offset(size.width - inset - length, inset),
        paint,
      )
      ..drawLine(
        Offset(size.width - inset, inset),
        Offset(size.width - inset, inset + length),
        paint,
      )
      ..drawLine(
        Offset(inset, size.height - inset),
        Offset(inset + length, size.height - inset),
        paint,
      )
      ..drawLine(
        Offset(inset, size.height - inset),
        Offset(inset, size.height - inset - length),
        paint,
      )
      ..drawLine(
        Offset(size.width - inset, size.height - inset),
        Offset(size.width - inset - length, size.height - inset),
        paint,
      )
      ..drawLine(
        Offset(size.width - inset, size.height - inset),
        Offset(size.width - inset, size.height - inset - length),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FigmaPill extends StatelessWidget {
  const _FigmaPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF82A8F6), Color(0xFFAEC6CF)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.76)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF82A8F6).withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FigmaTinyTag extends StatelessWidget {
  const _FigmaTinyTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF).withValues(alpha: 0.88),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.54),
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.tacticalBlue,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FigmaPastelWash extends StatelessWidget {
  const _FigmaPastelWash();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFF4FBFF),
            Color(0xFFFFF7FB),
            Color(0xFFF5FFF7),
          ],
          stops: <double>[0, 0.42, 0.76, 1],
        ),
      ),
    );
  }
}

InputDecoration _figmaField(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFA4A4C8)),
    filled: true,
    fillColor: const Color(0xFFFFFEFA).withValues(alpha: 0.88),
    contentPadding: const EdgeInsets.all(12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFE2D5EF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFE2D5EF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFD68BA8), width: 1.7),
    ),
  );
}

class _FigmaCardData {
  const _FigmaCardData(
    this.label,
    this.placeholder, {
    this.description,
    this.subtext,
  });

  final String label;
  final String placeholder;
  final String? description;
  final String? subtext;
}
