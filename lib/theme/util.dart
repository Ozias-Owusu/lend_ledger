import 'package:flutter/material.dart';

/// Returns the app-wide text theme from [ThemeData].
TextTheme createTextTheme(
  BuildContext context,
  String bodyFontString,
  String displayFontString,
) {
  return Theme.of(context).textTheme;
}
