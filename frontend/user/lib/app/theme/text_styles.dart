import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const TextStyle _base = TextStyle(
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Display
  static TextStyle get displayLarge => _base.copyWith(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle get displayMedium => _base.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static TextStyle get displaySmall =>
      _base.copyWith(fontSize: 28, fontWeight: FontWeight.w700);

  // Headline
  static TextStyle get headlineLarge =>
      _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700);

  static TextStyle get headlineMedium =>
      _base.copyWith(fontSize: 20, fontWeight: FontWeight.w700);

  static TextStyle get headlineSmall =>
      _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600);

  // Title
  static TextStyle get titleLarge =>
      _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600);

  static TextStyle get titleMedium =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600);

  static TextStyle get titleSmall =>
      _base.copyWith(fontSize: 12, fontWeight: FontWeight.w600);

  // Body
  static TextStyle get bodyLarge =>
      _base.copyWith(fontSize: 16, fontWeight: FontWeight.w400);

  static TextStyle get bodyMedium =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400);

  static TextStyle get bodySmall => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Caption
  static TextStyle get caption =>
      _base.copyWith(fontSize: 12, color: AppColors.textSecondary);

  // Inputs
  static TextStyle get inputText =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400);

  static TextStyle get inputHint =>
      _base.copyWith(fontSize: 14, color: AppColors.textSecondary);

  static TextStyle get inputHelper =>
      _base.copyWith(fontSize: 12, color: AppColors.textSecondary);

  static TextStyle get inputError => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
  );

  // Buttons
  static TextStyle get button => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  // Aliases
  static TextStyle get heading => headlineMedium;
  static TextStyle get body => bodyMedium;
}
