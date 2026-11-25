import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/texts_style.dart';

class AppTheme {
  static ThemeData defaultTheme = ThemeData(
    fontFamily: 'WorkSans',
    useMaterial3: true,
    textTheme: textTheme,
    primaryColor: AppColors.primary,
    primaryColorLight: AppColors.primaryLight,
    primaryColorDark: AppColors.black,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.white),
    inputDecorationTheme: inputDecorationTheme,
    elevatedButtonTheme: elevatedButtonTheme,
    progressIndicatorTheme: progressIndicatorTheme,
    splashColor: AppColors.secondary,
    scaffoldBackgroundColor: AppColors.white,
  );

  static ThemeData darkTheme = ThemeData.dark(useMaterial3: true);

  static TextTheme textTheme = TextTheme(
    titleLarge: AppTextsStyle.titleLarge(),
    titleMedium: AppTextsStyle.titleMedium(),
    titleSmall: AppTextsStyle.titleSmall(),
    bodyLarge: AppTextsStyle.bodyLarge(),
    bodyMedium: AppTextsStyle.bodyMedium(),
    bodySmall: AppTextsStyle.bodySmall(),
    labelLarge: AppTextsStyle.labelLarge(),
    labelMedium: AppTextsStyle.labelMedium(),
    labelSmall: AppTextsStyle.labelSmall(),
  );

  static ElevatedButtonThemeData elevatedButtonTheme = ElevatedButtonThemeData(
    style: ButtonStyle(
      textStyle: WidgetStateProperty.all(textTheme.bodyLarge),
      foregroundColor: WidgetStateProperty.all(AppColors.white),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return AppColors.grayLight;
        }
        return AppColors.primaryLight;
      }),
    ),
  );

  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    hintStyle: textTheme.bodyMedium,
  );

  static ProgressIndicatorThemeData progressIndicatorTheme =
      const ProgressIndicatorThemeData(color: AppColors.primaryLight);
}
