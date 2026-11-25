import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/texts_style.dart';
import 'package:planejamento_financeiro/widgets/load/load.dart';

class AppButton extends StatelessWidget {
  final String text;
  final GestureTapCallback? onPressed;
  final double? width;
  final bool disabled;
  final bool loading;
  final IconData? icon;
  final Color? backgroundColor;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.disabled = false,
    this.loading = false,
    this.icon,
    this.backgroundColor,
  });

  GestureTapCallback? _getOnPressed() {
    if (loading || disabled) return null;
    return onPressed;
  }

  @override
  Widget build(BuildContext context) {
    bool isLight = backgroundColor == null;

    return SizedBox(
      height: 50,
      width: width ?? double.infinity,
      child: ElevatedButton.icon(
        icon: (icon != null && !loading)
            ? Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Icon(
                  icon,
                  color: isLight ? AppColors.primary : AppColors.white,
                ),
              )
            : null,
        iconAlignment: IconAlignment.end,
        onPressed: _getOnPressed(),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          elevation: 0,
          backgroundColor: isLight ? AppColors.white : backgroundColor,
          disabledBackgroundColor: isLight
              ? AppColors.white.withAlpha(200)
              : HSLColor.fromColor(
                  backgroundColor!,
                ).withLightness((0.85).clamp(0.0, 1.0)).toColor(),
        ),
        label: _buildText(
          color: isLight ? AppColors.primary : AppColors.white,
          isLight: isLight,
        ),
      ),
    );
  }

  Widget _buildText({Color color = AppColors.white, isLight}) {
    if (loading) {
      return _buildLoading(color: isLight ? AppColors.primary : color);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) SizedBox(width: 48),
        Text(text, style: AppTextsStyle.bodyLarge(color: color)),
      ],
    );
  }

  Widget _buildLoading({Color? color}) {
    return SizedBox(width: 50, child: AppLoad(color: color!));
  }
}
