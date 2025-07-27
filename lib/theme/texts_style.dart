import 'package:flutter/widgets.dart';
import 'package:planejamento_financeiro/theme/colors.dart';

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

  static final double _sizeScale = 0.9;

  static AppTextsStyle titleLarge({
    Color? color = AppColors.white,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 24 / _sizeScale,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle titleMedium({
    Color? color = AppColors.white,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 20 / _sizeScale,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle titleSmall({
    Color? color = AppColors.white,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 18 / _sizeScale,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle bodyLarge({
    Color? color = AppColors.white,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 16 / _sizeScale,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle bodyMedium({
    Color? color = AppColors.white,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 14 / _sizeScale,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle bodySmall({
    Color? color = AppColors.white,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 12 / _sizeScale,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle labelLarge({
    Color? color = AppColors.white,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 10 / _sizeScale,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle labelMedium({
    Color? color = AppColors.white,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 8 / _sizeScale,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle labelSmall({
    Color? color = AppColors.white,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1,
    TextDecoration? decoration,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: 6 / _sizeScale,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }

  static AppTextsStyle customSize({
    Color? color = AppColors.white,
    FontWeight fontWeight = FontWeight.w400,
    double? height = 1,
    TextDecoration? decoration,
    double? fontSize,
  }) {
    return AppTextsStyle(
      color: color,
      fontSize: (fontSize ?? 10) / _sizeScale,
      fontWeight: fontWeight,
      height: height,
      decoration: decoration,
    );
  }
}
