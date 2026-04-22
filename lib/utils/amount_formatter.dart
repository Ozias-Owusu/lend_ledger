class AmountFormatter {
  AmountFormatter._();

  static String compactNumber(num value) {
    final number = value.toDouble();
    final absValue = number.abs();

    if (absValue >= 1000000000000) {
      return '${_trimTrailingZeroes((number / 1000000000000).toStringAsFixed(1))}T';
    }
    if (absValue >= 1000000000) {
      return '${_trimTrailingZeroes((number / 1000000000).toStringAsFixed(1))}B';
    }
    if (absValue >= 1000000) {
      return '${_trimTrailingZeroes((number / 1000000).toStringAsFixed(1))}M';
    }
    if (absValue >= 1000) {
      return '${_trimTrailingZeroes((number / 1000).toStringAsFixed(1))}K';
    }
    return _trimTrailingZeroes(number.toStringAsFixed(2));
  }

  static String compactCurrency(
    num value, {
    String symbol = 'GHS',
    bool withSpace = true,
  }) {
    final gap = withSpace ? ' ' : '';
    return '$symbol$gap${compactNumber(value)}';
  }

  static String _trimTrailingZeroes(String value) {
    if (!value.contains('.')) return value;
    return value.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
