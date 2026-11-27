import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/spacing.dart';
import 'package:planejamento_financeiro/widgets/load/load.dart';

// Botão principal: fundo branco com texto na cor de ganhos, ou fundo colorido
// com texto branco. O ícone, quando há, vem antes do texto.
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
    final bool isLight = backgroundColor == null;
    final Color foreground = isLight ? AppColors.primary : AppColors.white;

    return SizedBox(
      height: 50,
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: _getOnPressed(),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          elevation: 0,
          backgroundColor: isLight ? AppColors.white : backgroundColor,
          disabledBackgroundColor: isLight
              ? AppColors.white.withAlpha(200)
              : HSLColor.fromColor(backgroundColor!)
                    .withLightness(0.85)
                    .toColor(),
        ),
        child: loading
            ? SizedBox(width: 50, child: AppLoad(color: foreground))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: foreground),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge!
                          .copyWith(color: foreground),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
