import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lend_ledger/theme/theme.dart';

typedef PinDigitCallback = void Function(String digit);
typedef PinActionCallback = void Function();

/// Animated 6-digit PIN keypad shared by setup and lock screens.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.filledCount,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.showBiometric = false,
    this.errorShake = false,
  });

  final int filledCount;
  final PinDigitCallback onDigit;
  final PinActionCallback onBackspace;
  final PinActionCallback? onBiometric;
  final bool showBiometric;
  final bool errorShake;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PinDots(count: filledCount, shake: errorShake),
        const SizedBox(height: 36),
        _KeyGrid(
          onDigit: onDigit,
          onBackspace: onBackspace,
          onBiometric: onBiometric,
          showBiometric: showBiometric,
        ),
      ],
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.count, required this.shake});

  final int count;
  final bool shake;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: shake ? 1 : 0, end: 0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (context, shakeValue, child) {
        final raw = shake ? shakeValue * 12 * (count.isOdd ? 1 : -1) : 0.0;
        final offset = raw.clamp(-14.0, 14.0);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: ClipRect(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            final filled = i < count;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: filled ? 14 : 12,
              height: filled ? 14 : 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? AppTheme.softRose
                    : AppTheme.mintGray.withValues(alpha: 0.45),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.softRose.withValues(
                      alpha: filled ? 0.4 : 0,
                    ),
                    blurRadius: filled ? 8 : 0,
                    spreadRadius: 0,
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _KeyGrid extends StatelessWidget {
  const _KeyGrid({
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.showBiometric = false,
  });

  final PinDigitCallback onDigit;
  final PinActionCallback onBackspace;
  final PinActionCallback? onBiometric;
  final bool showBiometric;

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
    return Column(
      children: [
        for (var row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: keys
                  .sublist(row * 3, row * 3 + 3)
                  .map((d) => _PinKey(label: d, onTap: () => _tap(context, d)))
                  .toList(),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            showBiometric && onBiometric != null
                ? _PinKey(
                    icon: Icons.fingerprint_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onBiometric!();
                    },
                  )
                : const SizedBox(width: 76, height: 76),
            _PinKey(label: '0', onTap: () => _tap(context, '0')),
            _PinKey(
              icon: Icons.backspace_outlined,
              onTap: () {
                HapticFeedback.selectionClick();
                onBackspace();
              },
            ),
          ],
        ),
      ],
    );
  }

  void _tap(BuildContext context, String digit) {
    HapticFeedback.lightImpact();
    onDigit(digit);
  }
}

class _PinKey extends StatefulWidget {
  const _PinKey({this.label, this.icon, required this.onTap});

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  State<_PinKey> createState() => _PinKeyState();
}

class _PinKeyState extends State<_PinKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: _pressed ? 0.55 : 0.72),
              border: Border.all(
                color: AppTheme.peach.withValues(alpha: 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.softRose.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: widget.icon != null
                  ? Icon(widget.icon, size: 28, color: AppTheme.softRose)
                  : Text(
                      widget.label!,
                      style: AppTheme.body(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
