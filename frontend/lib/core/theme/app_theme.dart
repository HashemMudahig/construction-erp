import "package:flutter/material.dart";

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF1565C0),
    );
  }
}