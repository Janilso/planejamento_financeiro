import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/repository/auth.dart';
import 'package:planejamento_financeiro/screens/login.dart';
import 'package:planejamento_financeiro/commons/formats.dart';
import 'package:planejamento_financeiro/commons/icons.dart';
import 'package:planejamento_financeiro/commons/months.dart';
import 'package:planejamento_financeiro/extensions/string.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/models/month_balance.dart';
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
  const HomeScreen({super.key, this.repository, this.clock, this.onLogout});

  final BalanceRepository? repository;
  final DateTime Function()? clock;
  // Padrão: sai da API, do Firebase e do Google e volta para o login.
  final Future<void> Function()? onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime dateNow = (widget.clock ?? DateTime.now)();
  List<DateTime> months = [];
  int initialNextsPrevsMonths = 12;
  late int actualIndex;
  String typeBalancePage = TypeBalance.gains;
  late final BalanceRepository _balanceRepository =
      widget.repository ?? appInjector.get<BalanceRepository>();
  // Uma busca só por carregamento; todas as abas de mês usam o mesmo resultado.
  late Future<MonthBalanceModel> _balances;

  @override
  void initState() {
    super.initState();
    months = monthsAround(
      dateNow,
      before: initialNextsPrevsMonths,
      after: initialNextsPrevsMonths,
    );
    actualIndex = _indexOfMonth(months, dateNow);
    _balances = _loadBalances();
  }

  // O erro é tratado pelo FutureBuilder; ignore() evita que ele conte como
  // não tratado antes de o FutureBuilder começar a ouvir.
  Future<MonthBalanceModel> _loadBalances() =>
      _balanceRepository.getBalances()..ignore();

  void _reloadBalances() {
    setState(() {
      _balances = _loadBalances();
    });
  }

  int _indexOfMonth(List<DateTime> list, DateTime month) => list.indexWhere(
    (date) => date.year == month.year && date.month == month.month,
  );

  String _buildTabBuilder(BuildContext context, int index) {
    return monthKey(months[index]);
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
      ...(isMorePast ? monthsBefore(months[0], initialNextsPrevsMonths) : []),
      ...months,
      ...(isMoreFuture
          ? monthsAfter(months[months.length - 1], initialNextsPrevsMonths)
          : []),
    ];
    newInitialIndex = _indexOfMonth(newMonths, actualMonth);

    setState(() {
      months = newMonths;
      actualIndex = newInitialIndex;
      typeBalancePage = TypeBalance.gains;
    });
  }

  Future<void> _onSubmitCreate(BalanceModel balance) async {
    await _balanceRepository.createBalance(
      balance.copyWith(
        date: dateForNewBalance(months[actualIndex], DateTime.now()),
      ),
    );
    _reloadBalances();
  }

  Future<void> _onDelete(
    BalanceModel balance, {
    bool onlyInstallment = false,
  }) async {
    if (onlyInstallment) {
      await _balanceRepository.deleteInstallment(
        balance.id!,
        balance.installment,
      );
    } else {
      await _balanceRepository.deleteBalance(balance.id!);
    }
    _reloadBalances();
  }

  // Manda à API só o que mudou. A data não vai: editar não muda o mês.
  // Em parcelado, o valor do formulário é o total e o "realizado" é por parcela.
  Future<void> _onSubmitEdit(BalanceModel original, BalanceModel edited) async {
    final id = original.id!;
    final fields = <String, dynamic>{
      if (edited.name != original.name) 'name': edited.name,
      if (edited.value != (original.totalValue ?? original.value))
        'value': edited.value,
      if (edited.totalInstallments != original.totalInstallments)
        'totalInstallments': edited.totalInstallments,
    };
    final realizedChanged = edited.realized != original.realized;
    final realizedPerInstallment =
        original.isInstallmented && edited.isInstallmented;
    if (realizedChanged && !realizedPerInstallment) {
      fields['realized'] = edited.realized;
    }

    if (fields.isNotEmpty) {
      await _balanceRepository.updateBalance(id, fields);
    }
    // Se a parcela deixou de existir (menos parcelas), não há o que marcar.
    if (realizedChanged &&
        realizedPerInstallment &&
        original.installment <= edited.totalInstallments) {
      await _balanceRepository.setInstallmentRealized(
        id,
        original.installment,
        edited.realized,
      );
    }
    _reloadBalances();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await (widget.onLogout ?? _logout)();
  }

  Future<void> _logout() async {
    await appInjector.get<AuthRepository>().logout();
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
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
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: Icon(
              Icons.logout,
              color: isGainTab ? AppColors.primary : AppColors.secondary,
            ),
            onPressed: _confirmLogout,
          ),
        ],
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
              future: _balances,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Não foi possível carregar os lançamentos',
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(color: AppColors.white),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _reloadBalances,
                          child: Text(
                            'Tentar de novo',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (snapshot.hasData) {
                  // Cada aba lê o próprio mês, não o mês selecionado.
                  final data = snapshot.data?.months[monthKey(months[index])];

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
                          onEdit: _onSubmitEdit,
                          onDelete: _onDelete,
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
