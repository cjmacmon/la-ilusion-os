import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppColors {
  static const primary = Color(0xFF1B4332);
  static const primaryLight = Color(0xFF2D6A4F);
  static const accent = Color(0xFFF59E0B);
  static const accentDark = Color(0xFFD4A017);
  static const background = Color(0xFFF0FDF4);
  static const surface = Colors.white;
  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
  static const textPrimary = Color(0xFF1B4332);
  static const textSecondary = Color(0xFF6B7280);
}

ThemeData buildAppTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );

// Colombian peso formatter: $ 1.250.000
final _copFormat = NumberFormat.currency(
  locale: 'es_CO',
  symbol: '\$ ',
  decimalDigits: 0,
);

String formatCOP(num amount) => _copFormat.format(amount);
String formatNum(num n) => NumberFormat('#,###', 'es_CO').format(n);
