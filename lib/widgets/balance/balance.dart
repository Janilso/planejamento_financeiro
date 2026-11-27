import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/commons/formats.dart';
import 'package:planejamento_financeiro/commons/icons.dart';
import 'package:planejamento_financeiro/extensions/string.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/widgets/balance/enum.dart';

// "Parcela 2 de 3 · Recebido": a parcela (só em parcelado) e o status em texto.
String balanceSubtitle(BalanceModel balance) {
  final String status;
  if (!balance.realized) {
    status = 'Previsto';
  } else {
    status = balance.type == TypeBalance.expenses ? 'Pago' : 'Recebido';
  }
  return [
    if (balance.isInstallmented)
      'Parcela ${balance.installment} de ${balance.totalInstallments}',
    status,
  ].join(' · ');
}

class Balance extends StatelessWidget {
  final String name;
  final String? subtitle;
  final double? value;
  final bool isDanger;
  final bool realized;
  final GestureTapCallback? onTap;

  const Balance({
    super.key,
    required this.name,
    this.subtitle,
    this.value,
    this.isDanger = false,
    this.realized = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color tone = isDanger ? AppColors.secondary : AppColors.primary;
    final textTheme = Theme.of(context).textTheme;
    // Toque na cor do tipo e retangular, do tamanho da linha.
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: tone.withAlpha(31),
        highlightColor: tone.withAlpha(20),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDanger ? AppColors.secondaryLight : AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            realized ? AppIcons.check : AppIcons.clock,
            size: 20,
            color: tone,
          ),
        ),
        title: Text(
          name.capitalize(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyLarge,
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: textTheme.bodySmall!.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
        trailing: Text(
          AppFormats.valueToMoney(value),
          style: textTheme.bodyLarge!.copyWith(
            color: tone,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
