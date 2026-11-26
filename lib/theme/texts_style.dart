import 'package:flutter/widgets.dart';
import 'package:planejamento_financeiro/theme/colors.dart';

// Estilos de texto em WorkSans, com tamanhos reais em sp
// (docs/tema-e-layout.md). O padrão é o texto principal escuro.
class AppTextsStyle extends TextStyle {
  const AppTextsStyle({
    super.inherit,
    super.color,
    super.backgroundColor,
    super.fontSize,
    super.fontWeight,
    super.fontStyle,
    super.letterSpacing,
    super.wordSpacing,
    super.textBaseline,
    super.leadingDistribution,
    super.locale,
    super.foreground,
    super.background,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.debugLabel,
    super.overflow,
    super.height,
  }) : super(fontFamily: "WorkSans");

  static AppTextsStyle displaySmall({
    Color? color = AppColors.black,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1.2,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 36,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle titleLarge({
    Color? color = AppColors.black,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1.2,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 26,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle titleMedium({
    Color? color = AppColors.black,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1.25,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 22,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle titleSmall({
    Color? color = AppColors.black,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1.3,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 20,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle bodyLarge({
    Color? color = AppColors.black,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1.3,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 18,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle bodyMedium({
    Color? color = AppColors.black,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1.5,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 16,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle bodySmall({
    Color? color = AppColors.black,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1.4,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 13,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle labelLarge({
    Color? color = AppColors.black,
    FontWeight fontWeight = FontWeight.w600,
    double? height = 1.25,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 16,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle labelMedium({
    Color? color = AppColors.black,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1.4,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 14,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle labelSmall({
    Color? color = AppColors.black,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1.4,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 12,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }
}
