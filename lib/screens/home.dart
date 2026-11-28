import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/repository/auth.dart';
import 'package:planejamento_financeiro/screens/login.dart';
import 'package:planejamento_financeiro/commons/icons.dart';
import 'package:planejamento_financeiro/commons/routes.dart';
import 'package:planejamento_financeiro/commons/months.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/models/month_balance.dart';
import 'package:planejamento_financeiro/repository/balance.dart';
import 'package:planejamento_financeiro/repository/injector.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/overlay.dart';
import 'package:planejamento_financeiro/theme/spacing.dart';
import 'package:planejamento_financeiro/widgets/state_message.dart';
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
  // A última busca falhou: o botão + fica desativado até carregar de novo.
  bool _loadFailed = false;
  // O último resultado carregado: páginas novas (troca de mês, lista que
  // cresce) nascem com ele e não piscam o loader enquanto o Future resolve.
  MonthBalanceModel? _lastBalances;
  // A cor do fundo e do botão +: 0 em ganhos, 1 em gastos. Acompanha o dedo e
  // a animação das abas de tipo.
  final ValueNotifier<double> _tipo = ValueNotifier(0);

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
  Future<MonthBalanceModel> _loadBalances() {
    final future = _balanceRepository.getBalances();
    future.then(
      (data) {
        // Reconstruir aqui é o que leva o resultado às páginas que o
        // TabBarView ainda não montou: elas guardam o initialData do build.
        // Só a busca mais recente vale: uma recarga antiga que chega depois
        // não pode desfazer a nova.
        if (!mounted || !identical(future, _balances)) return;
        setState(() {
          _lastBalances = data;
          _loadFailed = false;
        });
      },
      onError: (_) {
        if (!mounted || !identical(future, _balances)) return;
        if (!_loadFailed) setState(() => _loadFailed = true);
      },
    );
    return future..ignore();
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

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

  void _handleTabProgress(double progress) {
    _tipo.value = progress.clamp(0.0, 1.0);
  }

  // Sem setState: o + lê o tipo no toque e as páginas novas leem ao montar.
  // Reconstruir a home inteira a cada troca de tipo custa quadros à toa.
  void _handleChangeBalance(String typeBalance) {
    typeBalancePage = typeBalance;
  }

  void _handleChangeMonth([int index = 0]) {
    List<DateTime> newMonths = months;
    int newInitialIndex = index;
    DateTime actualMonth = months[index];
    bool isMorePast = index <= 3;
    bool isMoreFuture = index >= (months.length - 4);

    // Só a lista que cresce precisa reconstruir a home; nos outros casos, a
    // página já está na tela e só guardamos o índice.
    if (!isMorePast && !isMoreFuture) {
      actualIndex = index;
      return;
    }

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
    });
  }

  Future<void> _onSubmitCreate(BalanceModel balance) async {
    await _balanceRepository.createBalance(
      balance.copyWith(
        date: dateForNewBalance(months[actualIndex], DateTime.now()),
      ),
    );
    _reloadBalances();
    _showMessage('Lançamento salvo');
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
    _showMessage('Lançamento excluído');
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
    _showMessage('Lançamento salvo');
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Seus lançamentos continuam salvos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
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
      fadeRoute((context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _tipo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: onBrandOverlay,
      // A cor segue as abas de tipo. O corpo vai como `child`, para não ser
      // reconstruído a cada quadro.
      child: ValueListenableBuilder<double>(
        valueListenable: _tipo,
        builder: (context, valor, body) {
          final tone = Color.lerp(
            AppColors.primary,
            AppColors.secondary,
            valor,
          )!;
          return Scaffold(
            backgroundColor: tone,
            body: body,
            floatingActionButton: FloatingActionButton(
              tooltip: 'Novo lançamento',
              onPressed: _loadFailed
                  ? null
                  : () => baseModal(
                      context,
                      FormBalance(
                        typeBalance: typeBalancePage,
                        onSubmit: _onSubmitCreate,
                      ),
                    ),
              backgroundColor: _loadFailed ? tone.withAlpha(110) : tone,
              foregroundColor: AppColors.white,
              child: const Icon(AppIcons.plus),
            ),
          );
        },
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: InfiniteTabView(
              initialIndex: actualIndex,
              length: months.length,
              onChangePage: _handleChangeMonth,
              buildTabBar: _buildTabBuilder,
              // O botão tem 48 dp e o ⋮ fica no meio: do centro à borda são
              // 24 dp, e os pontos têm 2 dp de raio. Deslocar o botão 22 dp
              // leva a borda dos pontos até a borda do conteúdo; a área de
              // toque e o efeito avançam sobre a margem da tela.
              trailing: Transform.translate(
                offset: const Offset(22, 0),
                child: PopupMenuButton<String>(
                  tooltip: 'Mais opções',
                  icon: const Icon(Icons.more_vert, color: AppColors.white),
                  onSelected: (_) => _confirmLogout(),
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(value: 'sair', child: Text('Sair')),
                  ],
                ),
              ),
              buildTabView: (context, index) => FutureBuilder(
                future: _balances,
                initialData: _lastBalances,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Material(
                        color: AppColors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.lg),
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: StateMessage(
                            icon: AppIcons.erro,
                            title: 'Não foi possível carregar os lançamentos',
                            action: TextButton(
                              onPressed: _reloadBalances,
                              child: const Text('Tentar de novo'),
                            ),
                          ),
                        ),
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
                            initialType: typeBalancePage,
                            onTabChanged: _handleChangeBalance,
                            onTabProgress: _handleTabProgress,
                            onEdit: _onSubmitEdit,
                            onDelete: _onDelete,
                          ),
                        ),
                      ],
                    );
                  }
                  return Center(child: AppLoad());
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
