import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/commons/formats.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/spacing.dart';

// Rótulo, valor e uma linha de apoio, em branco sobre a cor da marca.
class ResumeMoney extends StatelessWidget {
  final String label;
  final double value;
  final bool center;
  final String? hint;

  const ResumeMoney({
    super.key,
    required this.label,
    required this.value,
    this.center = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final align = center ? TextAlign.center : TextAlign.start;
    final white = textTheme.bodySmall!.copyWith(color: AppColors.white);
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: white, textAlign: align),
        const SizedBox(height: AppSpacing.xs),
        // Encolhe em vez de estourar quando o valor é muito grande.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: center ? Alignment.center : Alignment.centerLeft,
          child: Text(
            AppFormats.valueToMoney(value),
            textAlign: align,
            style: (center ? textTheme.displaySmall! : textTheme.titleLarge!)
                .copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(hint!, style: white, textAlign: align),
        ],
      ],
    );
  }
}
