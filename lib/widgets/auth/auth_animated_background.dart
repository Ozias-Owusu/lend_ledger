import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lend_ledger/theme/theme.dart';

/// Soft drifting orbs behind auth screens — matches [AppTheme] palette.
class AuthAnimatedBackground extends StatefulWidget {
  const AuthAnimatedBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AuthAnimatedBackground> createState() => _AuthAnimatedBackgroundState();
}

class _AuthAnimatedBackgroundState extends State<AuthAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * math.pi;
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFAF8),
                    Color(0xFFF8EDE6),
                    Color(0xFFE8F0EC),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
            _Orb(
              color: AppTheme.softRose.withValues(alpha: 0.35),
              size: 220,
              offset: Offset(
                -40 + math.sin(t) * 28,
                80 + math.cos(t * 0.8) * 22,
              ),
            ),
            _Orb(
              color: AppTheme.peach.withValues(alpha: 0.42),
              size: 180,
              offset: Offset(
                MediaQuery.sizeOf(context).width - 120 + math.cos(t * 1.1) * 24,
                160 + math.sin(t * 0.9) * 30,
              ),
            ),
            _Orb(
              color: AppTheme.mintGray.withValues(alpha: 0.38),
              size: 260,
              offset: Offset(
                40 + math.sin(t * 0.7) * 32,
                MediaQuery.sizeOf(context).height * 0.55 +
                    math.cos(t) * 26,
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.color,
    required this.size,
    required this.offset,
  });

  final Color color;
  final double size;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
