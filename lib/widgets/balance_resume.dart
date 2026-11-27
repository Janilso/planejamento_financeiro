import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/commons/formats.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/spacing.dart';
import 'package:planejamento_financeiro/widgets/resume_money.dart';

// Resumo do mês: ganhos, gastos, quanto ainda falta e o balanço.
class BalanceResume extends StatelessWidget {
  final List<BalanceModel> gains;
  final List<BalanceModel> expenses;

  const BalanceResume({
    super.key,
    this.gains = const [],
    this.expenses = const [],
  });

  double _sum(Iterable<BalanceModel> data) =>
      data.fold(0, (acum, balance) => acum + (balance.value ?? 0));

  // "Falta …" só quando há algo previsto.
  String? _hint(String prefix, List<BalanceModel> data) {
    final pending = _sum(data.where((b) => !b.realized));
    return pending > 0 ? '$prefix ${AppFormats.valueToMoney(pending)}' : null;
  }

  @override
  Widget build(BuildContext context) {
    final ganhos = _sum(gains);
    final gastos = _sum(expenses);
    final balanco = ganhos - gastos;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ResumeMoney(
                  label: 'GANHOS',
                  value: ganhos,
                  hint: _hint('Falta receber', gains),
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: ResumeMoney(
                  label: 'GASTOS',
                  value: gastos,
                  hint: _hint('Falta pagar', expenses),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.white, thickness: 2),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: ResumeMoney(
            label: 'balanço',
            value: balanco,
            center: true,
            hint: balanco < 0 ? 'Gastos acima dos ganhos' : null,
          ),
        ),
      ],
    );
  }
}
