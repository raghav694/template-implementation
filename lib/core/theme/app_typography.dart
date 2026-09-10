import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_template/core/theme/app_colors.dart';

class AppTypography {
  AppTypography._();

  /// Google Fonts family used by [textTheme]. Change via `./scripts/setup_theme.sh`.
  static const String fontFamily = 'Poppins';

  static TextStyle get _base =>
      GoogleFonts.getFont(fontFamily, color: AppColors.textPrimary);

  static TextTheme get textTheme => TextTheme(
    displayLarge: _base.copyWith(fontSize: 32, fontWeight: FontWeight.bold),
    displayMedium: _base.copyWith(fontSize: 28, fontWeight: FontWeight.bold),
    displaySmall: _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
    headlineLarge: _base.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
    headlineMedium: _base.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
    headlineSmall: _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
    titleLarge: _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
    titleMedium: _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
    titleSmall: _base.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
    bodyLarge: _base.copyWith(fontSize: 16, fontWeight: FontWeight.normal),
    bodyMedium: _base.copyWith(fontSize: 14, fontWeight: FontWeight.normal),
    bodySmall: _base.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondary,
    ),
    labelLarge: _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: _base.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
    labelSmall: _base.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
  );

  /// Content titles — brand font SemiBold at a custom size.
  static TextStyle contentTitle({double fontSize = 18}) =>
      _base.copyWith(fontSize: fontSize, fontWeight: FontWeight.w600);

  /// The same scale, resolved from the bundled font family in `pubspec.yaml`
  /// instead of `google_fonts`.
  ///
  /// Some Flutter engines (no plugin registration) cannot reach the
  /// `google_fonts` cache. Naming the bundled family keeps those surfaces
  /// on-brand. Bundled files stay Poppins unless you replace `assets/fonts/`.
  static TextTheme get staticTextTheme => _applyFamily(textTheme);

  static TextTheme _applyFamily(TextTheme theme) =>
      theme.apply(fontFamily: fontFamily, fontFamilyFallback: const <String>[]);
}
