import 'package:flutter/material.dart';
import 'package:lend_ledger/core/auth/password_policy.dart';
import 'package:lend_ledger/theme/theme.dart';

/// Live checklist shown while the user types a new password.
class PasswordRequirementsPanel extends StatelessWidget {
  const PasswordRequirementsPanel({
    super.key,
    required this.password,
    this.visible = true,
  });

  final String password;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final checks = PasswordPolicy.evaluate(password);

    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: visible
          ? Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppTheme.peach.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.mintGray.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password must include:',
                    style: AppTheme.body(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5C504D),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...checks.map(
                    (check) => _RuleRow(
                      key: ValueKey('${check.id}_${check.met}'),
                      label: check.label,
                      met: check.met,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    super.key,
    required this.label,
    required this.met,
  });

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: met
                  ? const Color(0xFF6B9B7A).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.6),
              border: Border.all(
                color: met ? const Color(0xFF6B9B7A) : const Color(0xFFC4B5B0),
                width: 1.4,
              ),
            ),
            child: met
                ? const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Color(0xFF4D7A5C),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: AppTheme.body(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: met ? FontWeight.w600 : FontWeight.w500,
                color: met
                    ? const Color(0xFF4D7A5C)
                    : const Color(0xFF7A6E6A),
              ),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
