import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/commons/formats.dart';
import 'package:planejamento_financeiro/commons/icons.dart';
import 'package:planejamento_financeiro/extensions/string.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/repository/balance.dart';
import 'package:planejamento_financeiro/repository/injector.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/widgets/app_bar.dart';
import 'package:planejamento_financeiro/widgets/balance/enum.dart';
import 'package:planejamento_financeiro/widgets/balance_resume.dart';
import 'package:planejamento_financeiro/widgets/balance_tab_view.dart';
import 'package:planejamento_financeiro/widgets/base_modal.dart';
import 'package:planejamento_financeiro/widgets/formBalance/form_balance.dart';
import 'package:planejamento_financeiro/widgets/infiniteTabelView/infinite_tabel_view.dart';
import 'package:planejamento_financeiro/widgets/load/load.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime dateNow = DateTime.now();
  List<DateTime> months = [];
  int initialNextsPrevsMonths = 12;
  late int actualIndex;
  String typeBalancePage = TypeBalance.gains;
  final BalanceRepository _balanceRepository = appInjector
      .get<BalanceRepository>();
  List<BalanceModel> gainBalances = [
    BalanceModel(
      uuid: 'uuid',
      name: 'Salário',
      value: 1500,
      date: DateTime.now(),
      realized: true,
      type: TypeBalance.gains,
      installment: 5,
      totalInstallments: 12,
    ),
    BalanceModel(
      uuid: 'uuid',
      name: 'Venda da bicicleta',
      value: 400,
      date: DateTime.now(),
      type: TypeBalance.gains,
    ),
  ];
  List<BalanceModel> expensesBalances = [
    BalanceModel(
      uuid: 'uuid',
      name: 'Apartamento',
      value: 1300,
      date: DateTime.now(),
      realized: true,
      installment: 1,
      totalInstallments: 12,
      type: TypeBalance.expenses,
    ),
    BalanceModel(
      uuid: 'uuid',
      name: 'Condomínio',
      value: 500,
      date: DateTime.now(),
      type: TypeBalance.expenses,
    ),
  ];

  @override
  void initState() {
    super.initState();
    months = [
      ...getMoths(initialNextsPrevsMonths, dateNow, prev: true),
      dateNow,
      ...getMoths(initialNextsPrevsMonths, dateNow),
    ];
    actualIndex = months.indexWhere(
      (date) =>
          date.year == dateNow.year &&
          date.month == dateNow.month &&
          date.day == dateNow.day,
    );
  }

  List<DateTime> getMoths(
    int quantidade,
    DateTime date, {
    bool prev = false,
    int skipMonths = 0,
  }) {
    List<DateTime> newMonths = [];

    for (int i = 1; i <= quantidade; i++) {
      DateTime newDate = DateTime(
        date.year,
        prev ? date.month - (skipMonths + i) : date.month + (skipMonths + i),
        date.day,
      );
      prev ? newMonths.insert(0, newDate) : newMonths.add(newDate);
    }
    return newMonths;
  }

  String _buildTabBuilder(BuildContext context, int index) {
    return AppFormats.dateToFormat(
      months[index],
      'MMM/yy',
    ).toUpperCase().replaceAll('.', '');
  }

  void _handleChangeBalance(String typeBalance) {
    setState(() {
      typeBalancePage = typeBalance;
    });
  }

  void _handleChangeMonth([int index = 0]) {
    List<DateTime> newMonths = months;
    int newInitialIndex = index;
    DateTime actualMonth = months[index];
    bool isMorePast = index <= 3;
    bool isMoreFuture = index >= (months.length - 4);

    newMonths = [
      ...(isMorePast
          ? getMoths(initialNextsPrevsMonths, months[0], prev: true)
          : []),
      ...months,
      ...(isMoreFuture
          ? getMoths(initialNextsPrevsMonths, months[months.length - 1])
          : []),
    ];
    newInitialIndex = newMonths.indexWhere(
      (date) =>
          date.year == actualMonth.year &&
          date.month == actualMonth.month &&
          date.day == actualMonth.day,
    );

    setState(() {
      months = newMonths;
      actualIndex = newInitialIndex;
      typeBalancePage = TypeBalance.gains;
    });
  }

  Future<void> _onSubmitCreate(BalanceModel balance) async {
    final res = await _balanceRepository.createBalance(
      balance.copyWith(date: months[actualIndex]).toMap(),
    );
    print("===========>data ${res.months["JAN/25"]?.gains.first}");
  }

  Future<void> _onSubmitEdit(BalanceModel balance) async {
    final res = await _balanceRepository.editBalance(
      balance.copyWith(date: months[actualIndex]).toMap(),
    );
    print("===========>data ${res.months["JAN/25"]?.gains.first}");
  }

  @override
  Widget build(BuildContext context) {
    bool isGainTab = typeBalancePage == TypeBalance.gains;
    String title = isGainTab ? 'GANHOS' : 'GASTOS';
    Color colorState = isGainTab ? AppColors.primary : AppColors.secondary;

    return Scaffold(
      backgroundColor: colorState,
      appBar: CustomAppBar(
        title:
            "$title - ${AppFormats.dateToFormat(months[actualIndex]).capitalize()}",
        isDanger: !isGainTab,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: InfiniteTabView(
          initialIndex: actualIndex,
          length: months.length,
          onChangePage: _handleChangeMonth,
          buildTabBar: _buildTabBuilder,
          buildTabView: (context, index) {
            return FutureBuilder(
              future: _balanceRepository.getBalances(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '${snapshot.error} occured',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  );
                }
                if (snapshot.hasData) {
                  final data = snapshot
                      .data
                      ?.months[_buildTabBuilder(context, actualIndex)];

                  return Column(
                    children: [
                      BalanceResume(
                        gains: data?.gains ?? [],
                        expenses: data?.expenses ?? [],
                      ),
                      Expanded(
                        child: BalanceTabView(
                          gainBalances: data?.gains ?? [],
                          expensesBalances: data?.expenses ?? [],
                          onTabChanged: _handleChangeBalance,
                          onSubmit: _onSubmitEdit,
                        ),
                      ),
                    ],
                  );
                }
                return Center(child: AppLoad());
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => baseModal(
          context,
          FormBalance(typeBalance: typeBalancePage, onSubmit: _onSubmitCreate),
        ),
        backgroundColor: colorState,
        child: const Icon(AppIcons.plus, color: AppColors.white),
      ),
    );
  }
}
