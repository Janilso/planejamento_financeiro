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
    colorScheme: colorScheme,
    inputDecorationTheme: inputDecorationTheme,
    elevatedButtonTheme: elevatedButtonTheme,
    progressIndicatorTheme: progressIndicatorTheme,
    // Cada componente usa a cor do seu contexto; o padrão é a cor de ganhos.
    splashColor: AppColors.primary.withAlpha(31),
    highlightColor: AppColors.primary.withAlpha(20),
    scaffoldBackgroundColor: AppColors.white,
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.white,
      titleTextStyle: textTheme.titleSmall!.copyWith(
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: textTheme.bodyMedium!.copyWith(
        color: AppColors.textSecondary,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.black,
        textStyle: textTheme.labelLarge,
        minimumSize: const Size(64, 48),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.white,
      modalBackgroundColor: AppColors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      foregroundColor: AppColors.white,
    ),
    // Desligado, o switch precisa aparecer sobre o branco (3:1). Ligado, as
    // cores vêm do tipo, definidas em cada campo.
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? null
            : AppColors.textSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? null : AppColors.white,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : AppColors.textSecondary,
      ),
    ),
  );

  static const ColorScheme colorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    error: AppColors.danger,
    onError: AppColors.white,
    surface: AppColors.white,
    onSurface: AppColors.black,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.grayLight,
  );

  static ThemeData darkTheme = ThemeData.dark(useMaterial3: true);

  static TextTheme textTheme = TextTheme(
    displaySmall: AppTextsStyle.displaySmall(),
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

  static UnderlineInputBorder _underline(Color color, [double width = 1]) =>
      UnderlineInputBorder(
        borderSide: BorderSide(color: color, width: width),
      );

  // Rótulo do campo: escuro, e no vermelho de perigo quando há erro.
  static WidgetStateTextStyle get _labelStyle =>
      WidgetStateTextStyle.resolveWith(
        (states) => textTheme.labelMedium!.copyWith(
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.error)
              ? AppColors.danger
              : AppColors.black,
        ),
      );

  // Rótulo sempre acima do campo; erro no vermelho de perigo.
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: _labelStyle,
    floatingLabelStyle: _labelStyle,
    hintStyle: textTheme.bodyLarge!.copyWith(color: AppColors.hint),
    errorStyle: textTheme.labelSmall!.copyWith(color: AppColors.danger),
    // O campo reserva a linha do erro com um texto em branco; o mesmo estilo
    // do erro dá à linha reservada a altura exata da linha de erro.
    helperStyle: textTheme.labelSmall,
    border: _underline(AppColors.grayLight),
    enabledBorder: _underline(AppColors.grayLight),
    focusedBorder: _underline(AppColors.textSecondary, 2),
    errorBorder: _underline(AppColors.danger),
    focusedErrorBorder: _underline(AppColors.danger, 2),
  );

  static ProgressIndicatorThemeData progressIndicatorTheme =
      const ProgressIndicatorThemeData(color: AppColors.primaryLight);
}
