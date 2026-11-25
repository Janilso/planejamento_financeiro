import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/widgets/resume_money.dart';

// class BalanceResume extends StatelessWidget {
//   final List<BalanceModel> gainBalances;
//   final List<BalanceModel> expensesBalances;

//   const BalanceResume({
//     super.key,
//     this.gainBalances = const [],
//     this.expensesBalances = const [],
//   });

//   @override
//   State<BalanceResume> createState() => _BalanceResumeState();
// }

class BalanceResume extends StatelessWidget {
  final List<BalanceModel> gains;
  final List<BalanceModel> expenses;

  const BalanceResume({
    super.key,
    this.gains = const [],
    this.expenses = const [],
  });

  double _calValuesBalance(List<BalanceModel> data) {
    // double ganhos = gains.fold(
    //   0,
    //   (acum, balance) => acum + (balance.value ?? 0),
    // );
    // double gastos = expenses.fold(
    //   0,
    //   (acum, balance) => acum + (balance.value ?? 0),
    // );
    // return [ganhos, gastos];

    return data.fold(0, (acum, balance) => acum + (balance.value ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    double ganhos = _calValuesBalance(gains);
    double gastos = _calValuesBalance(expenses);
    return Column(
      children: [
        Wrap(
          spacing: 40,
          children: [
            IntrinsicWidth(
              child: ResumeMoney(label: 'GANHOS', value: ganhos),
            ),
            IntrinsicWidth(
              child: ResumeMoney(label: 'GASTOS', value: gastos),
            ),
          ],
        ),
        const Divider(color: AppColors.whiteDesable, thickness: 2),
        Center(
          child: ResumeMoney(
            label: 'balanço',
            value: ganhos - gastos,
            center: true,
          ),
        ),
      ],
    );
  }
}
