/// Password rules aligned with ASP.NET Core Identity defaults used by LendLedger.
///
/// Backend defaults: min length 6, requires uppercase, lowercase, digit,
/// and non-alphanumeric character.
class PasswordPolicy {
  PasswordPolicy._();

  static const int minLength = 6;
  static const bool requireUppercase = true;
  static const bool requireLowercase = true;
  static const bool requireDigit = true;
  static const bool requireSpecialCharacter = true;

  static final RegExp _uppercase = RegExp(r'[A-Z]');
  static final RegExp _lowercase = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _special = RegExp(r'[^a-zA-Z0-9]');

  static List<PasswordRuleCheck> evaluate(String password) {
    return [
      PasswordRuleCheck(
        id: 'length',
        label: 'At least $minLength characters',
        met: password.length >= minLength,
      ),
      if (requireUppercase)
        PasswordRuleCheck(
          id: 'upper',
          label: 'One uppercase letter (A–Z)',
          met: _uppercase.hasMatch(password),
        ),
      if (requireLowercase)
        PasswordRuleCheck(
          id: 'lower',
          label: 'One lowercase letter (a–z)',
          met: _lowercase.hasMatch(password),
        ),
      if (requireDigit)
        PasswordRuleCheck(
          id: 'digit',
          label: 'One number (0–9)',
          met: _digit.hasMatch(password),
        ),
      if (requireSpecialCharacter)
        PasswordRuleCheck(
          id: 'special',
          label: 'One special character (!@#\$%…)',
          met: _special.hasMatch(password),
        ),
    ];
  }

  static bool isValid(String password) {
    final checks = evaluate(password);
    return checks.every((c) => c.met);
  }

  static String? validatorMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (!isValid(value)) {
      return 'Password does not meet all requirements';
    }
    return null;
  }

  static String get requirementsSummary =>
      'Use at least $minLength characters with uppercase, lowercase, a number, and a special character.';
}

class PasswordRuleCheck {
  const PasswordRuleCheck({
    required this.id,
    required this.label,
    required this.met,
  });

  final String id;
  final String label;
  final bool met;
}
