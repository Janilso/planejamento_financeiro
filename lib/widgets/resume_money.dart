import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/commons/formats.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/texts_style.dart';

class ResumeMoney extends StatelessWidget {
  final String label;
  final double value;
  final bool center;

  const ResumeMoney({
    super.key,
    required this.label,
    required this.value,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.whiteDesable),
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
      ),
      subtitle: Text(
        AppFormats.valueToMoney(value),
        style: center
            ? AppTextsStyle.customSize(
                fontSize: 32,
                fontWeight: FontWeight.w600,
              )
            : Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w600),
        textAlign: center ? TextAlign.center : TextAlign.start,
      ),
    );
  }
}
